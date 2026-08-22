import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_urls.dart';
import '../permissions/SessionManager.dart';
import '../screens/login/login_screen.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../utilities/mylogger.dart';
import 'navigation_service.dart';


class ApiServices {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      sendTimeout: const Duration(seconds: 50),
    ),
  )..interceptors.add(
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
    AppLogger.warning("API markAttendance bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> outletCheckIn({
    required int outletId,
    required double latitude,
    required double longitude,
    String? address,
    String? remarks,
  }) async {
    AppLogger.warning("API outletCheckIn bypassed (API Removed)");
    return {
      "status": true,
      "visit_id": 99999,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> outletCheckOut({
    required int visitId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    AppLogger.warning("API outletCheckOut bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getTodayAttendance() async {
    AppLogger.warning("API getTodayAttendance bypassed (API Removed)");
    return {
      "status": true,
      "attendance_status": {
        "today_status": "NOT_CHECKED_IN",
        "last_session": null
      }
    };
  }

  static Future<List<Map<String, dynamic>>?> getAttendanceRange({
    required String fromDate,
    required String toDate,
  }) async {
    AppLogger.warning("API getAttendanceRange bypassed (API Removed)");
    return [];
  }

  static Future<Map<String, dynamic>?> registerOutlet({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API registerOutlet bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
      "outlet_id": 9999,
    };
  }

  static Future<Map<String, dynamic>?> getUserOutlets({int? routeId}) async {
    AppLogger.warning("API getUserOutlets bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getNearbyOutlets({
    required double latitude,
    required double longitude,
    int radius = 5,
    int? routeId,
  }) async {
    AppLogger.warning("API getNearbyOutlets bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getProductsWithSkus() async {
    AppLogger.warning("API getProductsWithSkus bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> insertDistributorStock({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API insertDistributorStock bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getDistributorStock({
    required int distributorId,
    int? productId,
  }) async {
    AppLogger.warning("API getDistributorStock bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getModules() async {
    AppLogger.warning("API getModules bypassed (API Removed)");
    return {
      "status": "success",
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> generatePob({
    required String outletId,
    String? distributorId,
    required String itemsJson,
    required String remarks,
    File? orderCopy,
  }) async {
    AppLogger.warning("API generatePob bypassed (API Removed)");
    return {
      "status": "success",
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> supplyPob({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API supplyPob bypassed (API Removed)");
    return {
      "status": "success",
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getPobHistory({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API getPobHistory bypassed (API Removed)");
    return {
      "status": "success",
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> submitPosTransaction({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API submitPosTransaction bypassed (API Removed)");
    return {
      "status": "success",
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getPosHistory({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API getPosHistory bypassed (API Removed)");
    return {
      "status": "success",
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getSupportTeam() async {
    AppLogger.warning("API getSupportTeam bypassed (API Removed)");
    return {
      "status": "success",
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getCallsInfo({
    String? date,
    String? month,
    int? distributorId,
  }) async {
    AppLogger.warning("API getCallsInfo bypassed (API Removed)");
    return {
      "status": "success",
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getExpenses() async {
    AppLogger.warning("API getExpenses bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getOutletCategories() async {
    AppLogger.warning("API getOutletCategories bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
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
    AppLogger.warning("API getTeamAttendanceReport bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getAttendanceStatus() async {
    AppLogger.warning("API getAttendanceStatus bypassed (API Removed)");
    return {
      "status": true,
      "data": {
        "attendance_status": {
          "today_status": "NOT_CHECKED_IN",
          "last_session": null
        }
      }
    };
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
    AppLogger.warning("API getTeamPosHistory bypassed (API Removed)");
    return [];
  }

  static Future<List<dynamic>> getTeamPobHistory({
    int? outletId,
    int? distributorId,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    AppLogger.warning("API getTeamPobHistory bypassed (API Removed)");
    return [];
  }

  static Future<Map<String, dynamic>?> getActivityTypes() async {
    AppLogger.warning("API getActivityTypes bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> createOutletActivity({
    required String visitId,
    required String activityTypeId,
    required String remarks,
    String? productId,
    String? skuId,
    List<File>? attachments,
  }) async {
    AppLogger.warning("API createOutletActivity bypassed (API Removed)");
    return {
      "status": true,
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getOutletHistory({
    required int outletId,
  }) async {
    AppLogger.warning("API getOutletHistory bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getDashboardCounts({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API getDashboardCounts bypassed (API Removed)");
    return {
      "status": true,
      "data": {},
    };
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
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      print("Get Distributors API Response: ${response.data}");
      if (response.statusCode == 200 && response.data["status"] == true) {
        final rawDistributors = response.data["distributors"];
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
          "message": response.data["message"],
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
    AppLogger.warning("API distributorStockInsert bypassed (API Removed)");
    return {
      "status": "success",
      "message": "Bypassed (API Removed)",
    };
  }

  static Future<Map<String, dynamic>?> getDistributorStockHistory({
    required Map<String, dynamic> payload,
  }) async {
    AppLogger.warning("API getDistributorStockHistory bypassed (API Removed)");
    return {
      "status": "success",
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getTargets() async {
    AppLogger.warning("API getTargets bypassed (API Removed)");
    return {
      "status": true,
      "data": {},
    };
  }

  static Future<Map<String, dynamic>?> getTeamMembersSummary({
    required int month,
    required int year,
  }) async {
    AppLogger.warning("API getTeamMembersSummary bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getTeamMemberOutlets({
    required int userId,
    required int month,
    required int year,
  }) async {
    AppLogger.warning("API getTeamMemberOutlets bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getOutletPobHistory({
    required int outletId,
    required int month,
    required int year,
  }) async {
    AppLogger.warning("API getOutletPobHistory bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }

  static Future<Map<String, dynamic>?> getOutletVisitActivityHistory({
    required int outletId,
    required int month,
    required int year,
  }) async {
    AppLogger.warning("API getOutletVisitActivityHistory bypassed (API Removed)");
    return {
      "status": true,
      "data": [],
    };
  }
}
