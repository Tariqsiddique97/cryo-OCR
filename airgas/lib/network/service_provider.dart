import 'dart:convert';
import 'dart:developer';

import 'package:airgas/response_model/send_report_model.dart';
import 'package:airgas/response_model/trip_stop_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../response_model/inspection_model.dart';
import '../response_model/login_model.dart';
import '../response_model/stop_complete_model.dart';
import '../response_model/stop_progress_model.dart';
import '../response_model/truck_number_response.dart';
import '../util.dart';
import 'api_constants.dart';
import 'api_services.dart';
import 'error_model.dart';
import 'package:http/http.dart' as http;


class ServiceProvider {
  Future<LoginModel> login({
    required String username,
    required String password,
  }) async {
    showLoader();

    final response = await ApiService().post(ApiConstants.login, {
      "username": username,
      "password": password,
    });

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return LoginModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return LoginModel();
    }
  }

  Future<TruckNumberModel> truckNumberAPi({
    required String truckNumber,
    required String trailerNumber,
  }) async {
    showLoader();

    final response = await ApiService().post(
      ApiConstants.truck,
      {"tractor_number": truckNumber, "trailer_number": trailerNumber},
      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return TruckNumberModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return TruckNumberModel();
    }
  }

  Future<TripStopModel> tripStopApi() async {
    showLoader();

    final response = await ApiService().post(
      ApiConstants.tripSite,
      {
        "tractor_number": LocalStorages().getTankNumber(),
        "trailer_number": LocalStorages().gettrailorNumber(),
      },
      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return TripStopModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return TripStopModel();
    }
  }

  Future<StopProgressModel> stopInProgressApi() async {
    showLoader();

    final response = await ApiService().post(
      ApiConstants.stopInProgress,
      {
        "tractor_number": LocalStorages().getTankNumber(),
        "trailer_number": LocalStorages().gettrailorNumber(),
      },
      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return StopProgressModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return StopProgressModel();
    }
  }

  Future<SendReportModel> sendReport({required int trip}) async {
    showLoader();

    final response = await ApiService().post(
      ApiConstants.sendReportApi,
      {"trip_id": trip},
      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return SendReportModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return SendReportModel();
    }
  }

  Future<StopCompleteModel> stopCompleteApi({
    required String tankNumber,
    required String Endtime,
  }) async {
    showLoader();

    final response = await ApiService().post(
      ApiConstants.stopComplete,
      {"tank_number": tankNumber, "end_time": Endtime},
      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return StopCompleteModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return StopCompleteModel();
    }
  }

  Future<InspectionReportModel> inspectionAPi() async {
    showLoader();

    final response = await ApiService().get(
      ApiConstants.sendInspectionReportApi,

      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return InspectionReportModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return InspectionReportModel();
    }
  }
  Future<InspectionReportModel> inspectionAPiTrailor() async {
    showLoader();

    final response = await ApiService().get(
      ApiConstants.sendInspectionReportApiTrailor,

      headers: {
        "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",
        "Accept": "application/json",
      },
    );

    hideLoader();
    final result = checkResponse(response);

    if (result != null && result.body != null) {
      return InspectionReportModel.fromJson(result.body);
    } else {
      log("❌ Login failed: ${response.body}");
      return InspectionReportModel();
    }
  }
  Future<Map<String, dynamic>> inspectionReportSubmitApi({
    required String vehicleType,
    required String vehicleNumber,
    required String locationName,
    required int odometerReading,
    required String inspectionDate,
    required String comments,
    required List<String> inspectionChecks,
  }) async {
    const url =
        'http://ec2-18-206-172-221.compute-1.amazonaws.com/api/inspection-report';

    final body = {
      "vehicle_type": vehicleType,
      "vehicle_number": vehicleNumber,
      "location_name": locationName,
      "odometer_reading": odometerReading,
      "inspection_date": inspectionDate,
      "comments": comments,
      "inspection_checks": inspectionChecks.join(","),
    };

    print("📤 Sending Inspection Data: ${jsonEncode(body)}");

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("📥 Response: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to submit inspection report");
    }
  }

  void showSnackBar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
    );
  }


  snackBarMessage({
    required String message,
    required String head,
    Color? color,
    bool isError = true,
  }) {
    return Get.snackbar(
      head,
      message,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      borderRadius: 20,
      margin: const EdgeInsets.all(20),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
  }

  showLoader() {
    Get.dialog(
      barrierDismissible: true,
      const AbsorbPointer(
        child: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      ),
    );
  }

  hideLoader() {
    Navigator.of(Get.context!, rootNavigator: true).pop('dialog');
  }

  successSnackBarMessage({required String message, required String head}) {
    return Get.snackbar(
      head,
      message,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      borderRadius: 20,
      margin: const EdgeInsets.all(20),
      backgroundColor: Colors.green,
    );
  }

  Response? checkResponse(Response response) {
    log("RESPONSE :${response.body}");
    final errorModel = ErrorModel.fromJson(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        // successSnackBarMessage(
        //   message: errorModel.message ?? "Success",
        //   head: "Success",
        // );
        return response;

      case 400:
      case 401:
      case 404:
      case 409:
      case 422:
        snackBarMessage(
          message: errorModel.message ?? "Something went wrong",
          head: "Error",
        );
        return null;

      default:
        snackBarMessage(message: "Check Internet Connection", head: "Error");
        return null;
    }
  }
}
