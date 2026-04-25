import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            "Change Password",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconTheme: const IconThemeData(
            color: AppColors.white,
          ),
        ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(decoration: InputDecoration(labelText: "Current Password")),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: "New Password")),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: "Repeat Password")),
            SizedBox(height: 10),
            Text(
              "Make sure your password should contain atleast one capital, small letters, one alphanumeric, one special character.",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}