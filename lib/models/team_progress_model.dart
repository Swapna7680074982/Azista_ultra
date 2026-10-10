import '../utilities/role_helper.dart';

class TeamMemberSummary {
  final String userId;
  final String employeeId;
  final String fullName;
  final String roleCode;
  final int totalOutlets;
  final int newOutlets;
  final int totalVisits;
  final int totalActivities;
  final int totalPobs;
  final double pobSaleValue;

  TeamMemberSummary({
    required this.userId,
    required this.employeeId,
    required this.fullName,
    required this.roleCode,
    required this.totalOutlets,
    required this.newOutlets,
    required this.totalVisits,
    required this.totalActivities,
    required this.totalPobs,
    required this.pobSaleValue,
  });

  factory TeamMemberSummary.fromJson(Map<String, dynamic> json) {
    return TeamMemberSummary(
      userId: json['user_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? json['employee_name']?.toString() ?? '',
      roleCode: (json['rolecode'] ?? json['role'] ?? '').toString().trim().toUpperCase(),
      totalOutlets: (json['total_outlets'] as num?)?.toInt() ?? 0,
      newOutlets: (json['new_outlets'] as num?)?.toInt() ?? 0,
      totalVisits: (json['total_visits'] as num?)?.toInt() ?? 0,
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      totalPobs: (json['total_pobs'] as num?)?.toInt() ?? 0,
      pobSaleValue: (json['pob_sale_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Hierarchy sorting priority:
  /// RSM/RM (Regional): 1
  /// ASM/AM (Area): 2
  /// SO/FSE (Field Sales): 3
  /// Others: 4
  int get hierarchyPriority {
    final norm = RoleHelper.normalizeRole(roleCode);
    if (norm == 'RM') return 1;
    if (norm == 'AM') return 2;
    if (norm == 'SO') return 3;
    return 4;
  }
}
