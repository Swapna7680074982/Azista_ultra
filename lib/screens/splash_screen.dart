import 'dart:async';
import 'package:flutter/material.dart';

import '../constants/image_constants.dart';
import '../permissions/SessionManager.dart';
import 'asm/asm_dashboard_screen.dart';
import 'rm/rm_dashboard_screen.dart';
import 'Homes/main_shell_screen.dart';
import 'login/login_screen.dart';

import '../constants/app_colors.dart';

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

    if (!mounted) return;

    if (token != null && !isExpired) {
      final role = await SessionManager.getUserRole();
      if (!mounted) return;
      final normalizedRole = role.toLowerCase().trim();
      if (normalizedRole == "rm") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RmDashboardScreen()),
        );
      } else if (normalizedRole == "asm" || normalizedRole == "am") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AmDashboardScreen()),
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
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.button,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Image.asset(
            ImageConstants.appLogo,
            width: 220,
          ),
        ),
      ),
    );
  }
}