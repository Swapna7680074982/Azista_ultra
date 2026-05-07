import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class ProductivityProvider extends ChangeNotifier {
  String _selectedDailyCallType = "Normal Calls";
  Map<String, dynamic>? callsSummary;
  List<dynamic> callsData = [];
  bool isLoading = false;

  String get selectedDailyCallType => _selectedDailyCallType;

  void setDailyCallType(String type) {
    _selectedDailyCallType = type;
    notifyListeners();
  }

  Future<void> fetchCallsInfo({String? date, String? month, int? distributorId}) async {
    isLoading = true;
    notifyListeners();

    final res = await ApiServices.getCallsInfo(
      date: date,
      month: month,
      distributorId: distributorId,
    );

    if (res != null) {
      callsSummary = res["summary"];
      callsData = res["data"] ?? [];
    } else {
      callsSummary = null;
      callsData = [];
    }

    isLoading = false;
    notifyListeners();
  }

  List<Map<String, String>> get dailyData {
    return callsData.map<Map<String, String>>((item) {
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
    return callsData.map<Map<String, dynamic>>((item) {
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
