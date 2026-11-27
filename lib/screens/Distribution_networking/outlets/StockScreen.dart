import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../utilities/common_widgets.dart';

class StockBody extends StatefulWidget {
  final int outletId;
  const StockBody({super.key, required this.outletId});

  @override
  State<StockBody> createState() => _StockBodyState();
}

class _StockBodyState extends State<StockBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final provider = Provider.of<OutletActivityProvider>(context, listen: false);
        provider.fetchProductsWithSkus();
        provider.fetchOutletFocusedProducts(widget.outletId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, child) {
        return provider.isLoadingProducts
            ? const Center(child: LogoProgressIndicator())
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
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () async {
                        final appState = Provider.of<AppStateProvider>(context, listen: false);
                        final distributorId = appState.selectedDistributorId;

                        LoadingDialog.show(context, message: "Submitting Stock...");

                        final result = await provider.submitPosTransaction(
                          "stock",
                          widget.outletId,
                          distributorId: distributorId,
                        );

                        if (!context.mounted) return;
                        LoadingDialog.hide(context);

                        if (result != null && result['status'] == true) {
                          SuccessDialog.show(context, message: "Stock Submitted Successfully!");
                          provider.fetchProductsWithSkus();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result?['message'] ?? "Failed to submit Stock")),
                          );
                        }
                      },
                      child: const Text(
                        "SUBMIT STOCK",
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

    final bool isFocused = provider.isProductFocused(productId) ||
        product['focused_brand'] == true ||
        product['focused_brand'] == 1 ||
        product['focused_brand'] == '1' ||
        product['focused_brand'] == 'true' ||
        product['is_focused_brand'] == true ||
        product['is_focus'] == true ||
        product['focus_brand'] == true;

    return Container(
      margin: isFocused ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8) : EdgeInsets.zero,
      decoration: isFocused
          ? BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade400, width: 1.5),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFocused) ...[
                  const FocusedBrandTag(),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isFocused ? const Color(0xFF1B5E20) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...skus.map((sku) => _buildSkuRow(productId, sku, provider, isProductFocused: isFocused)).toList(),
          if (isFocused) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSkuRow(dynamic productId, dynamic sku, OutletActivityProvider provider, {bool isProductFocused = false}) {
    final skuName = sku['sku_displayname'] ?? sku['sku_name'] ?? 'Unknown SKU';
    final skuId = sku['sku_id'];
    final currentQty = provider.stockQuantities["${productId}_$skuId"]?.toString() ?? "";

    final bool isSkuFocused = provider.isSkuFocused(skuId, productId: productId) ||
        sku['focused_brand'] == true ||
        sku['focused_brand'] == 1 ||
        sku['focused_brand'] == '1' ||
        sku['focused_brand'] == 'true' ||
        sku['is_focused_brand'] == true ||
        sku['is_focus'] == true;

    return Container(
      margin: isSkuFocused ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: isSkuFocused
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border(left: BorderSide(color: Colors.green.shade600, width: 3.5)),
            )
          : null,
      child: Row(
        children: [
          if (isSkuFocused) ...[
            const Icon(Icons.star, size: 14, color: Color(0xFF2E7D32)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              skuName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSkuFocused ? FontWeight.bold : FontWeight.w500,
                color: isSkuFocused ? const Color(0xFF1B5E20) : Colors.black87,
              ),
            ),
          ),
          QtyBox(
            isRed: !isSkuFocused,
            isGreen: isSkuFocused,
            initialValue: currentQty,
            onChanged: (value) {
              provider.updateStockQuantity(productId, skuId, value);
            },
          ),
        ],
      ),
    );
  }
}