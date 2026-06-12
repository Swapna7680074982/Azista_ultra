import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import 'StockOnHandScreen.dart';
import 'package:provider/provider.dart';
import 'distribution_list_provider.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../utilities/common_widgets.dart';

class SecondaryStockUpdateScreen extends StatefulWidget {
  const SecondaryStockUpdateScreen({super.key});

  @override
  State<SecondaryStockUpdateScreen> createState() => _SecondaryStockUpdateScreenState();
}

class _SecondaryStockUpdateScreenState extends State<SecondaryStockUpdateScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<DistributionListProvider>(context, listen: false);
      provider.fetchProductsWithSkus();
      provider.fetchDistributorsList();
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
              "SECONDARY STOCK UPDATE",
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
              ? const Center(child: CircularProgressIndicator())
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
                            SuccessDialog.show(context, message: "Stock Submitted Successfully!", onDismiss: () {
                              Navigator.pop(context);
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to submit stock or no stock entered"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
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
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

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
            const Text(
              "DISTRIBUTOR & PERIOD SELECTION",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: provider.selectedDistributor != null
                            ? provider.selectedDistributor['distributor_id']?.toString()
                            : null,
                        hint: const Text("Select Distributor", style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        items: provider.distributors.map<DropdownMenuItem<dynamic>>((dist) {
                          return DropdownMenuItem<dynamic>(
                            value: dist['distributor_id']?.toString(),
                            child: Text(
                              dist['distributor_name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final selected = provider.distributors.firstWhere(
                            (d) => d['distributor_id']?.toString() == val,
                            orElse: () => null,
                          );
                          if (selected != null) {
                            provider.selectDistributor(selected);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () => _showCreateDistributorDialog(context, provider),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text("NEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: provider.selectedStockMonth,
                        items: List.generate(12, (index) {
                          final months = [
                            "January", "February", "March", "April", "May", "June",
                            "July", "August", "September", "October", "November", "December"
                          ];
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(months[index], style: const TextStyle(fontSize: 13)),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) provider.setStockMonth(val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: provider.selectedStockYear,
                        items: years.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString(), style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) provider.setStockYear(val);
                        },
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

  InputDecoration _dialogInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.button, size: 20),
      labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 13),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.button, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  void _showCreateDistributorDialog(BuildContext context, DistributionListProvider provider) {
    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final contactController = TextEditingController();
    final mobileController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.add_business, color: AppColors.button, size: 24),
              const SizedBox(width: 10),
              const Text(
                "CREATE DISTRIBUTOR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.button,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _dialogInputDecoration(
                        labelText: "Distributor Name*",
                        hintText: "e.g. ABC Distributors",
                        prefixIcon: Icons.storefront,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ownerController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _dialogInputDecoration(
                        labelText: "Owner Name*",
                        hintText: "e.g. Ramesh Kumar",
                        prefixIcon: Icons.person,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _dialogInputDecoration(
                        labelText: "Contact Person*",
                        hintText: "e.g. Suresh",
                        prefixIcon: Icons.badge,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mobileController,
                      style: const TextStyle(fontSize: 14),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _dialogInputDecoration(
                        labelText: "Mobile*",
                        hintText: "e.g. 9876543210",
                        prefixIcon: Icons.phone_iphone,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Required";
                        if (v.trim().length != 10) return "Must be 10 digits";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(fontSize: 14),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dialogInputDecoration(
                        labelText: "Email*",
                        hintText: "e.g. abc@gmail.com",
                        prefixIcon: Icons.email,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Required";
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      decoration: _dialogInputDecoration(
                        labelText: "Address*",
                        hintText: "e.g. Hyderabad",
                        prefixIcon: Icons.location_on,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CANCEL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 2,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final payload = {
                    "distributor_name": nameController.text.trim(),
                    "owner_name": ownerController.text.trim(),
                    "contact_person": contactController.text.trim(),
                    "mobile": mobileController.text.trim(),
                    "email": emailController.text.trim(),
                    "address": addressController.text.trim(),
                  };
                  LoadingDialog.show(context, message: "Creating distributor...");
                  final success = await provider.createDistributor(payload);
                  if (context.mounted) {
                    LoadingDialog.hide(context);
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Distributor Created successfully!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to create distributor")),
                      );
                    }
                  }
                }
              },
              child: const Text("CREATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        );
      },
    );
  }
}
