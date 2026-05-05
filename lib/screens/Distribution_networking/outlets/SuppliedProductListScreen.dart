import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class SuppliedProductListScreen extends StatelessWidget {
  final dynamic pobData;
  const SuppliedProductListScreen({super.key, this.pobData});

  @override
  Widget build(BuildContext context) {
    final items = pobData?['items'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          pobData?['pob_number'] ?? "Supplied product list",
          style: const TextStyle(
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _productItem(items[index]);
          },
        ),
      ),
    );
  }

  Widget _productItem(dynamic item) {
    final title = "${item['product_name']} - ${item['sku_displayname']}";
    final raisedQty = item['quantity']?.toString() ?? "0";
    final suppliedQty = item['supplied_qty']?.toString() ?? "0";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  color: const Color(0xFFB0B8D9),
                  child: Text(
                    "RAISED QTY: $raisedQty",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  color: const Color(0xFFB0B8D9),
                  child: Text(
                    "SUPPLIED: $suppliedQty",
                    style: const TextStyle(fontSize: 12),
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