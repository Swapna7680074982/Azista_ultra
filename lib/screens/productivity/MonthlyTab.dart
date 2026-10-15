import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'productivity_provider.dart';
import '../../constants/app_colors.dart';
import '../../utilities/date_formatter.dart';
import '../../utilities/common_widgets.dart';

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
      if (mounted) {
        Provider.of<ProductivityProvider>(context, listen: false).fetchMonthlyCalls();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        return provider.isMonthlyLoading
            ? const LogoProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _monthDropdown(context, provider),
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
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => provider.fetchMonthlyCalls(),
                  child: provider.monthlyData.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text("No monthly call data available")),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
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
                                      (data["outletName"] ?? "-").toString().toUpperCase(),
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
                                                  DateFormatter.formatDateOnly(data["date"]?.toString()),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.flag,
                                                  color: data["attendance"] == true ? Colors.green : AppColors.primary,
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
                                              "TARGET CALLS",
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              data["totalCalls"]?.toString() ?? "0",
                                              style: const TextStyle(
                                                  fontSize: 16, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "PRODUCTIVE CALLS",
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              data["productiveCalls"]?.toString() ?? "0",
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _monthDropdown(BuildContext context, ProductivityProvider provider) {
    return Container(
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
    );
  }

  String _monthName(int m) {
    const months = [
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
    return months[m - 1];
  }
}
