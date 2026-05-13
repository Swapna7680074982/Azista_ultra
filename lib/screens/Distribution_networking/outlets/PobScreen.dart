import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../constants/app_colors.dart';
import 'PobHistoryScreen.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../utilities/common_widgets.dart';

import 'package:geolocator/geolocator.dart';
import '../../../services/location_service.dart';

class PobBody extends StatefulWidget {
  final int outletId;
  final double outletLat;
  final double outletLng;
  const PobBody({super.key, required this.outletId, required this.outletLat, required this.outletLng});

  @override
  State<PobBody> createState() => _PobBodyState();
}

class _PobBodyState extends State<PobBody> {
  bool? isLocationValid;
  String locationError = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final coords = await LocationService.getCoordinates();
        final currentLat = double.parse(coords[0]);
        final currentLng = double.parse(coords[1]);

        final distance = Geolocator.distanceBetween(
          currentLat,
          currentLng,
          widget.outletLat,
          widget.outletLng,
        );

        if (distance > 50) {
          if (mounted) {
            setState(() {
              isLocationValid = false;
              locationError = "You are ${distance.toStringAsFixed(0)} meters away from the outlet. You must be within 50 meters to add POB.";
            });
          }
          return;
        } else {
          if (mounted) {
            setState(() {
              isLocationValid = true;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLocationValid = false;
            locationError = "Failed to get your location. Please check GPS and permissions.";
          });
        }
        return;
      }

      final provider = Provider.of<OutletActivityProvider>(context, listen: false);
      provider.fetchProductsWithSkus();
      
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedDistributorId != null) {
        provider.fetchDistributorStock(appState.selectedDistributorId!);
      }
    });
  }
  Widget build(BuildContext context) {
    if (isLocationValid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isLocationValid == false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                locationError,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

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

    return ProductCard(
      title: title,
      children: skus.map((sku) => _buildSkuRow(productId, sku, provider)).toList(),
    );
  }

  Widget _buildSkuRow(int productId, dynamic sku, OutletActivityProvider provider) {
    final skuName = sku['sku_displayname'] ?? 'Unknown SKU';
    final skuId = sku['sku_id'];
    final currentQty = provider.stockQuantities["${productId}_$skuId"]?.toString() ?? "";
    final distStockStr = provider.distributorStock["${productId}_$skuId"]?.toString() ?? "0";

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

          QtyBox(isEditable: false, initialValue: distStockStr),

          const SizedBox(width: 12),
          
          QtyBox(
            isRed: true,
            initialValue: currentQty,
            onChanged: (val) {
              provider.updateStockQuantity(productId, skuId, val);
            },
          ),
        ],
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