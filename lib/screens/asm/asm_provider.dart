import 'package:flutter/material.dart';

class AmProvider extends ChangeNotifier {
  DateTime _fromDate = DateTime(2026, 4, 1);
  DateTime _toDate = DateTime(2026, 4, 23);
  String _searchQuery = "";
  bool _isLoading = false;

  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // SO List
  final List<Map<String, dynamic>> _allSoList = [
    {
      "id": "30794",
      "name": "Srawan Kumar N",
      "role": "SALEOFF",
      "logs": [
        {"date": "Apr 01, 2026", "in": "04:33:50", "out": "18:25:04", "status": "PRESENT", "netHours": "08:00"},
        {"date": "Apr 02, 2026", "in": "04:46:04", "out": "18:25:04", "status": "PRESENT", "netHours": "08:00"},
        {"date": "Apr 03, 2026", "in": "00:00:00", "out": "00:00:00", "status": "ABSENT", "netHours": "00:00"},
        {"date": "Apr 04, 2026", "in": "05:07:36", "out": "18:25:04", "status": "PRESENT", "netHours": "08:00"},
        {"date": "Apr 05, 2026", "in": "00:00:00", "out": "00:00:00", "status": "WEEKOFF", "netHours": "00:00"},
        {"date": "Apr 06, 2026", "in": "04:54:00", "out": "17:44:10", "status": "PRESENT", "netHours": "08:00"},
      ]
    },
    {"id": "30076", "name": "Vittal Machunuri", "role": "SALEOFF", "logs": []},
    {"id": "30880", "name": "Ravinder Sandiri", "role": "SALEOFF", "logs": []},
    {"id": "30876", "name": "Tabrez Khan", "role": "SALEOFF", "logs": []},
    {"id": "30874", "name": "Surat Subramanyam", "role": "SALEOFF", "logs": []},
    {"id": "30329", "name": "Vijaya Bhasker Dara", "role": "SALEOFF", "logs": []},
  ];

  List<Map<String, dynamic>> get allSoList => _allSoList;

  List<Map<String, dynamic>> get filteredSoList {
    return _allSoList.where((so) {
      final nameMatch = so["name"].toLowerCase().contains(_searchQuery.toLowerCase());
      final idMatch = so["id"].contains(_searchQuery);
      return nameMatch || idMatch;
    }).toList();
  }

  // Daily Activities Mock Data
  final List<Map<String, dynamic>> _dailyActivities = [
    {"date": "May 01, 2026", "hasAttendance": true, "productiveCalls": 0, "totalCalls": 0, "sale": 0},
    {"date": "May 02, 2026", "hasAttendance": false, "productiveCalls": 0, "totalCalls": 0, "sale": 0},
    {"date": "May 03, 2026", "hasAttendance": false, "productiveCalls": 0, "totalCalls": 0, "sale": 0},
    {"date": "May 04, 2026", "hasAttendance": true, "productiveCalls": 0, "totalCalls": 0, "sale": 0},
    {"date": "May 05, 2026", "hasAttendance": false, "productiveCalls": 0, "totalCalls": 0, "sale": 0},
  ];

  List<Map<String, dynamic>> get dailyActivities => _dailyActivities;

  // Travel Plans Mock Data
  final List<Map<String, dynamic>> _travelPlans = [];
  List<Map<String, dynamic>> get travelPlans => _travelPlans;

  void addTravelRequest(Map<String, dynamic> request) {
    _travelPlans.insert(0, request);
    notifyListeners();
  }

  void updateDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
    _fetchData();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> _fetchData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }
}
