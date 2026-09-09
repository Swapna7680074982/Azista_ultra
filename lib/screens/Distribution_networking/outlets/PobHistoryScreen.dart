import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        Provider.of<OutletActivityProvider>(context, listen: false)
            .fetchPobHistory(widget.outletId, distributorId: appState.selectedDistributorId);
      }
    });
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
    }
  }

  DateTime? _parseDate(String dateStr) {
    final cleaned = dateStr.trim();
    DateTime? dt = DateTime.tryParse(cleaned);
    if (dt == null) {
      try {
        dt = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleaned);
      } catch (_) {
        try {
          dt = DateFormat("yyyy-MM-dd").parse(cleaned);
        } catch (_) {
          try {
            dt = DateFormat("dd-MM-yyyy HH:mm:ss").parse(cleaned);
          } catch (_) {
            try {
              dt = DateFormat("dd-MM-yyyy").parse(cleaned);
            } catch (_) {}
          }
        }
      }
    }
    return dt;
  }

  bool _isInSelectedMonth(dynamic pob) {
    final dateStr = pob['created_at'] ?? pob['created_on'];
    if (dateStr == null) return false;
    final dt = _parseDate(dateStr.toString());
    if (dt == null) return false;
    return dt.year == selectedDate.year &&
           dt.month == selectedDate.month &&
           dt.day == selectedDate.day;
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

  int selectedTab = 0; // 0: ALL, 1: PENDING, 2: SUPPLIED
  String selectedTypeFilter = "ALL"; // "ALL", "REGULAR", "TELE"

  bool _isTelePob(dynamic pob) {
    if (pob is! Map) return false;

    final pobType = pob['pob_type']?.toString().toLowerCase() ?? '';
    if (pobType.contains('tele')) return true;

    final type = pob['type']?.toString().toLowerCase() ?? '';
    if (type.contains('tele')) return true;

    final orderType = pob['order_type']?.toString().toLowerCase() ?? '';
    if (orderType.contains('tele')) return true;

    if (pob['is_tele'] == true || pob['is_tele'] == 1 || pob['is_tele'] == '1' || pob['is_tele'] == 'true') return true;
    if (pob['is_tele_pob'] == true || pob['is_tele_pob'] == 1 || pob['is_tele_pob'] == '1' || pob['is_tele_pob'] == 'true') return true;

    final pobNumber = pob['pob_number']?.toString().toUpperCase() ?? '';
    if (pobNumber.contains('TELE')) return true;

    final remarks = pob['remarks']?.toString().toLowerCase() ?? '';
    if (remarks.contains('tele')) return true;

    return false;
  }

  Widget _buildPobTypeBadge(dynamic pob) {
    final isTele = _isTelePob(pob);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isTele ? Colors.purple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isTele ? Colors.purple.shade300 : Colors.blue.shade300,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTele ? Icons.phone_in_talk : Icons.storefront,
            size: 11,
            color: isTele ? Colors.purple.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isTele ? "TELE POB" : "REGULAR POB",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTele ? Colors.purple.shade800 : Colors.blue.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bg = Colors.orange.shade50;
    Color border = Colors.orange.shade200;
    Color text = Colors.orange.shade800;
    String label = "PENDING";

    if (s == 'supplied' || s == 'completed') {
      bg = Colors.green.shade50;
      border = Colors.green.shade200;
      text = Colors.green.shade800;
      label = "SUPPLIED";
    } else if (s == 'partial') {
      bg = Colors.blue.shade50;
      border = Colors.blue.shade200;
      text = Colors.blue.shade800;
      label = "PARTIAL";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String type, String label) {
    final isSelected = selectedTypeFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTypeFilter = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.button : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.button : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _tabItem(0, "All POBs"),
          _tabItem(1, "Pending"),
          _tabItem(2, "Supplied"),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String title) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _applyTypeFilter(List<dynamic> list) {
    if (selectedTypeFilter == "ALL") return list;
    if (selectedTypeFilter == "TELE") {
      return list.where((pob) => _isTelePob(pob)).toList();
    }
    return list.where((pob) => !_isTelePob(pob)).toList();
  }

  Widget _buildPobCard(dynamic pob) {
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

    if (totalAmount == 0.0) {
      final fallbackAmt = pob['ptr_incl_gst_total_amount'] ?? pob['total_amount'] ?? pob['order_value'] ?? pob['total_value'] ?? 0.0;
      totalAmount = double.tryParse(fallbackAmt.toString()) ?? 0.0;
    }

    final pobNumber = pob['pob_number']?.toString() ?? 'N/A';
    final dateStr = pob['created_at'] ?? pob['created_on'];
    final status = pob['status']?.toString() ?? 'pending';
    final isSupplied = status.toLowerCase() == 'supplied' || status.toLowerCase() == 'completed';

    return GestureDetector(
      onTap: () async {
        if (!isSupplied) {
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
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SuppliedProductListScreen(pobData: pob),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          "POB: $pobNumber",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPobTypeBadge(pob),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "₹${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  "Date: ${DateFormatter.formatDateTime(dateStr)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const Spacer(),
                _buildStatusBadge(status),
              ],
            ),
            if (!isSupplied) ...[
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
            if (pob['order_copy_url'] != null && pob['order_copy_url'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _viewAttachment(context, pob['order_copy_url']),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: pob['order_copy_url'].toString().toLowerCase().endsWith('.pdf')
                        ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 26)
                        : Image.network(
                            pob['order_copy_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 26),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> list, String emptyMessage) {
    final filtered = _applyTypeFilter(list);
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            emptyMessage,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildPobCard(filtered[index]);
      },
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

          return Column(
            children: [
              GestureDetector(
                onTap: () => _selectMonth(context),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                        DateFormat('dd MMMM yyyy').format(selectedDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const Icon(Icons.calendar_month, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              // Type filter chips (ALL, REGULAR, TELE)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    _buildTypeFilterChip("ALL", "ALL POBS"),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip("REGULAR", "REGULAR POB"),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip("TELE", "TELE POB"),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _tabs(),
              const SizedBox(height: 6),
              Expanded(
                child: selectedTab == 0
                    ? _buildList(allFiltered, "No POBs found for this month")
                    : selectedTab == 1
                        ? _buildList(filteredPending, "No pending POBs for this month")
                        : _buildList(filteredSupplied, "No supplied POBs for this month"),
              ),
            ],
          );
        },
      ),
    );
  }
}