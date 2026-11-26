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
      appBar: AppBar(
        title: Text(
          pobData?['pob_number'] ?? "Supplied product list",
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
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
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.white),
            tooltip: "Refresh",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Supplied products refreshed"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
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

    final bool isFocusedBrand = item['focused_brand'] == true ||
        item['focused_brand'] == 1 ||
        item['focused_brand'] == '1' ||
        item['focused_brand'] == 'true' ||
        item['is_focused_brand'] == true ||
        item['is_focus'] == true ||
        item['focus_brand'] == true ||
        (title.toUpperCase().contains('DASUTRA'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFocusedBrand ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFocusedBrand ? Colors.green.shade500 : Colors.grey.shade300,
          width: isFocusedBrand ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFocusedBrand ? const Color(0xFF1B5E20) : Colors.black87,
                  ),
                ),
              ),
              if (isFocusedBrand)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "FOCUSED BRAND",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFocusedBrand ? const Color(0xFFA5D6A7) : const Color(0xFFB0B8D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "RAISED QTY: $raisedQty",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isFocusedBrand ? FontWeight.bold : FontWeight.normal,
                      color: isFocusedBrand ? const Color(0xFF1B5E20) : Colors.black87,
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
                    color: isFocusedBrand ? const Color(0xFFC8E6C9) : const Color(0xFFB0B8D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "SUPPLIED: $suppliedQty",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isFocusedBrand ? FontWeight.bold : FontWeight.normal,
                      color: isFocusedBrand ? const Color(0xFF1B5E20) : Colors.black87,
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