import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'DistributorExpensesScreen.dart';
import 'DistributorVisitScreen.dart';
import 'StockOnHandScreen.dart';
import 'package:provider/provider.dart';
import 'distribution_list_provider.dart';
class DistributorStockScreen extends StatelessWidget {
  const DistributorStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DistributionListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade200,

      appBar: AppBar(
        title: const Text(
          "Distributor Stock",
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StockOnHandScreen(),
                ),
              );
            },
            icon: const Icon(Icons.menu_book),
          ),
          const SizedBox(width: 15),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DistributorExpensesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.currency_rupee),
          ),
          const SizedBox(width: 15),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DistributorVisitScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_tree_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          ...provider.distributorStockSections.entries.map((entry) {
            return _buildSection(entry.key, entry.value);
          }).toList(),

          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "SUBMIT DISTRIBUTOR STOCK",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
        );
      },
    );
  }
  Widget _buildSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 6),

          ...items.map((item) => _buildRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),

          SizedBox(
            width: 60,
            height: 30,
            child: TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),

                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}