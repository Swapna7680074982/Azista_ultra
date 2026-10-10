import 'package:flutter/material.dart';
import '../../models/team_progress_model.dart';
import '../../services/api_services.dart';
import '../../utilities/mylogger.dart';
import '../../utilities/role_helper.dart';

class TeamProgressProvider extends ChangeNotifier {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String? _errorMessage;
  List<TeamMemberSummary> _members = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';
  String? _currentUserRole;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TeamMemberSummary> get members => _members;
  String get searchQuery => _searchQuery;
  String get selectedRoleFilter => _selectedRoleFilter;
  String? get currentUserRole => _currentUserRole;

  DateTime get selectedDate => DateTime(_selectedYear, _selectedMonth, 1);

  // Filtered and hierarchy-sorted members
  List<TeamMemberSummary> get filteredMembers {
    final list = _members.where((member) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          member.fullName.toLowerCase().contains(query) ||
          member.employeeId.toLowerCase().contains(query) ||
          member.roleCode.toLowerCase().contains(query) ||
          RoleHelper.formatRole(member.roleCode).toLowerCase().contains(query);

      if (!matchesQuery) return false;

      if (_selectedRoleFilter == 'ALL') return true;

      final normRole = RoleHelper.normalizeRole(member.roleCode);
      final filterNorm = RoleHelper.normalizeRole(_selectedRoleFilter);
      return normRole == filterNorm || RoleHelper.formatRole(member.roleCode) == _selectedRoleFilter;
    }).toList();

    // Sort by hierarchy priority (RSM -> ASM -> SO), then alphabetically by name
    list.sort((a, b) {
      final cmp = a.hierarchyPriority.compareTo(b.hierarchyPriority);
      if (cmp != 0) return cmp;
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });

    return list;
  }

  // Summary aggregates for currently filtered view
  int get totalMembersCount => filteredMembers.length;
  int get totalOutletsCount => filteredMembers.fold(0, (sum, m) => sum + m.totalOutlets);
  int get totalNewOutletsCount => filteredMembers.fold(0, (sum, m) => sum + m.newOutlets);
  int get totalVisitsCount => filteredMembers.fold(0, (sum, m) => sum + m.totalVisits);
  int get totalActivitiesCount => filteredMembers.fold(0, (sum, m) => sum + m.totalActivities);
  int get totalPobsCount => filteredMembers.fold(0, (sum, m) => sum + m.totalPobs);
  double get totalPobSaleValue => filteredMembers.fold(0.0, (sum, m) => sum + m.pobSaleValue);

  // Available roles for filter chips, ordered by hierarchy
  List<String> get availableRoles {
    final roleSet = <String>{};
    for (final m in _members) {
      roleSet.add(RoleHelper.formatRole(m.roleCode));
    }
    final sortedRoles = roleSet.toList()
      ..sort((a, b) {
        final prioA = _roleToPriority(a);
        final prioB = _roleToPriority(b);
        return prioA.compareTo(prioB);
      });
    return ['ALL', ...sortedRoles];
  }

  int _roleToPriority(String displayRole) {
    if (displayRole == 'RSM') return 1;
    if (displayRole == 'ASM') return 2;
    if (displayRole == 'FSE') return 3;
    return 4;
  }

  void setCurrentUserRole(String? role) {
    _currentUserRole = role;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _selectedRoleFilter = role;
    notifyListeners();
  }

  void selectMonthAndYear(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    fetchTeamProgress();
  }

  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear -= 1;
    } else {
      _selectedMonth -= 1;
    }
    fetchTeamProgress();
  }

  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear += 1;
    } else {
      _selectedMonth += 1;
    }
    fetchTeamProgress();
  }

  Future<void> fetchTeamProgress({int? month, int? year}) async {
    if (month != null) _selectedMonth = month;
    if (year != null) _selectedYear = year;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiServices.getTeamMembersSummary(
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (response != null && (response['status'] == true || response['status_code'] == 200)) {
        final List dataList = response['data'] is List ? response['data'] : [];
        _members = dataList.map((item) => TeamMemberSummary.fromJson(item)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = response?['message']?.toString() ?? "Failed to load team progress data.";
      }
    } catch (e) {
      AppLogger.error("fetchTeamProgress error", e);
      _errorMessage = "Something went wrong. Please check your connection.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
