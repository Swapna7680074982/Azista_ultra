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
        actions: [
          IconButton(
            tooltip: "Refresh Products",
            icon: const Icon(Icons.sync, color: AppColors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Refreshing products..."),
                  duration: Duration(milliseconds: 900),
                ),
              );
              setState(() {});
            },
          ),
          const SizedBox(width: 4),
        ],
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

    final activityProvider = Provider.of<OutletActivityProvider>(context, listen: false);
    final bool isFocusedBrand = activityProvider.isSkuFocused(item['sku_id'], productId: item['product_id']) ||
        item['focused_brand'] == true ||
        item['focused_brand'] == 1 ||
        item['focused_brand'] == '1' ||
        item['focused_brand'] == 'true' ||
        item['is_focused_brand'] == true ||
        item['is_focus'] == true ||
        item['focus_brand'] == true;

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
        boxShadow: isFocusedBrand
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "Supplied: $suppliedQty | Remaining: $remainingQty",
            style: TextStyle(
              fontSize: 11,
              color: isFocusedBrand ? Colors.green.shade800 : Colors.grey,
            ),
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
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                    decoration: InputDecoration(
                      hintText: "Supply Qty",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: isFocusedBrand ? Colors.green.shade600 : Colors.red,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(
                          color: isFocusedBrand ? Colors.green.shade800 : Colors.red,
                          width: 2,
                        ),
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