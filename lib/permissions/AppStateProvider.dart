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
    if (role != null) {
      final norm = role.trim().toUpperCase();
      if (norm == 'ASM' || norm == 'AM') {
        userRole = 'AM';
      } else if (norm == 'RM') {
        userRole = 'RM';
      } else if (norm == 'SO' || norm.contains('SALE OFF') || norm.contains('SALES OFF') || norm.contains('SALE OFFICER') || norm.contains('SALES OFFICER')) {
        userRole = 'SO';
      } else {
        userRole = norm;
      }
    } else {
      userRole = null;
    }
    notifyListeners();
  }

  void setDistributor(String? distributor, {int? id}) {
    selectedDistributor = distributor;
    selectedDistributorId = id;
    notifyListeners();
  }

  void setSelectedDistributor(String? distributor, [int? id]) {
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