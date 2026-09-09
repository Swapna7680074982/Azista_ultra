class AppUrls {
  // Base URLs
  static const String astraBaseUrl = "https://services.heterohcl.com/azista-astra/api";
  static const String ultraIrisBaseUrl = "https://services.heterohcl.com/ultra-iris-v2/api";

  // 16 Azista Astra APIs
  static const String login = "$astraBaseUrl/user/login";
  static const String logout = "$astraBaseUrl/user/logout";
  static const String refreshToken = "$astraBaseUrl/user/refresh_token";
  static const String changePassword = "$ultraIrisBaseUrl/user/change_password";
  static const String routes = "$astraBaseUrl/user/get_user_routes";
  static const String getDistributors = "$astraBaseUrl/user/get_user_distributors";
  static const String markAttendance = "$astraBaseUrl/user/mark_attendance";
  static const String getAttendanceStatus = "$astraBaseUrl/user/get_attendance_status";
  static const String getTodayAttendance = "$astraBaseUrl/user/get_today_attendance";
  static const String getAttendanceRange = "$astraBaseUrl/user/get_attendance_range";
  static const String outletCategories = "$astraBaseUrl/user/outlet_categories";
  static const String outletRegistration = "$astraBaseUrl/user/outlet_registration";
  static const String getUserOutlets = "$astraBaseUrl/user/get_user_outlets";
  static const String getNearbyOutlets = "$astraBaseUrl/user/get_nearby_outlets";
  static const String getProductsWithSkus = "$astraBaseUrl/distribution/get_products_with_skus";
  static const String getModules = "$astraBaseUrl/distribution/get_modules";

  // Distribution APIs
  static const String distributorStockInsert = "$astraBaseUrl/distribution/distributor_stock_insert";
  static const String distributorStocks = "$astraBaseUrl/distribution/distributor_stocks";
  static const String generatePob = "$astraBaseUrl/distribution/generate_pob";
  static const String supplyPob = "$astraBaseUrl/distribution/supply_pob";
  static const String pobHistory = "$astraBaseUrl/distribution/pob_history";
  static const String posTransaction = "$astraBaseUrl/distribution/pos_transaction";
  static const String posHistory = "$astraBaseUrl/distribution/pos_history";
  static const String getSupportTeam = "$astraBaseUrl/distribution/get_support_team";
  static const String outletCheckIn = "$astraBaseUrl/distribution/outlet_checkin";
  static const String outletCheckOut = "$astraBaseUrl/distribution/outlet_checkout";
  static const String getActivityTypes = "$astraBaseUrl/distribution/get_activity_types";
  static const String createOutletActivity = "$astraBaseUrl/distribution/create_outlet_activity";
  static const String outletHistory = "$astraBaseUrl/distribution/outlet_history";
  static const String dashboardCounts = "$astraBaseUrl/distribution/dashboard_counts";
  static const String getTargets = "$astraBaseUrl/distribution/get_targets";
  static const String callsInfo = "$astraBaseUrl/distribution/calls_info";
  static const String posSummary = "$astraBaseUrl/distribution/pos_summary";
}