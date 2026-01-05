import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const String _kApiKey = 'AIzaSyCQuNf48yYC7ylH8xst51bgGq_fwg-Zjhs';

class TankApp extends StatelessWidget {
  const TankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tank Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFFF8F5FC),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: const TankSiteScreen(),
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

// -----------------------------------------------------------------------------
// REUSABLE WIDGET: single-value image scanner (gauges, totalizer, etc.)
// -----------------------------------------------------------------------------

class ImageUploadBox extends StatefulWidget {
  final String? label;
  final String? subLabel;
  final Function(File file, String aiValue) onImageCaptured;
  final String fieldType;

  const ImageUploadBox({
    super.key,
    this.label,
    this.subLabel,
    required this.onImageCaptured,
    required this.fieldType,
  });

  @override
  State<ImageUploadBox> createState() => _ImageUploadBoxState();
}

class _ImageUploadBoxState extends State<ImageUploadBox> {
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true;
        });

        final value = await AiService.extractValue(_image!, widget.fieldType);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (value == "NO_KEY") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No API key configured.")),
          );
          return;
        }
        if (value == "QUOTA") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "AI quota exceeded. Check billing / rate limits in Google AI.",
              ),
            ),
          );
          return;
        }
        if (value == "OVERLOADED") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Model is overloaded. Please try again in a bit."),
            ),
          );
          return;
        }
        if (value == "Retry" || value.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Could not read value from image, please retry."),
            ),
          );
          return;
        }

        widget.onImageCaptured(_image!, value);
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            const Text(
              "Select Image Source",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(Icons.camera_alt, "Camera", ImageSource.camera),
                _sourceButton(
                  Icons.photo_library,
                  "Gallery",
                  ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String text, ImageSource source) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade50,
            child: Icon(icon, color: Colors.deepPurple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        if (widget.subLabel != null)
          Text(
            widget.subLabel!,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSourceModal(context),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              image: _image != null
                  ? DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          "Scanning...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _image == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black45,
                          size: 40,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap to Scan",
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// NEW: TankFormUploadBox – scan 1 image to fill all 3 fields
// -----------------------------------------------------------------------------

class TankFormUploadBox extends StatefulWidget {
  final TextEditingController tankIdCtrl;
  final TextEditingController fullTrycockCtrl;
  final TextEditingController attnDriverCtrl;

  const TankFormUploadBox({
    super.key,
    required this.tankIdCtrl,
    required this.fullTrycockCtrl,
    required this.attnDriverCtrl,
  });

  @override
  State<TankFormUploadBox> createState() => _TankFormUploadBoxState();
}

class _TankFormUploadBoxState extends State<TankFormUploadBox> {
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });

      final result = await AiService.extractTankSiteInfo(
        _image!,
      ); // JSON with 3 values

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.containsKey("error")) {
        final err = result["error"];
        String msg = "Could not read form, please retry.";
        if (err == "NO_KEY") {
          msg = "No API key configured.";
        } else if (err == "QUOTA") {
          msg = "AI quota exceeded. Check Google AI billing / rate limits.";
        } else if (err == "OVERLOADED") {
          msg = "Model overloaded, please try again in a bit.";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      widget.tankIdCtrl.text = result["tank_id"] ?? "";
      widget.fullTrycockCtrl.text = result["full_trycock"] ?? "";
      widget.attnDriverCtrl.text = result["attn_driver"] ?? "";
    } catch (e) {
      debugPrint("Form Camera Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            const Text(
              "Scan Tank Form",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(Icons.camera_alt, "Camera", ImageSource.camera),
                _sourceButton(
                  Icons.photo_library,
                  "Gallery",
                  ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String text, ImageSource source) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple.shade50,
            child: Icon(icon, color: Colors.deepPurple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Image 1 (Tank Form)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSourceModal(context),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              image: _image != null
                  ? DecorationImage(
                      image: FileImage(_image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          "Reading form...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 2, color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _image == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.document_scanner,
                          color: Colors.black45,
                          size: 40,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap to scan form",
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class TankSiteScreen extends StatefulWidget {
  const TankSiteScreen({super.key});

  @override
  State<TankSiteScreen> createState() => _TankSiteScreenState();
}

class _TankSiteScreenState extends State<TankSiteScreen> {
  final TextEditingController _tankNumCtrl = TextEditingController();
  final TextEditingController _trycockCtrl = TextEditingController();
  final TextEditingController _attnDriverCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text(
          "Tank Site",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab("On Site", true),
                  _buildTab("New", false),
                  _buildTab("Update", false),
                  _buildTab("Tank Repair", false),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- One image -> fills all three fields ----
            TankFormUploadBox(
              tankIdCtrl: _tankNumCtrl,
              fullTrycockCtrl: _trycockCtrl,
              attnDriverCtrl: _attnDriverCtrl,
            ),

            _buildLabeledInput("Tank Identification Number", _tankNumCtrl),
            const SizedBox(height: 16),
            _buildInput("Full Trycock", _trycockCtrl),
            const SizedBox(height: 16),
            _buildInput("Attn Driver Maintain", _attnDriverCtrl),
            const SizedBox(height: 20),
            const Text(
              "Note: The Tank will be verified by the pre-populated information on the manifest...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TankGaugesScreen(tankId: _tankNumCtrl.text),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Next: Tank Gauges",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.black : Colors.grey.shade300,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _buildLabeledInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
      ),
    );
  }
}

class TankGaugesScreen extends StatefulWidget {
  final String tankId;

  const TankGaugesScreen({super.key, required this.tankId});

  @override
  State<TankGaugesScreen> createState() => _TankGaugesScreenState();
}

class _TankGaugesScreenState extends State<TankGaugesScreen> {
  final _levelBeforeCtrl = TextEditingController();
  final _levelAfterCtrl = TextEditingController();
  final _psiBeforeCtrl = TextEditingController();
  final _psiAfterCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  final _topLevelCtrl = TextEditingController();
  final _topPsiCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tank Gauges",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: ImageUploadBox(
                    fieldType: 'level_analog',
                    onImageCaptured: (f, v) {
                      setState(() => _topLevelCtrl.text = v);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        "Current Readings",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _readOnlyInput(
                              "Level (in)",
                              _topLevelCtrl.text,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _readOnlyInput("PSI", _topPsiCtrl.text),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ImageUploadBox(
                        label: "LEVEL BEFORE",
                        subLabel: "ins:",
                        fieldType: "level",
                        onImageCaptured: (f, val) =>
                            setState(() => _levelBeforeCtrl.text = val),
                      ),
                      _readOnlyInput("LevelBeforeValue", _levelBeforeCtrl.text),
                      const SizedBox(height: 20),
                      ImageUploadBox(
                        label: "PSI BEFORE",
                        subLabel: "psi:",
                        fieldType: "psi",
                        onImageCaptured: (f, val) =>
                            setState(() => _psiBeforeCtrl.text = val),
                      ),
                      _readOnlyInput("PSIBeforeValue", _psiBeforeCtrl.text),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      ImageUploadBox(
                        label: "LEVEL AFTER",
                        subLabel: "ins:",
                        fieldType: "level",
                        onImageCaptured: (f, val) =>
                            setState(() => _levelAfterCtrl.text = val),
                      ),
                      _readOnlyInput("LevelAfterValue", _levelAfterCtrl.text),
                      const SizedBox(height: 20),
                      ImageUploadBox(
                        label: "PSI AFTER",
                        subLabel: "psi:",
                        fieldType: "psi",
                        onImageCaptured: (f, val) =>
                            setState(() => _psiAfterCtrl.text = val),
                      ),
                      _readOnlyInput("PSIAfterValue", _psiAfterCtrl.text),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TIN: ${widget.tankId}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        "full tyc: 204",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const Text(
                        "ADM: 180",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Column(
                    children: [
                      const Text(
                        "Tank Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ImageUploadBox(
                        label: "TOTALIZER",
                        subLabel: "scan meter",
                        fieldType: "totalizer",
                        onImageCaptured: (f, val) {
                          setState(() {
                            _quantityCtrl.text = val;
                          });
                        },
                      ),
                      TextField(
                        controller: _quantityCtrl,
                        decoration: const InputDecoration(
                          hintText: "Quantity (lbs)",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Submitted:\n"
                  "Level Before: ${_levelBeforeCtrl.text}, PSI Before: ${_psiBeforeCtrl.text}\n"
                  "Level After: ${_levelAfterCtrl.text}, PSI After: ${_psiAfterCtrl.text}\n"
                  "Qty: ${_quantityCtrl.text}",
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Submit", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _readOnlyInput(String hint, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      readOnly: true,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
