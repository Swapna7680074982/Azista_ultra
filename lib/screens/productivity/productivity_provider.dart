import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class ProductivityProvider extends ChangeNotifier {
  String _selectedDailyCallType = "Normal Calls";

  // Daily state
  Map<String, dynamic>? dailyCallsSummary;
  List<dynamic> dailyCallsData = [];
  bool isDailyLoading = false;

  // Monthly state
  Map<String, dynamic>? monthlyCallsSummary;
  List<dynamic> monthlyCallsData = [];
  bool isMonthlyLoading = false;

  // General state for backward compatibility
  Map<String, dynamic>? callsSummary;
  List<dynamic> callsData = [];
  bool isLoading = false;

  String get selectedDailyCallType => _selectedDailyCallType;

  void setDailyCallType(String type) {
    _selectedDailyCallType = type;
    notifyListeners();
  }

  Future<void> fetchCallsInfo({String? date, String? month, int? distributorId}) async {
    if (date != null) isDailyLoading = true;
    if (month != null) isMonthlyLoading = true;
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiServices.getCallsInfo(
        date: date,
        month: month,
        distributorId: distributorId,
      );

      if (res != null) {
        if (date != null) {
          dailyCallsSummary = res["summary"];
          dailyCallsData = res["data"] ?? [];
        }
        if (month != null) {
          monthlyCallsSummary = res["summary"];
          monthlyCallsData = res["data"] ?? [];
        }
        callsSummary = res["summary"];
        callsData = res["data"] ?? [];
      } else {
        if (date != null) {
          dailyCallsSummary = null;
          dailyCallsData = [];
        }
        if (month != null) {
          monthlyCallsSummary = null;
          monthlyCallsData = [];
        }
        callsSummary = null;
        callsData = [];
      }
    } catch (e) {
      if (date != null) {
        dailyCallsSummary = null;
        dailyCallsData = [];
      }
      if (month != null) {
        monthlyCallsSummary = null;
        monthlyCallsData = [];
      }
      callsSummary = null;
      callsData = [];
    } finally {
      if (date != null) isDailyLoading = false;
      if (month != null) isMonthlyLoading = false;
      isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, String>> get dailyData {
    final list = dailyCallsData.isNotEmpty ? dailyCallsData : callsData;
    return list.map<Map<String, String>>((item) {
      return {
        "outletName": item["outlet_name"]?.toString() ?? "-",
        "ownerName": "N/A", // API doesn't provide owner name
        "phoneNumber": "N/A", // API doesn't provide phone number
        "targetCall": item["target_call"]?.toString() ?? "0",
        "productiveCall": item["productive_call"]?.toString() ?? "0",
        "saleValue": item["sale_value"]?.toString() ?? "0",
      };
    }).toList();
  }

  List<Map<String, dynamic>> get monthlyData {
    final list = monthlyCallsData.isNotEmpty ? monthlyCallsData : callsData;
    return list.map<Map<String, dynamic>>((item) {
      final attRaw = item["attendance"] ?? item["is_present"] ?? item["attendance_status"];
      bool isAtt = true;
      if (attRaw != null) {
        if (attRaw is bool) {
          isAtt = attRaw;
        } else if (attRaw == 0 || attRaw == "0" || attRaw == "false") {
          isAtt = false;
        }
      }
      return {
        "date": item["call_date"] ?? "-",
        "outletName": item["outlet_name"]?.toString() ?? "-",
        "attendance": isAtt,
        "sale": item["sale_value"]?.toString() ?? "0",
        "productiveCalls": item["productive_call"]?.toString() ?? "0",
        "totalCalls": item["target_call"]?.toString() ?? "0",
      };
    }).toList();
  }
}
