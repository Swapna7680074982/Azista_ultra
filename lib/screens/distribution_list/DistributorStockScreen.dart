import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'StockOnHandScreen.dart';
import 'package:provider/provider.dart';
import 'distribution_list_provider.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../utilities/common_widgets.dart';

class SecondaryStockUpdateScreen extends StatefulWidget {
  final int? initialDistributorId;
  final String? initialDistributorName;

  const SecondaryStockUpdateScreen({
    super.key,
    this.initialDistributorId,
    this.initialDistributorName,
  });

  @override
  State<SecondaryStockUpdateScreen> createState() => _SecondaryStockUpdateScreenState();
}

typedef DistributorStockScreen = SecondaryStockUpdateScreen;

class _SecondaryStockUpdateScreenState extends State<SecondaryStockUpdateScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final provider = Provider.of<DistributionListProvider>(context, listen: false);
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      final targetDistId = widget.initialDistributorId ?? appState.selectedDistributorId;
      final targetDistName = widget.initialDistributorName ?? appState.selectedDistributor;

      provider.fetchProductsWithSkus();
      await provider.fetchDistributorsList(
        initialDistributorId: targetDistId,
        initialDistributorName: targetDistName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Consumer<DistributionListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "DISTRIBUTOR STOCK UPDATE",
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
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
              const SizedBox(width: 10),
            ],
          ),
          body: provider.isLoadingProducts || provider.isLoadingDistributors
              ? const LogoProgressIndicator()
              : ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    _buildDistributorSelectionHeader(context, provider),
                    const SizedBox(height: 10),
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
                    // Error banner — shown when API returns an error
                    if (provider.submitStockError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300, width: 1.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.submitStockError!,
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => provider.clearSubmitError(),
                              child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.button,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () async {
                          if (provider.selectedDistributor == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please select a distributor first")),
                            );
                            return;
                          }
                          LoadingDialog.show(context, message: "Submitting Stock...");

                          final success = await provider.submitDistributorStock(
                              appState.selectedDistributorId);

                          if (!mounted) return;
                          LoadingDialog.hide(context);

                          if (success) {
                            provider.clearSubmitError();
                            SuccessDialog.show(context, message: "Stock Submitted Successfully!");
                          }
                          // Error is shown via the banner above — no extra snackbar needed
                        },
                        child: const Text(
                          "SUBMIT STOCK UPDATE",
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

  Widget _buildDistributorSelectionHeader(BuildContext context, DistributionListProvider provider) {
    final now = DateTime.now();
    final monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    final monthName = monthNames[now.month - 1];
    final year = now.year;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "DISTRIBUTOR SELECTION",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                // Month & Year badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        "$monthName $year",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: GestureDetector(
                      onTap: () => _showDistributorSearchBottomSheet(context, provider),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              provider.selectedDistributor != null
                                  ? provider.selectedDistributor['distributor_name'] ?? 'Unknown'
                                  : "Select Distributor",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: provider.selectedDistributor != null
                                      ? Colors.black87
                                      : Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDistributorSearchBottomSheet(
      BuildContext context, DistributionListProvider provider) {
    final searchController = TextEditingController();
    List<dynamic> filteredDistributors = List.from(provider.distributors);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "SELECT DISTRIBUTOR",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onChanged: (val) {
                      setModalState(() {
                        filteredDistributors = provider.distributors
                            .where((d) => (d['distributor_name'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(val.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search Distributor...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  filteredDistributors = List.from(provider.distributors);
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredDistributors.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                "No distributors found",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredDistributors.length,
                            itemBuilder: (context, index) {
                              final dist = filteredDistributors[index];
                              final isSelected = provider.selectedDistributor != null &&
                                  provider.selectedDistributor['distributor_id'] ==
                                      dist['distributor_id'];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(
                                  dist['distributor_name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : Colors.black87,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                                    : null,
                                onTap: () {
                                  provider.selectDistributor(dist);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
