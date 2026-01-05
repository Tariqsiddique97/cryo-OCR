import 'dart:convert';
import 'dart:io';

import 'package:airgas/dashboard/TankGaugesScreen.dart';
import 'package:airgas/dashboard/tank_repair.dart';
import 'package:airgas/response_model/stop_progress_model.dart';
import 'package:airgas/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../network/service_provider.dart';

const String _kApiKey = 'AIzaSyCQuNf48yYC7ylH8xst51bgGq_fwg-Zjhs';

class TankSiteScreen extends StatefulWidget {
  const TankSiteScreen({super.key});

  @override
  State<TankSiteScreen> createState() => _TankSiteScreenState();
}

class _TankSiteScreenState extends State<TankSiteScreen> {
  File? _capturedImage;
  StopProgressModel stopProgressModel = StopProgressModel();
  String? _photoTakenTime;
  String? _apiphotoTakenTime;

  // Controllers
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController fullTrycockController = TextEditingController();
  final TextEditingController attnDriverMaintainController =
      TextEditingController();
  final TextEditingController tankInformationNumber = TextEditingController();

  var isLoading = false;

  String formatDateTimeForApi(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final formatted =
        '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}.'
        '${utc.microsecond.toString().padLeft(6, '0')}+00:00';
    return formatted;
  }

