import 'dart:convert';
import 'dart:io';

import 'package:airgas/dashboard/truck_manifest.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../network/service_provider.dart';
import '../response_model/stop_progress_model.dart';
import '../util.dart';
const String _kApiKey = 'AIzaSyCQuNf48yYC7ylH8xst51bgGq_fwg-Zjhs';

class TankGaugesScreen extends StatefulWidget {
  String startTimeController;
  String tankNumber;

  // String endTimeController;
  String fullTrycockController;
  String attnDriverMaintainController;

  // String psiValueController;

  // String quantityValueController;
  // String quantityUmController;

  TankGaugesScreen({
    super.key,
    required this.startTimeController,
    required this.tankNumber,
    // required this.endTimeController,
    required this.fullTrycockController,
    required this.attnDriverMaintainController,
    // required this.psiValueController,
    // required this.quantityValueController,
    // required this.quantityUmController,
  });

  @override
  State<TankGaugesScreen> createState() => _TankGaugesScreenState();
}

String formatIsoTime(DateTime dateTime) {
  final utc = dateTime.toUtc(); // convert to UTC
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

String formatDisplayTime(DateTime dateTime) {
  return DateFormat('HH:mm').format(dateTime); // 24-hour format
  // OR use 'hh:mm a' for 12-hour format with AM/PM
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

class _TankGaugesScreenState extends State<TankGaugesScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _gaugeImage;
  File? _levelBeforeImage;
  File? _levelAfterImage;
  File? _psiBeforeImage;
  File? _psiAfterImage;
  File? _QtyImage;
  String? _tankLevelPhotoTakenTime;
  String? _qTYPhotoTakenTime;
  String? _lvlbfTakenTime;
  String? _lvlAfTakenTime;
  String? _psibfTakenTime;
  String? _psiAfTakenTime;
  String? _apitankLevelPhotoTakenTime;
  String? _apiqTYPhotoTakenTime;
  String? _apilvlbfTakenTime;
  String? _apilvlAfTakenTime;
  String? _apipsibfTakenTime;
  String? _apipsiAfTakenTime;
  String selectedUnit = 'lbs'; // Default value
  void _handleAiResponse(BuildContext context, String value, TextEditingController controller) {
    if (value == "NO_KEY" || value == "QUOTA" || value == "OVERLOADED" || value == "Retry" || value.isEmpty) {
      String msg = "Could not read value from image, please retry.";
      if (value == "NO_KEY") {
        msg = "No API key configured.";
      } else if (value == "QUOTA") {
        msg = "AI quota exceeded.";
      } else if (value == "OVERLOADED") {
        msg = "Model overloaded, please try again.";
      } else if (value == "Retry" || value.isEmpty) {
        msg = "Could not read value from image, please retry.";
      }

      controller.text = ""; // Clear the field if AI fails
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // Success
    controller.text = value;
  }
  Future<void> _captureGaugeImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (photo == null) return;

    final now = DateTime.now();
    final file = File(photo.path);

    setState(() {
      _gaugeImage = file;
      _tankLevelPhotoTakenTime = formatDisplayTime(now);
      _apitankLevelPhotoTakenTime = formatIsoTime(now);
      isload = true;
    });

    // Since this image likely contains both PSI and Level, we'll run OCR twice
    // or use a complex prompt (running twice is more robust for single-value extraction).

    // OCR for PSI value
    final psiValue = await AiService.extractValue(file, 'psi');
    _handleAiResponse(context, psiValue, psiValueController);

    // OCR for Level value
    final levelValue = await AiService.extractValue(file, 'level');
    _handleAiResponse(context, levelValue, levelValueController);

    if (!mounted) return;
    setState(() => isload = false);
  }

  Future<void> _captureQtyImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (photo == null) return;

    final now = DateTime.now();
    final file = File(photo.path);

    setState(() {
      _QtyImage = file;
      _qTYPhotoTakenTime = formatDisplayTime(now);
      _apiqTYPhotoTakenTime = formatIsoTime(now);
      isload = true;
    });

    final value = await AiService.extractValue(file, 'totalizer');
    _handleAiResponse(context, value, quantityValueController);

    if (!mounted) return;
    setState(() => isload = false);
  }


// 3. PSI Before / After
  Future<void> _capturePsiImage({required bool isBefore}) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (photo == null) return;

    final now = DateTime.now();
    final file = File(photo.path);
    final controller = isBefore ? psiBeforeValue : psiAfterValue;

    setState(() {
      if (isBefore) {
        _psiBeforeImage = file;
        _psibfTakenTime = formatDisplayTime(now);
        _apipsibfTakenTime = formatIsoTime(now);
      } else {
        _psiAfterImage = file;
        _psiAfTakenTime = formatDisplayTime(now);
        _apipsiAfTakenTime = formatIsoTime(now);
      }
      isload = true;
    });

    final value = await AiService.extractValue(file, 'psi');
    _handleAiResponse(context, value, controller);

    if (!mounted) return;
    setState(() => isload = false);
  }


