import 'dart:convert'; // For JSON decoding
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../network/service_provider.dart';
import '../response_model/trip_stop_model.dart';

class MapRouteScreen extends StatefulWidget {
  const MapRouteScreen({super.key});

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  TripStopModel? tripStopModel;
  bool isLoading = true;

  GoogleMapController? mapController;
  LatLng? currentLatLng;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> routePoints = [];

  // ⭐️ CRITICAL FIX: This stores the detailed road path for the full map view. ⭐️
  List<LatLng> decodedRoutePoints = [];

  // ⚠️ Replace with your actual Google Maps Directions API Key
  static const String GOOGLE_API_KEY =
      "AIzaSyAocbSLfNBPGEElNem-VEPyIdNTwHSY7m8";

  // -------------------------------
  // 🚛 TRIP STOPS API (unchanged)
  // -------------------------------
  Future<void> truckApi() async {
    try {
      final result = await ServiceProvider().tripStopApi();

      setState(() {
        tripStopModel = result;
        isLoading = false;
      });

      _loadStopsOnMap();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching truck API: $e");
      }
      setState(() => isLoading = false);
    }
  }

  // -------------------------------
  // 📍 Get current GPS (unchanged)
  // -------------------------------
  Future<void> _getLocation() async {
    await Geolocator.requestPermission();

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    currentLatLng = LatLng(pos.latitude, pos.longitude);

    setState(() {});

    if (mapController != null && currentLatLng != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng!, 16),
      );
    }
  }

  // -------------------------------
  // 🟢 Create dynamic stop icon (unchanged)
  // -------------------------------
  Future<BitmapDescriptor> _createStopIcon(int number) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint circle = Paint()..color = Colors.red;
    canvas.drawCircle(const Offset(40, 40), 35, circle);

    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(40 - textPainter.width / 2, 40 - textPainter.height / 2),
    );

    final img = await recorder.endRecording().toImage(80, 80);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // -------------------------------
  // 🗺 LOAD ALL STOPS ON MAP (REFACTORED)
  // -------------------------------
  void _loadStopsOnMap() async {
    if (tripStopModel == null || tripStopModel!.trip?.stops == null) {
      if (kDebugMode) print('DEBUG: Trip model or stops list is null.');
      return;
    }

    // Clear previous markers, but keep polylines clear for now
    markers.clear();
    routePoints.clear();

    final stops = tripStopModel!.trip!.stops;
    int index = 1;
    LatLng? firstStop;

    for (var s in stops!) {
      final lat = double.tryParse(s.latitude ?? "");
      final lng = double.tryParse(s.longitude ?? "");

      if (lat != null && lng != null) {
        final point = LatLng(lat, lng);
        routePoints.add(point);
        if (firstStop == null) firstStop = point;

        final icon = await _createStopIcon(index);

        markers.add(
          Marker(
            markerId: MarkerId("stop_${s.id}"),
            position: point,
            icon: icon,
            infoWindow: InfoWindow(
              title: "Stop $index",
              snippet: s.address ?? "",
            ),
            onTap: () {
              _moveToStop(point);
              // 🎯 IMPLEMENTATION: Start navigation to the tapped stop
              _startNavigation(point, index);
            },
          ),
        );
        index++;
      }
    }

    // After loading stops and markers, load the full route overview
    _loadFullTripRoute();
  }

  // -------------------------------
  // 🗺 LOAD FULL TRIP ROUTE (NEW)
  // -------------------------------
  Future<void> _loadFullTripRoute() async {
    polylines.clear();
    decodedRoutePoints.clear();

    if (routePoints.isNotEmpty && currentLatLng != null) {
      // 1. Add current location as the true starting point
      List<LatLng> fullRoute = [currentLatLng!, ...routePoints];

      // 2. Fetch and decode the polyline
      final encodedPolyline = await _fetchRoutePolyline(fullRoute);

      if (encodedPolyline != null) {
        final decodedPoints = _decodePolyline(encodedPolyline);

        // Store the decoded points for the full map screen
        decodedRoutePoints = decodedPoints;

        polylines.add(
          Polyline(
            polylineId: const PolylineId("trip_route"),
            points: decodedPoints,
            color: Colors.blue,
            // Full trip route in Blue
            width: 5,
            jointType: JointType.round,
          ),
        );

        // 3. Set the AOI to view the entire route (Bounding Box)
        _setCameraToRoute(decodedPoints);
      } else if (routePoints.isNotEmpty) {
        // If route calculation fails, at least move the camera to the full area
        _setCameraToRoute([currentLatLng!, ...routePoints]);
      }
    }

    // Ensure all markers are visible after route re-load
    setState(() {});
  }

  // -------------------------------
  // 🧭 START NAVIGATION (NEW IMPLEMENTATION)
  // -------------------------------
  void _startNavigation(LatLng destination, int stopNumber) async {
    if (currentLatLng == null) {
      Get.snackbar(
        "Error",
        "Your current location is not available.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 1. Prepare the route (from current location to the tapped stop/destination)
    // Only two points: current location and the next stop. No other waypoints.
    List<LatLng> navigationRoute = [currentLatLng!, destination];

    // 2. Fetch and decode the polyline for this specific route
    final encodedPolyline = await _fetchRoutePolyline(navigationRoute);

    if (encodedPolyline != null) {
      final decodedPoints = _decodePolyline(encodedPolyline);

      // 3. Update state to display the new, specific navigation route
      setState(() {
        polylines.clear(); // Clear the old full trip route
        decodedRoutePoints =
            decodedPoints; // The current active route is now this navigation route

        polylines.add(
          Polyline(
            polylineId: const PolylineId("navigation_route"),
            points: decodedPoints,
            color: Colors.red,
            // Navigation route in Red
            width: 6,
            jointType: JointType.round,
          ),
        );
      });

      // 4. Set the camera to view the navigation route
      _setCameraToRoute(decodedPoints);

      Get.snackbar(
        "Navigation Started",
        "Route from current location to Stop $stopNumber is displayed.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "Route Error",
        "Could not find a route from your current location to the stop.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -------------------------------
  // 📡 API CALL TO GOOGLE DIRECTIONS (unchanged)
  // -------------------------------
  Future<String?> _fetchRoutePolyline(List<LatLng> points) async {
    if (points.length < 2) return null;

    // Origin: Current location (first point)
    final origin = "${points.first.latitude},${points.first.longitude}";
    // Destination: Final stop (last point)
    final destination = "${points.last.latitude},${points.last.longitude}";

    // Waypoints: All points between the first and last (will be empty for _startNavigation)
    final waypoints = points
        .sublist(1, points.length - 1)
        .map((p) => "${p.latitude},${p.longitude}")
        .join('|');

    final url = 'https://maps.googleapis.com/maps/api/directions/json?';

    // Construct the full URI
    final uri = Uri.parse(
      '$url'
      'origin=$origin'
      '&destination=$destination'
      // Only include waypoints if they exist to avoid a bad request
      '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}'
      '&mode=driving' // Set travel mode to driving
      '&key=$GOOGLE_API_KEY',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['routes'] != null && json['routes'].isNotEmpty) {
          // Extract the encoded polyline string
          return json['routes'][0]['overview_polyline']['points'];
        }
      }
      if (kDebugMode) {
        print(
          "Directions API Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      if (kDebugMode) print("HTTP Request Error: $e");
    }
    return null;
  }

  // -------------------------------
  // 🧩 DECODE POLYLINE STRING (unchanged)
  // -------------------------------
  List<LatLng> _decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

    return result
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  // -------------------------------
  // 🎯 Set Camera to Route Bounding Box (AOI) (unchanged)
  // -------------------------------
  void _setCameraToRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate the camera to fit the entire route
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        50, // Padding around the edges in pixels
      ),
    );
  }

  // -------------------------------
  // 📍 move camera (unchanged)
  // -------------------------------
  void _moveToStop(LatLng point) {
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 15));
  }

  // -------------------------------
  // 🧭 GOOGLE MAPS DRIVING NAVIGATION (UNCHANGED)
  // -------------------------------
  void _navigateToMapScreen() {
    if (kDebugMode) {
      print(
        'DEBUG: Tapped map. Decoded Route Points Count: ${decodedRoutePoints.length}. Is Loading: $isLoading',
      );
    }

    // Placeholder for actual navigation to a full screen map
    if (decodedRoutePoints.isEmpty) {
      Get.snackbar(
        "No Route Available",
        "No road-following route could be calculated. Showing current map area.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -------------------------------
  // INIT (unchanged)
  // -------------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getLocation();
      truckApi();
    });
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // -------------------------- UI (MODIFIED) ---------------------------
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [_buildManagementTab()])),
    );
  }

  // -------------------- UI Components --------------------

  Widget _buildManagementTab() {
    // Helper function to get the coordinates of the next stop (Stop 1)
    String getNextStopCoordinates() {
      if (routePoints.isEmpty) return "Loading/No stops";
      final nextStop = routePoints.first;
      return "Stop 1: Lat ${nextStop.latitude.toStringAsFixed(4)}, Lon ${nextStop.longitude.toStringAsFixed(4)}";
    }

    // Helper function to get current location coordinates
    String getCurrentCoordinates() {
      if (currentLatLng == null) return "Loading GPS...";
      return "Current Loc: Lat ${currentLatLng!.latitude.toStringAsFixed(4)}, Lon ${currentLatLng!.longitude.toStringAsFixed(4)}";
    }

    // Helper function to get the final stop coordinates (Stop N)
    String getFinalStopCoordinates() {
      if (routePoints.length < 2) return "Single stop/Loading";
      final finalStop = routePoints.last;
      return "Final Stop: Lat ${finalStop.latitude.toStringAsFixed(4)}, Lon ${finalStop.longitude.toStringAsFixed(4)}";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        children: [
          const Text(
            "Turn by Turn Navigation",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          // ⭐️ Address/Coordinate Display ⭐️
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getCurrentCoordinates(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  getNextStopCoordinates(),
                  style: const TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  getFinalStopCoordinates(),
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ],
            ),
          ),

          // ⭐️ END OVERLAY ⭐️
          const SizedBox(height: 15),

          // MAP PREVIEW SECTION
          GestureDetector(
            onTap: () {
              // Get.to(TankRepairScreen());
            }, // <-- Navigation Call
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: currentLatLng == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        // ⭐️ FIX: Allow tap to pass to parent GestureDetector
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                              Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                              ),
                              Factory<HorizontalDragGestureRecognizer>(
                                () => HorizontalDragGestureRecognizer(),
                              ),
                              Factory<TapGestureRecognizer>(
                                () => TapGestureRecognizer()..onTap = () => {},
                              ),
                            },

                        // Keep existing map properties for the preview
                        initialCameraPosition: CameraPosition(
                          target: currentLatLng!,
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        zoomControlsEnabled: false,
                        polylines: polylines,
                        markers: markers,
                        onMapCreated: (controller) {
                          mapController = controller;
                          if (currentLatLng != null && polylines.isEmpty) {
                            // Only animate to current location if no full route is loaded yet
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(currentLatLng!, 16),
                            );
                          }
                        },
                      ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ⭐️ NEW: Button to reset to the Full Trip Route ⭐️
              // GestureDetector(
              //   onTap: () {
              //     _loadFullTripRoute();
              //     Get.snackbar("Route Reset", "Displaying full trip route overview.", snackPosition: SnackPosition.BOTTOM);
              //   },
              //   child: Container(
              //     height: 50,
              //     padding: const EdgeInsets.symmetric(horizontal: 15),
              //     decoration: BoxDecoration(
              //       color: Colors.blueGrey,
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //     child: const Center(
              //       child: Text("Full Route", style: TextStyle(color: Colors.white)),
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
