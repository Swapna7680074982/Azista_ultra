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

  // Outlet Geo Requests & Coordinate APIs
  static const String raiseOutletGeoRequest = "$astraBaseUrl/distribution/raise_outlet_geo_request";
  static const String myOutletGeoRequests = "$astraBaseUrl/distribution/my_outlet_geo_requests";
  static const String listOutletGeoRequests = "$astraBaseUrl/distribution/list_outlet_geo_requests";
  static const String reviewOutletGeoRequest = "$astraBaseUrl/distribution/review_outlet_geo_request";
  static const String previewOutletCoordinates = "$astraBaseUrl/distribution/preview_outlet_coordinates";
  static const String updateOutletCoordinatesDirect = "$astraBaseUrl/distribution/update_outlet_coordinates_direct";

  // Team APIs (For AM, RM)
  static const String myTeam = "$astraBaseUrl/user/my_team";
  static const String teamAttendanceReport = "$astraBaseUrl/user/attendance_report";
  static const String teamPobHistory = "$astraBaseUrl/distribution/team_pob_history";
  static const String teamPosHistory = "$astraBaseUrl/distribution/team_pos_history";
  static const String teamMembersSummary = "$astraBaseUrl/distribution/team_members_summary";
  static const String teamMemberOutlets = "$astraBaseUrl/distribution/team_member_outlets";
  static const String outletPobHistory = "$astraBaseUrl/distribution/outlet_pob_history";
  static const String outletVisitActivityHistory = "$astraBaseUrl/distribution/outlet_visit_activity_history";
}