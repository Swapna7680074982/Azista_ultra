import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'DistributorExpensesScreen.dart';
import 'DistributorVisitScreen.dart';
import 'StockOnHandScreen.dart';
import 'package:provider/provider.dart';
import 'distribution_list_provider.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../utilities/common_widgets.dart';

class DistributorStockScreen extends StatefulWidget {
  const DistributorStockScreen({super.key});

  @override
  State<DistributorStockScreen> createState() => _DistributorStockScreenState();
}

class _DistributorStockScreenState extends State<DistributorStockScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DistributionListProvider>(context, listen: false)
          .fetchProductsWithSkus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Consumer<DistributionListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            title: const Text(
              "DISTRIBUTOR STOCK",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
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
              // IconButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const DistributorVisitScreen(),
              //       ),
              //     );
              //   },
              //   icon: const Icon(Icons.account_tree_outlined, color: Colors.white),
              // ),
              const SizedBox(width: 10),
            ],
          ),
          body: provider.isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(10),
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
                        onPressed: () async {
                          if (appState.selectedDistributorId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No distributor selected"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final success = await provider.submitDistributorStock(
                              appState.selectedDistributorId!);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? "Stock submitted successfully"
                                    : "Failed to submit stock or no stock entered"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
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
      },
    );
  }

  Widget _buildProductSection(dynamic product, DistributionListProvider provider) {
    final title = product['product_name'] ?? 'Unknown Product';
    final skus = product['skus'] as List<dynamic>? ?? [];
    final productId = product['product_id'];

    if (skus.isEmpty) return const SizedBox.shrink();

    return ProductCard(
      title: title,
      children: skus.map((sku) => _buildSkuRow(productId, sku, provider)).toList(),
    );
  }

  Widget _buildSkuRow(int productId, dynamic sku, DistributionListProvider provider) {
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
