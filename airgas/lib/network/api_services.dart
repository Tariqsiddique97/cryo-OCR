import 'dart:developer';

// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../util.dart';



class ApiService extends GetConnect {
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  ApiService() {
    httpClient.defaultContentType = "application/json";
    httpClient.addRequestModifier<dynamic>((request) async {
      // String? fcm = await FirebaseMessaging.instance.getToken();
      // request.headers['Authorization'] =
      "Bearer ${LocalStorages().getToken() ?? ""}";
      request.headers['Accept'] = 'application/json';
      // request.headers['fcm-token'] = fcm ?? "Not Get";
      return request;
    });

    httpClient.addResponseModifier((request, response) {
      print("url ${request.url}");
      print("status code ${response.statusCode}");
      print("body  ${response.body}");
      return response;
    });
    httpClient.addRequestModifier<dynamic>((request) {
      print("url${request.url}");
      print("status code${request.url}");
      print("header4  ${request.headers}");
      return request;
    });
    httpClient.timeout = Duration(minutes: 1);
    log("Constructor");
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    // log("API  :" + url.toString());
    // log("BODY : " + jsonEncode(body).toString());
    // TODO: implement post
    return super.post(
      url,
      body,
      contentType: contentType,
      headers: headers,
      query: query,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    String? autherization,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    // TODO: implement get
    return super.get(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    // TODO: implement put
    return super.put(
      url,
      body,
      headers: headers,
      contentType: contentType,
      query: query,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String url,
    body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    // TODO: implement patch
    return super.patch(
      url,
      body,
      contentType: contentType,
      headers: headers,
      query: query,
    );
  }
}
