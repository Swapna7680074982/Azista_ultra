import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class LoginProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  Future<bool> login(String phone, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final success = await ApiServices.login(
        phone: phone,
        password: password,
      );

      isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return false;
  }
}