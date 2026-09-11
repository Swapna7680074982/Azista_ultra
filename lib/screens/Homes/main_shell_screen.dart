import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _lastBackPressTime;

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
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) return;
            if (nav.currentIndex != 0) {
              _lastBackPressTime = null;
              nav.setTab(0);
              return;
            }

            final now = DateTime.now();
            if (_lastBackPressTime == null ||
                now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
              _lastBackPressTime = now;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Press back again to exit"),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
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
          ),
        );
      },
    );
  }
}