class Attendance {
  final DateTime start;
  final DateTime end;
  final bool hasRequest;

  Attendance({
    required this.start,
    required this.end,
    this.hasRequest = true,
  });
}