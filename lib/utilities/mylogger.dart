import 'package:flutter/foundation.dart';

class AppLogger {
  static void printFull(String message, {String tag = "INFO"}) {
    if (kDebugMode) {
      const int chunkSize = 800;
      if (message.length <= chunkSize) {
        debugPrint("ℹ️ [$tag]: $message");
        return;
      }
      for (int i = 0; i < message.length; i += chunkSize) {
        final end = (i + chunkSize < message.length) ? i + chunkSize : message.length;
        // ignore: avoid_print
        print("ℹ️ [$tag PART ${(i ~/ chunkSize) + 1}]: ${message.substring(i, end)}");
      }
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint("ℹ️ INFO: $message");
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint("✅ SUCCESS: $message");
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint("⚠️ WARNING: $message");
    }
  }

  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint("❌ ERROR: $message");
      if (error != null) {
        debugPrint("❌ DETAILS: $error");
      }
    }
  }
}