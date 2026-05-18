import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  bool isOnline = false;
  String? selectedDistributor;
  int? selectedDistributorId;
  String? userRole;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setUserRole(String? role) {
    userRole = role;
    notifyListeners();
  }

  void setDistributor(String? distributor, {int? id}) {
    selectedDistributor = distributor;
    selectedDistributorId = id;
    notifyListeners();
  }

  void reset() {
    isOnline = false;
    selectedDistributor = null;
    selectedDistributorId = null;
    userRole = null;
    notifyListeners();
  }
}