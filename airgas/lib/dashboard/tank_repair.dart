import 'dart:io';

import 'package:airgas/dashboard/bottomnavigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'tank_repair_api.dart';

class TankRepairScreen extends StatefulWidget {
  @override
  _TankRepairScreenState createState() => _TankRepairScreenState();
}

class _TankRepairScreenState extends State<TankRepairScreen> {
  final TextEditingController notesController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  List<File> photos = [];
  List<File> videos = [];

  double? latitude;
  double? longitude;

  GoogleMapController? mapController;
  LatLng? currentLatLng;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  /// ============================
  /// 🌍 Fetch Current GPS Location
  /// ============================
  Future<void> _getLocation() async {
    await Geolocator.requestPermission();

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = pos.latitude;
    longitude = pos.longitude;

    currentLatLng = LatLng(latitude!, longitude!);

    setState(() {});

    /// Move map camera when ready
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng!, 15),
      );
    }
  }

  /// ============================
  /// 📸 Pick Photo
  /// ============================
  Future pickPhoto() async {
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      photos.add(File(file.path));
      setState(() {});
    }
  }

  /// ============================
  /// 🎥 Pick Video
  /// ============================
  Future pickVideo() async {
    final file = await picker.pickVideo(source: ImageSource.camera);
    if (file != null) {
      videos.add(File(file.path));
      setState(() {});
    }
  }

  /// ============================
  /// 🚀 Submit API
  /// ============================
  Future submitReport() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (latitude == null || longitude == null) {
      await _getLocation();
    }

    if (latitude == null) {
      setState(() => isLoading = false);
      Get.snackbar(
        "Location Error",
        "GPS location not found",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
      return;
    }

    var api = TankRepairAPI();

    try {
      var response = await api.submitTankRepair(
        tripId: 6,
        latitude: latitude!,
        longitude: longitude!,
        notes: notesController.text,
        photos: photos,
        videos: videos,
      );

      if (response.data['status'] == true) {
        setState(() => isLoading = false);

        Get.offAll(() => BottomBarScreen());

        Future.delayed(Duration(milliseconds: 300), () {
          Get.rawSnackbar(
            title: "Success",
            message: "Data Successfully submit",
            backgroundColor: Colors.green.shade100,
            duration: Duration(seconds: 3),
          );
        });
      } else {
        setState(() => isLoading = false);

        Get.snackbar(
          "Error",
          response.data['message'] ?? "Server Error",
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);

      Get.snackbar(
        "Error",
        "API Request Failed",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    }
  }

  /// ============================
  /// UI BUILD
  /// ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tank Repair"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),

      body: Column(
        children: [
          /// ============================
          /// 🗺 GOOGLE MAP (NO SCROLL)
          /// ============================
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: currentLatLng == null
                  ? Center(child: CircularProgressIndicator())
                  : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentLatLng!,
                  zoom: 18, // 🔥 High zoom like screenshot
                ),
                onMapCreated: (controller) {
                  mapController = controller;

                  // Lock camera to this position after map loads
                  mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(currentLatLng!, 18),
                  );
                },

                // Disable gestures like your screenshot (optional)
                zoomGesturesEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,

                // Show ONLY one marker (blue dot style)
                markers: {
                  Marker(
                    markerId: MarkerId("current_location"),
                    position: currentLatLng!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  ),
                },
              )

            ),
          ),

          /// ============================
          /// SCROLLABLE CONTENT
          /// ============================
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Notes
                    Text(
                      "Notes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write your notes...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),

                    /// Media buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: pickPhoto,
                          icon: Icon(Icons.camera_alt),
                          label: Text("Add Photo"),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: pickVideo,
                          icon: Icon(Icons.videocam),
                          label: Text("Add Video"),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    /// Photos preview
                    Wrap(
                      spacing: 10,
                      children: photos.map((file) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            file,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10,),
                    Wrap(
                      spacing: 10,
                      children: videos.map((file) {
                        return Container(
                          width: 80,
                          height: 60,
                          color: Colors.black12,
                          child: Icon(Icons.videocam, color: Colors.red),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),

                    /// Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitReport,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Submit Report",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
