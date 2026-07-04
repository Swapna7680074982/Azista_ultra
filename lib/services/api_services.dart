import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_urls.dart';
import 'package:http_parser/http_parser.dart';
import '../permissions/SessionManager.dart';
import '../screens/login/login_screen.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../utilities/mylogger.dart';
import 'navigation_service.dart';


class ApiServices {
  static final Dio _dio = Dio()..interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) async {
        final path = response.requestOptions.path;
        final isLogin = path.contains('/user/login');
        final isRefresh = path.contains('/user/refresh_token');
        final isLogout = path.contains('/user/logout');

        if (!isLogin && !isRefresh && !isLogout &&
            (response.statusCode == 401 ||
                (response.data is Map &&
                    (response.data["message"]?.toString().contains("Token expired") == true ||
                     response.data["message"]?.toString().contains("Token revoked") == true)))) {
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

        if (!isLogin && !isRefresh && !isLogout &&
            (e.response?.statusCode == 401 ||
                (e.response?.data is Map &&
                    (e.response?.data["message"]?.toString().contains("Token expired") == true ||
                     e.response?.data["message"]?.toString().contains("Token revoked") == true)))) {
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
  );

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
      final dio = Dio();
      final response = await dio.post(
        AppUrls.refreshToken,
        data: payload,
      );

      AppLogger.info("Refresh Token response: ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        final newAccessToken = response.data["access_token"];
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

      if (response.statusCode == 200) {
        return response.data;
      }

      AppLogger.warning("Login failed: ${response.data}");
      return response.data;
    } catch (e) {
      AppLogger.error("Login error", e);
      String message = "Login failed";
      if (e is DioException) {
        if (e.response != null) {
          final data = e.response?.data;
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

      AppLogger.info("Get Routes API called: ${AppUrls.routes}");
      AppLogger.info("Headers: ${jsonEncode({
        "Authorization": token.length > 10 ? "${token.substring(0, 10)}..." : "Bearer $token",
      })}");

      final response = await _dio.get(
        AppUrls.routes,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      AppLogger.info("Get Routes response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
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

  static Future<Map<String, dynamic>?> outletCheckIn({
    required int outletId,
    required double latitude,
    required double longitude,
    String? address,
    String? remarks,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for outletCheckIn");
        return null;
      }

      final payload = {
        "outlet_id": outletId,
        "latitude": latitude,
        "longitude": longitude,
        "address": address ?? "",
        "remarks": remarks ?? "",
      };

      AppLogger.info("Outlet Check-In API called: ${AppUrls.outletCheckIn}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletCheckIn,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Outlet Check-In response: ${response.data}");
      return response.data;
    } catch (e) {
      AppLogger.error("Outlet Check-In error", e);
      if (e is DioException) {
        AppLogger.error("Outlet Check-In status code: ${e.response?.statusCode}");
        AppLogger.error("Outlet Check-In response data: ${e.response?.data}");
        if (e.response?.data is Map) {
          return e.response!.data as Map<String, dynamic>;
        }
      }
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

      final payload = {
        "visit_id": visitId,
        "latitude": latitude,
        "longitude": longitude,
        "address": address ?? "",
      };

      AppLogger.info("Outlet Check-Out API called: ${AppUrls.outletCheckOut}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletCheckOut,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Outlet Check-Out response: ${response.data}");
      return response.data;
    } catch (e) {
      AppLogger.error("Outlet Check-Out error", e);
      if (e is DioException) {
        AppLogger.error("Outlet Check-Out status code: ${e.response?.statusCode}");
        AppLogger.error("Outlet Check-Out response data: ${e.response?.data}");
        if (e.response?.data is Map) {
          return e.response!.data as Map<String, dynamic>;
        }
      }
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

  static Future<Map<String, dynamic>?> registerOutlet({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dio.post(
        AppUrls.outletRegistration,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      final data = response.data;

      AppLogger.info("RAW STATUS: ${data["status"]}");
      AppLogger.info("TYPE: ${data["status"].runtimeType}");

      return {
        "status": data["status"] == true || data["outlet_id"] != null,
        "message": data["message"]?.toString() ?? "Success",
        "outlet_id": data["outlet_id"],
      };

    } catch (e) {
      return {
        "status": false,
        "message": "Registration failed"
      };
    }
  }

  static Future<Map<String, dynamic>?> getUserOutlets({int? routeId}) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = routeId != null ? {"route_id": routeId} : {};

      final response = await _dio.post(
        AppUrls.Outlets,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == true) {
        final data = response.data["data"];
        if (data is List && data.isNotEmpty) {
          AppLogger.info("getUserOutlets first outlet sample: ${data.first}");
        }
        return response.data;
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
    int radius = 5,
    int? routeId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = {
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
      };

      if (routeId != null) {
        payload["route_id"] = routeId;
      }

      final response = await _dio.post(
        AppUrls.nearOutlets,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("API FULL RESPONSE: ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
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
      if (token == null) return null;

      final response = await _dio.get(
        AppUrls.getProductsWithSkus,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
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
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.insertDistributorStock,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      return {
        "status": response.data["status"] == true,
        "message": response.data["message"]?.toString() ?? "Success",
      };
    } catch (e) {
      AppLogger.error("Insert Distributor Stock error", e);
      return {
        "status": false,
        "message": "Failed to insert stock",
      };
    }
  }

  static Future<Map<String, dynamic>?> getDistributorStock({
    required int distributorId,
    int? productId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = {
        "distributor_id": distributorId,
      };
      
      if (productId != null) {
        payload["product_id"] = productId;
      }

      final response = await _dio.post(
        AppUrls.getDistributorStock,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Distributor Stock error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getModules() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.get(
        AppUrls.getModules,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
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
    File? orderCopy,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final Map<String, dynamic> fields = {
        "outlet_id": outletId,
        if (distributorId != null) "distributor_id": distributorId,
        "items": itemsJson,
        "remarks": remarks,
      };

      final FormData formData = FormData.fromMap(fields);

      if (orderCopy != null) {
        final fileName = orderCopy.path.split('/').last.split('\\').last;
        formData.files.add(MapEntry(
          "order_copy",
          await MultipartFile.fromFile(
            orderCopy.path,
            filename: fileName,
            contentType: MediaType('image', fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'),
          ),
        ));
      }

      AppLogger.info("Generate POB API call: ${AppUrls.generatePob}");
      AppLogger.info("Fields: $fields");
      AppLogger.info("File payload: ${orderCopy != null ? 'order_copy -> ${orderCopy.path}' : 'None'}");

      final response = await _dio.post(
        AppUrls.generatePob,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Generate POB response status: ${response.statusCode}");
      AppLogger.info("Generate POB response data: ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Generate POB error", e);
      if (e is DioException) {
        AppLogger.error("Generate POB status code: ${e.response?.statusCode}");
        AppLogger.error("Generate POB response data: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> supplyPob({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.supplyPob,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Supply POB API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
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
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.pobHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("POB History API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("POB History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> submitPosTransaction({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.posTransaction,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("POS Transaction error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPosHistory({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.posHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("POS History error", e);
      return null;
    }
  }
  static Future<Map<String, dynamic>?> getSupportTeam() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Get Support Team API called: ${AppUrls.getSupportTeam}");
      AppLogger.info("Headers: ${jsonEncode({
        "Authorization": "Bearer $token",
      })}");
      final response = await _dio.post(
        AppUrls.getSupportTeam,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      AppLogger.info("Get Support Team response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
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
    int? distributorId,
  }) async {
    final payload = <String, dynamic>{};
    if (date != null) payload["date"] = date;
    if (month != null) payload["month"] = month;
    if (distributorId != null) payload["distributor_id"] = distributorId;

    AppLogger.info("Get Calls Info API call: ${AppUrls.callsInfo} with payload: $payload");

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("Get Calls Info: Session token is null");
        return null;
      }

      final response = await _dio.post(
        AppUrls.callsInfo,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Get Calls Info API Endpoint: ${AppUrls.callsInfo} | Response: ${response.data}");

      AppLogger.info("Get Calls Info response status: ${response.statusCode}");
      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      AppLogger.warning("Get Calls Info unexpected response: ${response.data}");
      return null;
    } catch (e) {
      if (e is DioException) {
        AppLogger.error("Get Calls Info DioException: ${e.message}");
        AppLogger.error("Get Calls Info Response Status Code: ${e.response?.statusCode}");
        AppLogger.error("Get Calls Info Response Data: ${e.response?.data}");
      } else {
        AppLogger.error("Get Calls Info error: $e");
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExpenses() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Get Expenses API called: ${AppUrls.getExpenses}");
      final response = await _dio.get(
        AppUrls.getExpenses,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Get Expenses response: ${jsonEncode(response.data)}");
      return response.data;
    } catch (e) {
      AppLogger.error("Get Expenses error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOutletCategories() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        AppLogger.warning("No token found for getOutletCategories");
        return null;
      }

      AppLogger.info("Get Outlet Categories API called: ${AppUrls.outletCategories}");
      final response = await _dio.get(
        AppUrls.outletCategories,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      AppLogger.info("Get Outlet Categories response: ${response.statusCode}");
      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
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
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final String? fileName = expenseBill != null
          ? expenseBill.path.split('/').last.split('\\').last
          : null;

      FormData formData = FormData.fromMap({
        "distributor_id": distributorId,
        "expense_date": expenseDate,
        "expense_amount": expenseAmount,
        "description": description,
        "expense_type": expenseType,
        "payment_mode": paymentMode,
      });

      if (expenseBill != null) {
        formData.files.add(MapEntry(
          "expense_bill",
          await MultipartFile.fromFile(
            expenseBill.path,
            filename: fileName,
          ),
        ));
      }

      // ── DEBUG: Print full payload before sending ──
      AppLogger.info("━━━━━━━ ADD EXPENSE PAYLOAD ━━━━━━━");
      AppLogger.info("URL       : ${AppUrls.addExpense}");
      AppLogger.info("distributor_id  : $distributorId");
      AppLogger.info("expense_date    : $expenseDate");
      AppLogger.info("expense_amount  : $expenseAmount");
      AppLogger.info("description     : $description");
      AppLogger.info("expense_type    : $expenseType");
      AppLogger.info("payment_mode    : $paymentMode");
      AppLogger.info("Expense_bill    : ${expenseBill != null ? '✅ File attached → $fileName (${expenseBill.lengthSync()} bytes)' : '❌ No file'}");
      AppLogger.info("FormData files  : ${formData.files.map((e) => '${e.key}=${e.value.filename}').toList()}");
      AppLogger.info("FormData fields : ${formData.fields.map((e) => '${e.key}=${e.value}').toList()}");
      AppLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response = await _dio.post(
        AppUrls.addExpense,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Add Expense response: ${jsonEncode(response.data)}");
      return response.data;
    } catch (e) {
      AppLogger.error("Add Expense error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> submitToAm(String expenseId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Submit to AM API called: ${AppUrls.submitToAm}");
      AppLogger.info("Payload: ${jsonEncode({"expense_id": expenseId})}");
      final response = await _dio.post(
        AppUrls.submitToAm,
        data: {"expense_id": expenseId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Submit to AM response: ${jsonEncode(response.data)}");
      return response.data;
    } catch (e) {
      AppLogger.error("Submit to AM error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> receiveFromSo(String expenseId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Receive from SO API called: ${AppUrls.receiveFromSo}");
      AppLogger.info("Payload: ${jsonEncode({"expense_id": expenseId})}");
      final response = await _dio.post(
        AppUrls.receiveFromSo,
        data: {"expense_id": expenseId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Receive from SO response: ${jsonEncode(response.data)}");
      return response.data;
    } catch (e) {
      AppLogger.error("Receive from SO error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> submitToAdmin(String expenseId) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Submit to Admin API called: ${AppUrls.submitToAdmin}");
      AppLogger.info("Payload: ${jsonEncode({"expense_id": expenseId})}");
      final response = await _dio.post(
        AppUrls.submitToAdmin,
        data: {"expense_id": expenseId},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Submit to Admin response: ${jsonEncode(response.data)}");
      return response.data;
    } catch (e) {
      AppLogger.error("Submit to Admin error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTeamAttendanceReport({
    String? month,
    int? today,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        print("❌ TEAM ATTENDANCE: Session Token is null");
        return null;
      }

      final payload = <String, dynamic>{};
      if (month != null) payload["month"] = month;
      if (today != null) payload["today"] = today;

      print("━━━━━━━ TEAM ATTENDANCE REPORT REQUEST ━━━━━━━");
      print("URL: ${AppUrls.teamAttendanceReport}");
      print("Headers: {Authorization: Bearer $token, Content-Type: application/json}");
      print("Payload: $payload");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final response = await _dio.post(
        AppUrls.teamAttendanceReport,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("━━━━━━━ TEAM ATTENDANCE REPORT RESPONSE ━━━━━━━");
      print("Status: ${response.statusCode}");
      print("Response Data: ${response.data}");
      print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print("❌ Team Attendance Report error: $e");
      if (e is DioException) {
        print("❌ DioException Status Code: ${e.response?.statusCode}");
        print("❌ DioException Response Data: ${e.response?.data}");
      }
      AppLogger.error("Team Attendance Report error", e);
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
          headers: {
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      AppLogger.info("Get Attendance Status response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
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

  static Future<List<dynamic>?> getTeamPosHistory({
    required String posType,
    int? distributorId,
    int? outletId,
    int? productId,
  }) async {
    try {
      final token = await SessionManager.getToken();

      if (token == null) {
        AppLogger.warning("No token found for getTeamPosHistory");
        return null;
      }

      final Map<String, dynamic> payload = {
        "pos_type": posType,
      };
      if (distributorId != null) payload["distributor_id"] = distributorId;
      if (outletId != null) payload["outlet_id"] = outletId;
      if (productId != null) payload["product_id"] = productId;

      AppLogger.info("Get Team POS History API called: ${AppUrls.teamPosHistory}");
      AppLogger.info("Payload: $payload");

      final response = await _dio.post(
        AppUrls.teamPosHistory,
        data: payload,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      AppLogger.info("Get Team POS History response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        final rawData = response.data?.toString() ?? "";
        if (rawData.isEmpty) return null;

        // Try standard JSON first
        try {
          final decoded = jsonDecode(rawData.trim());
          if (decoded is List) {
            return decoded;
          } else if (decoded is Map && decoded["data"] is List) {
            return decoded["data"];
          }
        } catch (_) {
          AppLogger.warning("Get Team POS History: not valid JSON, trying raw PHP print_r parser");
          final parsed = parsePhpPrintR(rawData);
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Team POS History error", e);
      return null;
    }
  }

  static Future<List<dynamic>?> getTeamPobHistory({
    int? outletId,
    int? distributorId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final token = await SessionManager.getToken();

      if (token == null) {
        AppLogger.warning("No token found for getTeamPobHistory");
        return null;
      }

      final Map<String, dynamic> payload = {};
      if (outletId != null) payload["outlet_id"] = outletId;
      if (distributorId != null) payload["distributor_id"] = distributorId;
      if (status != null) payload["status"] = status;
      if (fromDate != null) payload["from_date"] = fromDate;
      if (toDate != null) payload["to_date"] = toDate;

      AppLogger.info("Get Team POB History API called: ${AppUrls.teamPobHistory}");
      AppLogger.info("Payload: $payload");

      final response = await _dio.post(
        AppUrls.teamPobHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      AppLogger.info("Get Team POB History response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        if (response.data is Map && response.data["status"] == "success") {
          return response.data["data"];
        }
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Team POB History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getActivityTypes() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Get Activity Types API called: ${AppUrls.getActivityTypes}");

      final response = await _dio.get(
        AppUrls.getActivityTypes,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Get Activity Types response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Activity Types error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createOutletActivity({
    required String visitId,
    required String activityTypeId,
    required String remarks,
    String? productId,
    String? skuId,
    List<File>? attachments,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final Map<String, dynamic> fields = {
        "visit_id": visitId,
        "activity_type_id": activityTypeId,
        "remarks": remarks,
      };

      if (productId != null) {
        fields["product_id"] = productId;
      }
      if (skuId != null) {
        fields["sku_id"] = skuId;
      }

      final FormData formData = FormData.fromMap(fields);

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          final fileName = file.path.split('/').last.split('\\').last;
          final extension = fileName.split('.').last.toLowerCase();
          
          String mimeType = 'octet-stream';
          String mimeSubtype = 'octet-stream';
          if (extension == 'pdf') {
            mimeType = 'application';
            mimeSubtype = 'pdf';
          } else if (extension == 'png') {
            mimeType = 'image';
            mimeSubtype = 'png';
          } else if (extension == 'jpg' || extension == 'jpeg') {
            mimeType = 'image';
            mimeSubtype = 'jpeg';
          }

          formData.files.add(MapEntry(
            "attachments[]",
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
              contentType: MediaType(mimeType, mimeSubtype),
            ),
          ));
        }
      }

      AppLogger.info("Create Outlet Activity API call: ${AppUrls.createOutletActivity}");
      AppLogger.info("Fields: $fields");
      AppLogger.info("Attachments count: ${attachments?.length ?? 0}");

      final response = await _dio.post(
        AppUrls.createOutletActivity,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      AppLogger.info("Create Outlet Activity response status: ${response.statusCode}");
      AppLogger.info("Create Outlet Activity response data: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Create Outlet Activity error", e);
      if (e is DioException) {
        AppLogger.error("Create Outlet Activity status code: ${e.response?.statusCode}");
        AppLogger.error("Create Outlet Activity response data: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOutletHistory({
    required int outletId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = {
        "outlet_id": outletId,
      };

      AppLogger.info("Get Outlet History API called: ${AppUrls.outletHistory}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.outletHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Get Outlet History response status: ${response.statusCode}");
      AppLogger.info("Get Outlet History response data: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet History error", e);
      if (e is DioException) {
        AppLogger.error("Get Outlet History status code: ${e.response?.statusCode}");
        AppLogger.error("Get Outlet History response data: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDashboardCounts({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      AppLogger.info("Get Dashboard Counts API called: ${AppUrls.dashboardCounts}");
      AppLogger.info("Payload: ${jsonEncode(payload)}");

      final response = await _dio.post(
        AppUrls.dashboardCounts,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Get Dashboard Counts response status: ${response.statusCode}");
      AppLogger.info("Get Dashboard Counts response data: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Dashboard Counts error", e);
      if (e is DioException) {
        AppLogger.error("Get Dashboard Counts status code: ${e.response?.statusCode}");
        AppLogger.error("Get Dashboard Counts response data: ${e.response?.data}");
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createDistributor({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.createDistributor,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Create Distributor API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Create Distributor error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDistributors() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.get(
        AppUrls.getDistributors,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      print("Get Distributors API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
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
      if (token == null) return null;

      print("Distributor Stock Insert API Request Payload: $payload");
      final response = await _dio.post(
        AppUrls.distributorStockInsert,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Distributor Stock Insert API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
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
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.distributorStockHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Distributor Stock History API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Distributor Stock History error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTargets() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.getTargets,
        data: {},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      print("Get Targets API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == true) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Targets error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getTeamMembersSummary({
    required int month,
    required int year,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = {
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Team Members Summary API call: ${AppUrls.teamMembersSummary} with payload: $payload");

      final response = await _dio.post(
        AppUrls.teamMembersSummary,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Get Team Members Summary response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
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
      if (token == null) return null;

      final payload = {
        "user_id": userId,
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Team Member Outlets API call: ${AppUrls.teamMemberOutlets} with payload: $payload");

      final response = await _dio.post(
        AppUrls.teamMemberOutlets,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Get Team Member Outlets response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
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
      if (token == null) return null;

      final payload = {
        "outlet_id": outletId,
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Outlet Pob History API call: ${AppUrls.outletPobHistory} with payload: $payload");

      final response = await _dio.post(
        AppUrls.outletPobHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Get Outlet Pob History response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet Pob History error", e);
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
      if (token == null) return null;

      final payload = {
        "outlet_id": outletId,
        "month": month,
        "year": year,
      };

      AppLogger.info("Get Outlet Visit Activity History API call: ${AppUrls.outletVisitActivityHistory} with payload: $payload");

      final response = await _dio.post(
        AppUrls.outletVisitActivityHistory,
        data: payload,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );

      AppLogger.info("Get Outlet Visit Activity History response: ${response.statusCode} - ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Outlet Visit Activity History error", e);
      return null;
    }
  }
}
