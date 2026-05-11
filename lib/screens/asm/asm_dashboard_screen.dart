import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AppStateProvider.dart';
import '../../profile.dart';
import '../Homes/HomeProvider.dart';
import '../leave_management/leave_management_screen.dart';
import 'asm_provider.dart';
import 'select_so_screen.dart';
import 'so_attendance_screen.dart';
import 'travel_plan_screen.dart';

class AsmDashboardScreen extends StatefulWidget {
  const AsmDashboardScreen({super.key});

  @override
  State<AsmDashboardScreen> createState() => _AsmDashboardScreenState();
}

class _AsmDashboardScreenState extends State<AsmDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await homeProvider.initializeAttendance(appState);
      await homeProvider.fetchTodayAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(80),
                bottomRight: Radius.circular(80),
              ),
            ),
            child: const Center(
              child: Text(
                "AZISTA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              children: [
                _buildMenuItem(
                  iconPath: Icons.people_outline,
                  label: "SO Attendance",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SoAttendanceScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.track_changes,
                  label: "SO Daily Targets",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SelectSoScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.calendar_today_outlined,
                  label: "Travel Plan",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TravelPlanScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.account_tree_outlined,
                  label: "Distributor Visit",
                  onTap: () {
                    // Placeholder for Distributor Visit
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.person_search_outlined,
                  label: "Leave Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LeaveManagementScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.person_outline,
                  label: "Profile",
                  onTap: () {
                    _showProfileDrawer(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Icon(iconPath, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 25),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: const ProfileDrawer(selectedMenu: "Profile"),
      ),
    );
  }
}
