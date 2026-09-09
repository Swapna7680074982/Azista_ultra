import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
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

    if (!context.mounted) return false;

    final photoFile = File(picked.path);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      "Confirm Photo",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    photoFile,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Do you want to submit your attendance with this photo?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.button,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      message = "Check-in cancelled";
      notifyListeners();
      return false;
    }

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

    try {
      final res = await ApiServices.getTodayAttendance();

      if (res != null && res["data"] != null) {
        final data = res["data"];

        if (data is List) {
          if (data.isNotEmpty) {
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
        }
      }
    } catch (_) {
      // Keep existing data on error
    } finally {
      isAttendanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyCallSummary() async {
    isSummaryLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final res = await ApiServices.getCallsInfo(date: dateStr);

      if (res != null) {
        if (res["summary"] is Map) {
          dailyCallSummary = Map<String, dynamic>.from(res["summary"]);
        } else if (res.containsKey("target_calls") || res.containsKey("productive_calls")) {
          dailyCallSummary = {
            "target_calls": double.tryParse(res["target_calls"]?.toString() ?? "0") ?? 0,
            "productive_calls": double.tryParse(res["productive_calls"]?.toString() ?? "0") ?? 0,
          };
        } else if (res["data"] is List) {
          final dataList = res["data"] as List<dynamic>;
          double targetCalls = 0;
          double productiveCalls = 0;
          for (var item in dataList) {
            targetCalls += double.tryParse(item["target_call"]?.toString() ?? item["target_calls"]?.toString() ?? "0") ?? 0;
            productiveCalls += double.tryParse(item["productive_call"]?.toString() ?? item["productive_calls"]?.toString() ?? "0") ?? 0;
          }
          dailyCallSummary = {
            "target_calls": targetCalls,
            "productive_calls": productiveCalls,
          };
        } else if (res["data"] is Map) {
          final dataMap = res["data"] as Map<String, dynamic>;
          if (dataMap["summary"] is Map) {
            dailyCallSummary = Map<String, dynamic>.from(dataMap["summary"]);
          } else {
            dailyCallSummary = {
              "target_calls": double.tryParse(dataMap["target_calls"]?.toString() ?? dataMap["target_call"]?.toString() ?? "0") ?? 0,
              "productive_calls": double.tryParse(dataMap["productive_calls"]?.toString() ?? dataMap["productive_call"]?.toString() ?? "0") ?? 0,
            };
          }
        } else if (dailyCallSummary == null) {
          dailyCallSummary = {
            "target_calls": 0,
            "productive_calls": 0,
          };
        }
      } else if (dailyCallSummary == null) {
        dailyCallSummary = {
          "target_calls": 0,
          "productive_calls": 0,
        };
      }
    } catch (e) {
      if (dailyCallSummary == null) {
        dailyCallSummary = {
          "target_calls": 0,
          "productive_calls": 0,
        };
      }
    } finally {
      isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyCallSummary() async {
    isMonthlySummaryLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final monthStr = "${now.month.toString().padLeft(2, '0')}-${now.year}";

      final res = await ApiServices.getCallsInfo(month: monthStr);

      if (res != null) {
        if (res["summary"] is Map) {
          monthlyCallSummary = Map<String, dynamic>.from(res["summary"]);
        } else if (res.containsKey("target_calls") || res.containsKey("productive_calls")) {
          monthlyCallSummary = {
            "target_calls": double.tryParse(res["target_calls"]?.toString() ?? "0") ?? 0,
            "productive_calls": double.tryParse(res["productive_calls"]?.toString() ?? "0") ?? 0,
          };
        } else if (res["data"] is List) {
          final dataList = res["data"] as List<dynamic>;
          double targetCalls = 0;
          double productiveCalls = 0;
          for (var item in dataList) {
            targetCalls += double.tryParse(item["target_call"]?.toString() ?? item["target_calls"]?.toString() ?? "0") ?? 0;
            productiveCalls += double.tryParse(item["productive_call"]?.toString() ?? item["productive_calls"]?.toString() ?? "0") ?? 0;
          }
          monthlyCallSummary = {
            "target_calls": targetCalls,
            "productive_calls": productiveCalls,
          };
        } else if (res["data"] is Map) {
          final dataMap = res["data"] as Map<String, dynamic>;
          if (dataMap["summary"] is Map) {
            monthlyCallSummary = Map<String, dynamic>.from(dataMap["summary"]);
          } else {
            monthlyCallSummary = {
              "target_calls": double.tryParse(dataMap["target_calls"]?.toString() ?? dataMap["target_call"]?.toString() ?? "0") ?? 0,
              "productive_calls": double.tryParse(dataMap["productive_calls"]?.toString() ?? dataMap["productive_call"]?.toString() ?? "0") ?? 0,
            };
          }
        } else if (monthlyCallSummary == null) {
          monthlyCallSummary = {
            "target_calls": 0,
            "productive_calls": 0,
          };
        }
      } else if (monthlyCallSummary == null) {
        monthlyCallSummary = {
          "target_calls": 0,
          "productive_calls": 0,
        };
      }
    } catch (e) {
      if (monthlyCallSummary == null) {
        monthlyCallSummary = {
          "target_calls": 0,
          "productive_calls": 0,
        };
      }
    } finally {
      isMonthlySummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardCounts() async {
    isCountsLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> payload = {};
      if (selectedCountsFilter == "today") {
        payload = {"today": 1};
      } else if (selectedCountsFilter == "custom" && customCountsRange != null) {
        payload = {
          "from_date": "${customCountsRange!.start.year}-${customCountsRange!.start.month.toString().padLeft(2, '0')}-${customCountsRange!.start.day.toString().padLeft(2, '0')}",
          "to_date": "${customCountsRange!.end.year}-${customCountsRange!.end.month.toString().padLeft(2, '0')}-${customCountsRange!.end.day.toString().padLeft(2, '0')}",
        };
      } else {
        // month wise default
        final now = DateTime.now();
        payload = {
          "month": now.month,
          "year": now.year,
        };
      }

      final res = await ApiServices.getDashboardCounts(payload: payload);
      if (res != null && (res["status"] == true || res["status_code"] == 200 || res["data"] != null)) {
        if (res["data"] is Map) {
          dashboardCounts = Map<String, dynamic>.from(res["data"]);
        } else if (res["counts"] is Map) {
          dashboardCounts = Map<String, dynamic>.from(res["counts"]);
        } else if (dashboardCounts == null) {
          dashboardCounts = {
            "new_outlets": 0,
            "outlet_visits": 0,
            "pobs_done": 0,
            "pob_sale_value": 0.0,
          };
        }
      } else if (dashboardCounts == null) {
        dashboardCounts = {
          "new_outlets": 0,
          "outlet_visits": 0,
          "pobs_done": 0,
          "pob_sale_value": 0.0,
        };
      }
    } catch (e) {
      if (dashboardCounts == null) {
        dashboardCounts = {
          "new_outlets": 0,
          "outlet_visits": 0,
          "pobs_done": 0,
          "pob_sale_value": 0.0,
        };
      }
    } finally {
      isCountsLoading = false;
      notifyListeners();
    }
  }

  void setCountsFilter(String filter, {DateTimeRange? range}) {
    selectedCountsFilter = filter;
    if (range != null) {
      customCountsRange = range;
    }
    notifyListeners();
    fetchDashboardCounts();
  }

  Future<void> fetchTargets() async {
    isTargetsLoading = true;
    notifyListeners();
    try {
      final res = await ApiServices.getTargets();
      if (res != null && res["status"] == true) {
        targetsData = res["data"];
      }
    } catch (e) {
      // Keep existing targetsData
    } finally {
      isTargetsLoading = false;
      notifyListeners();
    }
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
