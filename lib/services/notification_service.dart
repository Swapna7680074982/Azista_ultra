import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  String? _fcmToken;
  String? _deviceId;

  String? get fcmToken => _fcmToken;
  String? get deviceId => _deviceId;

  Future<void> init() async {
    print("🔥 NotificationService INIT CALLED");
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission();

      _fcmToken = await messaging.getToken();

      debugPrint("FCM TOKEN: $_fcmToken");
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint("FCM TOKEN REFRESHED: $token");
      });

      _deviceId = await _getDeviceId();

      debugPrint("DEVICE ID: $_deviceId");
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return android.id ?? android.model ?? "unknown_android";
    } else {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor ?? "unknown_ios";
    }
  }
}