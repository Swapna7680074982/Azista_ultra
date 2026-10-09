import 'package:flutter/material.dart';

class MainTabProvider extends ChangeNotifier {
  int currentIndex = 0;
  int _visitsRefreshTick = 0;

  int get visitsRefreshTick => _visitsRefreshTick;
  int get nearMeRefreshTick => _visitsRefreshTick;

  void setTab(int index) {
    if (index == 2) {
      _visitsRefreshTick++;
    }
    currentIndex = index;
    notifyListeners();
  }

  void triggerVisitsRefresh() {
    _visitsRefreshTick++;
    notifyListeners();
  }

  void triggerNearMeRefresh() {
    _visitsRefreshTick++;
    notifyListeners();
  }
}