import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/wavy_app_bar.dart';
import '../login/login_provider.dart';
import '../login/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    final provider = Provider.of<LoginProvider>(context, listen: false);

    final oldPassword = _oldController.text.trim();
    final newPassword = _newController.text.trim();
    final confirmPassword = _confirmController.text.trim();

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
        const SnackBar(content: Text("New password and repeat password do not match")),
      );
      return;
    }

    LoadingDialog.show(context, message: "Changing password...");

    final success = await provider.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully. Please login with your new password."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? "Failed to change password"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();

    return Scaffold(
      appBar: WavyAppBar(
        title: "CHANGE PASSWORD",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "After successfully changing your password, you will be required to log in again.",
                        style: TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                controller: _oldController,
                label: "Current Password",
                hint: "Enter current password",
                obscureText: _obscureOld,
                onToggleVisibility: () {
                  setState(() {
                    _obscureOld = !_obscureOld;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newController,
                label: "New Password",
                hint: "Enter new password",
                obscureText: _obscureNew,
                onToggleVisibility: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmController,
                label: "Repeat Password",
                hint: "Re-enter new password",
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: provider.isLoading ? null : _submitChangePassword,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: provider.isLoading ? Colors.grey : AppColors.button,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.button.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            "UPDATE PASSWORD",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}