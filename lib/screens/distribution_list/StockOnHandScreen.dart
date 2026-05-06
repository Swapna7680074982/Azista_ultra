import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../permissions/AppStateProvider.dart';
import 'distribution_list_provider.dart';
import '../../../utilities/date_formatter.dart';

class StockOnHandScreen extends StatefulWidget {
  const StockOnHandScreen({super.key});

  @override
  State<StockOnHandScreen> createState() => _StockOnHandScreenState();
}

class _StockOnHandScreenState extends State<StockOnHandScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedDistributorId != null) {
        Provider.of<DistributionListProvider>(context, listen: false)
            .fetchDistributorStock(appState.selectedDistributorId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DistributionListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Stock on hand",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),

      body: provider.isLoadingStock
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "YEAR: 2026",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<String>(
                value: provider.selectedMonth,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: provider.months.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.setSelectedMonth(value);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Below are the list of submitted open stocks",
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 20),

            if (provider.submissions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text("No submissions found")),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.submissions.keys.length,
                  itemBuilder: (context, index) {
                    final date = provider.submissions.keys.elementAt(index);
                    final products = provider.submissions[date]!;
                    
                    return GestureDetector(
                      onTap: () {
                        _showProductPopup(context, products);
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
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Text(
                          "SUBMISSION ON ${DateFormatter.formatDateTime(date)}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        ),
        );
      },
    );
  }

  void _showProductPopup(BuildContext context, List<Map<String, dynamic>> products) {
    // Group products by name
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var p in products) {
      String name = p['product_name'] ?? 'Unknown';
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(p);
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
                const Center(
                  child: Text(
                    "PRODUCT LIST",
                    style: TextStyle(
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
                            ...entry.value.map((sku) {
                              return _skuRow(sku['sku_name'] ?? 'N/A', sku['qty'] ?? '0');
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
