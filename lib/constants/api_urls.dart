class AppUrls {
  // Base URLs
  static const String astraBaseUrl = "https://services.heterohcl.com/azista-astra/api";

  // 6 Required APIs
  static const String login = "$astraBaseUrl/user/login";
  static const String logout = "$astraBaseUrl/user/logout";
  static const String refreshToken = "$astraBaseUrl/user/refresh_token";
  static const String changePassword = "$astraBaseUrl/user/change_password";
  static const String routes = "$astraBaseUrl/user/get_user_beats";
  static const String getDistributors = "$astraBaseUrl/user/get_user_distributors";
}