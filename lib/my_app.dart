import 'package:azista_ultra/constants/app_colors.dart';
import 'package:azista_ultra/provider_create_list.dart';
import 'package:azista_ultra/screens/splash_screen.dart';
import 'package:azista_ultra/services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providerCreateList,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'ASTRA',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.button,
            primary: AppColors.primary,
            secondary: AppColors.button,
            background: AppColors.background,
          ),
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Heebo',
          cupertinoOverrideTheme: const CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              primaryColor: AppColors.primary,
              textStyle: TextStyle(fontFamily: 'Heebo'),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}