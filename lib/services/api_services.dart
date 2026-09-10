import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';

import '../constants/api_urls.dart';
import '../permissions/SessionManager.dart';
import '../screens/login/login_screen.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../utilities/mylogger.dart';
import 'navigation_service.dart';


class _ConcurrencyLimitInterceptor extends Interceptor {
  static const int maxConcurrent = 3;
  static int _activeCount = 0;
  static final List<void Function()> _queue = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_activeCount < maxConcurrent) {
      _activeCount++;
      handler.next(options);
    } else {
      _queue.add(() {
        _activeCount++;
        handler.next(options);
      });
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _release();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _release();
    handler.next(err);
  }

  static void _release() {
    _activeCount--;
    if (_activeCount < 0) _activeCount = 0;
    if (_queue.isNotEmpty && _activeCount < maxConcurrent) {
      final nextRequest = _queue.removeAt(0);
      Future.delayed(const Duration(milliseconds: 30), nextRequest);
    }
  }
}

class ApiServices {
  static dynamic _safeParseJson(dynamic rawData) {
    if (rawData == null) return null;
    if (rawData is Map || rawData is List) return rawData;
    if (rawData is String) {
      String text = rawData.trim();
      if (text.isEmpty) return null;
      if (text.startsWith('\uFEFF')) {
        text = text.substring(1).trim();
      }
      try {
        return jsonDecode(text);
      } catch (_) {
        final firstBrace = text.indexOf('{');
        final firstBracket = text.indexOf('[');
        int start = -1;
        int end = -1;
        if (firstBrace != -1 && (firstBracket == -1 || firstBrace < firstBracket)) {
          start = firstBrace;
          end = text.lastIndexOf('}');
        } else if (firstBracket != -1) {
          start = firstBracket;
          end = text.lastIndexOf(']');
        }
        if (start != -1 && end != -1 && end >= start) {
          final jsonSub = text.substring(start, end + 1);
          try {
            return jsonDecode(jsonSub);
          } catch (e) {
            AppLogger.error("Failed to parse extracted JSON substring", e);
          }
        }
      }
    }
    return null;
  }

  static Future<Response?> _postWithRetry(
    String url, {
    dynamic data,
    Options? options,
    int maxRetries = 2,
  }) async {
    for (int i = 0; i <= maxRetries; i++) {
      try {
        final response = await _dio.post(url, data: data, options: options);
        final parsed = _safeParseJson(response.data);
        if (response.statusCode == 200 && parsed != null) {
          return response;
        }
        if (i < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        } else {
          return response;
        }
      } catch (e) {
        if (i < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        } else {
          rethrow;
        }
      }
    }
    return null;
  }

