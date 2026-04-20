import 'package:azista_ultra/provider_create_list.dart';
import 'package:azista_ultra/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providerCreateList,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Azista App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}