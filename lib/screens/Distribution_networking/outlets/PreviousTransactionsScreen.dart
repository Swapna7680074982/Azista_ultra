import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class StockSalePosScreen extends StatefulWidget {
  const StockSalePosScreen({super.key});

  @override
  State<StockSalePosScreen> createState() => _StockSalePosScreenState();
}

class _StockSalePosScreenState extends State<StockSalePosScreen> {
  int selectedTab = 0;

  final tabs = ["STOCK", "SALE", "POS"];

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
        return _submissionList("POS");
      default:
        return Container();
    }
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
                builder: (context) => ProductListScreen(type: type),
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

class ProductListScreen extends StatelessWidget {
  final String type;

  const ProductListScreen({super.key, required this.type});

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
          _productItem(
            name: "KWIK MINT - 1X 44'S (1X 2'S) (BOXES)",
            raisedQty: 8,
            enteredQty: 6,
          ),
          _productItem(
            name: "KWIK MINT - BURST (BOXES)",
            raisedQty: 10,
            enteredQty: 10,
          ),
          _productItem(
            name: "CENTER FRESH - MINT (BOXES)",
            raisedQty: 5,
            enteredQty: 3,
          ),
        ],
      ),
    );
  }

}
class _productItem extends StatelessWidget {
  final String name;
  final int raisedQty;
  final int enteredQty;

  const _productItem({
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