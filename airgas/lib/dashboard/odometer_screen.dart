import 'dart:convert';
import 'dart:io';

import 'package:airgas/dashboard/truck_manifest.dart';
import 'package:airgas/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../network/service_provider.dart';
import '../response_model/stop_progress_model.dart';

const String _kApiKey = 'AIzaSyCQuNf48yYC7ylH8xst51bgGq_fwg-Zjhs';

class UpdateOdometerPage extends StatefulWidget {
  const UpdateOdometerPage({super.key});

  @override
  State<UpdateOdometerPage> createState() => _UpdateOdometerPageState();
}

class _UpdateOdometerPageState extends State<UpdateOdometerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tankNumberController = TextEditingController();
  final TextEditingController _odometerValueController =
      TextEditingController();

  File? _odometerImage;
  DateTime? _odometerCaptureTime;
  String? _tankLevelPhotoTakenTime; // Display time
  String? _apitankLevelPhotoTakenTime; // ISO time for API

  final ImagePicker _picker = ImagePicker();

  bool isload = false;
  StopProgressModel stopProgressModel = StopProgressModel();
  bool isLoading = false;

  // ─────────────────────────────────────────────
  // 🕒 TIME FORMAT HELPERS
  // ─────────────────────────────────────────────

  String formatIsoTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}T'
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')}.'
        '${utc.microsecond.toString().padLeft(6, '0')}+00:00';
  }

  String formatDisplayTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String formatIsoToDisplayTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "HH:MM";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('hh:mm a').format(date.toLocal());
    } catch (e) {
      return "HH:MM";
    }
  }

  String formatToIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  // ─────────────────────────────────────────────
  // 📸 PICK CAMERA IMAGE
  // ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// 📸 PICK CAMERA IMAGE (CORRECTED)
// ─────────────────────────────────────────────
  Future<void> _captureOdometerImage() async {
    // Use a generic try/catch block to ensure the loading state is always reset
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      final now = DateTime.now();
      final file = File(pickedFile.path);

      // ✅ CORRECTION: Use the correct controller name defined in the State class
      final controller = _odometerValueController;

      // 1. Update UI state for image preview and start loading
      setState(() {
        _odometerImage = file;
        _odometerCaptureTime = now;
        _tankLevelPhotoTakenTime = formatDisplayTime(now);
        _apitankLevelPhotoTakenTime = formatIsoTime(now);
        isload = true; // Start global loading indicator
      });

      // 2. OCR Extraction
      // Using 'totalizer' as a proxy for a meter/counter reading like an odometer.
      final value = await AiService.extractValue(file, 'totalizer');

      if (!mounted) return;

      // 3. Stop loading state
      setState(() => isload = false);

      // 4. Handle AI Errors and Populate Controller
      if (value == "NO_KEY" || value == "QUOTA" || value == "OVERLOADED" || value == "Retry" || value.isEmpty) {
        String msg = "Could not read Odometer value, please retry.";
        if (value == "NO_KEY") {
          msg = "No API key configured.";
        } else if (value == "QUOTA") {
          msg = "AI quota exceeded.";
        } else if (value == "OVERLOADED") {
          msg = "Model overloaded, please try again.";
        }

        controller.text = ""; // Clear the field if AI fails
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      // Success: Populate the controller
      controller.text = value;

    } catch (e) {
      debugPrint("Odometer Camera/OCR Error: $e");
      // Ensure loading state is turned off even on unexpected errors
      if (mounted) {
        setState(() => isload = false);
      }
    }
  }

  Future<void> _submitData() async {
    if (_odometerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please capture an odometer image.")),
      );
      return;
    }

    if (_odometerCaptureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Image capture time missing.")),
      );
      return;
    }

    if (_odometerValueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please enter an odometer value.")),
      );
      return;
    }

    setState(() => isload = true);

    try {
      final uri = Uri.parse(
        "http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/stop/update-odometer",
      );

      var request = http.MultipartRequest('POST', uri);

      // ✅ Set headers
      request.headers.addAll({
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      });

      // ✅ Add normal text fields
      request.fields['tank_number'] = LocalStorages().getTanksNumber() ?? "";

      request.fields['odometer_image_time'] = _apitankLevelPhotoTakenTime ?? "";

      request.fields['odometer_value'] = _odometerValueController.text.trim();

      // ✅ Add image file
      if (_odometerImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'odometer_image',
            _odometerImage!.path,
          ),
        );
      }

      // ✅ Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("✅ Success: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data submitted successfully!")),
        );

        LocalStorages().saveTanksNumber(
          tanksNumber: stopProgressModel.stop?.tankNumber ?? "",
        );

        Get.to(() => const TruckManifestScreen());
      } else {
        print("❌ Failed: ${response.statusCode}");
        print("Response: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isload = false);
    }
  }

  // ─────────────────────────────────────────────
  // 🚛 FETCH STOP PROGRESS API
  // ─────────────────────────────────────────────
  Future<void> truckStopProgressApi() async {
    setState(() => isLoading = true);
    try {
      final result = await ServiceProvider().stopInProgressApi();
      setState(() {
        stopProgressModel = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error occurred: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // truckStopProgressApi(); // Uncomment if needed
    });
  }

  // ─────────────────────────────────────────────
  // 🖼️ UI BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Odometer"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _gaugeCard(
          "Odometer Information",
          "",
          _odometerImage,
          _odometerValueController.text.trim(),
          onCameraTap: _captureOdometerImage,
        ),
      ),
    );
  }

  Widget _gaugeCard(
    String title,
    String time,
    File? imgFile,
    String psi, {
    VoidCallback? onCameraTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stopProgressModel.stop?.odometerImageTime == null
                ? (_tankLevelPhotoTakenTime != null
                      ? "Time: $_tankLevelPhotoTakenTime"
                      : "Time: HH:MM")
                : "Time: ${formatIsoToDisplayTime(stopProgressModel.stop!.odometerImageTime!)}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: onCameraTap,
              ),
            ],
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imgFile != null
                ? Image.file(imgFile, height: 190, fit: BoxFit.cover)
                : stopProgressModel.stop?.odometerImage == null
                ? Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Click on Camera")),
                  )
                : Image.network(
                    "http://ec2-18-206-172-221.compute-1.amazonaws.com/${stopProgressModel.stop?.odometerImage ?? ""}",
                    height: 220,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _odometerValueController,
            decoration: const InputDecoration(
              labelText: "Odometer Value",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isload ? null : _submitData,
            icon: const Icon(Icons.send, color: Colors.white),
            label: isload
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class AiService {
  // --------- generic single-value extractor (gauges, totalizer etc.) ---------
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

  // --------- NEW: multi-field extractor for tank site form  ------------------

  /// Reads TANK IDENTIFICATION NUMBER, FULL TRYCOCK, ATTN DRIVER MAINTAIN
  /// from one Bulk Installation Data form image.
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
