import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import '../../../permissions/AppStateProvider.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';
import '../../../utilities/date_formatter.dart';

class StockSalePosScreen extends StatefulWidget {
  final int outletId;
  const StockSalePosScreen({super.key, required this.outletId});

  @override
  State<StockSalePosScreen> createState() => _StockSalePosScreenState();
}

class _StockSalePosScreenState extends State<StockSalePosScreen> {
  int selectedTab = 0;

  final tabs = ["STOCK", "SALE", "POB"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _tabs(),
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
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 3)],
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