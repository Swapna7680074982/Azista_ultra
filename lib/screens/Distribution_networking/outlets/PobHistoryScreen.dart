import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';

import 'package:provider/provider.dart';
import '../../../permissions/AppStateProvider.dart';
import 'outlet_activity_provider.dart';
import '../../../utilities/date_formatter.dart';

class PobHistoryScreen extends StatefulWidget {
  final int outletId;
  const PobHistoryScreen({super.key, required this.outletId});

  @override
  State<PobHistoryScreen> createState() => _PobHistoryScreenState();
}

class _PobHistoryScreenState extends State<PobHistoryScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedDistributorId != null) {
        Provider.of<OutletActivityProvider>(context, listen: false)
            .fetchPobHistory(widget.outletId, appState.selectedDistributorId!);
      }
    });
  }

  String _getMonthName(int month, int year) {
    final months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${months[month - 1]} $year";
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear, selectedMonth, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedMonth = picked.month;
        selectedYear = picked.year;
      });
    }
  }

  bool _isInSelectedMonth(dynamic pob) {
    final dateStr = pob['created_at'] ?? pob['created_on'];
    if (dateStr == null) return false;
    try {
      final dt = DateTime.parse(dateStr);
      return dt.month == selectedMonth && dt.year == selectedYear;
    } catch (e) {
      return false;
    }
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "POB History",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
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
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),
      body: Consumer<OutletActivityProvider>(
        builder: (context, provider, child) {
          final filteredPending = provider.pendingPobs.where(_isInSelectedMonth).toList();
          final filteredSupplied = provider.suppliedPobs.where(_isInSelectedMonth).toList();
          final allFiltered = [...filteredPending, ...filteredSupplied];

          final pobCount = allFiltered.length;
          final visits = allFiltered.map((pob) {
            final dtStr = pob['created_at'] ?? pob['created_on'];
            if (dtStr == null) return '';
            try {
              final dt = DateTime.parse(dtStr);
              return "${dt.year}-${dt.month}-${dt.day}";
            } catch (e) {
              return '';
            }
          }).where((element) => element.isNotEmpty).toSet().length;

          final productiveCalls = pobCount;
          final orderValue = allFiltered.fold<double>(0.0, (sum, pob) {
            final amt = pob['total_amount'] ?? pob['order_value'] ?? pob['total_value'] ?? 0.0;
            return sum + (double.tryParse(amt.toString()) ?? 0.0);
          });

          return Column(
            children: [
              GestureDetector(
                onTap: () => _selectMonth(context),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getMonthName(selectedMonth, selectedYear),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const Icon(Icons.calendar_month, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryItem("Visits", "$visits"),
                          _summaryItem("POB Count", "$pobCount"),
                          _summaryItem("Prod. Calls", "$productiveCalls"),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.green, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "Total Order Value: ₹${orderValue.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _tabs(),
              const SizedBox(height: 6),
              Expanded(
                child: selectedTab == 0
                    ? _pendingScreen(filteredPending)
                    : _suppliedScreen(filteredSupplied),
              ),
            ],
          );
        },
      ),
    );
  }
  int selectedTab = 0;

  Widget _tabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedTab = 0);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: selectedTab == 0 ? Colors.white : Colors.grey[300],
              child: Center(
                child: Text(
                  "POB Pendings",
                  style: TextStyle(
                    color: selectedTab == 0 ? AppColors.primary : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedTab = 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: selectedTab == 1 ? Colors.white : Colors.grey[300],
              child: Center(
                child: Text(
                  "POB Supplied",
                  style: TextStyle(
                    color: selectedTab == 1 ? AppColors.primary : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingScreen(List<dynamic> pendingList) {
    if (pendingList.isEmpty) {
      return const Center(child: Text("No pending POBs for this month"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: pendingList.length,
      itemBuilder: (context, index) {
        final pob = pendingList[index];
        final orderVal = pob['total_amount'] ?? pob['order_value'] ?? pob['total_value'] ?? '0.00';

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListScreen(pobData: pob),
              ),
            );
            if (!mounted) return;
            if (result == true) {
              final appState = Provider.of<AppStateProvider>(context, listen: false);
              if (appState.selectedDistributorId != null) {
                Provider.of<OutletActivityProvider>(context, listen: false)
                    .fetchPobHistory(widget.outletId, appState.selectedDistributorId!);
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 3,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "POB NUMBER: ${pob['pob_number'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹$orderVal",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text("Date: ${DateFormatter.formatDateTime(pob['created_at'] ?? pob['created_on'])}"),
                Text("Status: ${pob['status'] ?? 'N/A'}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _suppliedScreen(List<dynamic> suppliedList) {
    if (suppliedList.isEmpty) {
      return const Center(child: Text("No supplied POBs for this month"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: suppliedList.length,
      itemBuilder: (context, index) {
        final pob = suppliedList[index];
        final orderVal = pob['total_amount'] ?? pob['order_value'] ?? pob['total_value'] ?? '0.00';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SuppliedProductListScreen(pobData: pob),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 3,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "POB NUMBER: ${pob['pob_number'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹$orderVal",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text("Date: ${DateFormatter.formatDateTime(pob['created_at'] ?? pob['created_on'])}"),
                Text("Status: ${pob['status'] ?? 'N/A'}"),
              ],
            ),
          ),
        );
      },
    );
  }
}