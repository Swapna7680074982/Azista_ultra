import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';

import 'package:provider/provider.dart';
import '../../../permissions/AppStateProvider.dart';
import 'outlet_activity_provider.dart';
import '../../../utilities/date_formatter.dart';
import '../../../utilities/common_widgets.dart';

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
      Provider.of<OutletActivityProvider>(context, listen: false)
          .fetchPobHistory(widget.outletId, distributorId: appState.selectedDistributorId);
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

  void _viewAttachment(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.85),
            ),
            Center(
              child: InteractiveViewer(
                maxScale: 4.0,
                child: url.toLowerCase().endsWith('.pdf')
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 80),
                          const SizedBox(height: 10),
                          Text(
                            url.split('/').last,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Image.network(
                        url,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
                      ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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
          if (provider.isLoadingPobHistory) {
            return const Center(child: LogoProgressIndicator());
          }
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
            final amt = pob['ptr_incl_gst_total_amount'] ?? pob['total_amount'] ?? pob['order_value'] ?? pob['total_value'] ?? 0.0;
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
        final items = pob['items'] as List<dynamic>? ?? [];
        double totalAmount = 0.0;
        double suppliedAmount = 0.0;
        double remainingAmount = 0.0;
        for (var item in items) {
          final price = double.tryParse(item['ptr_incl_gst_price']?.toString() ?? item['sku_retailerprice']?.toString() ?? item['price']?.toString() ?? '0.0') ?? 0.0;
          final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          final suppliedQty = int.tryParse(item['supplied_qty']?.toString() ?? '0') ?? 0;
          final remainingQty = int.tryParse(item['remaining_qty']?.toString() ?? '0') ?? 0;
          
          totalAmount += qty * price;
          suppliedAmount += suppliedQty * price;
          remainingAmount += remainingQty * price;
        }

        return GestureDetector(
          onTap: () async {
            final appState = Provider.of<AppStateProvider>(context, listen: false);
            final provider = Provider.of<OutletActivityProvider>(context, listen: false);
            final distributorId = appState.selectedDistributorId;
            final outletId = widget.outletId;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListScreen(pobData: pob),
              ),
            );
            if (result == true) {
              provider.fetchPobHistory(outletId, distributorId: distributorId);
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                            "₹${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("Date: ${DateFormatter.formatDateTime(pob['created_at'] ?? pob['created_on'])}"),
                      Text("Status: ${pob['status'] ?? 'N/A'}"),
                      const SizedBox(height: 6),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Supplied: ₹${suppliedAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "Remaining: ₹${remainingAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (pob['order_copy_url'] != null && pob['order_copy_url'].toString().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _viewAttachment(context, pob['order_copy_url']),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: pob['order_copy_url'].toString().toLowerCase().endsWith('.pdf')
                            ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30)
                            : Image.network(
                                pob['order_copy_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30),
                              ),
                      ),
                    ),
                  ),
                ],
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
        final items = pob['items'] as List<dynamic>? ?? [];
        double totalAmount = 0.0;
        for (var item in items) {
          final price = double.tryParse(item['ptr_incl_gst_price']?.toString() ?? item['sku_retailerprice']?.toString() ?? item['price']?.toString() ?? '0.0') ?? 0.0;
          final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
          totalAmount += qty * price;
        }

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                            "₹${totalAmount.toStringAsFixed(2)}",
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
                if (pob['order_copy_url'] != null && pob['order_copy_url'].toString().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _viewAttachment(context, pob['order_copy_url']),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: pob['order_copy_url'].toString().toLowerCase().endsWith('.pdf')
                            ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30)
                            : Image.network(
                                pob['order_copy_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}