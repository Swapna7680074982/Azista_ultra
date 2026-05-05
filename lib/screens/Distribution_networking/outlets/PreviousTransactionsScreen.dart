import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import '../../../permissions/AppStateProvider.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';

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
        return _submissionList("Stock");
      case 1:
        return _submissionList("Sale");
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
                  Text("Total Amount: \$${pob['total_amount'] ?? '0.00'}"),
                  Text("Date: ${pob['created_at'] ?? 'N/A'}"),
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

  Widget _submissionList(String type) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: 5,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DummyTransactionProductListScreen(type: type),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Text(
              "SUBMITTION ON 22-Apr-2026",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      },
    );
  }

}

class DummyTransactionProductListScreen extends StatelessWidget {
  final String type;

  const DummyTransactionProductListScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: Text(
          "$type Products",
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.all(10),
        children: const [
          ProductItem(
            name: "KWIK MINT - 1X 44'S (1X 2'S) (BOXES)",
            raisedQty: 8,
            enteredQty: 6,
          ),
          ProductItem(
            name: "KWIK MINT - BURST (BOXES)",
            raisedQty: 10,
            enteredQty: 10,
          ),
          ProductItem(
            name: "CENTER FRESH - MINT (BOXES)",
            raisedQty: 5,
            enteredQty: 3,
          ),
        ],
      ),
    );
  }

}
class ProductItem extends StatelessWidget {
  final String name;
  final int raisedQty;
  final int enteredQty;

  const ProductItem({
    required this.name,
    required this.raisedQty,
    required this.enteredQty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0B8D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "RAISED: $raisedQty",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "$enteredQty",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}