import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../services/location_service.dart';
import '../../../constants/app_colors.dart';
import '../../../services/call_service.dart';
import '../../../services/directions_map_screen.dart';
import 'BrandingScreen.dart';
import 'PobScreen.dart';
import 'MarketingScreen.dart';
import 'PreviousTransactionsScreen.dart';
import 'PromotionsScreen.dart';
import 'SamplingScreen.dart';
import 'StockScreen.dart';
import 'SaleScreen.dart';
import 'outlet_provider.dart';
import '../../../services/api_services.dart';
import '../../../utilities/common_widgets.dart';
import '../../../permissions/SessionManager.dart';
import '../../../utilities/date_formatter.dart';

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
  bool? isLocationValid;
  String locationError = "";
  List<Widget> _tabViews = [];

  void _buildTabViews() {
    _tabViews = dynamicTabs.map((tab) => _getModuleBody(tab['module_code'], selectedTab)).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchModules();
    _checkLocation();
    _loadOutletCheckInStatus();
  }

  Future<void> _loadOutletCheckInStatus() async {
    final currentOutletId = int.tryParse(widget.outlet.id);
    if (currentOutletId == null) return;

    try {
      final history = await ApiServices.getOutletHistory(outletId: currentOutletId);
      if (history != null && (history['status'] == true || history['status'] == 'success' || history['visit_history'] != null)) {
        final List visits = history['visit_history'] ?? [];
        final activeVisit = visits.firstWhere(
          (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
          orElse: () => null,
        );

        if (activeVisit != null) {
          final visitId = int.tryParse(activeVisit['visit_id']?.toString() ?? "") ?? 0;
          final checkInTimeStr = activeVisit['checkin_time']?.toString() ?? "";
          final checkInTime = DateTime.tryParse(checkInTimeStr);

          await SessionManager.saveOutletCheckIn(
            outletId: currentOutletId,
            visitId: visitId,
            checkInTime: checkInTime ?? DateTime.now(),
          );

          if (mounted) {
            setState(() {
              _isCheckedIn = true;
              _visitId = visitId;
              _checkInTime = checkInTime;
              _buildTabViews();
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error loading check-in status from API: $e");
    }

    final savedOutletId = await SessionManager.getOutletCheckInOutletId();
    if (savedOutletId == currentOutletId) {
      await SessionManager.clearOutletCheckIn();
    }
    if (mounted) {
      setState(() {
        _isCheckedIn = false;
        _visitId = null;
        _checkInTime = null;
      });
    }
  }

  Future<void> _checkLocation() async {
    if (mounted) {
      setState(() {
        isLocationValid = null;
      });
    }
    try {
      final coords = await LocationService.getCoordinates();
      final currentLat = double.parse(coords[0]);
      final currentLng = double.parse(coords[1]);

      final distance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        widget.outlet.latitude,
        widget.outlet.longitude,
      );

      if (distance > 50) {
        if (mounted) {
          setState(() {
            isLocationValid = false;
            locationError = "You are ${distance.toStringAsFixed(0)} meters away from the outlet. You must be within 50 meters to access POB.";
            _buildTabViews();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLocationValid = true;
            _buildTabViews();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLocationValid = false;
          locationError = "Failed to get your location. Please check GPS and permissions.";
          _buildTabViews();
        });
      }
    }
  }

  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  int? _visitId;

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleCheckIn() async {
    LoadingDialog.show(context, message: "Checking in...");
    try {
      final coords = await LocationService.getCoordinates();
      final currentLat = double.parse(coords[0]);
      final currentLng = double.parse(coords[1]);

      final outletId = int.tryParse(widget.outlet.id) ?? 0;

      final response = await ApiServices.outletCheckIn(
        outletId: outletId,
        latitude: currentLat,
        longitude: currentLng,
        remarks: "Visited outlet",
      );

      if (mounted) {
        LoadingDialog.hide(context);
      }

      if (response != null && (response['status'] == true || response['status'] == 'success')) {
        final visitId = response['visit_id'] ?? 0;
        final checkInTime = DateTime.now();

        await SessionManager.saveOutletCheckIn(
          outletId: outletId,
          visitId: visitId,
          checkInTime: checkInTime,
        );

        if (mounted) {
          setState(() {
            _isCheckedIn = true;
            _visitId = visitId;
            _checkInTime = checkInTime;
            _buildTabViews();
          });

          SuccessDialog.show(
            context,
            message: response['message'] ?? "Outlet checked-in successfully",
          );
        }
      } else {
        final errMsg = response != null ? response['message'] : "Failed to check in";
        _showErrorSnackBar(errMsg ?? "Failed to check in");
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
      }
      _showErrorSnackBar("Error getting location or checking in: $e");
    }
  }

  Future<void> _handleCheckOut() async {
    if (_visitId == null) {
      _showErrorSnackBar("No active visit ID found.");
      return;
    }

    LoadingDialog.show(context, message: "Checking out...");
    try {
      final coords = await LocationService.getCoordinates();
      final currentLat = double.parse(coords[0]);
      final currentLng = double.parse(coords[1]);

      final response = await ApiServices.outletCheckOut(
        visitId: _visitId!,
        latitude: currentLat,
        longitude: currentLng,
      );

      if (mounted) {
        LoadingDialog.hide(context);
      }

      if (response != null && (response['status'] == true || response['status'] == 'success')) {
        await SessionManager.clearOutletCheckIn();

        if (mounted) {
          setState(() {
            _isCheckedIn = false;
            _visitId = null;
            _checkInTime = null;
          });

          SuccessDialog.show(
            context,
            message: response['message'] ?? "Outlet checked-out successfully",
            onDismiss: () {
              Navigator.pop(context); // Go back to outlet list upon checkout
            },
          );
        }
      } else {
        final errMsg = response != null ? response['message'] : "Failed to check out";
        _showErrorSnackBar(errMsg ?? "Failed to check out");
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
      }
      _showErrorSnackBar("Error getting location or checking out: $e");
    }
  }

  Future<void> _fetchModules() async {
    final response = await ApiServices.getModules();
    List<Map<String, dynamic>> tabs = [];
    if (response != null && (response['status'] == 'success' || response['status'] == true || response['data'] != null)) {
      final List<dynamic> data = response['data'] ?? [];
      tabs = data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      // Fallback
      tabs = [
        {"module_name": "SAMPLING", "module_code": "SAMP"},
        {"module_name": "STOCK", "module_code": "STOCK"},
        {"module_name": "POB", "module_code": "POB"},
        {"module_name": "BRANDING", "module_code": "BRD"},
        {"module_name": "PROMOTIONS", "module_code": "PRM"},
      ];
    }
    
    // Add ACTIVITY module manually if not present
    if (!tabs.any((t) => t['module_code'] == 'MKT' || t['module_code'] == 'MARKETING')) {
      tabs.add({"module_name": "ACTIVITY", "module_code": "MKT"});
    }

    // Filter out Branding (BRD) and Promotions (PRM)
    tabs.removeWhere((t) {
      final code = t['module_code']?.toString().toUpperCase();
      final name = t['module_name']?.toString().toUpperCase();
      return code == 'BRD' || code == 'PRM' || name == 'BRANDING' || name == 'PROMOTIONS';
    });

    setState(() {
      dynamicTabs = tabs;
      isLoadingTabs = false;
      _buildTabViews();
    });
  }

  Widget _getModuleBody(String moduleCode, int currentTab) {
    if (isLocationValid == false) {
      return RestrictedModuleView(
        key: ValueKey("restricted_${moduleCode}_$currentTab"),
        locationError: locationError,
        onRetry: _checkLocation,
      );
    }
    final key = ValueKey("${moduleCode}_$currentTab");
    switch (moduleCode) {
      case "SAMP":
        return SamplingBody(key: key, outletId: int.tryParse(widget.outlet.id) ?? 0);
      case "STOCK":
        return StockBody(key: key, outletId: int.tryParse(widget.outlet.id) ?? 0);
      case "POB":
        return PobBody(
          key: key,
          outletId: int.tryParse(widget.outlet.id) ?? 0,
          outletLat: widget.outlet.latitude,
          outletLng: widget.outlet.longitude,
        );
      case "BRD":
        return BrandingBody(key: key);
      case "PRM":
        return PromotionsBody(key: key);
      case "SALE":
        return SaleBody(key: key, outletId: int.tryParse(widget.outlet.id) ?? 0);
      case "MKT":
        return MarketingBody(
          key: key,
          outletId: int.tryParse(widget.outlet.id) ?? 0,
          visitId: _visitId,
        );
      default:
        return Center(key: key, child: Text("$moduleCode Screen"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PURCHASE ORDER BOOKING",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
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
      ),
      body: isLoadingTabs 
          ? const Center(child: LogoProgressIndicator()) 
          : Column(
        children: [
          outletCard(widget.outlet),
          if (isLocationValid == null)
            const Expanded(child: Center(child: LogoProgressIndicator()))
          else if (_isCheckedIn) ...[
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _checkInTime != null
                            ? "Checked-in at: ${DateFormatter.formatDateTime(_checkInTime!.toIso8601String())}"
                            : "Checked-in",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirm Check-Out"),
                          content: Text("Are you sure you want to check out of ${widget.outlet.name}? This will lock the POB features."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("CANCEL"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _handleCheckOut();
                              },
                              child: const Text("CHECK-OUT", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.button,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "CHECK-OUT",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _tabs(),
            Expanded(
              child: IndexedStack(
                index: selectedTab,
                children: _tabViews,
              ),
            ),
          ] else ...[
            if (isLocationValid == false) ...[
              _tabs(),
              Expanded(
                child: IndexedStack(
                  index: selectedTab,
                  children: _tabViews,
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront, size: 64, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              "Welcome to ${widget.outlet.name.toUpperCase()}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "You must check in to this outlet to access POB features and submit sales, stock, POB, or marketing activities.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: _handleCheckIn,
                                child: const Text(
                                  "CHECK-IN",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
              Text(outlet.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),

              Text("OUTLET ID: ${outlet.id}",style: const TextStyle(fontSize: 15)),

              const Divider(),

              Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text(outlet.owner.toUpperCase(),style: const TextStyle(fontSize: 18)),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 8),
                  Text(outlet.phone,style: const TextStyle(fontSize: 18)),
                ],
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (outlet.type.isNotEmpty)
                      Text(
                        outlet.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (outlet.type.isNotEmpty) const SizedBox(width: 5),

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
                          fontSize: 12,
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
                              fontSize: 12,
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
                        border: Border.all(color: AppColors.green),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.green.withValues(alpha:0.05),
                      ),
                      child: TextButton(
                        onPressed: () {
                          CallService.makeCall(outlet.phone);
                        },
                        child: const Text(
                          "CALL",
                          style: TextStyle(
                            color: AppColors.green,
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
                        border: Border.all(color: AppColors.green),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.green.withValues(alpha:0.05),
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
                            color: AppColors.green,
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
              if (selectedTab != index) {
                Provider.of<OutletActivityProvider>(context, listen: false).clearQuantities();
                setState(() {
                  selectedTab = index;
                  _buildTabViews();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 25,
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

class RestrictedModuleView extends StatelessWidget {
  final String locationError;
  final VoidCallback onRetry;
  
  const RestrictedModuleView({
    super.key, 
    required this.locationError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: AppColors.button.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.button.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.button,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "ACCESS RESTRICTED",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.button,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(Icons.info_outline, color: Colors.grey, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        locationError,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                  label: const Text(
                    "REFRESH LOCATION",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1.5,
                  ),
                  onPressed: onRetry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}