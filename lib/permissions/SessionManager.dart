import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _tokenKey = "token";
  static const _distributorsKey = "distributors";
  static const _expiryKey = "expiry";
  static const _refreshTokenKey = "refresh_token";

  static Future<void> saveSession({
    required String token,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_expiryKey, midnight.toIso8601String());
  }

  static const _nameKey = "user_name";
  static const _roleKey = "user_role";
  static const _userInfoKey = "user_info";

  static Future<void> saveUserDetails(String name, String role, {Map<String, dynamic>? userInfo}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_roleKey, role);
    if (userInfo != null) {
      await prefs.setString(_userInfoKey, jsonEncode(userInfo));
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userInfoKey);
    return data != null ? jsonDecode(data) : null;
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? "Unknown User";
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? "Sale Off";
  }

  static const _attendanceKey = "attendance_status";
  static const _checkInTimeKey = "check_in_time";

  static Future<void> saveAttendanceStatus(String? status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attendanceKey, status ?? "");
    if (status == "CHECKED_IN") {
      await prefs.setString(_checkInTimeKey, DateTime.now().toIso8601String());
    } else if (status == "CHECKED_OUT") {
      await prefs.remove(_checkInTimeKey);
    }
  }

  static Future<String?> getAttendanceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_attendanceKey);
  }

  static Future<DateTime?> getCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_checkInTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<List> getDistributors() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_distributorsKey);
    return data != null ? jsonDecode(data) : [];
  }

  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) {
      return true;
    }
    final expiryStr = prefs.getString(_expiryKey);
    if (expiryStr == null) {
      return false;
    }
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) {
      return false;
    }
    return DateTime.now().isAfter(expiry);
  }

  static const _outletCheckInOutletIdKey = "outlet_check_in_outlet_id";
  static const _outletCheckInVisitIdKey = "outlet_check_in_visit_id";
  static const _outletCheckInTimeKey = "outlet_check_in_time";

  static Future<void> saveOutletCheckIn({
    required int outletId,
    required int visitId,
    required DateTime checkInTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_outletCheckInOutletIdKey, outletId);
    await prefs.setInt(_outletCheckInVisitIdKey, visitId);
    await prefs.setString(_outletCheckInTimeKey, checkInTime.toIso8601String());
  }

  static Future<void> clearOutletCheckIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_outletCheckInOutletIdKey);
    await prefs.remove(_outletCheckInVisitIdKey);
    await prefs.remove(_outletCheckInTimeKey);
  }

  static Future<int?> getOutletCheckInOutletId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_outletCheckInOutletIdKey);
  }

  static Future<int?> getOutletCheckInVisitId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_outletCheckInVisitIdKey);
  }

  static Future<DateTime?> getOutletCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_outletCheckInTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}