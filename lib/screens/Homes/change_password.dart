import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../login/login_provider.dart';
import '../login/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  final oldController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: oldController,
              decoration: const InputDecoration(labelText: "Current Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: newController,
              decoration: const InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: "Repeat Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                 final oldPassword = oldController.text.trim();
                 final newPassword = newController.text.trim();
                 final confirmPassword = confirmController.text.trim();

                  final missingFields = <String>[];
                  if (oldPassword.isEmpty) missingFields.add("Current Password");
                  if (newPassword.isEmpty) missingFields.add("New Password");
                  if (confirmPassword.isEmpty) missingFields.add("Repeat Password");

                  if (missingFields.isNotEmpty) {
                    String message;
                    if (missingFields.length == 1) {
                      message = "${missingFields[0]} is required";
                    } else if (missingFields.length == 2) {
                      message = "${missingFields[0]} and ${missingFields[1]} are required";
                    } else {
                      message = "${missingFields.sublist(0, missingFields.length - 1).join(', ')}, and ${missingFields.last} are required";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    return;
                  }
                 if (newPassword != confirmPassword) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Passwords do not match")),
                   );
                   return;
                 }

                final success = await provider.changePassword(
                  oldPassword: oldController.text,
                  newPassword: newController.text,
                  confirmPassword: confirmController.text,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password changed. Please login again")),
                  );

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? "Error")),
                  );
                }
              },
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }
}