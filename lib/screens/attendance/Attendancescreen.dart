import 'package:azista_ultra/screens/attendance/widgets/AttendanceCard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'attendance_provider.dart';


class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),
      body: Column(
        children: [
          _monthDropdown(context),

          Expanded(
            child: provider.list.isEmpty
                ? const Center(
              child: Text(
                "No attendance found",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView(
              children: provider.list
                  .map((e) => AttendanceCard(data: e))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthDropdown(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: provider.selectedMonth,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            style: const TextStyle(color: Colors.black, fontSize: 14),

            items: List.generate(
              12,
                  (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(_monthName(index + 1)),
              ),
            ),

            onChanged: (val) {
              if (val != null) {
                provider.changeMonth(val);
              }
            },
          ),
        ),
      ),
    );
  }
  String _monthName(int m) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[m - 1];
  }
}