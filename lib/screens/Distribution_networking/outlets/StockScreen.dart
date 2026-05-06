import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../constants/app_colors.dart';
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
      Provider.of<OutletActivityProvider>(context, listen: false)
          .fetchProductsWithSkus();
    });
  }

  @override
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
                    margin: const EdgeInsets.symmetric(vertical: 10),
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
                        final distributorId = appState.selectedDistributorId ?? 6;

                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Submitting Stock...')),
                        );

                        final result = await provider.submitPosTransaction("stock", widget.outletId, distributorId);

                        if (!context.mounted) return;
                        
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (result != null && result['status'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(result['message'] ?? 'Stock submitted successfully!'), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text(result?['message'] ?? 'Failed to submit stock'), backgroundColor: Colors.red),
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

    return ProductCard(
      title: title,
      children: skus.map((sku) => _buildSkuRow(productId, sku, provider)).toList(),
    );
  }

  Widget _buildSkuRow(int productId, dynamic sku, OutletActivityProvider provider) {
    final skuName = sku['sku_displayname'] ?? 'Unknown SKU';
    final skuId = sku['sku_id'];
    final currentQty = provider.stockQuantities["${productId}_$skuId"]?.toString() ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skuName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          QtyBox(
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