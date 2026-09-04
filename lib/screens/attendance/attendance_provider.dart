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
          if (day["sessions"] != null && day["sessions"] is List && (day["sessions"] as List).isNotEmpty) {
            final sessionsList = day["sessions"] as List;
            List<Attendance> daySessions = [];
            for (var session in sessionsList) {
              daySessions.add(Attendance.fromJson(session));
            }

            if (daySessions.isNotEmpty) {
              // Sort sessions by start time ascending
              daySessions.sort((a, b) => a.start.compareTo(b.start));

              DateTime firstStart = daySessions.first.start;
              
              // If any session has end == null, the overall end is null (meaning checked in)
              DateTime? lastEnd;
              bool hasActiveSession = daySessions.any((s) => s.end == null);
              if (!hasActiveSession) {
                lastEnd = daySessions.last.end;
              }

              double totalWorkingHours = daySessions.fold(0.0, (sum, s) => sum + s.workingHours);

              temp.add(Attendance(
                start: firstStart,
                end: lastEnd,
                workingHours: totalWorkingHours,
                checkoutType: daySessions.last.checkoutType,
              ));
            }
          }
        }

        _list = temp;
      } else {
        _list = [];
      }
    } catch (e) {
      _list = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}