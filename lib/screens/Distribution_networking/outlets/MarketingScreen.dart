import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_colors.dart';
import 'outlet_activity_provider.dart';
import '../../../utilities/common_widgets.dart';

class MarketingBody extends StatefulWidget {
  final int outletId;
  const MarketingBody({super.key, required this.outletId});

  @override
  State<MarketingBody> createState() => _MarketingBodyState();
}

class _MarketingBodyState extends State<MarketingBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // ADD Form state variables
  String selectedActivityType = "Branding";
  String? selectedProduct;
  final TextEditingController remarksController = TextEditingController();
  XFile? _capturedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

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
  void dispose() {
    _tabController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = "marketing_activities_${widget.outletId}";
      final String? jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          _historyItems = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() {
          _historyItems = [];
        });
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveToHistory(Map<String, dynamic> newItem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = "marketing_activities_${widget.outletId}";
      _historyItems.insert(0, newItem); // Put new item at the top
      await prefs.setString(key, jsonEncode(_historyItems));
      setState(() {});
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50, // compress to save space
      );
      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _submitActivity() async {
    if (selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Simulate API delay, and handle fallback UI/local store
    await Future.delayed(const Duration(milliseconds: 800));

    String? base64Image;
    if (_capturedImage != null) {
      try {
        final bytes = await File(_capturedImage!.path).readAsBytes();
        base64Image = base64Encode(bytes);
      } catch (e) {
        debugPrint("Error encoding image: $e");
      }
    }

    final newItem = {
      "activity_type": selectedActivityType,
      "product": selectedProduct,
      "remarks": remarksController.text.trim(),
      "date": DateTime.now().toIso8601String(),
      if (base64Image != null) "image": base64Image,
    };

    await _saveToHistory(newItem);

    setState(() {
      _isSubmitting = false;
      remarksController.clear();
      _capturedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marketing Activity Saved Successfully!")),
    );

    // Switch to history tab
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, child) {
        final List<String> productsList = (provider.products.isNotEmpty 
            ? provider.products.toSet().toList() 
            : ["Defend 99", "Menthopas", "Sparkel", "Spice Sip", "Taste Good"]).cast<String>();

        if (selectedProduct == null && productsList.isNotEmpty) {
          selectedProduct = productsList.first;
        } else if (selectedProduct != null && !productsList.contains(selectedProduct)) {
          selectedProduct = productsList.isNotEmpty ? productsList.first : null;
        }

        return Column(
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
                  _buildAddForm(productsList),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddForm(List<String> productsList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedActivityType = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            "PRODUCT",
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
                value: selectedProduct,
                isExpanded: true,
                items: productsList.map((prod) {
                  return DropdownMenuItem(
                    value: prod,
                    child: Text(prod),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedProduct = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

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

          const Text(
            "CAPTURE / UPLOAD PHOTO",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
          const SizedBox(height: 30),

          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
        ],
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
        final product = item["product"]?.toString() ?? "N/A";
        final remarks = item["remarks"]?.toString() ?? "";
        final dateStr = item["date"]?.toString() ?? "";
        final imgBase64 = item["image"]?.toString();

        String formattedDate = "-";
        if (dateStr.isNotEmpty) {
          try {
            final dt = DateTime.parse(dateStr);
            formattedDate = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          } catch (e) {
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
                    child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
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
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Product: $product",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (remarks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          remarks,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
