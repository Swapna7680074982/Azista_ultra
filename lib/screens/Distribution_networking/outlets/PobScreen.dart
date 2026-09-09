import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../permissions/SessionManager.dart';
import 'outlet_activity_provider.dart';
import 'PobHistoryScreen.dart';
import '../../../permissions/AppStateProvider.dart';
import '../../../utilities/common_widgets.dart';

import 'package:geolocator/geolocator.dart';
import '../../../services/location_service.dart';

class PobBody extends StatefulWidget {
  final int outletId;
  final double outletLat;
  final double outletLng;
  final bool isTelePob;
  const PobBody({
    super.key,
    required this.outletId,
    required this.outletLat,
    required this.outletLng,
    this.isTelePob = false,
  });

  @override
  State<PobBody> createState() => _PobBodyState();
}

class _PobBodyState extends State<PobBody> {
  bool? isLocationValid;
  String locationError = "";
  XFile? _capturedImage;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController remarksController = TextEditingController();

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image != null && mounted) {
        setState(() {
          _capturedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isTelePob) {
      isLocationValid = true;
    }
    Future.microtask(() async {
      if (!widget.isTelePob) {
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
      } else {
        if (mounted) {
          setState(() {
            isLocationValid = true;
          });
        }
      }

      if (!mounted) return;

      final provider = Provider.of<OutletActivityProvider>(context, listen: false);
      provider.fetchProductsWithSkus();
      
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      int? distId = appState.selectedDistributorId;
      if (distId == null) {
        final savedDistributors = await SessionManager.getDistributors();
        if (!mounted) return;
        if (savedDistributors.isNotEmpty) {
          distId = int.tryParse(savedDistributors.first['distributor_id']?.toString() ?? '');
        }
      }
      if (distId != null) {
        provider.fetchDistributorStock(distId);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLocationValid == null) {
      content = const Center(child: LogoProgressIndicator());
    } else if (isLocationValid == false) {
      content = Center(
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
    } else {
      content = Consumer<OutletActivityProvider>(
        builder: (context, provider, child) {
          return provider.isLoadingProducts
              ? const Center(child: LogoProgressIndicator())
              : Column(
                  children: [
                    if (widget.isTelePob)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_in_talk, size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              "TELE POB (Telephonic Order Booking)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Prefilled Non-Editable Date Field
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            "ORDER DATE: ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            DateFormat('dd-MM-yyyy').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Product name",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Container(
                            width: 65,
                            alignment: Alignment.center,
                            child: Text(
                              "DSA QTY",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              "R.QTY",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
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

                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "CAPTURE / UPLOAD PHOTO",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text("Camera"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text("Gallery"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_capturedImage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(File(_capturedImage!.path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _capturedImage = null;
                                        });
                                      },
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.red,
                                        radius: 16,
                                        child: Icon(Icons.delete, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "REMARKS",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: remarksController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: "Enter POB remarks...",
                                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: (!widget.isTelePob && _capturedImage == null) ? Colors.grey.shade400 : AppColors.button,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                              ),
                              onPressed: (!widget.isTelePob && _capturedImage == null) ? null : () async {
                                final appState = Provider.of<AppStateProvider>(context, listen: false);

                                LoadingDialog.show(context, message: widget.isTelePob ? "Submitting Tele POB..." : "Submitting POB...");

                                bool success = await provider.submitPob(
                                  widget.outletId,
                                  distributorId: appState.selectedDistributorId,
                                  imageFile: _capturedImage != null ? File(_capturedImage!.path) : null,
                                  remarks: remarksController.text.trim(),
                                  pobType: widget.isTelePob ? "tele" : "regular",
                                );

                                if (!mounted) return;
                                LoadingDialog.hide(context);

                                if (success) {
                                  SuccessDialog.show(context, message: widget.isTelePob ? "Tele POB Submitted Successfully!" : "POB Submitted Successfully!");
                                  setState(() {
                                    _capturedImage = null;
                                    remarksController.clear();
                                  });
                                  provider.fetchProductsWithSkus();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Failed to submit POB or no items selected.")),
                                  );
                                }
                              },
                              child: Text(
                                widget.isTelePob ? "SUBMIT TELE POB" : "SUBMIT POB",
                                style: const TextStyle(
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
                                backgroundColor: AppColors.button,
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
                                "POB HISTORY",
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
                      ),
                    ),
                  ],
                );
        },
      );
    }
    return Container(
      color: Colors.white,
      child: content,
    );
  }

  Widget _buildProductSection(dynamic product, OutletActivityProvider provider) {
    final title = product['product_name'] ?? 'Unknown Product';
    final skus = product['skus'] as List<dynamic>? ?? [];
    final productId = product['product_id'];

    if (skus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        ...skus.map((sku) => _buildSkuRow(productId, sku, provider)).toList(),
      ],
    );
  }

  Widget _buildSkuRow(int productId, dynamic sku, OutletActivityProvider provider) {
    final skuName = sku['sku_displayname'] ?? sku['sku_name'] ?? 'Unknown SKU';
    final skuId = sku['sku_id'];
    final currentQty = provider.stockQuantities["${productId}_$skuId"]?.toString() ?? "";
    final dsaQty = provider.distributorStock["${productId}_$skuId"] ?? 0;

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
          // Non-editable DSA Qty display box
          Container(
            width: 65,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              "$dsaQty",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: dsaQty > 0 ? Colors.black87 : Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Editable R.Qty box
          SizedBox(
            width: 60,
            child: QtyBox(
              isRed: true,
              initialValue: currentQty,
              onChanged: (val) {
                provider.updateStockQuantity(productId, skuId, val);
              },
            ),
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

class PobScreen extends StatelessWidget {
  final int outletId;
  final String outletName;
  final double outletLat;
  final double outletLng;
  final bool isTelePob;

  const PobScreen({
    super.key,
    required this.outletId,
    required this.outletName,
    required this.outletLat,
    required this.outletLng,
    this.isTelePob = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTelePob ? "TELE POB: ${outletName.toUpperCase()}" : "POB: ${outletName.toUpperCase()}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PobBody(
        outletId: outletId,
        outletLat: outletLat,
        outletLng: outletLng,
        isTelePob: isTelePob,
      ),
    );
  }
}