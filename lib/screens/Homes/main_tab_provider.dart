import 'package:flutter/material.dart';

class MainTabProvider extends ChangeNotifier {
  int currentIndex = 0;
  int _nearMeRefreshTick = 0;

  int get nearMeRefreshTick => _nearMeRefreshTick;

  void setTab(int index) {
    if (index == 2) {
      _nearMeRefreshTick++;
    }
    currentIndex = index;
    notifyListeners();
  }

  void triggerNearMeRefresh() {
    _nearMeRefreshTick++;
    notifyListeners();
  }
}