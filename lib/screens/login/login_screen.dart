import 'package:azista_ultra/constants/app_colors.dart';
import 'package:azista_ultra/constants/app_strings.dart';
import 'package:azista_ultra/constants/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Homes/main_shell_screen.dart';
import 'login_provider.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              color: AppColors.primary,
              child: const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: _Logo()),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer<LoginProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone),
                            hintText: AppStrings.mobileHint,
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            hintText: AppStrings.passwordHint,
                            filled: true,
                            fillColor: AppColors.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.button,
                            ),
                            // onPressed: provider.isLoading
                            //     ? null
                            //     : () async {
                            //   final success = await provider.login(
                            //     phoneController.text.trim(),
                            //     passwordController.text.trim(),
                            //   );
                            //
                            //   if (success) {
                            //     Navigator.pushReplacement(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) => const MainShellScreen(),
                            //       ),
                            //     );
                            //   } else {
                            //     ScaffoldMessenger.of(context).showSnackBar(
                            //       SnackBar(
                            //         content: Text(
                            //           provider.error ?? "Login Failed",
                            //         ),
                            //       ),
                            //     );
                            //   }
                            // },
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainShellScreen(),
                                ),
                              );
                            },
                            child: provider.isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text(
                              AppStrings.login,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ImageConstants.appLogo,
      width: 150,
      color: AppColors.white,
    );
  }
}