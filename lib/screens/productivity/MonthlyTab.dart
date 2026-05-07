import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'productivity_provider.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AppStateProvider.dart';

class MonthlyTab extends StatefulWidget {
  const MonthlyTab({super.key});

  @override
  State<MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<MonthlyTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final now = DateTime.now();
      final monthStr = "${now.month.toString().padLeft(2, '0')}-${now.year}";
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      Provider.of<ProductivityProvider>(context, listen: false).fetchCallsInfo(
        month: monthStr,
        distributorId: appState.selectedDistributorId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        return provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getCurrentMonthName(),
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87),
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
                      const Text("ATTENDANCE",
                          style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.flag, color: AppColors.primary),
                      const SizedBox(width: 4),
                      const Text("NO ATTENDANCE",
                          style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.monthlyData.isEmpty
                    ? const Center(child: Text("No monthly data available"))
                    : ListView.builder(
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
                            Text(
                              "OUTLET NAME",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data["outletName"]!.toString().toUpperCase(),
                              style: const TextStyle(fontSize: 18, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DATE",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          data["date"]!,
                                          style: const TextStyle(fontSize: 16,
                                              color: Colors.black87),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.flag,
                                          color: data["attendance"] ? Colors
                                              .green : AppColors.primary,
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
                                      "SALE",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "₹${data["sale"]}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                      "PRODUCTIVE CALLS",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data["productiveCalls"]!,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "TARGET CALLS",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data["totalCalls"]!,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black87),
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

  String _getCurrentMonthName() {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    final now = DateTime.now();
    return "${months[now.month - 1]} ${now.year}";
  }
}
