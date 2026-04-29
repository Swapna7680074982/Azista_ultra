class AppUrls {
  static const String baseUrl =
      "https://services.heterohcl.com/ultra-iris-v2/api";

  static const String login = "$baseUrl/user/login";
  static const String logout = "$baseUrl/user/logout";
  static const String changePassword = "$baseUrl/user/change_password";
  static const String routes = "$baseUrl/user/get_routes";
  static const String markAttendance = "$baseUrl/user/mark_attendance";
  static const String todaysAttendance = "$baseUrl/user/get_today_attendance";
  static const String attendanceRange = "$baseUrl/user/get_attendance_range";
}