  static Future<Response?> _getWithRetry(
    String url, {
    Options? options,
    int maxRetries = 2,
  }) async {
    for (int i = 0; i <= maxRetries; i++) {
      try {
        final response = await _dio.get(url, options: options);
        final parsed = _safeParseJson(response.data);
        if (response.statusCode == 200 && parsed != null) {
          return response;
        }
        if (i < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        } else {
          return response;
        }
      } catch (e) {
        if (i < maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        } else {
          rethrow;
        }
      }
    }
    return null;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      sendTimeout: const Duration(seconds: 50),
    ),
  )..interceptors.addAll([
    _ConcurrencyLimitInterceptor(),
    InterceptorsWrapper(
      onResponse: (response, handler) async {
        final path = response.requestOptions.path;
        final isLogin = path.contains('/user/login');
        final isRefresh = path.contains('/user/refresh_token');
        final isLogout = path.contains('/user/logout');

        final parsedData = _safeParseJson(response.data);

        if (!isLogin && !isRefresh && !isLogout &&
            (response.statusCode == 401 ||
                (parsedData is Map &&
                    (parsedData["message"]?.toString().contains("Token expired") == true ||
                     parsedData["message"]?.toString().contains("Token revoked") == true)))) {
          final token = await SessionManager.getToken();
          final refreshTokenStr = await SessionManager.getRefreshToken();
          if (token == null || refreshTokenStr == null || token.isEmpty || refreshTokenStr.isEmpty) {
            return handler.next(response);
          }

          final success = await refreshToken();
          if (success) {
            final token = await SessionManager.getToken();
            final opts = response.requestOptions;
            opts.headers["Authorization"] = "Bearer $token";
            
            try {
              final cloneReq = await _dio.request(
                opts.path,
                data: opts.data,
                queryParameters: opts.queryParameters,
                options: Options(
                  method: opts.method,
                  headers: opts.headers,
                  contentType: opts.contentType,
                  responseType: opts.responseType,
                ),
              );
              return handler.resolve(cloneReq);
            } catch (err) {
              return handler.next(response);
            }
          } else {
            final tokenNow = await SessionManager.getToken();
            if (tokenNow != null && tokenNow.isNotEmpty) {
              await _handleTokenExpired();
            }
          }
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final isLogin = path.contains('/user/login');
        final isRefresh = path.contains('/user/refresh_token');
        final isLogout = path.contains('/user/logout');

        final parsedData = _safeParseJson(e.response?.data);

        if (!isLogin && !isRefresh && !isLogout &&
            (e.response?.statusCode == 401 ||
                (parsedData is Map &&
                    (parsedData["message"]?.toString().contains("Token expired") == true ||
                     parsedData["message"]?.toString().contains("Token revoked") == true)))) {
          final token = await SessionManager.getToken();
          final refreshTokenStr = await SessionManager.getRefreshToken();
          if (token == null || refreshTokenStr == null || token.isEmpty || refreshTokenStr.isEmpty) {
            return handler.next(e);
          }

          final success = await refreshToken();
          if (success) {
            final token = await SessionManager.getToken();
            final opts = e.requestOptions;
            opts.headers["Authorization"] = "Bearer $token";
            
            try {
              final cloneReq = await _dio.request(
                opts.path,
                data: opts.data,
                queryParameters: opts.queryParameters,
                options: Options(
                  method: opts.method,
                  headers: opts.headers,
                  contentType: opts.contentType,
                  responseType: opts.responseType,
                ),
              );
              return handler.resolve(cloneReq);
            } catch (err) {
              return handler.next(e);
            }
          } else {
            final tokenNow = await SessionManager.getToken();
            if (tokenNow != null && tokenNow.isNotEmpty) {
              await _handleTokenExpired();
            }
          }
        }
        return handler.next(e);
      },
    ),
  ]);

  static bool _isRedirecting = false;

  static Future<void> _handleTokenExpired() async {
    if (_isRedirecting) return;
    _isRedirecting = true;

    try {
      AppLogger.warning("Token expired or 401 Unauthorized detected. Clearing session & redirecting to LoginScreen.");
      await SessionManager.clearSession();
      
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );

      // Show a snackbar message once redirected
      Future.delayed(const Duration(milliseconds: 300), () {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Session expired. Please login again.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } catch (e) {
      AppLogger.error("Failed to redirect to LoginScreen", e);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isRedirecting = false;
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final refresh = await SessionManager.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        AppLogger.warning("Refresh token is null or empty");
        return false;
      }

      final deviceId = NotificationService.instance.deviceId ?? "no_device";
      final deviceType = Platform.isAndroid ? "Android" : "iOS";
      final coords = await LocationService.getCoordinates(
        requestPermission: false,
        throwOnError: false,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => ["0.0", "0.0"],
      );

      final payload = {
        "refresh_token": refresh,
        "device_id": deviceId,
        "device_name": Platform.isAndroid ? "Android Device" : "iOS Device",
        "device_type": deviceType,
        "app_version": "1.0.0",
        "latitude": coords[0],
        "longitude": coords[1],
      };

      AppLogger.info("Refresh Token API called");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      // Use a separate Dio instance to avoid infinite loops
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 50),
          receiveTimeout: const Duration(seconds: 50),
          sendTimeout: const Duration(seconds: 50),
        ),
      );
      final response = await dio.post(
        AppUrls.refreshToken,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Refresh Token response: $parsed");

      if (response.statusCode == 200 && parsed is Map && parsed["status"] == true) {
        final newAccessToken = parsed["access_token"];
        if (newAccessToken != null) {
          await SessionManager.saveSession(
            token: newAccessToken,
            refreshToken: refresh,
          );
          AppLogger.success("Token refreshed successfully");
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error("Refresh token error", e);
      return false;
    }
  }

  static Future<Map<String, dynamic>?> login({
    required String phone,
    required String password,
  }) async {
    try {
      final coords = await LocationService.getCoordinates(
        requestPermission: false,
        throwOnError: false,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => ["0.0", "0.0"],
      );

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
          "coordinates": [
            coords[0],
            coords[1],
          ],
          "fcmToken": token,
        }
      };

      AppLogger.info("Login API called");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.login,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Login response: $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }

      AppLogger.warning("Login failed: ${response.data}");
      return null;
    } catch (e) {
      AppLogger.error("Login error", e);
      String message = "Login failed";
      if (e is DioException) {
        if (e.response != null) {
          final data = _safeParseJson(e.response?.data);
          if (data is Map && data.containsKey("message")) {
            message = data["message"]?.toString() ?? "Login failed";
          } else {
            message = "Server error (${e.response?.statusCode})";
          }
        } else {
          message = "Network error: ${e.message ?? 'Connection failed'}";
        }
      }
      return {"status": false, "message": message};
    }
  }

  static String _formatDateTime() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
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
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $accessToken",
          },
          validateStatus: (status) => true,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Logout response: $parsed");

      if (response.statusCode == 200 &&
          parsed is Map &&
          parsed["status"] == true) {
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
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Change Password response: $parsed");

      if (response.statusCode == 200 && parsed is Map && parsed["status"] == true) {
        return Map<String, dynamic>.from(parsed);
      }

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }

      return null;
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

      AppLogger.info("Get Routes API called: ${AppUrls.routes}");
      AppLogger.info("Headers: ${jsonEncode({
        "Authorization": token.length > 10 ? "${token.substring(0, 10)}..." : "Bearer $token",
      })}");

      final response = await _dio.get(
        AppUrls.routes,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Routes response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map && parsed["status"] == true) {
        return Map<String, dynamic>.from(parsed);
      }
      
      if (response.statusCode == 404) {
        AppLogger.warning("Get Routes returned 404 - treating as empty routes");
        return {
          "status": true,
          "message": "No routes found",
          "routes": <String, dynamic>{}
        };
      }

      return null;
    } catch (e) {
      AppLogger.error("Get Routes error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> markAttendance({
    required String type,
    File? photo,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for markAttendance");
        return null;
      }

      final deviceId = NotificationService.instance.deviceId ?? "device_001";

      List<String> coords;
      if (latitude != null && longitude != null && latitude != 0.0) {
        coords = [latitude.toString(), longitude.toString()];
      } else {
        coords = await LocationService.getCoordinates(
          requestPermission: true,
          throwOnError: false,
        );
      }

      final isCheckout = type.trim().toUpperCase() == "OUT";
      String? attendanceId;
      if (isCheckout) {
        attendanceId = await SessionManager.getAttendanceId();
        if (attendanceId == null || attendanceId.isEmpty) {
          try {
            final statusRes = await getAttendanceStatus();
            final todayStatus = statusRes?["data"]?["attendance_status"]?["today_status"]?.toString();
            final lastSession = statusRes?["data"]?["attendance_status"]?["last_session"];
            final hasNoCheckOut = lastSession == null ||
                lastSession["check_out"] == null ||
                lastSession["check_out"].toString().trim().isEmpty;
            final hasActiveSession = todayStatus == "CHECKED_IN" && hasNoCheckOut;
            if (hasActiveSession && lastSession != null) {
              final fetchedId = lastSession["attendance_id"]?.toString();
              if (fetchedId != null && fetchedId.isNotEmpty) {
                attendanceId = fetchedId;
                await SessionManager.saveAttendanceId(fetchedId);
              }
            }
          } catch (_) {}
        }
      }

      AppLogger.info("Mark Attendance API called: type=$type, lat=${coords[0]}, lng=${coords[1]}");

      final nowStr = _formatDateTime();
      final Map<String, dynamic> formMap = {
        "type": type.toUpperCase(),
        "meta.deviceId": deviceId,
        "meta.latitude": coords[0],
        "meta.longitude": coords[1],
        "meta.deviceTS": nowStr,
        "deviceId": deviceId,
        "latitude": coords[0],
        "longitude": coords[1],
      };

      if (photo != null) {
        final fileName = photo.path.split(Platform.pathSeparator).last;
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        final mimeSubtype = (ext == 'png') ? 'png' : 'jpeg';

        formMap["photo"] = await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', mimeSubtype),
        );
        formMap["Photo"] = await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType('image', mimeSubtype),
        );
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post(
        AppUrls.markAttendance,
        data: formData,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Mark Attendance response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        final map = Map<String, dynamic>.from(parsed);
        if (map["status"] == true) {
          if (isCheckout) {
            await SessionManager.saveAttendanceStatus("CHECKED_OUT");
            await SessionManager.saveAttendanceId(null);
          } else {
            await SessionManager.saveAttendanceStatus("CHECKED_IN");
            final attId = map["attendance_id"]?.toString() ??
                map["data"]?["attendance_id"]?.toString() ??
                map["data"]?["attendance_status"]?["last_session"]?["attendance_id"]?.toString();
            if (attId != null && attId.isNotEmpty) {
              await SessionManager.saveAttendanceId(attId);
            }
          }
        } else if (isCheckout && map["message"]?.toString().toLowerCase().contains("no active check-in") == true) {
          await SessionManager.saveAttendanceStatus("CHECKED_OUT");
          await SessionManager.saveAttendanceId(null);
        }
        return map;
      }
      return null;
    } catch (e) {
      AppLogger.error("Mark Attendance error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> outletCheckIn({
    required int outletId,
    required double latitude,
    required double longitude,
    int? distributorId,
    String? address,
    String? remarks,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for outletCheckIn");
        return null;
      }

      int? finalDistId = distributorId;
      if (finalDistId == null) {
        final savedDistributors = await SessionManager.getDistributors();
        if (savedDistributors.isNotEmpty) {
          finalDistId = int.tryParse(savedDistributors.first['distributor_id']?.toString() ?? '');
        }
      }

      final payload = <String, dynamic>{
        "outlet_id": outletId,
        "latitude": latitude,
        "longitude": longitude,
        if (finalDistId != null) "distributor_id": finalDistId,
        if (address != null && address.isNotEmpty) "address": address,
        if (remarks != null && remarks.isNotEmpty) "remarks": remarks,
      };

      AppLogger.info("Outlet Check-In API called: ${AppUrls.outletCheckIn}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletCheckIn,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Outlet Check-In response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Outlet Check-In error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> outletCheckOut({
    required int visitId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for outletCheckOut");
        return null;
      }

      final payload = <String, dynamic>{
        "visit_id": visitId,
        "latitude": latitude,
        "longitude": longitude,
        if (address != null && address.isNotEmpty) "address": address,
      };

      AppLogger.info("Outlet Check-Out API called: ${AppUrls.outletCheckOut}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletCheckOut,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Outlet Check-Out response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Outlet Check-Out error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTodayAttendance");
        return null;
      }

      AppLogger.info("Get Today Attendance API called: ${AppUrls.getTodayAttendance}");

      final response = await _getWithRetry(
        AppUrls.getTodayAttendance,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response == null) return null;

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Today Attendance response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Today Attendance error", e);
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getAttendanceRange({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getAttendanceRange");
        return null;
      }

      final payload = {
        "from_date": fromDate,
        "to_date": toDate,
      };

      AppLogger.info("Get Attendance Range API called: ${AppUrls.getAttendanceRange}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.getAttendanceRange,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Attendance Range response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map && parsed["status"] == true) {
        final rawData = parsed["data"];
        if (rawData is List) {
          return rawData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Attendance Range error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> registerOutlet({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for registerOutlet");
        return null;
      }

      AppLogger.info("Register Outlet API called: ${AppUrls.outletRegistration}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletRegistration,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Register Outlet response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Register Outlet error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserOutlets({int? routeId}) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getUserOutlets");
        return null;
      }

      final payload = <String, dynamic>{};
      if (routeId != null) {
        payload["route_id"] = routeId.toString();
      }

      AppLogger.info("Get User Outlets API called: ${AppUrls.getUserOutlets}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.getUserOutlets,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get User Outlets response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get User Outlets error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getNearbyOutlets({
    required double latitude,
    required double longitude,
    int radius = 10,
    int? routeId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getNearbyOutlets");
        return null;
      }

      final payload = <String, dynamic>{
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
      };
      if (routeId != null) {
        payload["route_id"] = routeId;
      }

      AppLogger.info("Get Nearby Outlets API called: ${AppUrls.getNearbyOutlets}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.getNearbyOutlets,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Nearby Outlets response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Nearby Outlets error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProductsWithSkus() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getProductsWithSkus");
        return null;
      }

      AppLogger.info("Get Products With SKUs API called: ${AppUrls.getProductsWithSkus}");

      final response = await _dio.get(
        AppUrls.getProductsWithSkus,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Products With SKUs response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Products With SKUs error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> insertDistributorStock({
    required Map<String, dynamic> payload,
  }) async {
    return distributorStockInsert(payload: payload);
  }

  static Future<Map<String, dynamic>?> getDistributorStocks({
    required int distributorId,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getDistributorStocks");
        return null;
      }

      final payload = {
        "distributor_id": distributorId,
        if (fromDate != null) "from_date": fromDate,
        if (toDate != null) "to_date": toDate,
        "limit": limit,
        "offset": offset,
      };

      AppLogger.info("Get Distributor Stocks API called: ${AppUrls.distributorStocks}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.distributorStocks,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Distributor Stocks response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Distributor Stocks error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDistributorStock({
    required int distributorId,
    int? productId,
    String? fromDate,
    String? toDate,
  }) async {
    return getDistributorStocks(
      distributorId: distributorId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  static Future<Map<String, dynamic>?> getModules() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getModules");
        return null;
      }

      AppLogger.info("Get Modules API called: ${AppUrls.getModules}");

      final response = await _dio.get(
        AppUrls.getModules,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Modules response: ${response.statusCode} - $parsed");

      if (response.statusCode == 200 && parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Modules error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> generatePob({
    required String outletId,
    String? distributorId,
    required String itemsJson,
    required String remarks,
    String? pobType = "regular",
    File? orderCopy,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for generatePob");
        return null;
      }

      AppLogger.info("Generate POB API called: ${AppUrls.generatePob}");

      final isTele = (pobType?.toLowerCase() == "tele" || pobType?.toLowerCase() == "tele_pob");
      final Map<String, dynamic> map = {
        "outlet_id": outletId,
        if (distributorId != null && distributorId.isNotEmpty) "distributor_id": distributorId,
        "pob_type": isTele ? "tele" : "regular",
        "type": isTele ? "tele" : "regular",
        "order_type": isTele ? "tele" : "regular",
        "is_tele": isTele ? 1 : 0,
        "is_tele_pob": isTele ? 1 : 0,
        "items": itemsJson,
        "remarks": isTele && !remarks.toLowerCase().contains("tele") ? "[TELE POB] $remarks".trim() : remarks,
      };

      if (orderCopy != null && await orderCopy.exists()) {
        final fileName = orderCopy.path.split(Platform.pathSeparator).last;
        final extension = fileName.split('.').last.toLowerCase();
        final mimeType = (extension == 'png')
            ? MediaType('image', 'png')
            : (extension == 'pdf')
                ? MediaType('application', 'pdf')
                : MediaType('image', 'jpeg');

        map["order_copy"] = await MultipartFile.fromFile(
          orderCopy.path,
          filename: fileName,
          contentType: mimeType,
        );
      }

      final formData = FormData.fromMap(map);

      final response = await _dio.post(
        AppUrls.generatePob,
        data: formData,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Generate POB response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Generate POB error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> supplyPob({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for supplyPob");
        return null;
      }

      AppLogger.info("Supply POB API called: ${AppUrls.supplyPob}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.supplyPob,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Supply POB response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Supply POB error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPobHistory({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getPobHistory");
        return null;
      }

      AppLogger.info("Get POB History API called: ${AppUrls.pobHistory}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _postWithRetry(
        AppUrls.pobHistory,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response == null) return null;

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get POB History response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get POB History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> submitPosTransaction({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for submitPosTransaction");
        return null;
      }

      AppLogger.info("POS Transaction Insert API called: ${AppUrls.posTransaction}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.posTransaction,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("POS Transaction Insert response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("POS Transaction Insert error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPosHistory({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getPosHistory");
        return null;
      }

      AppLogger.info("Get POS History API called: ${AppUrls.posHistory}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _postWithRetry(
        AppUrls.posHistory,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response == null) return null;

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get POS History response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get POS History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSupportTeam() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getSupportTeam");
        return null;
      }

      AppLogger.info("Get Support Team API called: ${AppUrls.getSupportTeam}");

      final response = await _dio.get(
        AppUrls.getSupportTeam,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Support Team response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Support Team error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCallsInfo({
    String? date,
    String? month,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getCallsInfo");
        return null;
      }

      Map<String, dynamic> body = {};
      if (payload != null && payload.isNotEmpty) {
        body = Map<String, dynamic>.from(payload);
      } else if (date != null && date.isNotEmpty) {
        body["date"] = date;
      } else if (month != null && month.isNotEmpty) {
        body["month"] = month;
      }

      AppLogger.info("Calls Info API called: ${AppUrls.callsInfo}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _postWithRetry(
        AppUrls.callsInfo,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response == null) return null;

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Calls Info response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Calls Info error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExpenses() async {
    AppLogger.warning("API getExpenses bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getOutletCategories() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getOutletCategories");
        return null;
      }

      AppLogger.info("Get Outlet Categories API called: ${AppUrls.outletCategories}");

      final response = await _dio.post(
        AppUrls.outletCategories,
        data: {},
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Outlet Categories response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet Categories error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> addExpense({
    required String distributorId,
    required String expenseDate,
    required String expenseAmount,
    required String description,
    required String expenseType,
    required String paymentMode,
    File? expenseBill,
  }) async {
    AppLogger.warning("API addExpense bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> submitToAm(String expenseId) async {
    AppLogger.warning("API submitToAm bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> receiveFromSo(String expenseId) async {
    AppLogger.warning("API receiveFromSo bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> submitToAdmin(String expenseId) async {
    AppLogger.warning("API submitToAdmin bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getTeamAttendanceReport({
    String? month,
    int? today,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTeamAttendanceReport");
        return null;
      }

      AppLogger.info("Get Team Attendance Report API called: ${AppUrls.teamAttendanceReport}");

      final Map<String, dynamic> body = {};
      if (today != null) {
        body["today"] = today;
      } else if (month != null && month.isNotEmpty) {
        body["month"] = month;
      }

      final response = await _dio.post(
        AppUrls.teamAttendanceReport,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Team Attendance Report response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Team Attendance Report error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAttendanceStatus() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getAttendanceStatus");
        return null;
      }

      AppLogger.info("Get Attendance Status API called: ${AppUrls.getAttendanceStatus}");

      final response = await _dio.get(
        AppUrls.getAttendanceStatus,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Attendance Status response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        final map = Map<String, dynamic>.from(parsed);
        if (map["status"] == true && map["data"] != null) {
          final todayStatus = map["data"]["attendance_status"]?["today_status"]?.toString();
          final lastSession = map["data"]["attendance_status"]?["last_session"];
          final hasNoCheckOut = lastSession == null ||
              lastSession["check_out"] == null ||
              lastSession["check_out"].toString().trim().isEmpty;
          final bool isCurrentlyCheckedIn = todayStatus == "CHECKED_IN" && hasNoCheckOut;
          if (isCurrentlyCheckedIn && lastSession != null) {
            final attId = lastSession["attendance_id"]?.toString();
            if (attId != null && attId.isNotEmpty) {
              await SessionManager.saveAttendanceId(attId);
            }
          } else {
            await SessionManager.saveAttendanceId(null);
          }
        }
        return map;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Attendance Status error", e);
      return null;
    }
  }

  static List<Map<String, dynamic>> parsePhpPrintR(String text) {
    final List<Map<String, dynamic>> list = [];
    final blocks = text.split('stdClass Object');
    for (int i = 1; i < blocks.length; i++) {
      final block = blocks[i];
      final Map<String, dynamic> item = {};
      final lines = block.split('\n');
      for (var line in lines) {
        final match = RegExp(r'\[([a-zA-Z0-9_]+)\]\s*=>\s*(.*)').firstMatch(line);
        if (match != null) {
          final key = match.group(1)!;
          final value = match.group(2)!.trim();
          item[key] = value;
        }
      }
      if (item.isNotEmpty) {
        list.add(item);
      }
    }
    return list;
  }

  static Future<List<dynamic>> getTeamPosHistory({
    required String posType,
    int? distributorId,
    int? outletId,
    int? productId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTeamPosHistory");
        return [];
      }

      AppLogger.info("Get Team POS History API called: ${AppUrls.teamPosHistory}");

      final Map<String, dynamic> body = {
        "pos_type": posType.toLowerCase(),
      };
      if (outletId != null) body["outlet_id"] = outletId;
      if (productId != null) body["product_id"] = productId;
      if (distributorId != null) body["distributor_id"] = distributorId;

      final response = await _dio.post(
        AppUrls.teamPosHistory,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Team POS History response: ${response.statusCode} - $parsed");

      if (parsed is Map && parsed["data"] is List) {
        return List<dynamic>.from(parsed["data"]);
      }
      return [];
    } catch (e) {
      AppLogger.error("Get Team POS History error", e);
      return [];
    }
  }

  static Future<List<dynamic>> getTeamPobHistory({
    int? outletId,
    int? distributorId,
    String? status,
    String? fromDate,
    String? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTeamPobHistory");
        return [];
      }

      AppLogger.info("Get Team POB History API called: ${AppUrls.teamPobHistory}");

      final Map<String, dynamic> body = {};
      if (outletId != null) body["outlet_id"] = outletId;
      if (distributorId != null) body["distributor_id"] = distributorId;
      if (status != null && status.isNotEmpty) body["status"] = status;
      if (fromDate != null && fromDate.isNotEmpty) body["from_date"] = fromDate;
      if (toDate != null && toDate.isNotEmpty) body["to_date"] = toDate;
      if (limit != null) body["limit"] = limit;
      if (offset != null) body["offset"] = offset;

      final response = await _dio.post(
        AppUrls.teamPobHistory,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Team POB History response: ${response.statusCode} - $parsed");

      if (parsed is Map && parsed["data"] is List) {
        return List<dynamic>.from(parsed["data"]);
      }
      return [];
    } catch (e) {
      AppLogger.error("Get Team POB History error", e);
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMyTeam() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getMyTeam");
        return null;
      }

      AppLogger.info("Get My Team API called: ${AppUrls.myTeam}");

      final response = await _dio.post(
        AppUrls.myTeam,
        data: {},
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get My Team response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get My Team error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getActivityTypes() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getActivityTypes");
        return null;
      }

      AppLogger.info("Get Activity Types API called: ${AppUrls.getActivityTypes}");

      final response = await _dio.get(
        AppUrls.getActivityTypes,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Activity Types response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Activity Types error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createOutletActivity({
    required dynamic visitId,
    required dynamic activityTypeId,
    required String remarks,
    dynamic productId,
    dynamic skuId,
    List<File>? attachments,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for createOutletActivity");
        return null;
      }

      AppLogger.info("Create Outlet Activity API called: ${AppUrls.createOutletActivity}");

      final formData = FormData();
      formData.fields.add(MapEntry("visit_id", visitId.toString()));
      formData.fields.add(MapEntry("activity_type_id", activityTypeId.toString()));
      formData.fields.add(MapEntry("remarks", remarks));

      if (productId != null && productId.toString().isNotEmpty) {
        formData.fields.add(MapEntry("product_id", productId.toString()));
      }
      if (skuId != null && skuId.toString().isNotEmpty) {
        formData.fields.add(MapEntry("sku_id", skuId.toString()));
      }

      if (attachments != null && attachments.isNotEmpty) {
        for (final file in attachments) {
          if (await file.exists()) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            final ext = fileName.split('.').last.toLowerCase();
            MediaType? mediaType;
            if (ext == 'png') {
              mediaType = MediaType('image', 'png');
            } else if (ext == 'jpg' || ext == 'jpeg') {
              mediaType = MediaType('image', 'jpeg');
            } else if (ext == 'pdf') {
              mediaType = MediaType('application', 'pdf');
            }

            formData.files.add(
              MapEntry(
                "attachments[]",
                await MultipartFile.fromFile(
                  file.path,
                  filename: fileName,
                  contentType: mediaType,
                ),
              ),
            );
          }
        }
      }

      final response = await _dio.post(
        AppUrls.createOutletActivity,
        data: formData,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Create Outlet Activity response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Create Outlet Activity error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOutletHistory({
    required int outletId,
    int? today,
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getOutletHistory");
        return null;
      }

      final payload = <String, dynamic>{
        "outlet_id": outletId,
        if (today != null) "today": today,
        if (fromDate != null && fromDate.isNotEmpty) "from_date": fromDate,
        if (toDate != null && toDate.isNotEmpty) "to_date": toDate,
        if (month != null) "month": month,
        if (year != null) "year": year,
      };

      AppLogger.info("Get Outlet History API called: ${AppUrls.outletHistory}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletHistory,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Outlet History response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDashboardCounts({
    Map<String, dynamic>? payload,
    String? fromDate,
    String? toDate,
    int? month,
    int? year,
    int? today,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getDashboardCounts");
        return null;
      }

      Map<String, dynamic> body = {};
      if (payload != null && payload.isNotEmpty) {
        body = Map<String, dynamic>.from(payload);
      } else if (today != null) {
        body["today"] = today;
      } else if (fromDate != null && toDate != null) {
        body["from_date"] = fromDate;
        body["to_date"] = toDate;
      } else if (month != null && year != null) {
        body["month"] = month;
        body["year"] = year;
      }

      AppLogger.info("Dashboard Counts API called: ${AppUrls.dashboardCounts}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _postWithRetry(
        AppUrls.dashboardCounts,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response == null) return null;

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Dashboard Counts response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Dashboard Counts error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createDistributor({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API createDistributor bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getDistributors() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.get(
        AppUrls.getDistributors,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Distributors API Response: ${response.statusCode} - $parsed");
      if (response.statusCode == 200 && parsed is Map && parsed["status"] == true) {
        final rawDistributors = parsed["distributors"];
        final List<Map<String, dynamic>> distList = [];
        if (rawDistributors is Map) {
          rawDistributors.forEach((key, val) {
            if (val is Map) {
              distList.add({
                "distributor_id": val["DISTRIBUTOR_ID"]?.toString(),
                "distributor_name": val["DISTRIBUTOR_NAME"]?.toString(),
                "sap_code": val["SAP_CODE"]?.toString(),
                "udm_autoid": val["UDM_autoID"],
              });
            }
          });
        }

        await SessionManager.saveDistributors(distList);

        return {
          "status": true,
          "message": parsed["message"],
          "data": distList,
        };
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Distributors error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> distributorStockInsert({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for distributorStockInsert");
        return null;
      }

      AppLogger.info("Distributor Stock Insert API called: ${AppUrls.distributorStockInsert}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.distributorStockInsert,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Distributor Stock Insert response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Distributor Stock Insert error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDistributorStockHistory({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getDistributorStockHistory");
        return null;
      }

      AppLogger.info("Get Distributor Stock History API called: ${AppUrls.distributorStocks}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.distributorStocks,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Distributor Stock History response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Distributor Stock History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTargets() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTargets");
        return null;
      }

      AppLogger.info("Get Targets API called: ${AppUrls.getTargets}");

      final response = await _postWithRetry(
        AppUrls.getTargets,
        data: {},
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response == null) return null;

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Targets response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Targets error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPosSummary({
    Map<String, dynamic>? payload,
    String? month,
    int? today,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getPosSummary");
        return null;
      }

      Map<String, dynamic> body = {};
      if (payload != null && payload.isNotEmpty) {
        body = Map<String, dynamic>.from(payload);
      } else if (today != null) {
        body["today"] = today;
      } else if (month != null && month.isNotEmpty) {
        body["month"] = month;
      }

      AppLogger.info("POS Summary API called: ${AppUrls.posSummary}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.posSummary,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("POS Summary response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("POS Summary error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTeamMembersSummary({
    required int month,
    required int year,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTeamMembersSummary");
        return null;
      }

      AppLogger.info("Get Team Members Summary API called: ${AppUrls.teamMembersSummary}");

      final response = await _dio.post(
        AppUrls.teamMembersSummary,
        data: {
          "month": month,
          "year": year,
        },
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Team Members Summary response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Team Members Summary error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTeamMemberOutlets({
    required int userId,
    required int month,
    required int year,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getTeamMemberOutlets");
        return null;
      }

      final body = {
        "user_id": userId,
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Team Member Outlets API called: ${AppUrls.teamMemberOutlets}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.teamMemberOutlets,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Team Member Outlets response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Team Member Outlets error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOutletPobHistory({
    required int outletId,
    required int month,
    required int year,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getOutletPobHistory");
        return null;
      }

      final body = {
        "outlet_id": outletId,
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Outlet POB History API called: ${AppUrls.outletPobHistory}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.outletPobHistory,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Outlet POB History response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet POB History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOutletVisitActivityHistory({
    required int outletId,
    required int month,
    required int year,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getOutletVisitActivityHistory");
        return null;
      }

      final body = {
        "outlet_id": outletId,
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Outlet Visit-Activity History API called: ${AppUrls.outletVisitActivityHistory}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.outletVisitActivityHistory,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Get Outlet Visit-Activity History response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet Visit-Activity History error", e);
      return null;
    }
  }

  // ==========================================
  // OUTLET GEO REQUEST & COORDINATE APIS
  // ==========================================

  /// Raise Geo Request (For SO) to unblock or update outlet coordinates
  static Future<Map<String, dynamic>?> raiseOutletGeoRequest({
    required int outletId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for raiseOutletGeoRequest");
        return null;
      }

      final body = {
        "outlet_id": outletId,
        "latitude": latitude,
        "longitude": longitude,
      };

      AppLogger.info("Raise Outlet Geo Request API called: ${AppUrls.raiseOutletGeoRequest}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.raiseOutletGeoRequest,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Raise Outlet Geo Request response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Raise Outlet Geo Request error", e);
      return null;
    }
  }

  /// My Outlet Geo Requests (For SO) to view history of raised geo requests
  static Future<Map<String, dynamic>?> getMyOutletGeoRequests({
    int? outletId,
    String? status,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getMyOutletGeoRequests");
        return null;
      }

      final Map<String, dynamic> queryParams = {};
      if (outletId != null) queryParams["outlet_id"] = outletId;
      if (status != null && status.isNotEmpty && status.toLowerCase() != "all") {
        queryParams["status"] = status.toLowerCase();
      }

      AppLogger.info("My Outlet Geo Requests API called: ${AppUrls.myOutletGeoRequests} params: $queryParams");

      final response = await _dio.post(
        AppUrls.myOutletGeoRequests,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: {},
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("My Outlet Geo Requests response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("My Outlet Geo Requests error", e);
      return null;
    }
  }

  /// Outlet Geo Requests (For AM, RM) to list requests for review
  static Future<Map<String, dynamic>?> getListOutletGeoRequests({
    String? status,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getListOutletGeoRequests");
        return null;
      }

      final Map<String, dynamic> queryParams = {};
      if (status != null && status.isNotEmpty && status.toLowerCase() != "all") {
        queryParams["status"] = status.toLowerCase();
      }

      AppLogger.info("List Outlet Geo Requests API called: ${AppUrls.listOutletGeoRequests} params: $queryParams");

      final response = await _dio.post(
        AppUrls.listOutletGeoRequests,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: {},
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("List Outlet Geo Requests response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("List Outlet Geo Requests error", e);
      return null;
    }
  }

  /// Review Outlet Geo Request (For AM, RM) to approve/reject
  static Future<Map<String, dynamic>?> reviewOutletGeoRequest({
    required int requestId,
    required String action, // "approve" or "reject"
    required String remarks,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for reviewOutletGeoRequest");
        return null;
      }

      final body = {
        "request_id": requestId,
        "action": action,
        "remarks": remarks,
      };

      AppLogger.info("Review Outlet Geo Request API called: ${AppUrls.reviewOutletGeoRequest}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.reviewOutletGeoRequest,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Review Outlet Geo Request response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Review Outlet Geo Request error", e);
      return null;
    }
  }

  /// Preview Outlet Coordinates (For AM, RM)
  static Future<Map<String, dynamic>?> previewOutletCoordinates({
    required int outletId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for previewOutletCoordinates");
        return null;
      }

      final body = {
        "outlet_id": outletId,
        "latitude": latitude,
        "longitude": longitude,
      };

      AppLogger.info("Preview Outlet Coordinates API called: ${AppUrls.previewOutletCoordinates}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.previewOutletCoordinates,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Preview Outlet Coordinates response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Preview Outlet Coordinates error", e);
      return null;
    }
  }

  /// Update Outlet Coordinates Direct (For AM, RM)
  static Future<Map<String, dynamic>?> updateOutletCoordinatesDirect({
    required int outletId,
    required double latitude,
    required double longitude,
    required String remarks,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for updateOutletCoordinatesDirect");
        return null;
      }

      final body = {
        "outlet_id": outletId,
        "latitude": latitude,
        "longitude": longitude,
        "remarks": remarks,
      };

      AppLogger.info("Update Outlet Coordinates Direct API called: ${AppUrls.updateOutletCoordinatesDirect}");
      AppLogger.info("Payload: ${jsonEncode(body)}");

      final response = await _dio.post(
        AppUrls.updateOutletCoordinatesDirect,
        data: body,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      final parsed = _safeParseJson(response.data);
      AppLogger.info("Update Outlet Coordinates Direct response: ${response.statusCode} - $parsed");

      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      AppLogger.error("Update Outlet Coordinates Direct error", e);
      return null;
    }
  }
}
