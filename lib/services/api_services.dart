import 'dart:convert';
import 'dart:io';
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

      if (response.statusCode == 200) {
        return response.data;
      }

      AppLogger.warning("Login failed: ${response.data}");
      return response.data;
    } catch (e) {
      AppLogger.error("Login error", e);
      return {"status": false, "message": "Login failed"};
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
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final response = await _dio.post(
        AppUrls.generatePob,
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
      AppLogger.error("Generate POB error", e);
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

  static Future<Map<String, dynamic>?> getDailyCallSummary({
    required String date,
    int? distributorId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = {
        "date": date,
      };
      if (distributorId != null) {
        payload["distributor_id"] = distributorId.toString();
      }

      final response = await _dio.post(
        AppUrls.dailyCallSummary,
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
      AppLogger.error("Get Daily Call Summary error", e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCallsInfo({
    String? date,
    String? month,
    int? distributorId,
  }) async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return null;

      final payload = <String, dynamic>{};
      if (date != null) payload["date"] = date;
      if (month != null) payload["month"] = month;
      if (distributorId != null) payload["distributor_id"] = distributorId;

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

      if (response.statusCode == 200 && response.data["status"] == "success") {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Get Calls Info error", e);
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
      if (token == null) return null;

      final payload = <String, dynamic>{};
      if (month != null) payload["month"] = month;
      if (today != null) payload["today"] = today;

      AppLogger.info("Team Attendance Report API called");
      AppLogger.info("Payload: $payload");

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

      AppLogger.info("Team Attendance Report response: ${response.data}");

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      AppLogger.error("Team Attendance Report error", e);
      return null;
    }
  }
}
