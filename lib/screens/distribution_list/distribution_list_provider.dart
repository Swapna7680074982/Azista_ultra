import 'package:flutter/material.dart';

class DistributionListProvider extends ChangeNotifier {
  // DistributorStatusScreen State
  List<bool> _statusList = [true, false, false, false];
  List<bool> _buttonEnabled = [false, true, false, false];

  List<bool> get statusList => _statusList;
  List<bool> get buttonEnabled => _buttonEnabled;

  void updateStatus(int index) {
    _statusList[index] = true;
    _buttonEnabled[index] = false;
    if (index + 1 < _buttonEnabled.length) {
      _buttonEnabled[index + 1] = true;
    }
    notifyListeners();
  }

  // StockOnHandScreen State
  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  String _selectedMonth = "April";

  List<String> get months => _months;
  String get selectedMonth => _selectedMonth;

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  final List<Map<String, String>> _stockOnHandProducts = [
    {"name": "3 - BURST'S CASSETS(10 X 20'S) (PCS)", "qty": "5"},
    {"name": "2 - 1X 44'S (1X 2'S) (BOXES)", "qty": "5"},
    {"name": "1 - BURST (BOXES)", "qty": "5"},
    {"name": "5 - 1X 44'S (1X 2'S) (BOXES)", "qty": "1"},
    {"name": "4 - BURST (BOXES)", "qty": "1"},
  ];

  List<Map<String, String>> get stockOnHandProducts => _stockOnHandProducts;

  // DistributorStockScreen State
  final Map<String, List<String>> _distributorStockSections = {
    "Kwik Mint": [
      "Burst (Boxes)",
      "1X 44'S (1X 2'S) (Boxes)",
      "BURST'S CASSETS(10 X 20S) (Pcs)",
      "PREMIUM STRONG CASSET 20",
      "KWIK MINT STRONG CASSETS(10 X 20'S)",
      "KWIK MINT BURST",
    ],
    "Menthopas": ["3 PATCHES POUCHES (Pcs)"],
    "Sparkel": [
      "FACIAL MASK (Pcs)",
      "GLOW FACIAL MASK (Pcs)",
      "YOUTH FACIAL MASK (Pcs)",
    ],
    "Spice Sip": ["(1X6) (Boxes)"],
    "Taste Good": ["KARELA BISCUIT 100G (Boxes)"],
  };

  Map<String, List<String>> get distributorStockSections => _distributorStockSections;
}
