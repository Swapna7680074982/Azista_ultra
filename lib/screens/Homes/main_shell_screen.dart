import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Distribution_networking/distribution_network_screen.dart';
import '../../User_transactions/UserTransactionScreen.dart';
import '../attendance/Attendancescreen.dart';
import '../leave_management/leave_management_screen.dart';
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
        return Scaffold(
          body: IndexedStack(
            index: nav.currentIndex,
            children: [
              const HomeScreen(),
              const UserTransactionScreen(),
              const NearMeScreen(),
              const DistributionNetworkScreen(),
              AttendanceScreen(),
            ],
          ),
          bottomNavigationBar: const CustomBottomNav(),
        );
      },
    );
  }
}