import 'package:flutter/material.dart';

class MainTabProvider extends ChangeNotifier {
  int currentIndex = 0;

  void setTab(int index) {
    currentIndex = index;
    notifyListeners();
  }
}