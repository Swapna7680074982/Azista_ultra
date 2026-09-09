import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final monthStr = "${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
      if (mounted) {
        Provider.of<ProductivityProvider>(context, listen: false).fetchCallsInfo(
          month: monthStr,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        return provider.isLoading
            ? const LogoProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _selectMonth(context),
                child: Container(
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
                        DateFormat('dd MMMM yyyy').format(selectedDate),
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                      Icon(Icons.calendar_month, color: AppColors.primary),
                    ],
                  ),
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
                child: () {
                  final filteredData = provider.monthlyData.where((item) {
                    final itemDateStr = item["date"]?.toString() ?? "";
                    if (itemDateStr.isEmpty || itemDateStr == "-") return false;
                    try {
                      final itemDate = DateTime.parse(itemDateStr.split(' ')[0]);
                      return itemDate.year == selectedDate.year &&
                             itemDate.month == selectedDate.month &&
                             itemDate.day == selectedDate.day;
                    } catch (_) {
                      return false;
                    }
                  }).toList();

                  if (filteredData.isEmpty) {
                    return const Center(child: Text("No daily data available for selected date"));
                  }

                  return ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final data = filteredData[index];
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
                                            DateFormatter.formatDateOnly(data["date"]),
                                            style: const TextStyle(fontSize: 16,
                                                color: Colors.black87),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.flag,
                                            color: data["attendance"] ? Colors.green : AppColors.primary,
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
                                        data["totalCalls"]!,
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
                                        data["productiveCalls"]!,
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
                  );
                }(),
              ),
            ],
          ),
        );
      },
    );
  }



  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      final monthStr = "${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
      if (mounted) {
        Provider.of<ProductivityProvider>(context, listen: false).fetchCallsInfo(
          month: monthStr,
        );
      }
    }
  }
}
