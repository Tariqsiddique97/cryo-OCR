import 'dart:convert';

import 'package:airgas/response_model/inspection_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // ✅ for date formatting

import '../network/service_provider.dart';
import '../util.dart';
import 'bottomnavigation_screen.dart';

class DVIRScreen1 extends StatefulWidget {
  const DVIRScreen1({super.key});

  @override
  State<DVIRScreen1> createState() => _DVIRScreen1State();
}

class _DVIRScreen1State extends State<DVIRScreen1> {
  InspectionReportModel inspectionReportModel = InspectionReportModel();
  bool _loading = true;

  /// 🧾 Controllers
  final TextEditingController vehicleController = TextEditingController(
    text: "${LocalStorages().gettrailorNumber()}",
  );
  final TextEditingController locationController = TextEditingController();
  final TextEditingController odometerController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  final TextEditingController driverController = TextEditingController();

  /// Stores user selections
  final Map<String, Set<String>> selectedItems = {};

  /// Current Date
  late String currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now()); // ✅ API format
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadInspectionData();
    });
  }

  Future<void> loadInspectionData() async {
    try {
      final result = await ServiceProvider().inspectionAPiTrailor();
      setState(() {
        inspectionReportModel = result;
        _loading = false;

        // Initialize empty sets for each checklist group
        for (var section in inspectionReportModel.checklist ?? []) {
          selectedItems[section.group ?? ""] = {};
        }
      });
    } catch (e) {
      print('Error occurred: $e');
      setState(() => _loading = false);
    }
  }

  /// 🔹 API Call for submitting inspection report
  Future<void> submitInspectionReport() async {
    try {
      // Collect selected inspection items
      List<String> selectedChecks = [];
      selectedItems.forEach((group, items) {
        selectedChecks.addAll(items);
      });

      // Prepare request body
      final body = {
        "vehicle_type": "trailer",
        "vehicle_number": vehicleController.text.trim(),
        "location_name": locationController.text.trim(),
        "odometer_reading": int.tryParse(odometerController.text.trim()) ?? 0,
        "inspection_date": currentDate, // ✅ current date
        "driver_name": driverController.text.trim(), // ✅ driver name field
        "comments": commentController.text.trim(),
        "inspection_checks": selectedChecks.join(","),
      };

      print("📤 Sending Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(
          "http://ec2-18-206-172-221.compute-1.amazonaws.com/api/inspection-report",
        ),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        },
        body: jsonEncode(body),
      );

      print("📥 API Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data["status"] == true) {
          ServiceProvider().showSnackBar(
            "Success",
            "Inspection report submitted successfully!",
          );
          Get.offAll(BottomBarScreen());
        } else {
          ServiceProvider().showSnackBar(
            "Error",
            data["message"] ?? "Submission failed",
            isError: true,
          );
        }
      } else {
        ServiceProvider().showSnackBar(
          "Error",
          "Failed with status: ${response.statusCode}",
          isError: true,
        );
      }
    } catch (e) {
      ServiceProvider().showSnackBar(
        "Error",
        "Something went wrong: $e",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final checklists = inspectionReportModel.checklist ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Airgas DVIR",
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      /// ✅ Bottom submit button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ElevatedButton(
          onPressed: submitInspectionReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Submit",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),

      /// ✅ Dynamic Body
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),

            Text(
              "Driver Vehicle Inspection Report",
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "REMARKS - Items marked with * are safety related & must be repaired prior to equipment’s next use.",
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: odometerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Odometer Reading",
                      prefixIcon: const Icon(Icons.speed, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: "Location Name",
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    // controller: odometerController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Tractor and truck number",
                      prefixIcon: const Icon(Icons.speed, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    // controller: locationController,
                    decoration: InputDecoration(
                      labelText: "tripReport",
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ✅ Dynamic Sections
            ...checklists.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildSection(section),
              );
            }),

            const SizedBox(height: 20),

            _buildCommentCard(),
          ],
        ),
      ),
    );
  }

  /// 🔹 Header info
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            controller: vehicleController,
            decoration: InputDecoration(
              hintText: "${LocalStorages().gettrailorNumber()}",
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text("RED TAGGED", style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 Checklist section
  Widget _buildSection(Checklist section) {
    final groupName = section.group ?? "";
    final items = section.items ?? [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final selected = selectedItems[groupName]!.contains(item.id);
                final isSafety = item.isSafety ?? false;

                return ChoiceChip(
                  selected: selected,
                  onSelected: (bool value) {
                    setState(() {
                      if (value) {
                        selectedItems[groupName]!.add(item.id ?? "");
                      } else {
                        selectedItems[groupName]!.remove(item.id ?? "");
                      }
                    });
                  },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label ?? "",
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isSafety)
                        const Text(
                          " *",
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.black,
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Comments + Driver info section
  Widget _buildCommentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Comments:",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: commentController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter comments...",
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Driver Name:",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: driverController,
              decoration: const InputDecoration(
                hintText: "Enter Driver Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "DATE: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                // ✅ Display format
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
