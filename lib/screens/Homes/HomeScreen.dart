import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../User_transactions/UserTransactionScreen.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AccessValidator.dart';
import '../../permissions/AppStateProvider.dart';
import '../../profile.dart';
import '../attendance/Attendancescreen.dart';
import '../distribution_list/DistributorStockScreen.dart';
import '../leave_management/leave_management_screen.dart';
import '../productivity/ProductivityScreen.dart';
import 'widgets/DonutChart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: const ProfileDrawer(selectedMenu: "Attendance"),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 60,
        titleSpacing: 0,

        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Icon(
                Icons.menu,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
        ),
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        actions: [
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: appState.isOnline,
              onChanged: (val) {
                appState.setOnline(val);
              },

              activeThumbColor: AppColors.button,
              activeTrackColor: AppColors.button.withValues(alpha: 0.35),
              inactiveThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.white.withValues(alpha: 0.4),

              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          const SizedBox(width: 6),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications,
                  color: AppColors.white,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Consumer<AppStateProvider>(
                        builder: (context, appState, _) {
                          return DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text("Select Distributor"),
                            value: appState.selectedDistributor,
                            items: const [
                              DropdownMenuItem(
                                value: "Distributor 1",
                                child: Text("Distributor 1"),
                              ),
                              DropdownMenuItem(
                                value: "Distributor 2",
                                child: Text("Distributor 2"),
                              ),
                              DropdownMenuItem(
                                value: "Distributor 3",
                                child: Text("Distributor 3"),
                              ),
                            ],
                            onChanged: (value) {
                              appState.setDistributor(value);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    if (appState.selectedDistributor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a distributor first"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DistributorStockScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 45,
                    width: 65,
                    decoration: BoxDecoration(
                      color: appState.selectedDistributor == null
                          ? Colors.grey.shade400
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        "GO",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(0, 60, 0, 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border,
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DonutChart(
                      value: 2,
                      total: 30,
                      label: "Total Calls",
                      color: Colors.green,
                    ),
                    DonutChart(
                      value: 6,
                      total: 30,
                      label: "Target Productive",
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductivityScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "View Details >>",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey),
              SizedBox(width: 6),
              Text("Current Session"),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            "20-Apr-2026 09:24 am",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionBox(
                  Icons.person,
                  "Leave\nManagement",
                  enabled: !appState.isOnline,
                  onTap: () {
                    if (AccessValidator.validate(
                      context: context,
                      isOnline: appState.isOnline,
                      hasDistributor: appState.selectedDistributor != null,
                      checkDistributor: false,
                      isLeave: true,
                    )) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeaveManagementScreen(),
                        ),
                      );
                    }
                  },
                ),
                ActionBox(
                  Icons.access_time,
                  "Attendance",
                  enabled: appState.isOnline,
                  onTap: () {
                    if (AccessValidator.validate(
                      context: context,
                      isOnline: appState.isOnline,
                      hasDistributor: appState.selectedDistributor != null,
                      checkDistributor: false,
                      isLeave: false,
                    )) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceScreen(),
                        ),
                      );
                    }
                  },
                ),
                ActionBox(
                  Icons.receipt,
                  "User\nTransaction's",
                  enabled: appState.isOnline,
                  onTap: () {
                    if (AccessValidator.validate(
                      context: context,
                      isOnline: appState.isOnline,
                      hasDistributor: appState.selectedDistributor != null,
                      isLeave: false,
                    )) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserTransactionScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}