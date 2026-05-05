import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../constants/app_colors.dart';
import 'PobHistoryScreen.dart';
import '../../../permissions/AppStateProvider.dart';

class PobBody extends StatefulWidget {
  final int outletId;
  const PobBody({super.key, required this.outletId});

  @override
  State<PobBody> createState() => _PobBodyState();
}

class _PobBodyState extends State<PobBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<OutletActivityProvider>(context, listen: false);
      provider.fetchProductsWithSkus();
      
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedDistributorId != null) {
        provider.fetchDistributorStock(appState.selectedDistributorId!);
      }
    });
  }
  Widget build(BuildContext context) {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, child) {
        return provider.isLoadingProducts
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  if (provider.productsWithSkus.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No products found"),
                      ),
                    )
                  else
                    ...provider.productsWithSkus.map((product) {
                      return _buildProductSection(product, provider);
                    }).toList(),

                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () async {
                        final appState = Provider.of<AppStateProvider>(context, listen: false);
                        if (appState.selectedDistributorId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No distributor selected")),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Submitting POB...")),
                        );

                        bool success = await provider.submitPob(
                          widget.outletId,
                          appState.selectedDistributorId!,
                        );

                        if (!mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("POB Submitted Successfully!")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to submit POB or no items selected.")),
                          );
                        }
                      },
                      child: const Text(
                        "SUBMIT POB",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PobHistoryScreen(outletId: widget.outletId),
                          ),
                        );
                      },
                      child: const Text(
                        "POS HISTORY",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              );
      },
    );
  }

  Widget _buildProductSection(dynamic product, OutletActivityProvider provider) {
    final title = product['product_name'] ?? 'Unknown Product';
    final skus = product['skus'] as List<dynamic>? ?? [];
    final productId = product['product_id'];

    if (skus.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...skus.map((sku) => _buildSkuRow(productId, sku, provider)).toList(),
        ],
      ),
    );
  }

  Widget _buildSkuRow(int productId, dynamic sku, OutletActivityProvider provider) {
    final skuName = sku['sku_displayname'] ?? 'Unknown SKU';
    final skuId = sku['sku_id'];
    // Red box input value might need a different state map, but we'll use stockQuantities temporarily
    final currentQty = provider.stockQuantities["${productId}_$skuId"]?.toString() ?? "";
    final distStockStr = provider.distributorStock["${productId}_$skuId"]?.toString() ?? "0";
    final distStock = int.tryParse(distStockStr) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skuName,
              style: const TextStyle(fontSize: 13),
            ),
          ),

          _box(currentQty: distStockStr),

          const SizedBox(width: 10),
          _box(red: true, currentQty: currentQty, maxQty: distStock, onChange: (val) {
            provider.updateStockQuantity(productId, skuId, val);
          }),
        ],
      ),
    );
  }

  Widget _box({bool red = false, String currentQty = "", int maxQty = 0, Function(String)? onChange}) {
    if (red) {
      return SizedBox(
        width: 55,
        height: 30,
        child: TextFormField(
          initialValue: currentQty,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CustomMaxNumberFormatter(maxQty),
          ],
          onChanged: onChange,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 55,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        currentQty.isEmpty ? "0" : currentQty,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class CustomMaxNumberFormatter extends TextInputFormatter {
  final int max;

  CustomMaxNumberFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }
    if (value > max) {
      final maxStr = max.toString();
      return TextEditingValue(
        text: maxStr,
        selection: TextSelection.collapsed(offset: maxStr.length),
      );
    }
    return newValue;
  }
}