import 'package:flutter/cupertino.dart';

import '../../permissions/SessionManager.dart';
import '../../services/api_services.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<bool> login(String phone, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiServices.login(
        phone: phone,
        password: password,
      );

      if (response != null) {
        final status = response["status"];
        if (status == true || status == "success" || status == 1) {
          final data = response["data"];
          await SessionManager.saveSession(
            refreshToken: data["refresh_token"],
            token: data["access_token"],
            distributors: data["distributors"],
          );

          final userInfo = data["user_info"];
          if (userInfo != null) {
            final name = userInfo["name"]?.toString() ?? "Unknown";
            final rolecode = userInfo["rolecode"]?.toString().trim();
            final role = (rolecode == null || rolecode.isEmpty) ? "Sale Off" : rolecode;
            await SessionManager.saveUserDetails(name, role, userInfo: userInfo);
          }

          final attendanceStatus = data["attendance_status"]?["today_status"];
          await SessionManager.saveAttendanceStatus(attendanceStatus);

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
      error = "Operation failed";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

}