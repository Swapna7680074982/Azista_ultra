import 'package:flutter/material.dart';

class ProductivityProvider extends ChangeNotifier {
  String _selectedDailyCallType = "Normal Calls";

  String get selectedDailyCallType => _selectedDailyCallType;

  void setDailyCallType(String type) {
    _selectedDailyCallType = type;
    notifyListeners();
  }

  final List<Map<String, String>> _dailyData = [
    {
      "outletName": "test 89",
      "ownerName": "test89",
      "phoneNumber": "8454546464",
    },
    {
      "outletName": "Test 090724",
      "ownerName": "Priyanka",
      "phoneNumber": "8919495304",
    },
  ];

  List<Map<String, String>> get dailyData => _dailyData;

  final List<Map<String, dynamic>> _monthlyData = [
    {
      "date": "Nov 03, 2024",
      "attendance": false,
      "sale": "0",
      "productiveCalls": "0",
      "totalCalls": "0",
    },
    {
      "date": "Nov 04, 2024",
      "attendance": false,
      "sale": "0",
      "productiveCalls": "0",
      "totalCalls": "0",
    },
    {
      "date": "Nov 05, 2024",
      "attendance": false,
      "sale": "0",
      "productiveCalls": "0",
      "totalCalls": "0",
    },
    {
      "date": "Nov 06, 2024",
      "attendance": false,
      "sale": "1340",
      "productiveCalls": "1",
      "totalCalls": "2",
    },
  ];

  List<Map<String, dynamic>> get monthlyData => _monthlyData;
}
