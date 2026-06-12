import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';

import '../../../constants/app_colors.dart';
import '../../../services/api_services.dart';
import 'package:flutter/services.dart';
import '../../../utilities/common_widgets.dart';

class ProductListScreen extends StatefulWidget {
  final dynamic pobData;
  const ProductListScreen({super.key, this.pobData});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final Map<int, String> _supplyQuantities = {};
  final Map<int, TextEditingController> _controllers = {};
  List<dynamic> _currentItems = [];

  @override
  void initState() {
    super.initState();
    final allItems = widget.pobData?['items'] as List<dynamic>? ?? [];
    _currentItems = allItems.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentItems.where((item) {
      final remaining = int.tryParse(item['remaining_qty']?.toString() ?? "0") ?? 0;
      return remaining > 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pobData?['pob_number'] ?? "Product List",
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _productItem(index, items[index]);
                },
              ),
            ),
            const SizedBox(height: 10),
            _submitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _productItem(int index, dynamic item) {
    final title = "${item['product_name']} - ${item['sku_displayname']}";
    final raisedQty = item['quantity']?.toString() ?? "0";
    final suppliedQty = item['supplied_qty']?.toString() ?? "0";
    final remainingQty = item['remaining_qty']?.toString() ?? "0";
    final remainingVal = int.tryParse(remainingQty) ?? 0;
    final controller = _controllers.putIfAbsent(index, () => TextEditingController());

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
          const SizedBox(height: 5),
          Text("Supplied: $suppliedQty | Remaining: $remainingQty", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        final qty = int.tryParse(val) ?? 0;
                        if (qty > remainingVal) {
                          controller.text = remainingVal.toString();
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          _supplyQuantities[index] = remainingVal.toString();
                          return;
                        }
                      }
                      _supplyQuantities[index] = val;
                    },
                    decoration: const InputDecoration(
                      hintText: "Supply Qty",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        onPressed: () async {
          final items = _currentItems.where((item) {
            final remaining = int.tryParse(item['remaining_qty']?.toString() ?? "0") ?? 0;
            return remaining > 0;
          }).toList();
          List<Map<String, dynamic>> payloadItems = [];

          for (int i = 0; i < items.length; i++) {
            final supplyStr = _supplyQuantities[i];
            if (supplyStr != null && supplyStr.isNotEmpty) {
              final qty = int.tryParse(supplyStr) ?? 0;
              final remaining = int.tryParse(items[i]['remaining_qty']?.toString() ?? "0") ?? 0;
              if (qty > remaining) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Quantity for ${items[i]['product_name']} cannot exceed remaining quantity ($remaining)"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (qty > 0) {
                payloadItems.add({
                  "product_id": items[i]['product_id'] is String ? int.tryParse(items[i]['product_id']) : items[i]['product_id'],
                  "sku_id": items[i]['sku_id'] is String ? int.tryParse(items[i]['sku_id']) : items[i]['sku_id'],
                  "quantity": qty,
                });
              }
            }
          }

          if (payloadItems.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please enter supply quantities for at least one item.")),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Supplying POB...")),
          );

          final payload = {
            "pob_id": widget.pobData?['pob_id'] is String ? int.tryParse(widget.pobData!['pob_id']) : widget.pobData?['pob_id'],
            "remarks": "",
            "items": payloadItems,
          };

          final response = await ApiServices.supplyPob(payload: payload);
          if (mounted) {
            if (response != null && response['status'] == 'success') {
              final statusMsg = response['pob_status'] == 'supplied' ? 'Fully Supplied' : 'Partially Supplied';
              SuccessDialog.show(
                context,
                message: "${response['message'] ?? 'POB Supplied successfully!'} - $statusMsg",
                onDismiss: () {
                  Navigator.pop(context, true);
                },
              );

              setState(() {
                for (int i = 0; i < items.length; i++) {
                  final supplyStr = _supplyQuantities[i];
                  if (supplyStr != null && supplyStr.isNotEmpty) {
                    final qty = int.tryParse(supplyStr) ?? 0;
                    if (qty > 0) {
                      final remaining = int.tryParse(items[i]['remaining_qty']?.toString() ?? "0") ?? 0;
                      final supplied = int.tryParse(items[i]['supplied_qty']?.toString() ?? "0") ?? 0;
                      items[i]['remaining_qty'] = (remaining - qty).toString();
                      items[i]['supplied_qty'] = (supplied + qty).toString();
                    }
                  }
                }
                for (var controller in _controllers.values) {
                  controller.clear();
                }
                _supplyQuantities.clear();
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to supply POB")),
              );
            }
          }
        },
        child: const Text(
          "SUBMIT",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
      ),
    );
  }
}