import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
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

  final List<String> tabs = ["SALE", "STOCK", "POB"];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Transaction Details",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
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

  Widget _pobHistoryTab() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final distributorId = appState.selectedDistributorId ?? 6;
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiServices.getPobHistory(payload: {
        "outlet_id": widget.outletId,
        "distributor_id": distributorId,
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
          return const Center(child: Text("No POB History"));
        }
        final data = snapshot.data!['data'] as List<dynamic>? ?? [];
        if (data.isEmpty) {
          return const Center(child: Text("No POB History"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final pob = data[index];
            final items = pob['items'] as List<dynamic>? ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 3)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("POB NUMBER: ${pob['pob_number'] ?? 'N/A'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  //Text("Total Amount: \$${pob['total_amount'] ?? '0.00'}"),
                  Text("Date: ${DateFormatter.formatDateTime(pob['created_at'])}"),
                  Text("Status: ${pob['status'] ?? 'N/A'}"),
                  if (items.isNotEmpty) ...[
                    const Divider(),
                    ...items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "- ${item['product_name']} (${item['sku_displayname']}): Qty ${item['quantity']}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ],
                ],
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
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiServices.getPosHistory(payload: {
        "outlet_id": widget.outletId,
        "distributor_id": distributorId,
        "pos_type": posType,
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?['status'] != 'success') {
          return Center(child: Text("No ${posType.toUpperCase()} History"));
        }
        final data = snapshot.data!['data'] as List<dynamic>? ?? [];
        if (data.isEmpty) {
          return Center(child: Text("No ${posType.toUpperCase()} History"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['product_name'] ?? "Product ID: ${item['product_id'] ?? 'N/A'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("SKU: ${item['sku_name'] ?? item['sku_displayname'] ?? item['sku_id'] ?? 'N/A'}"),
                  Text("Quantity: ${item['quantity'] ?? '0'}"),
                   Text("Date: ${DateFormatter.formatDateTime(item['created_on'] ?? item['created_at'])}"),
                ],
              ),
            );
          },
        );
      },
    );
  }
}