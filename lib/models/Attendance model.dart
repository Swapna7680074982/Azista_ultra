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
    DateTime startDt = DateTime.now();
    if (json["check_in"] != null) {
      final parsed = DateTime.tryParse(json["check_in"].toString());
      if (parsed != null) startDt = parsed;
    }

    DateTime? endDt;
    if (json["check_out"] != null &&
        json["check_out"] != "NA" &&
        json["check_out"].toString().trim().isNotEmpty) {
      endDt = DateTime.tryParse(json["check_out"].toString());
    }

    double hours = 0.0;
    if (json["working_hours"] is num) {
      hours = (json["working_hours"] as num).toDouble();
    } else if (json["working_hours"] != null) {
      hours = double.tryParse(json["working_hours"].toString()) ?? 0.0;
    }

    return Attendance(
      start: startDt,
      end: endDt,
      workingHours: hours,
      checkoutType: json["checkout_type"]?.toString() ?? "",
    );
  }
}