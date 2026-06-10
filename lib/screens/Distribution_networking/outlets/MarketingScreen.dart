import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import 'outlet_activity_provider.dart';
import '../../../utilities/common_widgets.dart';

class MarketingBody extends StatefulWidget {
  final int outletId;
  const MarketingBody({super.key, required this.outletId});

  @override
  State<MarketingBody> createState() => _MarketingBodyState();
}

class _MarketingBodyState extends State<MarketingBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ADD Form state variables
  String selectedActivityType = "Branding";

  // Selected product/sku
  int? selectedProductId;
  int? selectedSkuId;
  String? selectedProductName;
  String? selectedSkuName;

  final TextEditingController remarksController = TextEditingController();
  XFile? _capturedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  bool _productsFetched = false;

  // History state
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoadingHistory = true;

  final List<String> activityTypes = [
    "Branding",
    "Promotion",
    "Poster",
    "Banner",
    "Pamphlet",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch products once on first dependency resolution (safe, no async gap)
    if (!_productsFetched) {
      _productsFetched = true;
      Provider.of<OutletActivityProvider>(context, listen: false)
          .fetchProductsWithSkus();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      // Use SharedPreferences if needed — keep local history
      setState(() => _historyItems = []);
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image != null) {
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

  Future<void> _submitActivity() async {
    if (selectedProductId == null || selectedSkuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product SKU")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 600));

    String? base64Image;
    if (_capturedImage != null) {
      try {
        final bytes = await File(_capturedImage!.path).readAsBytes();
        base64Image = base64Encode(bytes);
      } catch (e) {
        debugPrint("Error encoding image: $e");
      }
    }

    final newItem = <String, dynamic>{
      "activity_type": selectedActivityType,
      "product_id": selectedProductId,
      "sku_id": selectedSkuId,
      "product": selectedProductName ?? "",
      "sku": selectedSkuName ?? "",
      "remarks": remarksController.text.trim(),
      "date": DateTime.now().toIso8601String(),
      "image": base64Image,
    };

    setState(() {
      _historyItems.insert(0, newItem);
      _isSubmitting = false;
      remarksController.clear();
      _capturedImage = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marketing Activity Saved Successfully!")),
      );
      _tabController.animateTo(1);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedActivityType,
                    isExpanded: true,
                    items: activityTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedActivityType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product / SKU picker section
              const Text(
                "SELECT PRODUCT & SKU",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              // Header row
              Container(
                color: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Product / SKU",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      "SELECT",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              if (provider.isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: LogoProgressIndicator()),
                )
              else if (provider.productsWithSkus.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text("No products found")),
                )
              else
                ...provider.productsWithSkus.map((product) {
                  return _buildProductSection(product);
                }),

              const SizedBox(height: 20),

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
                "CAPTURE / UPLOAD PHOTO",
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
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_capturedImage != null)
                Stack(
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
                        onTap: () => setState(() => _capturedImage = null),
                        child: const CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 16,
                          child: Icon(Icons.delete, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),

              // Submit Button
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
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
                          "SUBMIT MARKETING ACTIVITY",
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

  Widget _buildProductSection(dynamic product) {
    final title = product['product_name']?.toString() ?? 'Unknown Product';
    final skus = product['skus'] as List<dynamic>? ?? [];
    final productId = product['product_id'] as int?;

    if (skus.isEmpty || productId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
        ...skus.map((sku) => _buildSkuRow(productId, title, sku)),
      ],
    );
  }

  Widget _buildSkuRow(int productId, String productName, dynamic sku) {
    final skuName = sku['sku_displayname']?.toString() ?? 'Unknown SKU';
    final skuId = sku['sku_id'] as int?;
    if (skuId == null) return const SizedBox.shrink();

    final isSelected = selectedProductId == productId && selectedSkuId == skuId;

    return InkWell(
      onTap: () {
        setState(() {
          selectedProductId = productId;
          selectedSkuId = skuId;
          selectedProductName = productName;
          selectedSkuName = skuName;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                skuName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyItems.isEmpty) {
      return const Center(child: Text("No marketing activities recorded"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        final type = item["activity_type"]?.toString() ?? "Marketing";
        final productName = item["product"]?.toString() ?? "N/A";
        final skuName = item["sku"]?.toString() ?? "";
        final remarks = item["remarks"]?.toString() ?? "";
        final dateStr = item["date"]?.toString() ?? "";
        final imgBase64 = item["image"]?.toString();

        String formattedDate = "-";
        if (dateStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(dateStr);
            formattedDate =
                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} "
                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          } catch (_) {
            formattedDate = dateStr;
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imgBase64 != null)
                  Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(imgBase64)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey[400]),
                  ),
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
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        productName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (skuName.isNotEmpty)
                        Text(
                          skuName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      if (remarks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          remarks,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
