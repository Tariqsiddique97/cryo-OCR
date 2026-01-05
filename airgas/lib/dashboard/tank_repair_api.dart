import 'dart:io';

import 'package:dio/dio.dart';

import '../util.dart';

class TankRepairAPI {
  final Dio _dio = Dio();

  Future<Response> submitTankRepair({
    required int tripId,
    required double latitude,
    required double longitude,
    required String notes,
    required List<File> photos,
    required List<File> videos,
  }) async {
    String url =
        "http://ec2-18-206-172-221.compute-1.amazonaws.com/api/tank-repair";

    FormData formData = FormData();

    // Basic fields
    formData.fields.add(MapEntry('trip_id', tripId.toString()));
    formData.fields.add(MapEntry('latitude', latitude.toString()));
    formData.fields.add(MapEntry('longitude', longitude.toString()));
    formData.fields.add(MapEntry('notes', notes));

    // Add photos as photos[] entries (one MapEntry per file)
    for (var img in photos) {
      final multipart = await MultipartFile.fromFile(
        img.path,
        filename: img.path.split(Platform.pathSeparator).last,
      );
      formData.files.add(MapEntry('photos[]', multipart));
    }

    // If you want to ensure an empty array is sent when no files:
    // (Laravel may still accept missing files; if you *must* send an empty array, uncomment)
    // if (photos.isEmpty) {
    //   formData.fields.add(MapEntry('photos', '[]'));
    // }

    // Add videos as videos[] entries
    for (var vid in videos) {
      final multipart = await MultipartFile.fromFile(
        vid.path,
        filename: vid.path.split(Platform.pathSeparator).last,
      );
      formData.files.add(MapEntry('videos[]', multipart));
    }

    // Same note for empty videos array as above:
    // if (videos.isEmpty) {
    //   formData.fields.add(MapEntry('videos', '[]'));
    // }

    Response response = await _dio.post(
      url,
      data: formData,
      options: Options(
        headers: {
          "Authorization": "Bearer ${LocalStorages().getToken() ?? ""}",

          "Accept": "application/json",
        },
        contentType: "multipart/form-data",
      ),
    );

    return response;
  }
}
