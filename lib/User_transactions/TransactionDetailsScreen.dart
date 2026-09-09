import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../utilities/wavy_app_bar.dart';
import '../utilities/common_widgets.dart';
import 'SaleItem.dart';
import '../services/api_services.dart';
import '../permissions/AppStateProvider.dart';
import '../utilities/date_formatter.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final int outletId;
  const TransactionDetailsScreen({super.key, required this.outletId});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends State<TransactionDetailsScreen> {

  int selectedTab = 0;
  DateTime selectedDate = DateTime.now();

  final List<String> tabs = ["SALE", "STOCK", "POB"];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: const WavyAppBar(
        title: "Transaction Details",
      ),
      body: Column(
        children: [

          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: List.generate(tabs.length, (index) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedTab == index
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: selectedTab == index
                                ? Colors.red
                                : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          _monthYearFilter(),
          Expanded(
            child: () {
              if (selectedTab == 0) return _posHistoryTab("sale");
              if (selectedTab == 1) return _posHistoryTab("stock");
              return _pobHistoryTab();
            }(),
          ),
        ],
      ),
    );
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

  Widget _pobHistoryTab() {
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final Map<String, dynamic> payload = {
      "outlet_id": widget.outletId,
      "from_date": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-01",
      "to_date": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}",
    };
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiServices.getPobHistory(payload: payload),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LogoProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
          return const Center(child: Text("No POB History"));
        }
        final data = snapshot.data!['data'] as List<dynamic>? ?? [];
        
        final filteredData = data.where((item) {
          final rawDate = item['created_at'] ?? item['created_on'];
          if (rawDate == null) return false;
          try {
            final date = DateTime.parse(rawDate.toString().trim());
            return date.year == selectedDate.year &&
                   date.month == selectedDate.month &&
                   date.day == selectedDate.day;
          } catch (e) {
            return false;
          }
        }).toList();
        
        if (filteredData.isEmpty) {
          return const Center(child: Text("No POB History"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final pob = filteredData[index];
            final items = pob['items'] as List<dynamic>? ?? [];
            final date = pob['created_at'] ?? pob['created_on'];
            final pobNumber = pob['pob_number']?.toString() ?? 'N/A';
            final status = pob['status']?.toString() ?? 'pending';

            double totalAmount = 0.0;
            for (var item in items) {
              final price = double.tryParse(item['ptr_incl_gst_price']?.toString() ?? item['sku_retailerprice']?.toString() ?? item['price']?.toString() ?? '0.0') ?? 0.0;
              final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
              totalAmount += qty * price;
            }
            if (totalAmount == 0.0) {
              final fallbackAmt = pob['ptr_incl_gst_total_amount'] ?? pob['total_amount'] ?? pob['order_value'] ?? pob['total_value'] ?? 0.0;
              totalAmount = double.tryParse(fallbackAmt.toString()) ?? 0.0;
            }
            
            return GestureDetector(
              onTap: () => _showProductPopup(context, items, title: "POB: $pobNumber"),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                        if (totalAmount > 0)
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
                          "Date: ${DateFormatter.formatDateTime(date)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        _buildStatusBadge(status),
                      ],
                    ),
                    if (pob['order_copy_url'] != null && pob['order_copy_url'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _viewAttachment(context, pob['order_copy_url']),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: pob['order_copy_url'].toString().toLowerCase().endsWith('.pdf')
                                ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24)
                                : Image.network(
                                    pob['order_copy_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
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
      },
    );
  }

  Widget _posHistoryTab(String posType) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final distributorId = appState.selectedDistributorId ?? 6;
    
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final Map<String, dynamic> payload = {
      "outlet_id": widget.outletId,
      "distributor_id": distributorId,
      "pos_type": posType,
      "from_date": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-01",
      "to_date": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}",
    };
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiServices.getPosHistory(payload: payload),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LogoProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
          return Center(child: Text("No ${posType.toUpperCase()} History"));
        }
        final data = snapshot.data!['data'] as List<dynamic>? ?? [];
        
        final filteredData = data.where((item) {
          final rawDate = item['created_on'] ?? item['created_at'];
          if (rawDate == null) return false;
          try {
            final date = DateTime.parse(rawDate.toString().trim());
            return date.year == selectedDate.year &&
                   date.month == selectedDate.month &&
                   date.day == selectedDate.day;
          } catch (e) {
            return false;
          }
        }).toList();
        
        if (filteredData.isEmpty) {
          return Center(child: Text("No ${posType.toUpperCase()} History"));
        }

        // Group by date
        final Map<String, List<dynamic>> grouped = {};
        for (var item in filteredData) {
          final rawDate = item['created_on'] ?? item['created_at'];
          if (rawDate != null) {
             final formattedDate = DateFormatter.formatDateTime(rawDate);
             if (!grouped.containsKey(formattedDate)) {
               grouped[formattedDate] = [];
             }
             grouped[formattedDate]!.add(item);
          }
        }

        final dates = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final items = grouped[date]!;
            
            return GestureDetector(
              onTap: () => _showProductPopup(context, items, title: "${posType.toUpperCase()} DETAILS"),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Text(
                  "SUBMISSION ON $date",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductPopup(BuildContext context, List<dynamic> items, {String? title}) {
    // Group by product name
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String name = item['product_name'] ?? "Product ID: ${item['product_id'] ?? 'N/A'}";
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(item);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    title ?? "PRODUCT LIST",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...entry.value.map((item) {
                              String qty = item['quantity']?.toString() ?? '0';
                              String sku = item['sku_name'] ?? item['sku_displayname'] ?? item['sku_id']?.toString() ?? 'N/A';
                              return _skuRow(sku, qty);
                            }).toList(),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:  Text(
                      "CLOSE",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _monthYearFilter() {
    final dateText = DateFormat('dd MMMM yyyy').format(selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: GestureDetector(
        onTap: () => _selectMonth(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                dateText.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
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
    }
  }

  Widget _skuRow(String sku, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              sku,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            width: 70,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              qty,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
