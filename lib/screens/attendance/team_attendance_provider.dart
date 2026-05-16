import 'package:flutter/material.dart';
import '../../models/team_attendance_model.dart';
import '../../services/api_services.dart';
import '../../utilities/mylogger.dart';

class TeamAttendanceProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<TeamAttendance> _allAttendance = [];
  List<TeamAttendance> _filteredAttendance = [];
  List<dynamic> _rawResponseList = []; // Store raw maps for detail view
  List<TeamAttendance> get attendanceList => _filteredAttendance;

  List<dynamic> getAllLogsForUser(String userId) {
    return _rawResponseList.where((item) => item['user_id'].toString() == userId).toList();
  }

  String _selectedRole = 'ALL';
  String get selectedRole => _selectedRole;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  Future<void> fetchTeamAttendance({String? month, bool isToday = true, String? defaultRole}) async {
    _isLoading = true;
    if (defaultRole != null && _selectedRole == 'ALL') {
      _selectedRole = defaultRole;
    }
    notifyListeners();

    try {
      final response = await ApiServices.getTeamAttendanceReport(
        month: month,
        today: isToday ? 1 : null,
      );

      if (response != null && response['status'] == true) {
        print("TEAM ATTENDANCE RESPONSE: $response");
        final List data = response['data'] ?? [];
        _rawResponseList = data; // Save all logs
        _allAttendance = data.map((item) => TeamAttendance.fromJson(item)).toList();
        _applyFilter();
      } else {
        _rawResponseList = [];
        _allAttendance = [];
        _filteredAttendance = [];
      }
    } catch (e) {
      AppLogger.error("Error fetching team attendance", e);
      _allAttendance = [];
      _filteredAttendance = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _selectedRole = role;
    _applyFilter();
  }

  void _applyFilter() {
    // First, filter by role
    List<TeamAttendance> roleFiltered;
    if (_selectedRole == 'ALL') {
      roleFiltered = List.from(_allAttendance);
    } else {
      roleFiltered = _allAttendance
          .where((item) => item.roleCode.toUpperCase() == _selectedRole.toUpperCase())
          .toList();
    }

    // Now, group by User ID to show unique users with their nested logs
    Map<String, List<TeamAttendance>> grouped = {};
    for (var item in roleFiltered) {
      if (!grouped.containsKey(item.userId)) {
        grouped[item.userId] = [];
      }
      grouped[item.userId]!.add(item);
    }

    // Create a list of unique users for the main display
    _filteredAttendance = grouped.values.map((logs) => logs.first).toList();
    
    // We can access logs for each user via getAllLogsForUser(userId)
    notifyListeners();
  }

  void updateDate(DateTime date) {
    _selectedDate = date;
    final monthStr = "${date.year}-${date.month.toString().padLeft(2, '0')}";
    fetchTeamAttendance(month: monthStr, isToday: false);
  }
}
