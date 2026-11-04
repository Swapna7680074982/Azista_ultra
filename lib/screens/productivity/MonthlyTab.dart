import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'productivity_provider.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AppStateProvider.dart';
import '../../utilities/date_formatter.dart';

class MonthlyTab extends StatefulWidget {
  const MonthlyTab({super.key});

  @override
  State<MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<MonthlyTab> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchData();
    });
  }

  void _fetchData() {
    final monthStr = "${_selectedMonth.toString().padLeft(2, '0')}-$_selectedYear";
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    Provider.of<ProductivityProvider>(context, listen: false).fetchCallsInfo(
      month: monthStr,
      distributorId: appState.selectedDistributorId,
    );
  }

  void _changeMonth(int month) {
    if (_selectedMonth == month) return;
    setState(() {
      _selectedMonth = month;
    });
    _fetchData();
  }

  void _changeYear(int year) {
    if (_selectedYear == year) return;
    setState(() {
      _selectedYear = year;
    });
    _fetchData();
  }

  String _monthName(int m) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        if (provider.isMonthlyLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final monthlyList = provider.monthlyData.where((item) {
          final itemDateStr = item["date"]?.toString() ?? "";
          if (itemDateStr.isEmpty || itemDateStr == "-") return true;
          try {
            final itemDate = DateTime.parse(itemDateStr.split(' ')[0]);
            return itemDate.year == _selectedYear && itemDate.month == _selectedMonth;
          } catch (_) {
            return true;
          }
        }).toList();

        // Sort descending by date (most recent first)
        monthlyList.sort((a, b) {
          final strA = a["date"]?.toString() ?? "";
          final strB = b["date"]?.toString() ?? "";
          return strB.compareTo(strA);
        });

        // Compute summary metrics for the month
        int totalTargetCalls = 0;
        int totalProductiveCalls = 0;
        double totalSales = 0.0;

        for (var item in monthlyList) {
          totalTargetCalls += int.tryParse(item["totalCalls"]?.toString() ?? "0") ?? 0;
          totalProductiveCalls += int.tryParse(item["productiveCalls"]?.toString() ?? "0") ?? 0;
          totalSales += double.tryParse(item["sale"]?.toString() ?? "0") ?? 0.0;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Filter (Same as Attendance screen)
              _buildMonthFilter(),
              const SizedBox(height: 12),

              // Monthly Summary Metrics Card
              _buildSummaryHeader(totalTargetCalls, totalProductiveCalls, totalSales),
              const SizedBox(height: 14),

              // Attendance Legend
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.flag, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "ATTENDANCE",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 16, color: Colors.grey.shade300),
                    Row(
                      children: [
                        Icon(Icons.flag, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          "NO ATTENDANCE",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // List of monthly productivity entries
              Expanded(
                child: monthlyList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 52, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "No productivity data available for ${_monthName(_selectedMonth)} $_selectedYear",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: monthlyList.length,
                        itemBuilder: (context, index) {
                          final data = monthlyList[index];
                          final isAttended = data["attendance"] == true;

                          return Card(
                            color: Colors.white,
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Outlet Header
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.storefront_outlined,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "OUTLET NAME",
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              data["outletName"]!.toString().toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(height: 1, thickness: 0.8, color: Color(0xFFF0F0F0)),
                                  const SizedBox(height: 12),

                                  // Date and Sale Row
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
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                DateFormatter.formatDateOnly(data["date"]),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.flag,
                                                color: isAttended ? Colors.green : AppColors.primary,
                                                size: 18,
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
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
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
                                  const SizedBox(height: 12),

                                  // Target Calls and Productive Calls Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "TARGET CALLS",
                                              style: TextStyle(
                                                color: Colors.blue.shade900,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              data["totalCalls"]!,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "PRODUCTIVE CALLS",
                                              style: TextStyle(
                                                color: Colors.green.shade900,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              data["productiveCalls"]!,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
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

  // Month filter dropdown same as Attendance screen with optional year navigation
  Widget _buildMonthFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _monthName(index + 1),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    _changeMonth(val);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 40),
                onPressed: () => _changeYear(_selectedYear - 1),
                tooltip: "Previous Year",
              ),
              Text(
                "$_selectedYear",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 40),
                onPressed: () => _changeYear(_selectedYear + 1),
                tooltip: "Next Year",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(int targetCalls, int productiveCalls, double sales) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.07),
            AppColors.button.withValues(alpha: 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("TARGET CALLS", "$targetCalls", Colors.blue.shade800),
          Container(width: 1, height: 26, color: Colors.grey.shade300),
          _buildSummaryItem("PRODUCTIVE", "$productiveCalls", Colors.green.shade800),
          Container(width: 1, height: 26, color: Colors.grey.shade300),
          _buildSummaryItem("TOTAL SALE", "₹${sales.toStringAsFixed(0)}", AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
