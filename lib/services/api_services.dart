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
  static Future<Map<String, dynamic>?> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await SessionManager.getToken();

      if (token == null) {
        AppLogger.warning("No token found");
        return null;
      }

      final payload = {
        "old_password": oldPassword,
        "new_password": newPassword,
        "confirm_password": confirmPassword,
      };

      AppLogger.info("Change Password API called");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.changePassword,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Change Password response: ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
      }

      return response.data;
    } catch (e) {
      AppLogger.error("Change Password error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRoutes() async {
    try {
      final token = await SessionManager.getToken();

      if (token == null) {
        AppLogger.warning("No token found for getRoutes");
        return null;
      }

      AppLogger.info("Get Routes API called");

      final response = await _dio.get(
        AppUrls.routes,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Get Routes response: ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
      }

      return null;
    } catch (e) {
      AppLogger.error("Get Routes error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> markAttendance({
    required String type,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final coords = await LocationService.getCoordinates();
      final deviceId =
          NotificationService.instance.deviceId ?? "no_device";

      final payload = {
        "type": type.trim(),
        "meta": {
          "deviceId": deviceId,
          "latitude": double.tryParse(coords[0]) ?? 0.0,
          "longitude": double.tryParse(coords[1]) ?? 0.0,
        }
      };

      final response = await _dio.post(
        AppUrls.markAttendance,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print("API RESPONSE: ${response.data}");

      return response.data;
    } catch (e) {
      print("REAL ERROR: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dio.get(
        AppUrls.todaysAttendance,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data["status"] == true) {
        return response.data;
      }

      return null;
    } catch (e) {
      print("Today Attendance Error: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAttendanceRange({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final payload = {
        "from_date": fromDate,
        "to_date": toDate,
      };

      AppLogger.info("Attendance Range API called");
      AppLogger.info("Payload: $payload");

      final response = await _dio.post(
        AppUrls.attendanceRange,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Attendance response: ${response.data}");

      if (response.statusCode == 200 &&
          response.data["status"] == true) {
        return List<Map<String, dynamic>>.from(response.data["data"]);
      }

      return null;
    } catch (e) {
      AppLogger.error("Attendance API error", e);
      return null;
    }
  }
}