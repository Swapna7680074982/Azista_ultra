import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'DistributorExpensesScreen.dart';
import 'StockOnHandScreen.dart';

class DistributorStockScreen extends StatelessWidget {
  const DistributorStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.account_tree_outlined),
          const SizedBox(width: 10),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          _buildSection("Kwik Mint", [
            "Burst (Boxes)",
            "1X 44'S (1X 2'S) (Boxes)",
            "BURST'S CASSETS(10 X 20S) (Pcs)",
            "PREMIUM STRONG CASSET 20",
            "KWIK MINT STRONG CASSETS(10 X 20'S)",
            "KWIK MINT BURST",
          ]),
          _buildSection("Menthopas", [
            "3 PATCHES POUCHES (Pcs)",
          ]),
          _buildSection("Sparkel", [
            "FACIAL MASK (Pcs)",
            "GLOW FACIAL MASK (Pcs)",
            "YOUTH FACIAL MASK (Pcs)",
          ]),
          _buildSection("Spice Sip", [
            "(1X6) (Boxes)",
          ]),
          _buildSection("Taste Good", [
            "KARELA BISCUIT 100G (Boxes)",
          ]),

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