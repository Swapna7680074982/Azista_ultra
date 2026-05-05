import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../services/call_service.dart';
import '../../../services/directions_map_screen.dart';
import 'BrandingScreen.dart';
import 'PobScreen.dart';
import 'PreviousTransactionsScreen.dart';
import 'PromotionsScreen.dart';
import 'SamplingScreen.dart';
import 'StockScreen.dart';
import 'outlet_provider.dart';

import '../../../services/api_services.dart';

class PosBaseScreen extends StatefulWidget {
  final Outlet outlet;

  const PosBaseScreen({super.key, required this.outlet});

  @override
  State<PosBaseScreen> createState() => _PosBaseScreenState();
}

class _PosBaseScreenState extends State<PosBaseScreen> {
  int selectedTab = 0;
  List<Map<String, dynamic>> dynamicTabs = [];
  bool isLoadingTabs = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    final response = await ApiServices.getModules();
    if (response != null && response['status'] == 'success') {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        dynamicTabs = data.map((e) => e as Map<String, dynamic>).toList();
        isLoadingTabs = false;
      });
    } else {
      // Fallback
      setState(() {
        dynamicTabs = [
          {"module_name": "SAMPLING", "module_code": "SAMP"},
          {"module_name": "STOCK", "module_code": "STOCK"},
          {"module_name": "POB", "module_code": "POB"},
          {"module_name": "BRANDING", "module_code": "BRD"},
          {"module_name": "PROMOTIONS", "module_code": "PRM"},
        ];
        isLoadingTabs = false;
      });
    }
  }

  Widget _getModuleBody(String moduleCode) {
    switch (moduleCode) {
      case "SAMP":
        return const SamplingBody();
      case "STOCK":
        return const StockBody();
      case "POB":
        return PobBody(outletId: int.tryParse(widget.outlet.id) ?? 0);
      case "BRD":
        return const BrandingBody();
      case "PRM":
        return const PromotionsBody();
      case "SALE":
        return const Center(child: Text("SALE Screen (TBD)"));
      default:
        return Center(child: Text("$moduleCode Screen"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "Point of sale",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),
      body: isLoadingTabs 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
        children: [
          outletCard(widget.outlet),
          _tabs(),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: dynamicTabs.map((tab) => _getModuleBody(tab['module_code'])).toList(),
            ),
          ),
        ],
      ),
    );
  }
  Widget outletCard(Outlet outlet) {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outlet.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),

              Text("OUTLET ID: ${outlet.id}"),

              const Divider(),

              Row(
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 8),
                  Text(outlet.owner),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.phone, size: 18),
                  const SizedBox(width: 8),
                  Text(outlet.phone),
                ],
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      outlet.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 5),

                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.orange,
                          Colors.teal,
                        ],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.storefront,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Feature will be implemented in future"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        "JOINT CALL",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StockSalePosScreen(
                                  outletId: int.tryParse(widget.outlet.id) ?? 0,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "PREVIOUS TRANSACTIONS",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.buttonBlue),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.white,
                      ),
                      child: TextButton(
                        onPressed: () {
                          CallService.makeCall(outlet.phone);
                        },
                        child: const Text(
                          "CALL",
                          style: TextStyle(
                            color: AppColors.buttonBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.button),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.white,
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectionsMapScreen(
                                outletLat: widget.outlet.latitude,
                                outletLng: widget.outlet.longitude,
                                outletName: widget.outlet.name,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "DIRECTIONS",
                          style: TextStyle(
                            color: AppColors.button,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),

    );
  }
  Widget _tabs() {
    if (dynamicTabs.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(dynamicTabs.length, (index) {
          final isSelected = index == selectedTab;
          final tabName = dynamicTabs[index]['module_name'] ?? 'UNKNOWN';

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 15,
              ),
              color: isSelected ? Colors.white : Colors.grey[300],
              child: Center(
                child: Text(
                  tabName,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
  void _showLocationPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    const Text(
                      "Would you like to update the latitude\nand longitude of this OUTLET",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        elevation: 4,
                        shadowColor: Colors.black26,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        _updateLocation();
                      },
                      child: const Text(
                        "YES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,color: AppColors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _updateLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Updating location..."),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location updated successfully"),
      ),
    );
  }
}