import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class ProductivityProvider extends ChangeNotifier {
  String _selectedDailyCallType = "Normal Calls";
  int _selectedMonth = DateTime.now().month;

  // Daily state
  Map<String, dynamic>? dailySummary;
  List<dynamic> dailyCallsData = [];
  bool isDailyLoading = false;

  // Monthly state
  Map<String, dynamic>? monthlySummary;
  List<dynamic> monthlyCallsData = [];
  bool isMonthlyLoading = false;

  int get selectedMonth => _selectedMonth;
  String get selectedDailyCallType => _selectedDailyCallType;

  // Backward compatibility getters
  Map<String, dynamic>? get callsSummary => monthlySummary ?? dailySummary;
  List<dynamic> get callsData => monthlyCallsData.isNotEmpty ? monthlyCallsData : dailyCallsData;
  bool get isLoading => isDailyLoading || isMonthlyLoading;

  void setDailyCallType(String type) {
    _selectedDailyCallType = type;
    notifyListeners();
  }

  void changeMonth(int month) {
    _selectedMonth = month;
    fetchMonthlyCalls();
  }

  Future<void> fetchDailyCalls({String? date}) async {
    isDailyLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final queryDate = date ??
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final res = await ApiServices.getCallsInfo(
      date: queryDate,
    );

    if (res != null) {
      dailySummary = res["summary"];
      final data = res["data"];
      if (data is List) {
        dailyCallsData = data;
      } else {
        dailyCallsData = [];
      }
    } else {
      dailySummary = null;
      dailyCallsData = [];
    }

    isDailyLoading = false;
    notifyListeners();
  }

  Future<void> fetchMonthlyCalls({String? month}) async {
    isMonthlyLoading = true;
    notifyListeners();

    final queryMonth = month ??
        "${_selectedMonth.toString().padLeft(2, '0')}-${DateTime.now().year}";

    final res = await ApiServices.getCallsInfo(
      month: queryMonth,
    );

    if (res != null) {
      monthlySummary = res["summary"];
      final data = res["data"];
      if (data is List) {
        monthlyCallsData = data;
      } else {
        monthlyCallsData = [];
      }
    } else {
      monthlySummary = null;
      monthlyCallsData = [];
    }

    isMonthlyLoading = false;
    notifyListeners();
  }

  // Keep fetchCallsInfo for backward compatibility
  Future<void> fetchCallsInfo({String? date, String? month}) async {
    if (month != null) {
      await fetchMonthlyCalls(month: month);
    } else {
      await fetchDailyCalls(date: date);
    }
  }

  List<Map<String, String>> get dailyData {
    return dailyCallsData.map<Map<String, String>>((item) {
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
    return monthlyCallsData.map<Map<String, dynamic>>((item) {
      return {
        "date": item["call_date"] ?? "-",
        "outletName": item["outlet_name"]?.toString() ?? "-",
        "attendance": true, // Assuming attendance if there's call data
        "sale": item["sale_value"]?.toString() ?? "0",
        "productiveCalls": item["productive_call"]?.toString() ?? "0",
        "totalCalls": item["target_call"]?.toString() ?? "0",
      };
    }).toList();
  }
}
