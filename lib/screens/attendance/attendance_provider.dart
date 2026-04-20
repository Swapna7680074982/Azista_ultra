import 'package:flutter/cupertino.dart';

import '../../models/Attendance model.dart';

class AttendanceProvider extends ChangeNotifier {
  int _selectedMonth = DateTime.now().month;

  int get selectedMonth => _selectedMonth;

  void changeMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  final List<Attendance> _list = [
    Attendance(
      start: DateTime(2026, 4, 20, 9, 24),
      end: DateTime(2026, 4, 20, 14, 50),
      hasRequest: false,
    ),
    Attendance(
      start: DateTime(2026, 4, 16, 10, 50),
      end: DateTime(2026, 4, 17, 5, 29),
    ),
    Attendance(
      start: DateTime(2026, 3, 15, 12, 42),
      end: DateTime(2026, 3, 16, 5, 29),
    ),
  ];

  List<Attendance> get list =>
      _list.where((e) => e.start.month == _selectedMonth).toList();
}