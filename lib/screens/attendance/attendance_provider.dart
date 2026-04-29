import 'package:flutter/material.dart';
import '../../models/Attendance model.dart';
import '../../services/api_services.dart';

class AttendanceProvider extends ChangeNotifier {
  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  List<Attendance> _list = [];
  List<Attendance> get list => _list;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void changeMonth(int month) {
    _selectedMonth = month;
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      final fromDate =
      DateTime(now.year, _selectedMonth, 1);
      final toDate =
      DateTime(now.year, _selectedMonth + 1, 0);

      final response =
      await ApiServices.getAttendanceRange(
        fromDate: _formatDate(fromDate),
        toDate: _formatDate(toDate),
      );

      if (response != null) {
        List<Attendance> temp = [];

        for (var day in response) {
          if (day["sessions"] != null) {
            for (var session in day["sessions"]) {
              temp.add(Attendance.fromJson(session));
            }
          }
        }

        _list = temp;
      } else {
        _list = [];
      }
    } catch (e) {
      _list = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}