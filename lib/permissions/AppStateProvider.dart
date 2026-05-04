import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  bool isOnline = false;
  String? selectedDistributor;
  int? selectedDistributorId;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setDistributor(String? distributor, {int? id}) {
    selectedDistributor = distributor;
    selectedDistributorId = id;
    notifyListeners();
  }
}