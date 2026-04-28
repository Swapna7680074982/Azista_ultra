import 'dart:convert';
import 'package:dio/dio.dart';

import '../constants/api_urls.dart';
import '../permissions/SessionManager.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../utilities/mylogger.dart';


class ApiServices {
  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>?> login({
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
          "mobile": phone,
          "password": password,
        },
        "meta": {
          "deviceId": deviceId,
          "deviceTS": _formatDateTime(),
          "coordinates": coords,
          "fcmToken": token,
        }
      };

      AppLogger.info("Login API called");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.login,
        data: payload,
      );

      AppLogger.info("Login response: ${response.data}");

      if (response.statusCode == 200 &&
          response.data["status"] == true) {
        AppLogger.success("Login successful");
        return response.data;
      }

      AppLogger.warning("Login failed: ${response.data}");
      return null;
    } catch (e) {
      AppLogger.error("Login error", e);
      return null;
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

  static Future<bool> logout() async {
    try {
      final accessToken = await SessionManager.getToken();
      final refreshToken = await SessionManager.getRefreshToken();

      final deviceId =
          NotificationService.instance.deviceId ?? "no_device";

      if (accessToken == null || refreshToken == null) {
        AppLogger.warning("Tokens missing → clearing session");
        await SessionManager.clearSession();
        return true;
      }

      final payload = {
        "refresh_token": refreshToken,
        "meta": {
          "deviceId": deviceId,
        }
      };

      AppLogger.info("Logout API called");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.logout,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $accessToken",
          },
          validateStatus: (status) => true,
        ),
      );

      AppLogger.info("Logout response: ${response.data}");

      if (response.statusCode == 200 &&
          response.data["status"] == true) {
        AppLogger.success("Logout successful");
        return true;
      }

      if (response.statusCode == 401) {
        AppLogger.warning("Token expired → treated as logout success");
        return true;
      }

      AppLogger.warning("Logout failed");
      return false;
    } catch (e) {
      AppLogger.error("Logout error", e);
      return false;
    }
  }
}