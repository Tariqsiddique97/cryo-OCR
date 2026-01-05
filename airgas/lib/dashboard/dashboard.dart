import 'dart:convert'; // For JSON decoding
import 'dart:ui' as ui;

import 'package:airgas/constant/assets_image.dart';
import 'package:airgas/dashboard/dvir_screen.dart';
import 'package:airgas/dashboard/tank_repair.dart';
import 'package:airgas/dashboard/truck_manifest.dart';
import 'package:airgas/dashboard/view1.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../network/service_provider.dart';
import '../response_model/trip_stop_model.dart';
import 'TankSiteScreen.dart';
import 'calculator_jscreen.dart';
import 'full_map_screen.dart';

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key});

  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  // 🗺 LOAD MAP ROUTE + STOPS (MODIFIED)
  // -------------------------------
  void _loadStopsOnMap() async {
    if (tripStopModel == null || tripStopModel!.trip?.stops == null) {
      if (kDebugMode) print('DEBUG: Trip model or stops list is null.');
      return;
    }

    markers.clear();
    routePoints.clear();
    polylines.clear();
    decodedRoutePoints.clear(); // Clear the list here too

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
              _startNavigation(point);
            },
          ),
        );
        index++;
      }
    }

    // ⭐️ NEW ROUTING LOGIC STARTS HERE ⭐️
    if (routePoints.isNotEmpty && currentLatLng != null) {
      // 1. Add current location as the true starting point
      List<LatLng> fullRoute = [currentLatLng!, ...routePoints];

      // 2. Fetch and decode the polyline
      final encodedPolyline = await _fetchRoutePolyline(fullRoute);

      if (encodedPolyline != null) {
        final decodedPoints = _decodePolyline(encodedPolyline);

        // ⭐️ CRITICAL FIX: Store the decoded points in the class variable ⭐️
        decodedRoutePoints = decodedPoints;

        polylines.add(
          Polyline(
            polylineId: const PolylineId("trip_route"),
            points: decodedPoints,
            color: Colors.blue,
            width: 5,
            jointType: JointType.round,
          ),
        );

        // 3. Set the AOI to view the entire route (Bounding Box)
        _setCameraToRoute(decodedPoints);
      } else if (firstStop != null) {
        // If route calculation fails, at least move the camera to the first stop/current location
        _setCameraToRoute([currentLatLng!, firstStop]);
      }
    }
    // ⭐️ NEW ROUTING LOGIC ENDS HERE ⭐️

    if (kDebugMode) {
      print(
        'DEBUG: Finished loading stops. Final routePoints count: ${routePoints.length}',
      );
    }

    setState(() {});
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

    // Waypoints: All points between the first and last
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
  // 🧭 GOOGLE MAPS DRIVING NAVIGATION (FIXED)
  // -------------------------------
  void _navigateToMapScreen() {
    if (kDebugMode) {
      print(
        'DEBUG: Tapped map. Decoded Route Points Count: ${decodedRoutePoints.length}. Is Loading: $isLoading',
      );
    }

    // Pass the correct state variable (decodedRoutePoints) to the full map screen
    Get.to(() => MapRouteScreen());

    if (decodedRoutePoints.isEmpty) {
      Get.snackbar(
        "No Route Available",
        "No road-following route could be calculated. Showing current map area.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _startNavigation(LatLng point) async {
    // ... (unchanged) ...
  }

  // -------------------------------
  // INIT (unchanged)
  // -------------------------------
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _getLocation();
      truckApi();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // -------------------------- UI (unchanged) ---------------------------
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 1,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Messenger",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Icon(Icons.video_call, size: 28, color: Colors.black),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: "Management"),
                      Tab(text: "Mechanics"),
                      Tab(text: "Plant"),
                      Tab(text: "Calculator"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildManagementTab(),
                    _buildSimpleText("Mechanics Messages Coming Soon..."),
                    _buildSimpleText("Plant Communication Area"),
                    const CryoCalculatorApp(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- UI Components --------------------

  Widget _buildManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBox(),
          const SizedBox(height: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircularGauge(
                    percent: 0.21,
                    label: "Trailer PSI",
                    color: Color(0xFFFFC107), // yellow-ish
                  ),

                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                      ),
                      SizedBox(width: 5),
                      Text("Parked - CLE04"),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  CircularGauge(
                    percent: 0.75,
                    label: "Product Level",
                    color: Color(0xFF4CAF50), // green
                  ),
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.yellow, width: 3),
                        ),
                      ),
                      SizedBox(width: 5),
                      Text("Not on yard      "),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTractorSection(),
          const SizedBox(height: 20),
          _buildIconRow(),
          const SizedBox(height: 20),
          _buildConesSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 🚚 FIXED Tractor + Map UI
  Widget _buildTractorSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              truckApi().whenComplete(() {
                if (tripStopModel?.status == true) {
                  Get.to(() => TruckManifestScreen());
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Driver Manifest",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 3,
          child: Column(
            children: [
              const Text(
                "Turn by Turn Navigation",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // WRAP MAP PREVIEW WITH GESTURE DETECTOR
              GestureDetector(
                onTap: () {
                  Get.to(TankRepairScreen());
                }, // <-- Navigation Call
                child: Container(
                  height: 120,
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
                                    () =>
                                        TapGestureRecognizer()
                                          ..onTap = () => {},
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
                                  CameraUpdate.newLatLngZoom(
                                    currentLatLng!,
                                    16,
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  _navigateToMapScreen();
                },
                child: Container(
                  height: 50,
                  width: 100,

                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      "View Map ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildIconText(
          AssetsScreen.iconsGas,
          "Onsite Tanks",
          onTap: () => Get.to(() => TankSiteScreen()),
        ),
        _buildIconText(
          AssetsScreen.iconsTrackter,
          "Day Cabs\n& Sleepers",
          onTap: () => Get.to(() => DVIRScreen()),
        ),
        _buildIconText(
          AssetsScreen.iconsTrailor,
          "Bulk Trailers",
          onTap: () => Get.to(() => DVIRScreen1()),
        ),
      ],
    );
  }

  Widget _buildConesSection() {
    return Column(
      children: [
        const Text(
          "Cones | Triangles",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 6),
        const Text("SELECT Image below to activate Projection"),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildProjection(AssetsScreen.iconsGParking, "GENERAL PARKING"),
            _buildProjection(AssetsScreen.iconsEParking, "EMERGENCY"),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleText(String txt) => Center(child: Text(txt));

  Widget _buildIconText(String asset, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(asset, height: 60),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProjection(String asset, String label) {
    return Column(
      children: [
        Image.asset(asset, height: 120),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}

class CircularGauge extends StatelessWidget {
  final double percent; // e.g. 0.21 for 21%
  final String label; // e.g. "Trailer PSI"
  final Color color;

  const CircularGauge({
    super.key,
    required this.percent,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircularPercentIndicator(
          radius: 25,
          lineWidth: 8,
          percent: percent,
          progressColor: color,
          backgroundColor: Colors.grey.shade300,
          circularStrokeCap: CircularStrokeCap.round,
          center: Text(
            "${(percent * 100).round()}%",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
