import 'package:flutter/cupertino.dart';

import '../../permissions/SessionManager.dart';
import '../../services/api_services.dart';
import '../../utilities/role_helper.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<bool> login(String employeeId, String password) async {
    error = null;

    if (employeeId.trim().isEmpty) {
      error = "Employee ID is required";
      notifyListeners();
      return false;
    }
    if (password.trim().isEmpty) {
      error = "Password is required";
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiServices.login(
        employeeId: employeeId.trim(),
        password: password.trim(),
      );

      if (response != null) {
        final status = response["status"];
        final statusCode = response["status_code"];
        final empStatus = response["empStatus"];

        if (status == true || status == "success" || status == 1 || statusCode == 200 || empStatus == true) {
          final data = (response["data"] is Map) ? response["data"] : response;
          final basicDetails = (response["basicDetails"] is Map) ? response["basicDetails"] : null;

          final token = data["access_token"]?.toString() ??
              response["token"]?.toString() ??
              response["access_token"]?.toString() ??
              data["token"]?.toString() ??
              data["jwt"]?.toString();
          final refreshToken = data["refresh_token"]?.toString() ??
              response["refresh_token"]?.toString() ??
              data["refreshToken"]?.toString() ??
              response["refreshToken"]?.toString() ??
              token;

          if (token == null || token.trim().isEmpty) {
            error = "Missing login tokens in response";
            isLoading = false;
            notifyListeners();
            return false;
          }

          // Clear any stale cached session/keys first before saving new session
          await SessionManager.clearSession();

          await SessionManager.saveSession(
            refreshToken: (refreshToken ?? token).trim(),
            token: token.trim(),
          );

          final userInfo = (data["user_info"] is Map)
              ? Map<String, dynamic>.from(data["user_info"])
              : <String, dynamic>{};

          if (basicDetails != null) {
            if (!userInfo.containsKey("name") || userInfo["name"] == null) {
              userInfo["name"] = basicDetails["EMPNAME"];
            }
            if (!userInfo.containsKey("employee_id") || userInfo["employee_id"] == null) {
              userInfo["employee_id"] = basicDetails["EMPID"]?.toString();
            }
            if (!userInfo.containsKey("email") || userInfo["email"] == null) {
              userInfo["email"] = basicDetails["EMAIL"];
            }
            if (!userInfo.containsKey("mobile") || userInfo["mobile"] == null) {
              userInfo["mobile"] = basicDetails["MOBILE"];
            }
            userInfo["basicDetails"] = basicDetails;
          }

          final name = userInfo["name"]?.toString() ?? basicDetails?["EMPNAME"]?.toString() ?? "Unknown";
          final rawRole = userInfo["rolecode"]?.toString().trim() ??
              data["role"]?.toString().trim() ??
              response["role"]?.toString().trim();
          final role = RoleHelper.formatRole(rawRole);
          userInfo["rolecode"] = role;
          await SessionManager.saveUserDetails(name, role, userInfo: userInfo);

          final attStatusObj = (data["attendance_status"] ?? response["attendance_status"]);
          final attendanceStatus = attStatusObj?["today_status"]?.toString();
          await SessionManager.saveAttendanceStatus(attendanceStatus);

          final lastSession = attStatusObj?["last_session"];
          final hasNoCheckOut = lastSession == null ||
              lastSession["check_out"] == null ||
              lastSession["check_out"].toString().trim().isEmpty;
          final bool isCurrentlyCheckedIn = attendanceStatus == "CHECKED_IN" && hasNoCheckOut;

          if (isCurrentlyCheckedIn && lastSession != null) {
            final attId = lastSession["attendance_id"]?.toString();
            if (attId != null && attId.isNotEmpty) {
              await SessionManager.saveAttendanceId(attId);
            }
          } else {
            await SessionManager.saveAttendanceId(null);
          }

          isLoading = false;
          notifyListeners();
          return true;
        } else {
          error = response["message"]?.toString() ?? "Invalid credentials";
        }
      } else {
        error = "Invalid credentials";
      }
    } catch (e) {
      debugPrint("Login error: $e");
      error = "Operation failed";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiServices.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response != null &&
          (response["status"] == true ||
           response["status"] == "success" ||
           response["status_code"] == 200 ||
           response["statusCode"] == 200)) {
        await SessionManager.clearSession();

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = response?["message"]?.toString() ?? "Change password failed";
      }
    } catch (e) {
      debugPrint("Change password error: $e");
      error = "Operation failed";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> deleteAccount({
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiServices.deleteAccount(
        password: password,
      );

      if (response != null &&
          (response["status"] == true ||
           response["status"] == "success" ||
           response["status_code"] == 200 ||
           response["statusCode"] == 200)) {
        await SessionManager.clearSession();

        isLoading = false;
        notifyListeners();
        return response;
      } else {
        error = response?["message"]?.toString() ?? "Delete account failed";
      }
    } catch (e) {
      debugPrint("Delete account error: $e");
      error = "Operation failed";
    }

    isLoading = false;
    notifyListeners();
    return null;
  }
}