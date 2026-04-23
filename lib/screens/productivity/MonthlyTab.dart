import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'productivity_provider.dart';
import '../../constants/app_colors.dart';

class MonthlyTab extends StatefulWidget {
  const MonthlyTab({super.key});

  @override
  State<MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<MonthlyTab> {

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "November 2024",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Icon(Icons.calendar_month, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text("Attendance", style: TextStyle(color: Colors.black87)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.flag, color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text("No Attendance", style: TextStyle(color: Colors.black87)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: provider.monthlyData.length,
              itemBuilder: (context, index) {
                final data = provider.monthlyData[index];
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Date",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      data["date"]!,
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.flag,
                                      color: data["attendance"] ? Colors.green :  AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Sale",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data["sale"]!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Productive Calls",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data["productiveCalls"]!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Total Calls",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data["totalCalls"]!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ],
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
      ),
    );
      },
    );
  }
}
