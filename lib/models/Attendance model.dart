class Attendance {
  final DateTime start;
  final DateTime? end;
  final double workingHours;
  final String checkoutType;

  Attendance({
    required this.start,
    this.end,
    required this.workingHours,
    required this.checkoutType,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      start: DateTime.parse(json["check_in"]),
      end: json["check_out"] != null
          ? DateTime.parse(json["check_out"])
          : null,
      workingHours:
      (json["working_hours"] as num?)?.toDouble() ?? 0.0,
      checkoutType: json["checkout_type"] ?? "",
    );
  }
}