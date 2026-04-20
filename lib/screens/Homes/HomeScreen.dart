import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../attendance/Attendancescreen.dart';
import 'widgets/DonutChart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 60,
        titleSpacing: 0,

        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.menu, color: AppColors.white, size: 26),
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
              value: isOnline,
              onChanged: (val) {
                setState(() {
                  isOnline = val;
                });
              },

              activeThumbColor: AppColors.button,
              activeTrackColor:AppColors.button.withValues(alpha: 0.35),
              inactiveThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.white.withValues(alpha:0.4),

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
                )
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Select Distributor"),
                        Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 45,
                  width: 65,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
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
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(0,70, 0, 20),
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
                      value: 30,
                      label: "Target Calls",
                      color: AppColors.primary,
                    ),
                    DonutChart(
                      value: 6,
                      label: "Target Productive",
                      color: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "View Details >>",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              ],
            )
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
                const ActionBox(Icons.person, "Leave\nManagement"),
                ActionBox(
                  Icons.access_time,
                  "Attendance",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(),
                      ),
                    );
                  },
                ),
                const ActionBox(Icons.receipt, "User\nTransaction's"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}