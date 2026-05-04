import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../constants/app_colors.dart';
import 'PobHistoryScreen.dart';

class PobBody extends StatefulWidget {
  const PobBody({super.key});

  @override
  State<PobBody> createState() => _PobBodyState();
}

class _PobBodyState extends State<PobBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OutletActivityProvider>(context, listen: false)
          .fetchProductsWithSkus();
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
                      onPressed: () {},
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
                            builder: (context) => const PobHistoryScreen(),
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

          _box(),

          const SizedBox(width: 10),
          _box(red: true, currentQty: currentQty, onChange: (val) {
            provider.updateStockQuantity(productId, skuId, val);
          }),
        ],
      ),
    );
  }

  Widget _box({bool red = false, String currentQty = "", Function(String)? onChange}) {
    if (red) {
      return SizedBox(
        width: 55,
        height: 30,
        child: TextFormField(
          initialValue: currentQty,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
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
      child: const Text(
        "0",
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}