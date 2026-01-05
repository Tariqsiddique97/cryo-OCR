import 'package:airgas/response_model/send_report_model.dart';
import 'package:airgas/response_model/stop_complete_model.dart';
import 'package:airgas/util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../network/service_provider.dart';
import '../response_model/trip_stop_model.dart';
import 'bottomnavigation_screen.dart';
import 'odometer_screen.dart';

class TruckManifestScreen extends StatefulWidget {
  const TruckManifestScreen({super.key});

  @override
  State<TruckManifestScreen> createState() => _TruckManifestScreenState();
}

class _TruckManifestScreenState extends State<TruckManifestScreen> {
  TripStopModel? tripStopModel;
  bool isLoading = true;

  // Separate scroll controllers for syncing header and body
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  Future<void> truckApi() async {
    try {
      final result = await ServiceProvider().tripStopApi();
      setState(() {
        tripStopModel = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  SendReportModel? sendReportModel;

  Future<void> sendReport(int trip) async {
    try {
      final result = await ServiceProvider().sendReport(trip: trip);

      setState(() {
        sendReportModel = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  StopCompleteModel stopCompleteModel = StopCompleteModel();

  Future<void> stopComplete() async {
    try {
      final result = await ServiceProvider().stopCompleteApi(
        tankNumber: LocalStorages().getTanksNumber() ?? "",
        Endtime: LocalStorages().getEndTime() ?? "",
      );
      setState(() {
        stopCompleteModel = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => truckApi());

    // 🔗 Sync header ↔ body scroll
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });

    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  String formatTime24(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    try {
      // Parse the date-time string
      DateTime dt = DateTime.parse(dateTime);
      // Format as 24-hour time with leading zeros
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          // ⬅️ CRITICAL FIX: Use standard Navigator.pop
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        centerTitle: true,
        title: const Text(
          "Truck Manifest",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Get.to(UpdateOdometerPage());
              },
              child: Icon(Icons.camera_alt_outlined, color: Colors.green),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tripStopModel?.trip?.stops == null ||
                tripStopModel!.trip!.stops!.isEmpty
          ? const Center(child: Text("No data available"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Shift No:", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  _shiftRow("Shift Start", "On-duty driving (paid)", [
                    "Day 1",
                    "Day 2",
                  ]),
                  _shiftRow("Shift Stop", "On-duty non-driving (paid)", [
                    "",
                    "",
                  ]),
                  _shiftRow(
                    "Driver Name: ${tripStopModel?.trip?.driverName ?? ""}",
                    "Off duty (paid)",
                    ["", ""],
                  ),
                  _shiftRow("Driver Emp #:", "Total paid hours", ["", ""]),
                  _shiftRow(
                    "Tractor:No ${LocalStorages().getTankNumber()}",
                    "Lunch/layover not paid",
                    ["", ""],
                  ),
                  _shiftRow(
                    "Trailer No:${LocalStorages().gettrailorNumber()}",
                    "Total Trip Hours",
                    ["", ""],
                  ),
                  _shiftRow("", "Total Trip miles", ["", ""]),
                  const SizedBox(height: 16),

                  const Center(
                    child: Text(
                      "HAZARDOUS MATERIAL INFORMATION",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "PRODUCT: UN1977, NITROGEN, REFRIGERATED LIQUID, 2.2, CARGO TANK; PRODUCT GRADE ON COA",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "This is to certify that the above named materials are properly classified, described, packaged, marked and labeled "
                    "and are in the proper condition for transportation according to the applicable regulations of the Department of Transportation.",
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text("1 Cargo Tank"),
                      Text("1 Tube Trailer"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text("Net Qty 635023"),
                      Text("LBS GAL SCF"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "SHIFT INSTRUCTIONS: **SAVE AT LEAST 2K GALLONS FOR AIR SUPPLY OF NORTH TEXAS. ONLY USE BELL IF YOU HAVE A BALANCE, "
                    "CALL DISPATCH IF YOU GET EMPTY AT THE SECOND STOP. THANK YOU!**",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "SHIFT EVENTS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text("* all time in HH:mm e.g. 15:30 23:59"),
                  const SizedBox(height: 8),

                  // 🔹 Combined SingleChildScrollView for both header and data
                  SizedBox(
                    height: 340, // header (40) + data (300)
                    child: SingleChildScrollView(
                      controller: _bodyScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1200, // total width of table columns
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                _headerCell("ID/type"),
                                _headerCell("Name"),
                                _headerCell("Start"),
                                _headerCell("End"),
                                _headerCell("Lev Bf"),
                                _headerCell("Lev Af"),
                                _headerCell("PSI Bef"),
                                _headerCell("PSI Aft"),
                                _headerCell("UM"),
                                _headerCell("Qty"),
                                _headerCell("ODO"),
                                _headerCell("Status"),
                              ],
                            ),
                            const Divider(),

                            // Data Rows (vertically scrollable)
                            Expanded(
                              child: ListView.builder(
                                // scrollDirection: Axis.horizontal,
                                itemCount:
                                    tripStopModel?.trip?.stops?.length ?? 0,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final stop =
                                      tripStopModel!.trip!.stops![index];
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            _dataCell(
                                              "Stop ${stop.sequenceNumber}",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.name ?? "",
                                              tripStopModel
                                                          ?.trip
                                                          ?.stops?[index]
                                                          .isTankVerified ==
                                                      "1"
                                                  ? Colors.green
                                                  : Colors.black,
                                            ),
                                            _dataCell(
                                              formatTime24(stop.startTime),
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              formatTime24(stop.endTime),
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.levelBeforeValue ?? "",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.levelAfterValue ?? "",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.psiBeforeValue ?? "",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.psiAfterValue ?? "",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.quantityUm ?? "",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.quantityValue ?? "",
                                              Colors.black,
                                            ),
                                            _dataCell(
                                              stop.odometerValue ?? "",
                                              Colors.black,
                                            ),
                                            tripStopModel
                                                        ?.trip
                                                        ?.stops?[index]
                                                        .status ==
                                                    0
                                                ? GestureDetector(
                                                    onTap: () {},
                                                    child: Container(
                                                      width: 100,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        color: Colors.yellow,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Pending",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : tripStopModel
                                                          ?.trip
                                                          ?.stops?[index]
                                                          .status ==
                                                      1
                                                ? GestureDetector(
                                                    onTap: () {
                                                      stopComplete().whenComplete(
                                                        () {
                                                          if (stopCompleteModel
                                                                  .status ==
                                                              true) {
                                                            LocalStorages()
                                                                .clearImage();
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  "✅ Data submitted successfully!",
                                                                ),
                                                              ),
                                                            );
                                                            Get.offAll(
                                                              BottomBarScreen(),
                                                            );
                                                          }
                                                        },
                                                      );
                                                    },
                                                    child: Container(
                                                      width: 100,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        color: Colors.green,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Complete",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      // stopComplete().whenComplete(
                                                      //   () {
                                                      //     if (stopCompleteModel
                                                      //             .status ==
                                                      //         true) {
                                                      //       ScaffoldMessenger.of(
                                                      //         context,
                                                      //       ).showSnackBar(
                                                      //         const SnackBar(
                                                      //           content: Text(
                                                      //             "✅ Data submitted successfully!",
                                                      //           ),
                                                      //         ),
                                                      //       );
                                                      //       Get.offAll(
                                                      //         BottomBarScreen(),
                                                      //       );
                                                      //     }
                                                      //   },
                                                      // );
                                                    },
                                                    child: Container(
                                                      width: 100,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "Completed",
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text("Signature:"),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        sendReport(
                          tripStopModel?.trip?.stops?[0].tripId ?? 0,
                        ).whenComplete(() {
                          if (sendReportModel?.status == true) {
                            Get.offAll(BottomBarScreen());
                          }
                        });
                      },
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _shiftRow(String left, String right, List<String> days) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              left,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(right, style: const TextStyle(color: Colors.black)),
          ),
          Expanded(
            flex: 3,
            child: Row(children: days.map((d) => _dayBox(d)).toList()),
          ),
        ],
      ),
    );
  }

  Widget _dayBox(String text) {
    return Container(
      width: 50,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _headerCell(String text) {
    return SizedBox(
      width: 100,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _dataCell(String text, Color? color) {
    return SizedBox(
      width: 100,
      child: Text(
        text,
        style: TextStyle(color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
