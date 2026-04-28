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
        final data = response["data"];
        await SessionManager.saveSession(
          refreshToken: data["refresh_token"],
          token: data["access_token"],
          distributors: data["distributors"],
        );

        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = "Invalid login";
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return false;
  }
}