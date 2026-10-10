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
      if (norm == 'ASM' || norm == 'AM' || norm.contains('AREA')) {
        userRole = 'ASM';
      } else if (norm == 'RSM' || norm == 'RM' || norm.contains('REGION')) {
        userRole = 'RSM';
      } else if (norm == 'SO' ||
          norm == 'FSE' ||
          norm.contains('SALE') ||
          norm.contains('FIELD') ||
          norm.contains('EXECUTIVE')) {
        userRole = 'FSE';
      } else {
        userRole = norm;
      }
    } else {
      userRole = null;
    }
    notifyListeners();
  }

  bool get isManager => userRole == 'RSM' || userRole == 'RM' || userRole == 'ASM' || userRole == 'AM' || userRole == 'ADMIN';
  bool get isRM => userRole == 'RSM' || userRole == 'RM';
  bool get isAM => userRole == 'ASM' || userRole == 'AM';

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