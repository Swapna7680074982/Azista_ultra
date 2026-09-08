import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import '../../../permissions/AppStateProvider.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';
import '../../../utilities/date_formatter.dart';
import '../../../utilities/common_widgets.dart';

class StockSalePosScreen extends StatefulWidget {
  final int outletId;
  const StockSalePosScreen({super.key, required this.outletId});

  @override
  State<StockSalePosScreen> createState() => _StockSalePosScreenState();
}

class _StockSalePosScreenState extends State<StockSalePosScreen> {
  int selectedTab = 0;
  DateTime selectedDate = DateTime.now();

  final tabs = ["STOCK", "SALE", "POB"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.white),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _tabs(),
          _monthYearFilter(),
          Expanded(child: _tabContent()),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedTab == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedTab = index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
  Widget _tabContent() {
    switch (selectedTab) {
      case 0:
        return _posHistoryTab("stock");
      case 1:
        return _posHistoryTab("sale");
      case 2:
        return _pobHistoryTab();
      default:
        return Container();
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
            
            return GestureDetector(
              onTap: () => _showProductPopup(context, items, title: "POB: ${pob['pob_number']}"),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 3)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "SUBMISSION ON ${DateFormatter.formatDateTime(date)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (pob['order_copy_url'] != null && pob['order_copy_url'].toString().isNotEmpty) ...[
                      const SizedBox(width: 10),
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
                    ]
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
