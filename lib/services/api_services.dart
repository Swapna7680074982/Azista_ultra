import 'dart:convert';
import 'package:dio/dio.dart';

import '../constants/api_urls.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class ApiServices {
  static final Dio _dio = Dio();

  static Future<bool> login({
    required String phone,
    required String password,
  }) async {
    try {
      final coords = await LocationService.getCoordinates();

      final deviceId =
          NotificationService.instance.deviceId ?? "no_device";
      final token =
          NotificationService.instance.fcmToken ?? "no_token";

      final payload = {
        "credentials": {
          "phone": phone,
          "password": password,
        },
        "meta": {
          "deviceTS": _formatDateTime(),
          "coordinates": coords,
          "version": "5.9",
        },
        "data": {
          "deviceID": deviceId,
          "token": token,
        }
      };

      print("REQUEST: ${jsonEncode(payload)}");

      final formData = FormData.fromMap({
        "request": jsonEncode(payload),
      });

      final response = await _dio.post(
        AppUrls.login,
        data: formData,
      );

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.data}");

      return response.statusCode == 200;

    } on DioException catch (e) {
      print("ERROR STATUS: ${e.response?.statusCode}");
      print("ERROR DATA: ${e.response?.data}");
      return false;
    }
  }

  static String _formatDateTime() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";
  }
}