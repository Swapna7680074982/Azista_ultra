import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import 'outlet_activity_provider.dart';
import '../../../utilities/common_widgets.dart';
import '../../../permissions/SessionManager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class MarketingBody extends StatefulWidget {
  final int outletId;
  final int? visitId;
  const MarketingBody({super.key, required this.outletId, this.visitId});

  @override
  State<MarketingBody> createState() => _MarketingBodyState();
}

class _MarketingBodyState extends State<MarketingBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ADD Form state variables
  String? selectedActivityTypeId;

  // Selected product/sku
  int? selectedProductId;
  int? selectedSkuId;
  String? selectedProductName;
  String? selectedSkuName;

  final TextEditingController remarksController = TextEditingController();
  final List<File> _selectedFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  bool _productsFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => _loadHistory());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch products once on first dependency resolution (safe, no async gap)
    if (!_productsFetched) {
      _productsFetched = true;
      Future.microtask(() {
        if (mounted) {
          final provider = Provider.of<OutletActivityProvider>(context, listen: false);
          provider.fetchProductsWithSkus();
          provider.fetchActivityTypes();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      if (mounted) {
        Provider.of<OutletActivityProvider>(context, listen: false)
            .fetchOutletHistory(widget.outletId);
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 files allowed")),
      );
      return;
    }
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
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

  Future<void> _submitActivity() async {
    final provider = Provider.of<OutletActivityProvider>(context, listen: false);

    if (selectedActivityTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an activity type")),
      );
      return;
    }

    if (selectedProductId == null || selectedSkuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a brand and SKU")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final resolvedVisitId = widget.visitId ?? await SessionManager.getOutletCheckInVisitId();

    if (resolvedVisitId == null) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active visit session found. Please check in first.")),
      );
      return;
    }

    final response = await provider.submitOutletActivity(
      visitId: resolvedVisitId,
      activityTypeId: selectedActivityTypeId!,
      remarks: remarksController.text.trim(),
      files: _selectedFiles,
      productId: selectedProductId,
      skuId: selectedSkuId,
    );

    setState(() => _isSubmitting = false);

    if (response['status'] == true) {
      setState(() {
        remarksController.clear();
        _selectedFiles.clear();
        selectedProductId = null;
        selectedSkuId = null;
        selectedProductName = null;
        selectedSkuName = null;
      });

      _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Activity Saved Successfully!")),
        );
        _tabController.animateTo(1);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to save activity")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
      children: [
        Container(
          color: Colors.grey[200],
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: "ADD ACTIVITY"),
              Tab(text: "HISTORY"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAddForm(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity Type Dropdown
              const Text(
                "ACTIVITY TYPE",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (provider.isLoadingActivityTypes)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: LogoProgressIndicator(size: 40),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedActivityTypeId,
                      isExpanded: true,
                      hint: const Text("Select Activity Type"),
                      items: provider.activityTypes.map((type) {
                        final typeId = type['activity_type_id']?.toString() ?? '';
                        final typeName = type['activity_name']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: typeId,
                          child: Text(typeName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedActivityTypeId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Brand dropdown
              const Text(
                "SELECT BRAND",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (provider.isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Center(child: LogoProgressIndicator()),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedProductId,
                      isExpanded: true,
                      hint: const Text("Select Brand"),
                      items: provider.productsWithSkus.map((product) {
                        final prodId = product['product_id'] as int;
                        final prodName = product['product_name']?.toString() ?? 'Unknown';
                        return DropdownMenuItem<int>(
                          value: prodId,
                          child: Text(prodName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final product = provider.productsWithSkus.where((p) => p['product_id'] == val).firstOrNull;
                          setState(() {
                            selectedProductId = val;
                            selectedProductName = product?['product_name']?.toString() ?? 'Unknown';
                            selectedSkuId = null;
                            selectedSkuName = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // SKU Dropdown
              if (selectedProductId != null) ...[
                const Text(
                  "SELECT SKU",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedSkuId,
                      isExpanded: true,
                      hint: const Text("Select SKU"),
                      items: (() {
                        final product = provider.productsWithSkus.where((p) => p['product_id'] == selectedProductId).firstOrNull;
                        final skus = product?['skus'] as List<dynamic>? ?? [];
                        return skus.map((sku) {
                          final sId = sku['sku_id'] as int;
                          final sName = sku['sku_displayname']?.toString() ?? 'Unknown';
                          return DropdownMenuItem<int>(
                            value: sId,
                            child: Text(sName),
                          );
                        }).toList();
                      })(),
                      onChanged: (val) {
                        if (val != null) {
                          final product = provider.productsWithSkus.where((p) => p['product_id'] == selectedProductId).firstOrNull;
                          final skus = product?['skus'] as List<dynamic>? ?? [];
                          final sku = skus.where((s) => s['sku_id'] == val).firstOrNull;
                          setState(() {
                            selectedSkuId = val;
                            selectedSkuName = sku?['sku_displayname']?.toString() ?? 'Unknown';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Remarks
              const Text(
                "REMARKS / DETAILS",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter activity details...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image Capture
              const Text(
                "CAPTURE / UPLOAD PHOTOS (MAX 5)",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _selectedFiles.length >= 5 ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _selectedFiles.length >= 5 ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ],
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, idx) {
                      final file = _selectedFiles[idx];
                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(idx);
                                  });
                                },
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                                  radius: 12,
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 30),

              // Submit Button
              _isSubmitting
                  ? const LogoProgressIndicator(size: 45, message: "Submitting activity...")
                  : SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.button,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: _submitActivity,
                        child: const Text(
                          "SUBMIT ACTIVITY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAttachmentUrl(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final Uri url = Uri.parse(urlString);
      final success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch attachment")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening link: $e")),
        );
      }
    }
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingHistory) {
          return const LogoProgressIndicator();
        }

        if (provider.activityHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  "No activities recorded",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.activityHistory.length,
          itemBuilder: (context, index) {
            final item = provider.activityHistory[index];
            final type = item["activity_name"]?.toString() ?? "Activity";
            final remarks = item["remarks"]?.toString() ?? "";
            final dateStr = item["activity_date"]?.toString() ?? item["visit_date"]?.toString() ?? "";
            final files = item["files"] as List<dynamic>? ?? [];
            final productName = item["product_name"]?.toString() ?? "";
            final skuName = item["sku_name"]?.toString() ?? "";

            String formattedDate = "-";
            if (dateStr.isNotEmpty) {
              try {
                final dt = DateTime.parse(dateStr);
                formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(dt);
              } catch (_) {
                formattedDate = dateStr;
              }
            }

            bool isImageFile(dynamic file) {
              final name = (file["file_name"] ?? "").toString().toLowerCase();
              final url = (file["file_url"] ?? "").toString().toLowerCase();
              
              bool hasImageExtension(String path) {
                final cleanPath = Uri.tryParse(path)?.path ?? path;
                return cleanPath.endsWith('.jpg') ||
                    cleanPath.endsWith('.jpeg') ||
                    cleanPath.endsWith('.png') ||
                    cleanPath.endsWith('.webp') ||
                    cleanPath.endsWith('.gif');
              }
              return hasImageExtension(name) || hasImageExtension(url);
            }

            final imageFiles = files.where(isImageFile).toList();
            final nonImageFiles = files.where((file) => !isImageFile(file)).toList();

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (productName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                          if (skuName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              skuName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (remarks.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              remarks,
                              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                            ),
                          ],
                          // Render attachment chips only for non-image files
                          if (nonImageFiles.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: nonImageFiles.map<Widget>((file) {
                                final name = file["file_name"]?.toString() ?? "Attachment";
                                final url = file["file_url"]?.toString() ?? "";
                                final lowercaseName = name.toLowerCase();
                                IconData icon = Icons.insert_drive_file;
                                if (lowercaseName.endsWith('.pdf')) {
                                  icon = Icons.picture_as_pdf;
                                } else if (lowercaseName.endsWith('.png') ||
                                    lowercaseName.endsWith('.jpg') ||
                                    lowercaseName.endsWith('.jpeg')) {
                                  icon = Icons.image;
                                }

                                return GestureDetector(
                                  onTap: () => _openAttachmentUrl(url),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (imageFiles.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: imageFiles.map<Widget>((file) {
                          final url = file["file_url"]?.toString() ?? "";
                          return GestureDetector(
                            onTap: () => _showFullImageDialog(context, url),
                            child: Container(
                              width: 70,
                              height: 70,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Hero(
                                  tag: url,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: imageUrl,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white, size: 48),
                            SizedBox(height: 12),
                            Text(
                              "Failed to load image",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
