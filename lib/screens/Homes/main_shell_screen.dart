import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Distribution_networking/distribution_network_screen.dart';
import '../../User_transactions/UserTransactionScreen.dart';
import '../attendance/Attendancescreen.dart';
import 'HomeScreen.dart';
import 'custom_bottom_nav.dart';
import 'main_tab_provider.dart';
import 'near_me_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Reset to the first tab every time the shell is opened/re-entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MainTabProvider>(context, listen: false).setTab(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainTabProvider>(
      builder: (context, nav, _) {
        _loadedTabs.add(nav.currentIndex);
        return Scaffold(
          body: IndexedStack(
            index: nav.currentIndex,
            children: [
              const HomeScreen(),
              _loadedTabs.contains(1) ? const UserTransactionScreen() : const SizedBox.shrink(),
              _loadedTabs.contains(2) ? const NearMeScreen() : const SizedBox.shrink(),
              _loadedTabs.contains(3) ? const DistributionNetworkScreen() : const SizedBox.shrink(),
              _loadedTabs.contains(4) ? const AttendanceScreen() : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: const CustomBottomNav(),
        );
      },
    );
  }
}