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
import '../../../permissions/AppStateProvider.dart';
import '../../../permissions/SessionManager.dart';
import '../../../utilities/date_formatter.dart';

class PosBaseScreen extends StatefulWidget {
  final Outlet outlet;
  final bool isTelePob;

  const PosBaseScreen({
    super.key,
    required this.outlet,
    this.isTelePob = false,
  });

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
  bool _isOutletCardExpanded = true;

  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  int? _visitId;

  void _buildTabViews() {
    _tabViews = dynamicTabs.map((tab) => _getModuleBody(tab['module_code'], selectedTab)).toList();
  }

  @override
  void initState() {
    super.initState();
    // Synchronously initialize check-in status from provider so there is 0ms delay / no UI flicker
    final currentOutletId = int.tryParse(widget.outlet.id);
    final outletProv = context.read<OutletProvider>();
    if (currentOutletId != null && outletProv.checkedInOutletId == currentOutletId) {
      _isCheckedIn = true;
      _visitId = outletProv.checkedInVisitId;
      _checkInTime = outletProv.checkedInTime;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchModules();
        _checkLocation();
        _loadOutletCheckInStatus();
      }
    });
  }

  Future<void> _loadOutletCheckInStatus() async {
    final currentOutletId = int.tryParse(widget.outlet.id);
    if (currentOutletId == null) return;

    // 1. Check local session first for fast local check
    final savedOutletId = await SessionManager.getOutletCheckInOutletId();
    final savedCheckInTime = await SessionManager.getOutletCheckInTime();
    final savedVisitId = await SessionManager.getOutletCheckInVisitId();

    if (savedOutletId == currentOutletId && savedCheckInTime != null) {
      if (mounted) {
        context.read<OutletProvider>().setCheckedInOutlet(
          currentOutletId,
          visitId: savedVisitId,
          checkInTime: savedCheckInTime,
        );
        setState(() {
          _isCheckedIn = true;
          _visitId = savedVisitId;
          _checkInTime = savedCheckInTime;
          _buildTabViews();
        });
      }
      return;
    }

    // 2. Query history API in background as fallback only if not in local session
    try {
      final history = await ApiServices.getOutletHistory(outletId: currentOutletId);
      if (history != null && history['status'] == true) {
        final List visits = history['visit_history'] ?? [];
        final activeVisit = visits.where(
          (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
        ).firstOrNull;

        if (activeVisit != null) {
          final visitId = int.tryParse(activeVisit['visit_id']?.toString() ?? "") ?? 0;
          final checkInTimeStr = activeVisit['checkin_time']?.toString() ?? "";
          final checkInTime = DateTime.tryParse(checkInTimeStr);

          if (mounted) {
            context.read<OutletProvider>().setCheckedInOutlet(
              currentOutletId,
              visitId: visitId,
              checkInTime: checkInTime ?? DateTime.now(),
            );
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
  }

  Future<void> _syncData() async {
    setState(() {
      isLoadingTabs = true;
    });
    await Future.wait([
      _fetchModules(),
      _checkLocation(),
      _loadOutletCheckInStatus(),
    ]);
    if (mounted) {
      final actProvider = context.read<OutletActivityProvider>();
      actProvider.fetchProductsWithSkus();
      final appState = context.read<AppStateProvider>();
      if (appState.selectedDistributorId != null) {
        actProvider.fetchDistributorStock(appState.selectedDistributorId!);
      }
      setState(() {
        isLoadingTabs = false;
        _buildTabViews();
      });
    }
  }

  Future<void> _checkLocation() async {
    if (widget.isTelePob) {
      if (mounted) {
        setState(() {
          isLocationValid = true;
          _buildTabViews();
        });
      }
      return;
    }
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

      if (distance > 250) {
        if (mounted) {
          setState(() {
            isLocationValid = false;
            final distStr = distance < 1000 ? "${distance.toStringAsFixed(0)} m" : "${(distance / 1000).toStringAsFixed(1)} km";
            locationError = "You are $distStr away from the outlet. You must be within 250 meters to access physical check-in / POB.";
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

  void _showVisitTypeSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.button],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Visit Type",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Check-in at ${widget.outlet.name.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Please select your visit type to proceed with check-in:",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 14),

              // Single Visit Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleCheckIn("Individual");
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Icon(Icons.person, color: Colors.blue.shade700, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Single / Individual Visit",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Individual representative visit",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Combined Visit Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleCheckIn("Combine");
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade100),
                          ),
                          child: Icon(Icons.groups_rounded, color: Colors.teal.shade700, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Combined Visit",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Joint visit with manager or colleague",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckIn(String visitType) async {
    final displayLabel = visitType == "Combine" ? "Combined Visit" : "Individual Visit";
    LoadingDialog.show(context, message: "Checking in ($displayLabel)...");
    try {
      final coords = await LocationService.getCoordinates();
      final currentLat = double.parse(coords[0]);
      final currentLng = double.parse(coords[1]);

      final outletId = int.tryParse(widget.outlet.id) ?? 0;
      final outletAddress = widget.outlet.address.isNotEmpty 
          ? widget.outlet.address 
          : (widget.outlet.area.isNotEmpty ? widget.outlet.area : "");

      final response = await ApiServices.outletCheckIn(
        outletId: outletId,
        latitude: currentLat,
        longitude: currentLng,
        address: outletAddress,
        remarks: "$displayLabel - Visited outlet",
        visitType: visitType,
      );

      if (mounted) {
        LoadingDialog.hide(context);
      }

      if (response != null && response['status'] == true) {
        int visitId = int.tryParse(response['visit_id']?.toString() ?? response['id']?.toString() ?? '') ?? 0;
        
        // If API returned visit_id: 0, query outlet history to resolve the active visit_id
        if (visitId <= 0) {
          try {
            final history = await ApiServices.getOutletHistory(outletId: outletId);
            if (history != null && history['status'] == true) {
              final List visits = history['visit_history'] ?? [];
              final activeVisit = visits.where(
                (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
              ).firstOrNull ?? (visits.isNotEmpty ? visits.first : null);
              if (activeVisit != null) {
                visitId = int.tryParse(activeVisit['visit_id']?.toString() ?? '') ?? 0;
              }
            }
          } catch (_) {}
        }

        final checkInTime = DateTime.now();

        if (mounted) {
          context.read<OutletProvider>().setCheckedInOutlet(
            outletId,
            visitId: visitId,
            checkInTime: checkInTime,
          );
          setState(() {
            _isCheckedIn = true;
            _visitId = visitId;
            _checkInTime = checkInTime;
            _buildTabViews();
          });

          SuccessDialog.show(
            context,
            message: response['message'] ?? "Outlet checked-in successfully ($visitType)",
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
    final outletId = int.tryParse(widget.outlet.id) ?? 0;
    int? resolvedVisitId = _visitId;
    
    if (resolvedVisitId == null || resolvedVisitId <= 0) {
      resolvedVisitId = await SessionManager.getOutletCheckInVisitId();
    }

    // If still 0 or null, query outlet history to find active visit
    if ((resolvedVisitId == null || resolvedVisitId <= 0) && outletId > 0) {
      try {
        final history = await ApiServices.getOutletHistory(outletId: outletId);
        if (history != null && history['status'] == true) {
          final List visits = history['visit_history'] ?? [];
          final activeVisit = visits.where(
            (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
          ).firstOrNull ?? (visits.isNotEmpty ? visits.first : null);
          if (activeVisit != null) {
            resolvedVisitId = int.tryParse(activeVisit['visit_id']?.toString() ?? '') ?? 0;
          }
        }
      } catch (_) {}
    }

    // If no active visit exists on server, simply clear local check-in
    if (resolvedVisitId == null || resolvedVisitId <= 0) {
      if (mounted) {
        context.read<OutletProvider>().clearCheckIn();
        setState(() {
          _isCheckedIn = false;
          _visitId = null;
          _checkInTime = null;
        });
        SuccessDialog.show(
          context,
          message: "Check-in cleared successfully",
          onDismiss: () {
            Navigator.pop(context);
          },
        );
      }
      return;
    }

    LoadingDialog.show(context, message: "Checking out...");
    try {
      final coords = await LocationService.getCoordinates();
      final currentLat = double.parse(coords[0]);
      final currentLng = double.parse(coords[1]);

      final response = await ApiServices.outletCheckOut(
        visitId: resolvedVisitId,
        latitude: currentLat,
        longitude: currentLng,
      );

      if (mounted) {
        LoadingDialog.hide(context);
      }

      if (response != null && response['status'] == true) {
        if (mounted) {
          context.read<OutletProvider>().clearCheckIn();
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
    if (response != null && response['status'] == 'success') {
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
    if (isLocationValid == false && !widget.isTelePob) {
      return RestrictedModuleView(
        key: ValueKey("restricted_${moduleCode}_$currentTab"),
        locationError: locationError,
        onRetry: _checkLocation,
        onTelePob: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PobScreen(
                outletId: int.tryParse(widget.outlet.id) ?? 0,
                outletName: widget.outlet.name,
                outletLat: widget.outlet.latitude,
                outletLng: widget.outlet.longitude,
                isTelePob: true,
              ),
            ),
          );
        },
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
          isTelePob: widget.isTelePob,
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
        actions: [
          IconButton(
            tooltip: "Sync & Refresh",
            icon: const Icon(Icons.sync, color: AppColors.white),
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Syncing outlet data..."),
                  duration: Duration(milliseconds: 900),
                ),
              );
              await _syncData();
            },
          ),
        ],
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
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 5 : 8,
              ),
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
                                onPressed: _showVisitTypeSelectionDialog,
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
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isExpanded = _isOutletCardExpanded && !isKeyboardOpen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isExpanded ? 10 : 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isOutletCardExpanded = !_isOutletCardExpanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outlet.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text("OUTLET ID: ${outlet.id}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                if (!isExpanded && outlet.type.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      outlet.type.toUpperCase(),
                      style: TextStyle(fontSize: 11, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 14),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    outlet.owner.toUpperCase(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(outlet.phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            if (outlet.type.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      outlet.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
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
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.green),
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.green.withValues(alpha: 0.05),
                    ),
                    child: TextButton(
                      onPressed: () => CallService.makeCall(outlet.phone),
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
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.green),
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.green.withValues(alpha: 0.05),
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
            ),
          ],
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
  final VoidCallback? onTelePob;
  
  const RestrictedModuleView({
    super.key, 
    required this.locationError,
    required this.onRetry,
    this.onTelePob,
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
              const SizedBox(height: 24),
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
              if (onTelePob != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
                    label: const Text(
                      "SUBMIT TELE POB",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1.5,
                    ),
                    onPressed: onTelePob,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}