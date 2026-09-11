import 'package:flutter/cupertino.dart';

import '../../permissions/SessionManager.dart';
import '../../services/api_services.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<bool> login(String phone, String password) async {
    error = null;

    if (phone.isEmpty) {
      error = "Mobile number is required";
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      error = "Password is required";
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await ApiServices.login(
        phone: phone,
        password: password,
      );

      if (response != null) {
        final status = response["status"];
        if (status == true || status == "success" || status == 1) {
          final data = (response["data"] is Map) ? response["data"] : response;
          final token = data["access_token"]?.toString() ??
              response["access_token"]?.toString() ??
              data["token"]?.toString() ??
              response["token"]?.toString() ??
              data["jwt"]?.toString();
          final refreshToken = data["refresh_token"]?.toString() ??
              response["refresh_token"]?.toString() ??
              data["refreshToken"]?.toString() ??
              response["refreshToken"]?.toString();

          if (token == null || refreshToken == null || token.trim().isEmpty || refreshToken.trim().isEmpty) {
            error = "Missing login tokens in response";
            isLoading = false;
            notifyListeners();
            return false;
          }

          // Clear any stale cached session/keys first before saving new session
          await SessionManager.clearSession();

          await SessionManager.saveSession(
            refreshToken: refreshToken.trim(),
            token: token.trim(),
          );

          final userInfo = data["user_info"] ?? response["user_info"];
          if (userInfo != null) {
            final name = userInfo["name"]?.toString() ?? "Unknown";
            final rolecode = userInfo["rolecode"]?.toString().trim();
            final role = (rolecode == null || rolecode.isEmpty) ? "Sale Off" : rolecode;
            await SessionManager.saveUserDetails(name, role, userInfo: userInfo);
          }

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
          error = response["message"] ?? "Invalid login";
        }
      } else {
        error = "Invalid login";
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

      if (response != null && response["status"] == true) {
        await SessionManager.clearSession();

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = response?["message"] ?? "Change password failed";
      }
    } catch (e) {
      debugPrint("Change password error: $e");
      error = "Operation failed";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

}