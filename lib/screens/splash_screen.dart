import 'dart:async';
import 'package:flutter/material.dart';

import '../constants/image_constants.dart';
import '../permissions/SessionManager.dart';
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

    if (token != null && !isExpired) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
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
      body: Container(
        color: AppColors.primary,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  ImageConstants.appLogo,
                  width: 240,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Container(
                  width: 200,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Field Force Automation for Smarter Sales Operations",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}