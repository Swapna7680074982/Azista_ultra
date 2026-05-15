import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../../permissions/AppStateProvider.dart';
import '../../permissions/SessionManager.dart';
import '../../services/api_services.dart';

class HomeProvider extends ChangeNotifier {
  List distributors = [];
  String? selectedDistributor;
  Map<String, dynamic>? todayAttendance;
  bool isAttendanceLoading = false;
  bool isLoading = false;
  String? message;
  Map<String, dynamic>? dailyCallSummary;
  bool isSummaryLoading = false;
  StreamSubscription? _autoCheckoutSubscription;

  Future<void> loadDistributors() async {
    distributors = await SessionManager.getDistributors();
    notifyListeners();
  }

  Future<void> initializeAttendance(AppStateProvider appState) async {
    final status = await SessionManager.getAttendanceStatus();

    if (status == "CHECKED_IN") {
      appState.setOnline(true);
      await checkAutoCheckout(appState);
    } else {
      appState.setOnline(false);
    }

    // Start a timer to check for auto-checkout every 15 minutes
    _startAutoCheckoutTimer(appState);
  }

  void _startAutoCheckoutTimer(AppStateProvider appState) {
    _autoCheckoutSubscription?.cancel();
    _autoCheckoutSubscription = Stream.periodic(const Duration(minutes: 15)).listen((_) {
      checkAutoCheckout(appState);
    });
  }

  Future<void> checkAutoCheckout(AppStateProvider appState) async {
    final status = await SessionManager.getAttendanceStatus();
    if (status != "CHECKED_IN") return;

    final checkInTime = await SessionManager.getCheckInTime();
    if (checkInTime == null) return;

    final now = DateTime.now();

    // Condition 1: Midnight check (Current day is different from check-in day)
    final isMidnightPassed = now.year != checkInTime.year ||
        now.month != checkInTime.month ||
        now.day != checkInTime.day;

    // Condition 2: 12 hours check
    final duration = now.difference(checkInTime);
    final is12HoursPassed = duration.inHours >= 12;

    if (isMidnightPassed || is12HoursPassed) {
      debugPrint("Auto-checkout triggered: Midnight=$isMidnightPassed, 12h=$is12HoursPassed");
      final success = await checkOut();
      if (success) {
        appState.setOnline(false);
        message = "Auto checked out (12h or Midnight)";
        notifyListeners();
      }
    }
  }

  Future<bool> checkIn() async {
    isLoading = true;
    notifyListeners();

    final res = await ApiServices.markAttendance(type: "IN");

    isLoading = false;
    notifyListeners();

    if (res != null && res["status"] == true) {
      message = res["message"];
      await SessionManager.saveAttendanceStatus("CHECKED_IN");
      return true;
    }

    message = res?["message"] ?? "Check-in failed";
    return false;
  }

  Future<bool> checkOut() async {
    isLoading = true;
    notifyListeners();

    final res = await ApiServices.markAttendance(type: "OUT");



    isLoading = false;
    notifyListeners();


    if (res != null && res["status"] == true) {
      message = res["message"];
      await SessionManager.saveAttendanceStatus("CHECKED_OUT");
      return true;
    }

    message = res?["message"] ?? "Check-out failed";
    return false;
  }

  Future<void> fetchTodayAttendance() async {
    isAttendanceLoading = true;
    notifyListeners();

    final res = await ApiServices.getTodayAttendance();

    if (res != null && res["data"] != null) {
      final data = res["data"];

      if (data is List) {

        if (data.isEmpty) {
          todayAttendance = null;
        } else {
          todayAttendance = data.first as Map<String, dynamic>;
        }
      } else if (data is Map<String, dynamic>) {
        todayAttendance = data;
      } else {
        todayAttendance = null;
      }
    } else {
      todayAttendance = null;
    }

    isAttendanceLoading = false;
    notifyListeners();
  }

  Future<void> fetchDailyCallSummary(int? distributorId) async {
    isSummaryLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final res = await ApiServices.getDailyCallSummary(
      date: dateStr,
      distributorId: distributorId,
    );

    if (res != null && res["data"] != null) {
      dailyCallSummary = res["data"];
    } else {
      dailyCallSummary = null;
    }

    isSummaryLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoCheckoutSubscription?.cancel();
    super.dispose();
  }
}
