import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import 'distribution_list_provider.dart';

class StockOnHandScreen extends StatefulWidget {
  const StockOnHandScreen({super.key});

  @override
  State<StockOnHandScreen> createState() => _StockOnHandScreenState();
}

class _StockOnHandScreenState extends State<StockOnHandScreen> {
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

      body: Padding(
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

            GestureDetector(
              onTap: () {
                _showProductPopup(context, provider);
              },
              child: Container(
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
                child: const Text(
                  "SUBMISSION ON 22-Apr-2026",
                  style: TextStyle(fontWeight: FontWeight.w500),
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

  void _showProductPopup(BuildContext context, DistributionListProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "PRODUCT LIST",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                ...provider.stockOnHandProducts.map((product) {
                  return _productRow(product["name"]!, product["qty"]!);
                }).toList(),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CLOSE",
                      style: TextStyle(color: AppColors.primary),
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

  Widget _productRow(String name, String qty) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name)),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text("QTY: $qty"),
          ),
        ],
      ),
    );
  }
}