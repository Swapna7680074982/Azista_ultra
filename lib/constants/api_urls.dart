class AppUrls {
  static const String baseUrl =
      "https://services.heterohcl.com/ultra-iris-v2/api";

  static const String login = "$baseUrl/user/login";
  static const String logout = "$baseUrl/user/logout";
  static const String changePassword = "$baseUrl/user/change_password";
  static const String routes = "$baseUrl/user/get_user_beats";
  static const String refreshToken = "$baseUrl/user/refresh_token";
  static const String markAttendance = "$baseUrl/user/mark_attendance";
  static const String todaysAttendance = "$baseUrl/user/get_today_attendance";
  static const String attendanceRange = "$baseUrl/user/get_attendance_range";
  static const String outletRegistration = "$baseUrl/user/outlet_registration";
  static const String Outlets = "$baseUrl/user/get_user_outlets";
  static const String nearOutlets = "$baseUrl/user/get_nearby_outlets";
  static const String getProductsWithSkus = "$baseUrl/distribution_v1/get_products_with_skus";
  static const String insertDistributorStock = "$baseUrl/distribution_v1/insert_distributor_stock";
  static const String getDistributorStock = "$baseUrl/distribution_v1/get_distributor_stock";
  static const String getModules = "$baseUrl/distribution_v1/get_modules";
  static const String generatePob = "$baseUrl/distribution/generate_pob";
  static const String supplyPob = "$baseUrl/distribution_v1/supply_pob";
  static const String pobHistory = "$baseUrl/distribution/pob_history";
  static const String posTransaction = "$baseUrl/distribution/pos_transaction";
  static const String posHistory = "$baseUrl/distribution/pos_history";
  static const String getSupportTeam = "$baseUrl/distribution_v1/get_support_team";
  static const String callsInfo = "$baseUrl/distribution_v1/calls_info";
  static const String addExpense = "$baseUrl/distribution_v1/add_expense";
  static const String submitToAm = "$baseUrl/distribution_v1/submit_to_am";
  static const String receiveFromSo = "$baseUrl/distribution_v1/receive_from_so";
  static const String submitToAdmin = "$baseUrl/distribution_v1/submit_to_admin";
  static const String getExpenses = "$baseUrl/distribution_v1/get_expenses";
  static const String teamAttendanceReport = "$baseUrl/user/attendance_report";
  static const String outletCategories = "$baseUrl/user/outlet_categories";
  static const String getAttendanceStatus = "$baseUrl/user/get_attendance_status";
  static const String teamPosHistory = "$baseUrl/distribution_v1/team_pos_history";
  static const String teamPobHistory = "$baseUrl/distribution_v1/team_pob_history";
  static const String outletCheckIn = "$baseUrl/distribution/outlet_checkin";
  static const String outletCheckOut = "$baseUrl/distribution/outlet_checkout";
  static const String getActivityTypes = "$baseUrl/distribution/get_activity_types";
  static const String createOutletActivity = "$baseUrl/distribution/create_outlet_activity";
  static const String outletHistory = "$baseUrl/distribution/outlet_history";
  static const String dashboardCounts = "$baseUrl/distribution/dashboard_counts";
}