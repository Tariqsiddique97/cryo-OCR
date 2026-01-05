import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TsrPdRSScreen extends StatelessWidget {
  const TsrPdRSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
            onTap: (){
              Get.back();
            },
            child: Icon(Icons.arrow_back_ios_new, color: Colors.black)),
        title: Text(
          "TSR-PDRS",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(Icons.camera_alt, color: Colors.black),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton("New", false),
                _buildButton("Update", false),
                _buildButton("Tank Repair", true),
              ],
            ),
            const SizedBox(height: 16),

            /// Header
            Text(
              "TSR-PDRS SITE ASSESSMENT & PERSONAL RISK REPORT",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            /// Form Details
            _buildLine("Driver Name:", "Date:"),
            _buildLine("Customer:", "Terminal Manager:"),
            _buildLine("St Address:", "City:   State:"),
            _buildLine("Tank ID:", "Tech Service   PDRS   Personal Risk Area"),
            _buildLine("Product: Choose One:", "LOX | LIN | LAR | CO2 | HY | OTHER"),
            const SizedBox(height: 16),

            /// Tech Service Report
            Text(
              "Tech Service (TSR) Report:  (in space below)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Location and Type of Problem:"),
            const SizedBox(height: 8),

            _wrapChips([
              "Fill Connection",
              "House Line",
              "Liq Level Gauge",
              "Site",
              "Fill Line",
              "Hospital Box",
              "Low Pressure",
              "Tank",
              "Gas Leak",
              "Ice Build-up",
              "PB Coil",
              "Telemetry Meter",
              "High Pressure",
              "Liquid Leak",
              "Pressure Gauge",
              "Valves",
              "Vaporizer",
            ]),

            const SizedBox(height: 12),
            Text("Comments:"),
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.purple.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),

            /// Risk Report
            Text(
              "Potential Delivery Risk Site Report (description of hazard & Recommended solution) "
                  "Mark all that apply: Use blanks for other issues:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _wrapChips([
              "Grease / Oil",
              "Improper Storage of Flammables",
              "Drive too Narrow",
              "Inappropriate Ingress and Egress",
              "Obstructions",
              "Unstable Structure",
              "Personal Risk Area",
              "Off Loading Pad",
              "Ventilation",
            ]),

            const SizedBox(height: 12),
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.purple.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 16),

            /// Images Attached
            Text("Images Attached *"),
            _buildLine("Technical Service Request Called into NLC:", "YES   |   NO"),
            _buildLine("NLC Contact Name:", "Entered in DB by:"),
            const SizedBox(height: 12),

            /// Notes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("• Class A Emergency - Failed Delivery. Site must be corrected before next delivery."),
                Text("• Class B Site needs corrected before next delivery can occur."),
                Text("• Class C Site needs attention and will be repaired as soon as possible"),
                Text("• Class D Site needs attention when scheduling allows, but no later than the next tank PM"),
              ],
            ),
            const SizedBox(height: 20),

            /// Submit Button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {},
                child: Text("SUBMIT"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, bool isFilled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isFilled ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isFilled ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLine(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(left)),
          Expanded(child: Text(right, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _wrapChips(List<String> items) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items
          .map(
            (e) => Text(
          e,
          style: TextStyle(fontSize: 15),
        ),
      )
          .toList(),
    );
  }
}
