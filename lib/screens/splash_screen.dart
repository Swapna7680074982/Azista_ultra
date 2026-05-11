import 'dart:async';
import 'package:flutter/material.dart';

import '../constants/image_constants.dart';
import '../permissions/SessionManager.dart';
import 'asm/asm_dashboard_screen.dart';
import 'Homes/main_shell_screen.dart';
import 'login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await SessionManager.getToken();
    final isExpired = await SessionManager.isSessionExpired();

    if (token != null && !isExpired) {
      final role = await SessionManager.getUserRole();
      if (role.toLowerCase().trim() == "asm") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AsmDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
        );
      }
    } else {
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          ImageConstants.appLogo,
          width: 180,
        ),
      ),
    );
  }
}