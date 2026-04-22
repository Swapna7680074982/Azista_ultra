import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  bool isOnline = false;
  String? selectedDistributor;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setDistributor(String? distributor) {
    selectedDistributor = distributor;
    notifyListeners();
  }
}