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
  static const String outletRegistration = "$baseUrl/user/outlet_registration";
  static const String Outlets = "$baseUrl/user/get_user_outlets";
  static const String nearOutlets = "$baseUrl/user/get_nearby_outlets";
  static const String getProductsWithSkus = "$baseUrl/distribution/get_products_with_skus";
  static const String insertDistributorStock = "$baseUrl/distribution/insert_distributor_stock";
  static const String getDistributorStock = "$baseUrl/distribution/get_distributor_stock";
  static const String getModules = "$baseUrl/distribution/get_modules";
  static const String generatePob = "$baseUrl/distribution/generate_pob";
  static const String supplyPob = "$baseUrl/distribution/supply_pob";
  static const String pobHistory = "$baseUrl/distribution/pob_history";
  static const String posTransaction = "$baseUrl/distribution/pos_transaction";
  static const String posHistory = "$baseUrl/distribution/pos_history";
  static const String getSupportTeam = "$baseUrl/distribution/get_support_team";
  static const String dailyCallSummary = "$baseUrl/distribution/daily_call_summary";
  static const String callsInfo = "$baseUrl/distribution/calls_info";
  static const String addExpense = "$baseUrl/distribution/add_expense";
  static const String submitToAm = "$baseUrl/distribution/submit_to_am";
  static const String receiveFromSo = "$baseUrl/distribution/receive_from_so";
  static const String submitToAdmin = "$baseUrl/distribution/submit_to_admin";
  static const String getExpenses = "$baseUrl/distribution/get_expenses";
  static const String teamAttendanceReport = "$baseUrl/user/attendance_report";
  static const String outletCategories = "$baseUrl/user/outlet_categories";
}