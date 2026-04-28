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
    required List distributors,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day, 23, 59, 59);

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_distributorsKey, jsonEncode(distributors));
    await prefs.setString(_expiryKey, midnight.toIso8601String());
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
    final expiry = prefs.getString(_expiryKey);

    if (expiry == null) return true;

    return DateTime.now().isAfter(DateTime.parse(expiry));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}