import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'HomeScreen.dart';
import 'custom_bottom_nav.dart';
import 'main_tab_provider.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainTabProvider>(
      builder: (context, nav, _) {
        return Scaffold(
          body: IndexedStack(
            index: nav.currentIndex,
            children: const [
              HomeScreen(),
              Center(child: Text("Marketing")),
              Center(child: Text("Near Me")),
              Center(child: Text("Dist Net")),
              Center(child: Text("Sync")),
            ],
          ),
          bottomNavigationBar: const CustomBottomNav(),
        );
      },
    );
  }
}