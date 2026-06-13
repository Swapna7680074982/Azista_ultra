class TeamAttendance {
  final String userId;
  final String employeeName;
  final String employeeId;
  final String roleCode;
  final String attendanceDate;
  final String? firstCheckin;
  final String? lastCheckout;
  final int workingMinutes;
  final int totalLogs;

  TeamAttendance({
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.roleCode,
    required this.attendanceDate,
    this.firstCheckin,
    this.lastCheckout,
    required this.workingMinutes,
    required this.totalLogs,
  });

  factory TeamAttendance.fromJson(Map<String, dynamic> json) {
    return TeamAttendance(
      userId: json['user_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      roleCode: _normalizeRole(json['rolecode']?.toString() ?? ''),
      attendanceDate: json['attendance_date']?.toString() ?? '',
      firstCheckin: json['first_checkin']?.toString(),
      lastCheckout: json['last_checkout']?.toString(),
      workingMinutes: (json['working_minutes'] as num?)?.toInt() ?? 0,
      totalLogs: (json['total_logs'] as num?)?.toInt() ?? 0,
    );
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