  String formatDisplayTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  String formatIsoTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final formatted =
        '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}.'
        '${utc.microsecond.toString().padLeft(6, '0')}+00:00';
    return formatted;
  }

  /// Camera picker
  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final now = DateTime.now();
      final file = File(pickedFile.path);

      setState(() {
        _capturedImage = file;

        _photoTakenTime = formatDisplayTime(now);
        _apiphotoTakenTime = formatIsoTime(now);
      });


      final result = await AiService.extractTankSiteInfo(file);

      if (!mounted) return;

      if (result.containsKey("error")) {
        final err = result["error"];
        String msg = "Could not read form, please retry.";
        if (err == "NO_KEY") {
          msg = "No API key configured.";
        } else if (err == "QUOTA") {
          msg = "AI quota exceeded. Check Google AI billing / rate limits.";
        } else if (err == "OVERLOADED") {
          msg = "Model overloaded, please try again in a bit.";
        } else if (err == "PARSE") {
          msg = "AI output was unreadable, retry form scan.";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));

        return;
      }
      tankInformationNumber.text = result["tank_id"] ?? "";
      fullTrycockController.text = result["full_trycock"] ?? "";
      attnDriverMaintainController.text = result["attn_driver"] ?? "";

      await LocalStorages().saveImage(Image: file.path);
      await LocalStorages().saveTankInformationTime(
        tankInformationTIme: _apiphotoTakenTime ?? "",
      );
    } catch (e) {
      debugPrint("Form Camera/OCR Error: $e");
      if (mounted) {

      }
    }
  }

  /// Fetch Stop Progress API
  Future<void> truckStopProgressApi() async {
    setState(() => isLoading = true);
    try {
      final result = await ServiceProvider().stopInProgressApi();

      setState(() {
        stopProgressModel = result;
        isLoading = false;
      });

      if (stopProgressModel.stop != null) {
        final stop = stopProgressModel.stop!;
        startTimeController.text = stop.startTime ?? "";
        endTimeController.text = stop.endTime ?? "";
        fullTrycockController.text = stop.fullTrycock?.toString() ?? "";
        attnDriverMaintainController.text =
            stop.attnDriverMaintain?.toString() ?? "";
        tankInformationNumber.text = stop.tankNumber?.toString() ?? "";
      } else {
        startTimeController.text = "";
        endTimeController.text = "";
        fullTrycockController.text = "";
        attnDriverMaintainController.text = "";
        tankInformationNumber.text = "";
      }
    } catch (e) {
      debugPrint('Error occurred: $e');
      setState(() => isLoading = false);
    }
  }

  /// DateTime Picker (fixed to match API format)
  Future<void> _pickDateTime(TextEditingController controller) async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (pickedTime == null) return;

    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final formatted = formatDateTimeForApi(finalDateTime);

    controller.text = formatted;
    debugPrint("✅ Formatted DateTime for API: $formatted");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      truckStopProgressApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text("Tank Site"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Filter Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip("On Site", true, () {}),
                      _chip("New", false, () {}),
                      _chip("Update", false, () {}),
                      _chip("Tank Repair", false, () {
                        Get.to(() => TankRepairScreen());
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// Image + Camera
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Image 1",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickImageFromCamera,
                        child: const Icon(Icons.camera_alt_outlined, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _capturedImage != null
                        ? Image.file(
                            _capturedImage!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : stopProgressModel.stop?.tankInformationImage == null
                        ? Container(
                            height: 220,
                            color: Colors.grey,
                            child: Center(child: Text("Click on Camera")),
                          )
                        : Image.network(
                            "http://ec2-18-206-172-221.compute-1.amazonaws.com${stopProgressModel.stop?.tankInformationImage ?? ""}",
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Text(
                    _photoTakenTime != null
                        ? "Time: $_photoTakenTime"
                        : "No photo taken yet",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// ----------- PARAMETER FIELDS -----------
                  _buildTextField(
                    "Tank Information Number",
                    tankInformationNumber,
                    readOnly:
                        stopProgressModel.stop?.tankNumber != null &&
                        stopProgressModel.stop!.tankNumber!.isNotEmpty,
                    hint: "0",
                  ),
                  // _buildDateTimeField("Start Time", startTimeController),
                  // _buildDateTimeField("End Time", endTimeController),
                  _buildTextField(
                    "Full Trycock",
                    fullTrycockController,
                    hint: "0",
                  ),
                  _buildTextField(
                    "Attn Driver Maintain",
                    attnDriverMaintainController,
                    hint: "0",
                  ),

                  const SizedBox(height: 20),

                  /// Submit Button + Note
                  Column(
                    children: [
                      Text(
                        "Note: The Tank will be verified by the pre-populated information on the manifest. "
                        "If it doesn't match, the button will turn red. If it matches, it will turn green.",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 44,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (_capturedImage != null) {
                              LocalStorages().saveImage(
                                Image: _capturedImage!.path,
                              );
                              LocalStorages().saveTankInformationTime(
                                tankInformationTIme: _apiphotoTakenTime ?? "",
                              );
                            }
                            Get.to(
                              () => TankGaugesScreen(
                                startTimeController: startTimeController.text
                                    .trim(),
                                fullTrycockController: fullTrycockController
                                    .text
                                    .trim(),
                                attnDriverMaintainController:
                                    attnDriverMaintainController.text.trim(),
                                tankNumber: tankInformationNumber.text.trim(),
                              ),
                            );
                          },
                          child: const Text(
                            "Submit",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Footer
                  const Center(
                    child: Text(
                      "All information is image driven",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Custom chip builder
  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.black,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool readOnly = false, // ✅ add this parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        readOnly: readOnly,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class AiService {
  static Future<String> extractValue(File imageFile, String fieldType) async {
    if (_kApiKey.isEmpty || _kApiKey == 'YOUR_API_KEY_HERE') {
      debugPrint('AI Error: NO API KEY');
      return "NO_KEY";
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const formatRule =
          "Answer with exactly one line in this format: VALUE=123 "
          "(only digits or digits with decimal, no units, no other text).";

      late String taskInstruction;

      switch (fieldType) {
        case 'tank_info':
          taskInstruction =
              "You see a form titled BULK INSTALLATION DATA. Find the field "
              "'TANK IDENTIFICATION NUMBER'. Read only the number in that "
              "field (ignore any letters or hyphens).";
          break;

        case 'totalizer':
          taskInstruction =
              "You see a gas flow meter display (e.g. NUFLO or Turbines Inc). "
              "Find the LARGE main TOTALIZER value in the center of the screen "
              "(e.g. 4758, 3716). Do not use any serial numbers or dates.";
          break;

        case 'bulk_monitor':
          taskInstruction =
              "You see a bulk tank monitor. Read the main large digital number "
              "showing the tank level. Ignore percentages, dates, and small text.";
          break;

        case 'psi_analog':
          taskInstruction =
              "You see a round analog PRESSURE gauge in PSI (0–400 range). "
              "Read the value where the thick black needle tip points. "
              "Return the approximate PSI (for example 75, 120, 250). "
              "Ignore any printed scale numbers that are not the needle reading.";
          break;

        case 'level_analog':
          taskInstruction =
              "You see a large round analog tank LEVEL gauge labeled "
              "'INCHES OF WATER' or similar. Read the value where the needle "
              "tip points on the scale (e.g. 60, 85, 110). Ignore any labels "
              "or other numbers printed on the plate.";
          break;

        case 'psi':
          taskInstruction =
              "Read the tank PRESSURE value from this gauge or digital display. "
              "Return only the current pressure value. Ignore scale ranges, "
              "units, setpoints, and dates.";
          break;

        case 'level':
          taskInstruction =
              "Read the tank LEVEL value from this gauge or digital display "
              "in inches of water. Return only the current level value. "
              "Ignore percentages, alarm arrows, and text like FULL / REPORT.";
          break;

        default:
          taskInstruction =
              "Extract the single most important numeric reading shown in this "
              "instrument photo (for example gauge needle value or big digital "
              "number). Do not return any dates, serial numbers or ranges.";
      }

      final prompt = "$taskInstruction\n\n$formatRule";

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/'
        'models/gemini-2.0-flash-exp:generateContent?key=$_kApiKey',
      );

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
              {"text": prompt},
            ],
          },
        ],
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode != 200) {
        debugPrint("AI HTTP Error: ${resp.statusCode} ${resp.body}");

        if (resp.statusCode == 429) return "QUOTA";
        if (resp.statusCode == 503) return "OVERLOADED";
        return "Retry";
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return "Retry";

      final content = candidates[0]['content'];
      if (content == null) return "Retry";

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return "Retry";

      String? text;
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          text = part['text'] as String;
          break;
        }
      }

      if (text == null || text.isEmpty) return "Retry";

      debugPrint("AI RAW TEXT ($fieldType): $text");

      return _cleanNumericOutput(text);
    } catch (e, stack) {
      debugPrint("AI Error: $e");
      debugPrint("AI Stack: $stack");
      return "Retry";
    }
  }

  static Future<Map<String, String>> extractTankSiteInfo(File imageFile) async {
    if (_kApiKey.isEmpty || _kApiKey == 'YOUR_API_KEY_HERE') {
      debugPrint('AI Error: NO API KEY');
      return {"error": "NO_KEY"};
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = '''
You see a BULK INSTALLATION DATA form.

Read these three fields from the form:
1) "TANK IDENTIFICATION NUMBER"
2) "FULL TRYCOCK"
3) "ATTN DRIVER MAINTAIN" (sometimes written as "ATTN DRIVER MAINTAIN ...")

Return them as ONE SINGLE LINE of JSON with exactly these keys:

{"tank_id":"...", "full_trycock":"...", "attn_driver":"..."}

Rules:
- If a value is a number, use only digits (for example "12345", "204", "180").
- If a value is text, copy the text exactly without extra explanation.
- Do not include any other keys.
- Do NOT add comments or extra text, only the JSON object.
''';

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/'
        'models/gemini-2.0-flash-exp:generateContent?key=$_kApiKey',
      );

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
              },
              {"text": prompt},
            ],
          },
        ],
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode != 200) {
        debugPrint("AI HTTP Error (form): ${resp.statusCode} ${resp.body}");
        if (resp.statusCode == 429) return {"error": "QUOTA"};
        if (resp.statusCode == 503) return {"error": "OVERLOADED"};
        return {"error": "Retry"};
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return {"error": "Retry"};
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return {"error": "Retry"};
      }

      String? text;
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          text = part['text'] as String;
          break;
        }
      }

      if (text == null || text.isEmpty) {
        return {"error": "Retry"};
      }

      debugPrint("AI RAW FORM JSON: $text");

      // Try to pull the first {...} block and parse as JSON
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text.trim());
      if (match == null) {
        return {"error": "PARSE"};
      }

      final jsonString = match.group(0)!;

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        return {"error": "PARSE"};
      }

      final tankId = decoded['tank_id']?.toString().trim() ?? "";
      final fullTrycock = decoded['full_trycock']?.toString().trim() ?? "";
      final attnDriver = decoded['attn_driver']?.toString().trim() ?? "";

      return {
        "tank_id": tankId,
        "full_trycock": fullTrycock,
        "attn_driver": attnDriver,
      };
    } catch (e, stack) {
      debugPrint("AI FORM Error: $e");
      debugPrint("AI FORM Stack: $stack");
      return {"error": "Retry"};
    }
  }

  // ------------------ helper for numeric-only outputs ------------------------

  static String _cleanNumericOutput(String text) {
    final valueRegex = RegExp(
      r'VALUE\s*=\s*([0-9]+(?:\.[0-9]+)?)',
      caseSensitive: false,
    );
    final m = valueRegex.firstMatch(text);
    if (m != null) return m.group(1)!;

    final simpleRegex = RegExp(r'\b([0-9]+(?:\.[0-9]+)?)\b');
    final simpleMatch = simpleRegex.firstMatch(text);
    if (simpleMatch != null) return simpleMatch.group(1)!;

    return "";
  }
}