// 4. Level Before / After
  Future<void> _captureImage({required bool isBefore}) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (photo == null) return;

    final now = DateTime.now();
    final file = File(photo.path);
    final controller = isBefore ? levelBeforeValue : levelAfterValue;

    setState(() {
      if (isBefore) {
        _levelBeforeImage = file;
        _lvlbfTakenTime = formatDisplayTime(now);
        _apilvlbfTakenTime = formatIsoTime(now);
      } else {
        _levelAfterImage = file;
        _lvlAfTakenTime = formatDisplayTime(now);
        _apilvlAfTakenTime = formatIsoTime(now);
      }
      isload = true;
    });

    final value = await AiService.extractValue(file, 'level');
    _handleAiResponse(context, value, controller);

    if (!mounted) return;
    setState(() => isload = false);
  }

  var isload = false;

  Future<void> _submitTankData() async {
    setState(() => isload = true); // show loader

    try {
      final uri = Uri.parse(
        "http://ec2-18-206-172-221.compute-1.amazonaws.com/api/trip/stop/update",
      );

      var request = http.MultipartRequest('POST', uri);

      // ✅ Set headers
      request.headers.addAll({
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      });

      // ✅ Add normal text fields
      request.fields['tank_number'] = widget.tankNumber;
      request.fields['tank_information_image_time'] =
          LocalStorages().getTankInformationTime() ?? "";
      // request.fields['start_time'] = widget.startTimeController;
      request.fields['full_trycock'] = widget.fullTrycockController;
      request.fields['attn_driver_maintain'] =
          widget.attnDriverMaintainController;
      request.fields['psi_value'] = psiValueController.text.trim();
      request.fields['levels_value'] = levelValueController.text.trim();
      request.fields['level_before_value'] = levelBeforeValue.text.trim();
      request.fields['level_after_value'] = levelAfterValue.text.trim();
      request.fields['psi_before_value'] = psiBeforeValue.text.trim();
      request.fields['psi_after_value'] = psiAfterValue.text.trim();
      request.fields['quantity_value'] = quantityValueController.text.trim();
      request.fields['odometer_value'] = odoMeter.text.trim();
      request.fields['tank_level_image_time'] =
          _apitankLevelPhotoTakenTime ?? "";
      request.fields['quantity_image_time'] = _apiqTYPhotoTakenTime ?? "";
      request.fields['level_before_image_time'] = _apilvlbfTakenTime ?? "";
      request.fields['level_after_image_time'] = _apilvlAfTakenTime ?? "";
      request.fields['psi_before_image_time'] = _apipsibfTakenTime ?? "";
      request.fields['psi_after_image_time'] = _apipsiAfTakenTime ?? "";
      request.fields['quantity_um'] = selectedUnit ?? "";

      // ✅ Add image files (only if they exist)
      Future<void> addImage(String field, File? file) async {
        if (file != null) {
          request.files.add(
            await http.MultipartFile.fromPath(field, file.path),
          );
        }
      }

      final tankInfoImagePath = LocalStorages().getImage();
      await addImage('psi_before_image', _psiBeforeImage);
      await addImage(
        'tank_information_image',
        tankInfoImagePath != null ? File(tankInfoImagePath) : null,
      );
      await addImage('psi_after_image', _psiAfterImage);
      await addImage('tank_level_image', _gaugeImage);
      await addImage('level_before_image', _levelBeforeImage);
      await addImage('level_after_image', _levelAfterImage);
      await addImage('quantity_image', _QtyImage);

      // ✅ Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("✅ Success: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data submitted successfully!")),
        );
        LocalStorages().saveTanksNumber(tanksNumber: widget.tankNumber);
        Get.to(() => TruckManifestScreen());
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
      setState(() => isload = false); // hide loader
    }
  }

  StopProgressModel stopProgressModel = StopProgressModel();
  var isLoading = false;

  Future<void> truckStopProgressApi() async {
    setState(() => isLoading = true);
    try {
      final result = await ServiceProvider().stopInProgressApi();

      setState(() {
        stopProgressModel = result;
        isLoading = false;
      });

      /// ✅ Populate text fields safely
      if (stopProgressModel.stop != null) {
        final stop = stopProgressModel.stop!;

        psiValueController.text = stop.psiValue ?? "";
        levelValueController.text = stop.levelsValue ?? "";
        quantityValueController.text = stop.quantityValue ?? "";
        levelBeforeValue.text = stop.levelBeforeValue?.toString() ?? "";
        levelAfterValue.text = stop.levelAfterValue?.toString() ?? "";
        psiBeforeValue.text = stop.psiBeforeValue ?? "";
        psiAfterValue.text = stop.psiAfterValue ?? "";
        odoMeter.text = stop.odometerValue ?? "";
        _tankLevelPhotoTakenTime = stop.tankLevelImageTime ?? "";
        _psibfTakenTime = stop.psiBeforeImageTime ?? "";
        _psiAfTakenTime = stop.psiAfterImageTime ?? "";

        // 🛠 Only update times if API actually has values
        if (stop.tankLevelImageTime != null &&
            stop.tankLevelImageTime!.isNotEmpty) {
          _tankLevelPhotoTakenTime = stop.tankLevelImageTime;
        }

        if (stop.psiBeforeImageTime != null &&
            stop.psiBeforeImageTime!.isNotEmpty) {
          _psibfTakenTime = stop.psiBeforeImageTime;
        }

        if (stop.psiAfterImageTime != null &&
            stop.psiAfterImageTime!.isNotEmpty) {
          _psiAfTakenTime = stop.psiAfterImageTime;
        }

        if (stop.levelBeforeImageTime != null &&
            stop.levelBeforeImageTime!.isNotEmpty) {
          _lvlbfTakenTime = stop.levelBeforeImageTime;
        }

        if (stop.levelAfterImageTime != null &&
            stop.levelAfterImageTime!.isNotEmpty) {
          _lvlAfTakenTime = stop.levelAfterImageTime;
        }

        if (stop.quantityImageTime != null &&
            stop.quantityImageTime!.isNotEmpty) {
          _qTYPhotoTakenTime = stop.quantityImageTime;
        }
      } else {
        /// If API returned null, clear all
        psiValueController.text = "";
        levelValueController.text = "";
        quantityValueController.text = "";
        levelBeforeValue.text = "";
        levelAfterValue.text = "";
        psiBeforeValue.text = "";
        psiAfterValue.text = "";
        odoMeter.text = "";
        _tankLevelPhotoTakenTime = "";
        _psibfTakenTime = "";
        _psiAfTakenTime = "";
        // _gaugeImage=null;
        // _levelBeforeImage=null;
        // _levelAfterImage=null;
      }
    } catch (e) {
      debugPrint('Error occurred: $e');
      setState(() => isLoading = false);
    }
  }

  final TextEditingController levelBeforeValue = TextEditingController();
  final TextEditingController levelAfterValue = TextEditingController();
  final TextEditingController psiBeforeValue = TextEditingController();
  final TextEditingController psiAfterValue = TextEditingController();
  final TextEditingController odoMeter = TextEditingController();
  final TextEditingController quantityValueController = TextEditingController();
  final TextEditingController psiValueController = TextEditingController();
  final TextEditingController levelValueController = TextEditingController();

  // final TextEditingController psisValueController = TextEditingController();

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
        title: const Text("Tank Gauges"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _gaugeCard(
                  "Tank Information",
                  "",
                  _gaugeImage,
                  psiValueController.text.trim(),
                  levelValueController.text.trim(),
                  onCameraTap: _captureGaugeImage,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "LevelValue",
                        levelValueController,
                        hint: "0",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        "Psi Value",
                        psiValueController,
                        hint: "0",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Center(
                //   child: Row(
                //     children: [
                //       Text("Time",style: TextStyle(
                //         color: Colors.black,
                //         fontWeight: FontWeight.w600,
                //         fontSize: 20,
                //       ),),
                //       SizedBox(width: 10,),
                //       Text(
                //           DateFormat('HH:mm').format(DateTime.now()),
                //         style: TextStyle(
                //           color: Colors.black,
                //           fontWeight: FontWeight.w600,
                //           fontSize: 20,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildLevelSection(
                        levelBeforeValue.text,
                        "LEVEL BEFORE",
                        _levelBeforeImage,
                        true,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildLevelSection(
                        levelAfterValue.text,
                        "LEVEL AFTER",
                        _levelAfterImage,
                        false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "LevelBeforeValue",
                        levelBeforeValue,
                        hint: "0",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        "LevelAfterValue",
                        levelAfterValue,
                        hint: "0",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPsiSection(
                        psiBeforeValue.text.trim(),
                        "PSI BEFORE",
                        _psiBeforeImage,
                        true,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildPsiSection(
                        psiAfterValue.text.trim(),
                        "PSI AFTER",
                        _psiAfterImage,
                        false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "PSIBeforeValue",
                        psiBeforeValue,
                        hint: "0",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        "PSIAfterValue",
                        psiAfterValue,
                        hint: "0",
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ Safely load local image
                                Builder(
                                  builder: (_) {
                                    final imagePath = LocalStorages()
                                        .getImage();
                                    if (imagePath != null &&
                                        imagePath.isNotEmpty) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(imagePath),
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Info labels
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "TIN:${(stopProgressModel.stop?.tankNumber ?? "")}",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      "full tyc: ${widget.fullTrycockController}",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      "ADM:${widget.attnDriverMaintainController}",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 3),
                    Expanded(
                      child: _gaugeQty(
                        "Tank Information",
                        _QtyImage,
                        "140 psi",

                        onCameraTap: _captureQtyImage,
                      ),
                    ),
                  ],
                ),
                const Center(
                  child: Text(
                    "All information is image driven",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submitTankData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          if (isload)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _gaugeCard(
    String title,
    String time,
    File? imgFile,
    String psi,
    String ins, {
    VoidCallback? onCameraTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stopProgressModel.stop?.tankLevelImageTime == null
                ? (_tankLevelPhotoTakenTime != null
                      ? "Time: $_tankLevelPhotoTakenTime"
                      : "Time: HH:MM")
                : "Time: ${formatIsoToDisplayTime(stopProgressModel.stop!.tankLevelImageTime!)}",
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imgFile != null
                    ? Image.file(imgFile, height: 190, fit: BoxFit.cover)
                    : stopProgressModel.stop?.tankLevelImage == null
                    ? Container(
                        color: Colors.grey,
                        child: Center(child: Text("Click on Camera")),
                        height: 190,
                      )
                    : Image.network(
                        "http://ec2-18-206-172-221.compute-1.amazonaws.com/${stopProgressModel.stop?.tankLevelImage ?? ""}",
                        height: 190,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(width: 10),
              Text("PSI:$psi\nLevel: $ins"),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _gaugeQty(
    String title,

    File? imgFile,

    String ins, {
    VoidCallback? onCameraTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imgFile != null
                    ? Image.file(imgFile, height: 70, fit: BoxFit.cover)
                    : stopProgressModel.stop?.quantityImage == null
                    ? Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: () => _captureQtyImage(),
                          ),
                        ),
                      )
                    : Image.network(
                        "http://ec2-18-206-172-221.compute-1.amazonaws.com/${stopProgressModel.stop?.quantityImage ?? ""}",
                        height: 60,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,

                children: [
                  Text("QTY", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    quantityValueController.text.trim(),
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    stopProgressModel.stop?.quantityImageTime == null
                        ? (_qTYPhotoTakenTime != null
                              ? "$_tankLevelPhotoTakenTime"
                              : "HH:MM")
                        : "${formatIsoToDisplayTime(stopProgressModel.stop!.quantityImageTime!)}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedUnit,
                    items: const [
                      DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                      DropdownMenuItem(value: 'gal', child: Text('gal')),
                      DropdownMenuItem(value: 'scf', child: Text('scf')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedUnit = value!;
                      });
                    },
                    underline: Container(),
                    // removes underline if you want a cleaner look
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(width: 1),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField("Quantity", quantityValueController, hint: "0"),
        ],
      ),
    );
  }

  Widget _buildLevelSection(
    String ins,
    String title,
    File? image,
    bool isBefore,
  ) {
    final String? localTime = isBefore ? _lvlbfTakenTime : _lvlAfTakenTime;
    final String? apiTime = isBefore
        ? stopProgressModel.stop?.levelBeforeImageTime
        : stopProgressModel.stop?.levelAfterImageTime;

    // Get API image path (if available)
    final String? apiImagePath = isBefore
        ? stopProgressModel.stop?.levelBeforeImage
        : stopProgressModel.stop?.levelAfterImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Section title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),

        // 🔹 Level info text
        Text("ins: ${ins}"),
        const SizedBox(height: 8),

        // 🔹 Image handling logic
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(image, height: 120, fit: BoxFit.cover),
          )
        else if (apiImagePath != null && apiImagePath.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              "http://ec2-18-206-172-221.compute-1.amazonaws.com$apiImagePath",
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 70,
                color: Colors.grey.withOpacity(0.3),
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          )
        else
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => _captureImage(isBefore: isBefore),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // 🔹 Time display logic
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              apiTime != null && apiTime.isNotEmpty
                  ? "Time: ${formatIsoToDisplayTime(apiTime)}"
                  : (localTime != null ? "Time: $localTime" : "Time: HH:MM"),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPsiSection(
    String psi,
    String title,
    File? image,
    bool isBefore,
  ) {
    final String? capturedTime = isBefore ? _psibfTakenTime : _psiAfTakenTime;
    final String? apiTime = isBefore
        ? stopProgressModel.stop?.psiBeforeImageTime
        : stopProgressModel.stop?.psiAfterImageTime;
    final String? apiImagePath = isBefore
        ? stopProgressModel.stop?.psiBeforeImage
        : stopProgressModel.stop?.psiAfterImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text("psi: ${psi}"),
        const SizedBox(height: 8),
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(image, height: 120, fit: BoxFit.cover),
          )
        else if (apiImagePath != null && apiImagePath.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              "http://ec2-18-206-172-221.compute-1.amazonaws.com$apiImagePath",
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 70,
                color: Colors.grey.withOpacity(0.3),
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          )
        else
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: () => _capturePsiImage(isBefore: isBefore),
              ),
            ),
          ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              apiTime != null
                  ? "Time: ${formatIsoToDisplayTime(apiTime)}"
                  : (capturedTime != null
                        ? "Time: $capturedTime"
                        : "Time: HH:MM"),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        keyboardType: TextInputType.number,
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

