import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  Map<String, dynamic>? dashboardCounts;
  bool isCountsLoading = false;
  String selectedCountsFilter = "month"; // 'today', 'month', 'custom'
  Map<String, dynamic>? targetsData;
  bool isTargetsLoading = false;
  DateTimeRange? customCountsRange;

  Future<void> loadDistributors([AppStateProvider? appState]) async {
    distributors = await SessionManager.getDistributors();
    if (distributors.isEmpty) {
      final res = await ApiServices.getDistributors();
      if (res != null && res["data"] is List) {
        distributors = res["data"];
      }
    }
    notifyListeners();
  }

  Future<void> initializeAttendance(AppStateProvider appState) async {
    try {
      localCheckInTime = await SessionManager.getCheckInTime();
      notifyListeners();

      final res = await ApiServices.getAttendanceStatus();
      if (res != null && res["status"] == true && res["data"] != null) {
        final todayStatus = res["data"]["attendance_status"]?["today_status"]?.toString();
        final lastSession = res["data"]["attendance_status"]?["last_session"];
        final hasNoCheckOut = lastSession == null ||
            lastSession["check_out"] == null ||
            lastSession["check_out"].toString().trim().isEmpty;
        final bool isCurrentlyCheckedIn = todayStatus == "CHECKED_IN" && hasNoCheckOut;

        if (isCurrentlyCheckedIn && lastSession != null) {
          final attId = lastSession["attendance_id"]?.toString();
          if (attId != null && attId.isNotEmpty) {
            await SessionManager.saveAttendanceId(attId);
          }
          appState.setOnline(true);
          await SessionManager.saveAttendanceStatus("CHECKED_IN");
          localCheckInTime = await SessionManager.getCheckInTime();
          notifyListeners();
          await checkAutoCheckout(appState);
        } else {
          appState.setOnline(false);
          await SessionManager.saveAttendanceStatus("CHECKED_OUT");
          await SessionManager.saveAttendanceId(null);
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
          await SessionManager.saveAttendanceId(null);
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
        await SessionManager.saveAttendanceId(null);
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

  Future<Map<String, dynamic>> checkIn({File? photo}) async {
    isLoading = true;
    notifyListeners();

    final res = await ApiServices.markAttendance(type: "IN", photo: photo);

    isLoading = false;
    notifyListeners();

    if (res != null && res["status"] == true) {
      message = res["message"] ?? "Check-in successful";
      String? attId = res["attendance_id"]?.toString() ??
          res["data"]?["attendance_id"]?.toString() ??
          res["data"]?["attendance_status"]?["last_session"]?["attendance_id"]?.toString();

      if (attId == null || attId.isEmpty) {
        try {
          final statusRes = await ApiServices.getAttendanceStatus();
          attId = statusRes?["data"]?["attendance_status"]?["last_session"]?["attendance_id"]?.toString();
        } catch (_) {}
      }

      if (attId != null && attId.isNotEmpty) {
        await SessionManager.saveAttendanceId(attId);
      }
      await SessionManager.saveAttendanceStatus("CHECKED_IN");
      localCheckInTime = await SessionManager.getCheckInTime();
      notifyListeners();
      return {"success": true, "message": message};
    }

    // If check-in failed, check if the server already has an active check-in
    try {
      final statusRes = await ApiServices.getAttendanceStatus();
      final todayStatus = statusRes?["data"]?["attendance_status"]?["today_status"]?.toString();
      final lastSession = statusRes?["data"]?["attendance_status"]?["last_session"];
      final hasNoCheckOut = lastSession == null ||
          lastSession["check_out"] == null ||
          lastSession["check_out"].toString().trim().isEmpty;
      if (todayStatus == "CHECKED_IN" && hasNoCheckOut) {
        final attId = lastSession?["attendance_id"]?.toString();
        if (attId != null && attId.isNotEmpty) {
          await SessionManager.saveAttendanceId(attId);
        }
        await SessionManager.saveAttendanceStatus("CHECKED_IN");
        localCheckInTime = await SessionManager.getCheckInTime();
        message = "Checked in successfully";
        notifyListeners();
        return {"success": true, "message": message};
      }
    } catch (_) {}

    final isPhotoRequired = res != null &&
        (res["photo_required"] == true ||
         res["message"]?.toString().toLowerCase().contains("photo") == true ||
         res["message"]?.toString().toLowerCase().contains("check-in failed") == true ||
         res["status_code"] == 500);

    message = res?["message"] ?? "Check-in failed";
    notifyListeners();
    return {
      "success": false,
      "photo_required": isPhotoRequired,
      "message": message,
    };
  }

  Future<bool> handleCheckInWithPhotoIfNeeded(BuildContext context) async {
    final hasNoSessionsToday = todayAttendance == null ||
        todayAttendance?["sessions"] == null ||
        (todayAttendance?["sessions"] is List && (todayAttendance!["sessions"] as List).isEmpty);

    if (hasNoSessionsToday) {
      return await _capturePhotoAndCheckIn(context);
    }

    final res = await checkIn();
    if (res["success"] == true) {
      return true;
    }

    if (res["photo_required"] == true) {
      if (!context.mounted) return false;
      return await _capturePhotoAndCheckIn(context);
    }

    return false;
  }

  Future<bool> _capturePhotoAndCheckIn(BuildContext context) async {
    if (!context.mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Opening camera: Photo required for check-in"),
        duration: Duration(seconds: 2),
      ),
    );

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (picked == null) {
      message = "Check-in cancelled: Photo is required";
      notifyListeners();
      return false;
    }

    final photoFile = File(picked.path);
    final photoRes = await checkIn(photo: photoFile);
    return photoRes["success"] == true;
  }

  Future<bool> checkOut() async {
    isLoading = true;
    notifyListeners();

    final res = await ApiServices.markAttendance(type: "OUT");

    isLoading = false;
    notifyListeners();

    final isAlreadyCheckedOut = res != null &&
        (res["message"]?.toString().toLowerCase().contains("no active check-in") == true ||
         res["message"]?.toString().toLowerCase().contains("already checked out") == true);

    if (res != null && (res["status"] == true || isAlreadyCheckedOut)) {
      message = res["status"] == true
          ? (res["message"] ?? "Checked out successfully")
          : "Already checked out";
      await SessionManager.saveAttendanceStatus("CHECKED_OUT");
      await SessionManager.saveAttendanceId(null);
      localCheckInTime = null;
      notifyListeners();
      return true;
    }

    // If check-out failed, verify if user is already checked out on server
    try {
      final statusRes = await ApiServices.getAttendanceStatus();
      final todayStatus = statusRes?["data"]?["attendance_status"]?["today_status"]?.toString();
      if (todayStatus == "CHECKED_OUT" || todayStatus == "NOT_CHECKED_IN") {
        await SessionManager.saveAttendanceStatus("CHECKED_OUT");
        await SessionManager.saveAttendanceId(null);
        localCheckInTime = null;
        message = "Checked out successfully";
        notifyListeners();
        return true;
      }
    } catch (_) {}

    message = res?["message"] ?? "Check-out failed";
    notifyListeners();
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
        final sessions = data["sessions"] as List<dynamic>?;
        if (sessions != null && sessions.isNotEmpty) {
          final last = sessions.last;
          final hasNoCheckOut = last is Map &&
              (last["check_out"] == null || last["check_out"].toString().trim().isEmpty);
          if (last is Map && last["attendance_id"] != null && hasNoCheckOut) {
            await SessionManager.saveAttendanceId(last["attendance_id"].toString());
          } else {
            await SessionManager.saveAttendanceId(null);
          }
        }
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

    final res = await ApiServices.getCallsInfo(
      date: dateStr,
      distributorId: distributorId,
    );

    print("fetchDailyCallSummary Response: $res");

    if (res != null) {
      if (res["summary"] != null) {
        dailyCallSummary = res["summary"];
      } else if (res["data"] is List) {
        final dataList = res["data"] as List<dynamic>;
        double targetCalls = 0;
        double productiveCalls = 0;
        for (var item in dataList) {
          targetCalls += double.tryParse(item["target_call"]?.toString() ?? "0") ?? 0;
          productiveCalls += double.tryParse(item["productive_call"]?.toString() ?? "0") ?? 0;
        }
        dailyCallSummary = {
          "target_calls": targetCalls,
          "productive_calls": productiveCalls,
        };
      } else {
        dailyCallSummary = null;
      }
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

    print("fetchMonthlyCallSummary Response: $res");

    if (res != null) {
      if (res["summary"] != null) {
        monthlyCallSummary = res["summary"];
      } else if (res["data"] is List) {
        final dataList = res["data"] as List<dynamic>;
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
    } else {
      monthlyCallSummary = null;
    }

    isMonthlySummaryLoading = false;
    notifyListeners();
  }

  Future<void> fetchDashboardCounts({int? distributorId}) async {
    isCountsLoading = true;
    notifyListeners();

    final userInfo = await SessionManager.getUserInfo();
    final userIdStr = userInfo?["user_id"]?.toString();

    int month = DateTime.now().month;
    int year = DateTime.now().year;

    if (selectedCountsFilter == "custom" && customCountsRange != null) {
      month = customCountsRange!.start.month;
      year = customCountsRange!.start.year;
    }

    try {
      final res = await ApiServices.getTeamMembersSummary(
        month: month,
        year: year,
      );
      if (res != null && res["status"] == true) {
        final List members = res["data"] ?? [];
        var memberData = members.firstWhere(
          (m) => m["user_id"]?.toString() == userIdStr,
          orElse: () => null,
        );
        if (memberData == null && members.length == 1) {
          memberData = members.first;
        }

        if (memberData != null) {
          dashboardCounts = {
            "new_outlets": memberData["new_outlets"],
            "outlet_visits": memberData["total_visits"],
            "pobs_done": memberData["total_pobs"],
            "pob_sale_value": memberData["pob_sale_value"],
          };
        } else {
          dashboardCounts = null;
        }
      } else {
        dashboardCounts = null;
      }
    } catch (e) {
      dashboardCounts = null;
    }

    isCountsLoading = false;
    notifyListeners();
  }

  void setCountsFilter(String filter, {DateTimeRange? range, int? distributorId}) {
    selectedCountsFilter = filter;
    if (range != null) {
      customCountsRange = range;
    }
    notifyListeners();
    fetchDashboardCounts(distributorId: distributorId);
  }

  Future<void> fetchTargets() async {
    isTargetsLoading = true;
    notifyListeners();
    try {
      final res = await ApiServices.getTargets();
      if (res != null && res["status"] == true) {
        targetsData = res["data"];
      } else {
        targetsData = null;
      }
    } catch (e) {
      targetsData = null;
    }
    isTargetsLoading = false;
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
    dashboardCounts = null;
    isCountsLoading = false;
    selectedCountsFilter = "month";
    customCountsRange = null;
    targetsData = null;
    isTargetsLoading = false;
    _autoCheckoutSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoCheckoutSubscription?.cancel();
    super.dispose();
  }
}
