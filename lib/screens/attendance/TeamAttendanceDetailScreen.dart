import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utilities/date_formatter.dart';

class TeamAttendanceDetailScreen extends StatelessWidget {
  final String employeeName;
  final String employeeId;
  final String role;
  final List<dynamic> logs;

  const TeamAttendanceDetailScreen({
    super.key,
    required this.employeeName,
    required this.employeeId,
    required this.role,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.button,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text("$employeeName's Logs", style: const TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildUserHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogTile(log, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            employeeName,
            style:  TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            "Employee ID: $employeeId | Role: $role",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(dynamic log, int logNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(logNumber.toString(), style:  TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeInfo("IN", DateFormatter.formatTimeOnly(log['first_checkin'])),
                    _buildTimeInfo("OUT", DateFormatter.formatTimeOnly(log['last_checkout'])),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${DateFormatter.formatDateOnly(log['attendance_date'])}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Builder(builder: (context) {
                      final checkInStr = log['first_checkin']?.toString();
                      final checkOutStr = log['last_checkout']?.toString();
                      int min = 0;
                      if (checkOutStr == null || checkOutStr.isEmpty || checkOutStr == 'N/A') {
                        if (checkInStr != null && checkInStr.isNotEmpty && checkInStr != 'N/A') {
                          try {
                            final checkInTime = DateTime.parse(checkInStr);
                            final diff = DateTime.now().difference(checkInTime);
                            if (diff.inMinutes > 0) {
                              min = diff.inMinutes;
                            }
                          } catch (e) {
                            final rawMin = log['working_minutes'];
                            min = rawMin is int ? rawMin : int.tryParse(rawMin?.toString() ?? "0") ?? 0;
                          }
                        }
                      } else {
                        final rawMin = log['working_minutes'];
                        min = rawMin is int ? rawMin : int.tryParse(rawMin?.toString() ?? "0") ?? 0;
                      }

                      if (min < 60) {
                        return Text(
                          "Work: ${min}m",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        );
                      } else {
                        final double hours = min / 60.0;
                        return Text(
                          "Work: ${hours.toStringAsFixed(1)} hours",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        );
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String type, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        Text(time, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
