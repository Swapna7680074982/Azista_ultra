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
  Map<String, dynamic>? monthlyCallSummary;
  bool isMonthlySummaryLoading = false;
  StreamSubscription? _autoCheckoutSubscription;
  DateTime? localCheckInTime;

  Future<void> loadDistributors([AppStateProvider? appState]) async {
    distributors = await SessionManager.getDistributors();
    // Do not auto-select the first distributor
    /*
    if (appState != null && distributors.isNotEmpty && appState.selectedDistributor == null) {
      final defaultDistributor = distributors.first;
      final name = defaultDistributor["distributor_name"];
      int? id;
      if (defaultDistributor["distributor_id"] is int) {
        id = defaultDistributor["distributor_id"];
      } else if (defaultDistributor["distributor_id"] != null) {
        id = int.tryParse(defaultDistributor["distributor_id"].toString());
      }
      appState.setDistributor(name, id: id);
    }
    */
    notifyListeners();
  }

  Future<void> initializeAttendance(AppStateProvider appState) async {
    try {
      localCheckInTime = await SessionManager.getCheckInTime();
      notifyListeners();

      final res = await ApiServices.getAttendanceStatus();
      if (res != null && res["status"] == true && res["data"] != null) {
        final todayStatus = res["data"]["attendance_status"]?["today_status"]?.toString();
        if (todayStatus == "CHECKED_IN") {
          appState.setOnline(true);
          await SessionManager.saveAttendanceStatus("CHECKED_IN");
          localCheckInTime = await SessionManager.getCheckInTime();
          notifyListeners();
          await checkAutoCheckout(appState);
        } else {
          appState.setOnline(false);
          await SessionManager.saveAttendanceStatus("CHECKED_OUT");
          localCheckInTime = null;
          notifyListeners();
        }
      } else {
        // Fallback to local session
        final status = await SessionManager.getAttendanceStatus();
        if (status == "CHECKED_IN") {
          appState.setOnline(true);
          localCheckInTime = await SessionManager.getCheckInTime();
          notifyListeners();
          await checkAutoCheckout(appState);
        } else {
          appState.setOnline(false);
          localCheckInTime = null;
          notifyListeners();
        }
      }
    } catch (e) {
      final status = await SessionManager.getAttendanceStatus();
      if (status == "CHECKED_IN") {
        appState.setOnline(true);
        localCheckInTime = await SessionManager.getCheckInTime();
        notifyListeners();
      } else {
        appState.setOnline(false);
        localCheckInTime = null;
        notifyListeners();
      }
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
      localCheckInTime = await SessionManager.getCheckInTime();
      notifyListeners();
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
      localCheckInTime = null;
      notifyListeners();
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

  Future<void> fetchMonthlyCallSummary(int? distributorId) async {
    isMonthlySummaryLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final monthStr = "${now.month.toString().padLeft(2, '0')}-${now.year}";

    final res = await ApiServices.getCallsInfo(
      month: monthStr,
      distributorId: distributorId,
    );

    if (res != null && res["data"] != null) {
      final dataList = res["data"] as List<dynamic>? ?? [];
      double targetCalls = 0;
      double productiveCalls = 0;
      for (var item in dataList) {
        targetCalls += double.tryParse(item["target_call"]?.toString() ?? "0") ?? 0;
        productiveCalls += double.tryParse(item["productive_call"]?.toString() ?? "0") ?? 0;
      }
      monthlyCallSummary = {
        "target_calls": targetCalls,
        "productive_calls": productiveCalls,
      };
    } else {
      monthlyCallSummary = null;
    }

    isMonthlySummaryLoading = false;
    notifyListeners();
  }

  void reset() {
    distributors = [];
    selectedDistributor = null;
    todayAttendance = null;
    localCheckInTime = null;
    isLoading = false;
    message = null;
    dailyCallSummary = null;
    isSummaryLoading = false;
    monthlyCallSummary = null;
    isMonthlySummaryLoading = false;
    _autoCheckoutSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoCheckoutSubscription?.cancel();
    super.dispose();
  }
}
