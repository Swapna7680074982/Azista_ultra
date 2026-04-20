import 'package:azista_ultra/my_app.dart';
import 'package:azista_ultra/services/notification_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 MAIN START"); // 👈 ADD THIS

  await NotificationService.instance.init();

  print("🚀 AFTER INIT"); // 👈 ADD THIS

  runApp(const MyApp());

  print("🚀 APP RUNNING"); // 👈 ADD THIS
}