import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'asm_provider.dart';

class DailyActivitiesScreen extends StatelessWidget {
  final String soName;
  const DailyActivitiesScreen({super.key, required this.soName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Daily Activities",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Consumer<AmProvider>(
        builder: (context, amProvider, child) {
          return Column(
            children: [
              // Month Picker
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("May 2026", style: TextStyle(fontSize: 16)),
                    Icon(Icons.calendar_month, color: AppColors.primary),
                  ],
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegend(Icons.flag, Colors.green, "Attendance"),
                    _buildLegend(Icons.flag, Colors.red, "No Attendance"),
                  ],
                ),
              ),

              // Activities List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: amProvider.dailyActivities.length,
                  itemBuilder: (context, index) {
                    final activity = amProvider.dailyActivities[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Date",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const Spacer(),
                                const Text(
                                  "Sale",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  activity["date"],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.flag,
                                  color: activity["hasAttendance"] ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                                const Spacer(),
                                Text(
                                  activity["sale"].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                const Text(
                                  "Productive Calls",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const Spacer(),
                                const Text(
                                  "Total Calls",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  activity["productiveCalls"].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  activity["totalCalls"].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
