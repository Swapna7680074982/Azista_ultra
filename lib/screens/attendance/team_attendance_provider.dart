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

  String? _currentUserRole;
  String? get currentUserRole => _currentUserRole;

  Future<void> fetchTeamAttendance({String? month, bool isToday = true, String? defaultRole, String? currentUserRole}) async {
    _isLoading = true;
    if (defaultRole != null && _selectedRole == 'ALL') {
      _selectedRole = _normalizeRole(defaultRole);
    }
    if (currentUserRole != null) {
      _currentUserRole = _normalizeRole(currentUserRole);
    }
    if (isToday) {
      _selectedDate = DateTime.now();
    }
    notifyListeners();

    try {
      final response = await ApiServices.getTeamAttendanceReport(
        month: month,
        today: isToday ? 1 : null,
      );

      final status = response != null ? response['status'] : null;
      if (response != null && (status == true || status == "success" || status == "true" || status == 1)) {
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
    _selectedRole = role == 'ALL' ? 'ALL' : _normalizeRole(role);
    _applyFilter();
  }

  void _applyFilter() {
    // First, filter by role
    List<TeamAttendance> roleFiltered;
    if (_selectedRole == 'ALL') {
      roleFiltered = List.from(_allAttendance);
    } else {
      roleFiltered = _allAttendance
          .where((item) => _normalizeRole(item.roleCode) == _normalizeRole(_selectedRole))
          .toList();
    }

    // If currentUserRole is 'AM', exclude 'RM' records completely
    if (_currentUserRole == 'AM') {
      roleFiltered = roleFiltered.where((item) => _normalizeRole(item.roleCode) != 'RM').toList();
    }

    // Filter by the selected date (year, month, day)
    roleFiltered = roleFiltered.where((item) {
      final parsed = DateTime.tryParse(item.attendanceDate);
      if (parsed == null) return false;
      return parsed.year == _selectedDate.year &&
             parsed.month == _selectedDate.month &&
             parsed.day == _selectedDate.day;
    }).toList();

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
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      fetchTeamAttendance(isToday: true);
    } else {
      final monthStr = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      fetchTeamAttendance(month: monthStr, isToday: false);
    }
  }

  String _normalizeRole(String role) {
    final norm = role.trim().toUpperCase();
    if (norm == 'ASM' || norm == 'AM') {
      return 'AM';
    } else if (norm == 'RM') {
      return 'RM';
    } else if (norm == 'SO' || norm.contains('SALE OFF') || norm.contains('SALES OFF') || norm.contains('SALE OFFICER') || norm.contains('SALES OFFICER')) {
      return 'SO';
    }
    return norm;
  }
}
