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
import 'package:intl/intl.dart';
import '../../../permissions/SessionManager.dart';
import '../../../utilities/date_formatter.dart';
import '../../distribution_list/VisitsScreen.dart';

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
  bool isLoadingCheckIn = true;
  bool? isLocationValid;
  String locationError = "";
  List<Widget> _tabViews = [];

  int _totalVisits = 0;
  String? _lastVisitText;
  bool _isCardExpanded = true;

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
    if (currentOutletId == null) {
      if (mounted) setState(() => isLoadingCheckIn = false);
      return;
    }

    // Immediately use preloaded history from OutletProvider (loaded on Outlets list screen)
    final outletProvider = Provider.of<OutletProvider>(context, listen: false);
    final cachedVisitsCount = outletProvider.getOutletVisitsCount(currentOutletId);
    final cachedLastVisit = outletProvider.getOutletLastVisit(currentOutletId);
    if (cachedVisitsCount > 0) {
      _totalVisits = cachedVisitsCount;
    }
    if (cachedLastVisit != null) {
      final dateStr = cachedLastVisit['visit_date'] ?? cachedLastVisit['checkin_time'];
      final type = (cachedLastVisit['visit_type'] ?? 'INDIVIDUAL').toString().toUpperCase();
      if (dateStr != null) {
        try {
          final dt = DateTime.parse(dateStr.toString()).toLocal();
          _lastVisitText = "LAST VISIT: ${DateFormat('dd MMM yyyy').format(dt)} ($type)";
        } catch (_) {
          _lastVisitText = "LAST VISIT: $dateStr ($type)";
        }
      }
    }
    if (outletProvider.checkedInOutletId == currentOutletId) {
      _isCheckedIn = true;
      _visitId = outletProvider.checkedInVisitId;
      _checkInTime = outletProvider.checkInTimeAndDate != null ? DateTime.tryParse(outletProvider.checkInTimeAndDate!) : null;
      isLoadingCheckIn = false;
      _buildTabViews();
    }

    try {
      final history = await ApiServices.getOutletHistory(outletId: currentOutletId);
      if (history != null && (history['status'] == true || history['status'] == 'success' || history['visit_history'] != null)) {
        final List visits = history['visit_history'] ?? [];
        if (mounted) {
          setState(() {
            _totalVisits = visits.length;
            if (visits.isNotEmpty) {
              final last = visits.first;
              final dateStr = last['visit_date'] ?? last['checkin_time'];
              final type = (last['visit_type'] ?? 'INDIVIDUAL').toString().toUpperCase();
              if (dateStr != null) {
                try {
                  final dt = DateTime.parse(dateStr.toString()).toLocal();
                  _lastVisitText = "LAST VISIT: ${DateFormat('dd MMM yyyy').format(dt)} ($type)";
                } catch (_) {
                  _lastVisitText = "LAST VISIT: $dateStr ($type)";
                }
              }
            }
          });
        }
        final activeVisit = visits.firstWhere(
          (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
          orElse: () => null,
        );

        if (activeVisit != null) {
          final visitId = int.tryParse(activeVisit['visit_id']?.toString() ?? "") ?? 0;
          final checkInTimeStr = activeVisit['checkin_time']?.toString() ?? "";
          final checkInTime = DateTime.tryParse(checkInTimeStr);
          final activeType = (activeVisit['visit_type'] ?? 'INDIVIDUAL').toString().toUpperCase();

          await SessionManager.saveOutletCheckIn(
            outletId: currentOutletId,
            visitId: visitId,
            checkInTime: checkInTime ?? DateTime.now(),
            visitType: activeType,
          );

          if (mounted) {
            setState(() {
              _isCheckedIn = true;
              _visitId = visitId;
              _checkInTime = checkInTime;
              _visitType = activeType;
              isLoadingCheckIn = false;
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
        isLoadingCheckIn = false;
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
  String _visitType = "INDIVIDUAL";

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

  Future<String?> _showVisitTypeDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Select Visit Type",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Please choose visit type to proceed with check-in at ${widget.outlet.name}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                // INDIVIDUAL Option
                InkWell(
                  onTap: () => Navigator.pop(ctx, "INDIVIDUAL"),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Individual Visit",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Solo visit to outlet",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // COMBINE Option
                InkWell(
                  onTap: () => Navigator.pop(ctx, "COMBINE"),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups, color: Colors.deepOrange, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Combine Visit",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Joint visit with Area Manager / Team",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepOrange),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCheckIn() async {
    final visitType = await _showVisitTypeDialog();
    if (visitType == null) {
      // User cancelled
      return;
    }

    if (!mounted) return;
    LoadingDialog.show(context, message: "Checking in ($visitType)...");
    try {
      final coords = await LocationService.getCoordinates();
      final currentLat = double.parse(coords[0]);
      final currentLng = double.parse(coords[1]);

      final outletId = int.tryParse(widget.outlet.id) ?? 0;

      final response = await ApiServices.outletCheckIn(
        outletId: outletId,
        latitude: currentLat,
        longitude: currentLng,
        visitType: visitType,
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
          visitType: visitType,
        );

        if (mounted) {
          Provider.of<OutletProvider>(context, listen: false).updateLocalCheckIn(
            outletId: outletId,
            visitId: visitId,
            checkInTime: checkInTime.toIso8601String(),
            visitType: visitType,
          );

          setState(() {
            _isCheckedIn = true;
            _visitId = visitId;
            _checkInTime = checkInTime;
            _visitType = visitType;
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
          Provider.of<OutletProvider>(context, listen: false).clearLocalCheckIn();

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
      body: (isLoadingTabs || isLoadingCheckIn || isLocationValid == null)
          ? const Center(child: LogoProgressIndicator()) 
          : Column(
        children: [
          outletCard(widget.outlet),
          if (_isCheckedIn) ...[
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Checked-in ($_visitType)",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (_checkInTime != null)
                                Text(
                                  DateFormatter.formatDateTime(_checkInTime!.toIso8601String()),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final outletProvider = context.watch<OutletProvider>();
    final outletIdNum = int.tryParse(outlet.id) ?? 0;
    final int visitsCount = _totalVisits > 0 
        ? _totalVisits 
        : outletProvider.getOutletVisitsCount(outletIdNum);
    
    String? lastVisitDisplay = _lastVisitText;
    if (lastVisitDisplay == null) {
      final lastV = outletProvider.getOutletLastVisit(outletIdNum);
      if (lastV != null) {
        final dStr = lastV['visit_date'] ?? lastV['checkin_time'];
        final tStr = (lastV['visit_type'] ?? 'INDIVIDUAL').toString().toUpperCase();
        if (dStr != null) {
          try {
            final dt = DateTime.parse(dStr.toString()).toLocal();
            lastVisitDisplay = "LAST VISIT: ${DateFormat('dd MMM yyyy').format(dt)} ($tStr)";
          } catch (_) {
            lastVisitDisplay = "LAST VISIT: $dStr ($tStr)";
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "OUTLET ID: ${outlet.id}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (visitsCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF90CAF9)),
                            ),
                            child: Text(
                              "$visitsCount VISITS",
                              style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isCardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _isCardExpanded = !_isCardExpanded;
                  });
                },
              ),
            ],
          ),

          if (_isCardExpanded) ...[
            const Divider(height: 20),

            Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(outlet.owner.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.phone, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(outlet.phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),

            if (lastVisitDisplay != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.history, size: 18, color: Color(0xFF1976D2)),
                  const SizedBox(width: 8),
                  Text(
                    lastVisitDisplay,
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (outlet.type.isNotEmpty)
                    Text(
                      outlet.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w600,
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

            const SizedBox(height: 12),

            // Buttons Row 1: VISIT HISTORY & TRANSACTIONS
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF90CAF9)),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFE3F2FD),
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.history, size: 16, color: Color(0xFF1976D2)),
                      label: const Text(
                        "VISIT HISTORY",
                        style: TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VisitsScreen(
                              initialOutletId: int.tryParse(widget.outlet.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        "TRANSACTIONS",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Buttons Row 2: CALL & DIRECTIONS
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.green),
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.green.withValues(alpha: 0.05),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        CallService.makeCall(outlet.phone);
                      },
                      child: const Text(
                        "CALL",
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.green),
                      borderRadius: BorderRadius.circular(6),
                      color: AppColors.green.withValues(alpha: 0.05),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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