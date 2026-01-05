import 'package:airgas/dashboard/bottomnavigation_screen.dart';
import 'package:airgas/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/service_provider.dart';
import '../response_model/truck_number_response.dart';

class TruckNumberScreen extends StatefulWidget {
  @override
  _TruckNumberScreenState createState() => _TruckNumberScreenState();
}

class _TruckNumberScreenState extends State<TruckNumberScreen> {
  final TextEditingController tractorController = TextEditingController();
  final TextEditingController trailerController = TextEditingController();

  TruckNumberModel truckNumberModel = TruckNumberModel();

  Future truckApi() async {
    try {
      truckNumberModel = await ServiceProvider().truckNumberAPi(
        truckNumber: tractorController.text.trim(),
        trailerNumber: trailerController.text.trim(),
      );
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F9FC), // Light background
      appBar: AppBar(
        title: Text('Fleet Tracker', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),

            // Tractor Number Field
            TextField(
              controller: tractorController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.local_shipping_outlined),
                labelText: 'Tractor Number',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide(color: Colors.black), // Add this
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  // 🔴 Black border here
                  borderRadius: BorderRadius.circular(15.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  // 🔴 Black focused border
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Trailer Number Field
            TextField(
              controller: trailerController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.confirmation_number_outlined),
                labelText: 'Trailer Number',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide(color: Colors.black), // Add this
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  // 🔴 Black border here
                  borderRadius: BorderRadius.circular(15.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  // 🔴 Black focused border
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),

            Spacer(),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  truckApi().whenComplete(() {
                    if (truckNumberModel.status == true) {
                      LocalStorages().saveTankNumber(
                        TankNumber: tractorController.text.trim(),
                      );
                      LocalStorages().saveTrailorNumber(
                        trailorNumber: trailerController.text.trim(),
                      );
                      Get.offAll(BottomBarScreen());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Submitted Successfully')),
                      );
                    }
                    setState(() {});
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
