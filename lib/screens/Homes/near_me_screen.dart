import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../profile.dart';
import '../../services/call_service.dart';
import '../../services/location_service.dart';
import '../Distribution_networking/distribution_provider.dart';
import '../Distribution_networking/outlets/outlet_provider.dart';
import '../Distribution_networking/outlets/PobScreen.dart';
import '../Distribution_networking/outlets/PosBaseScreen.dart';
import '../../services/directions_map_screen.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../permissions/SessionManager.dart';
import '../../utilities/date_formatter.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({super.key});

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  int? _checkedInOutletId;
  String? _checkInTimeAndDate;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    final cached = LocationService.cachedCoordinates;
    _userLat = double.tryParse(cached[0]);
    _userLng = double.tryParse(cached[1]);

    _loadCheckInStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final distProvider = Provider.of<DistributionProvider>(context, listen: false);
      final routeId = distProvider.selectedRouteId != null 
          ? int.tryParse(distProvider.selectedRouteId!) 
          : null;
      final provider = context.read<OutletProvider>();
      await Future.wait([
        _loadUserLocation(),
        provider.refreshNearbyOutlets(routeId: routeId),
      ]);
      if (mounted) {
        _checkServerCheckInStatus(provider.nearbyOutlets);
      }
    });
  }

  Future<void> _loadUserLocation() async {
    try {
      final coords = await LocationService.getCoordinates();
      if (mounted) {
        setState(() {
          _userLat = double.tryParse(coords[0]);
          _userLng = double.tryParse(coords[1]);
        });
      }
    } catch (e) {
      debugPrint("Error loading user location for near me: $e");
    }
  }

  double? _getDistanceToOutlet(Outlet outlet) {
    if (outlet.distanceKm != null) {
      return outlet.distanceKm! * 1000;
    }
    if (_userLat == null || _userLng == null) return null;
    if (outlet.latitude == 0.0 && outlet.longitude == 0.0) return null;
    return Geolocator.distanceBetween(_userLat!, _userLng!, outlet.latitude, outlet.longitude);
  }

  void _showBlockedOutletDialog(Outlet outlet, double? distance) {
    showDialog(
      context: context,
      builder: (ctx) {
        final distStr = distance != null ? "${distance.toStringAsFixed(0)} meters" : "out of range";
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Outlet Restricted",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You are currently $distStr away from ${outlet.name.toUpperCase()}.\n\nPhysical visits require you to be within 50 meters of the outlet.",
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "To place an order remotely without check-in, choose Tele POB.",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("UNBLOCK (RETRY GPS)", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                LoadingDialog.show(context, message: "Checking location...");
                await _loadUserLocation();
                if (!mounted) return;
                LoadingDialog.hide(context);

                final newDist = _getDistanceToOutlet(outlet);
                if (newDist != null && newDist <= 50) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Location verified! Outlet unblocked.")),
                  );
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PosBaseScreen(outlet: outlet),
                    ),
                  );
                  _loadCheckInStatus();
                } else {
                  final distMsg = newDist != null ? "${newDist.toStringAsFixed(0)}m" : "Unknown";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Still out of range ($distMsg). You must be within 50m.")),
                  );
                }
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.phone_in_talk, size: 16),
              label: const Text("TELE POB", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PobScreen(
                      outletId: int.tryParse(outlet.id) ?? 0,
                      outletName: outlet.name,
                      outletLat: outlet.latitude,
                      outletLng: outlet.longitude,
                      isTelePob: true,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkServerCheckInStatus(List<Outlet> outlets) async {
    if (_checkedInOutletId != null) return;
    try {
      final futures = outlets.map((outlet) async {
        final currentId = int.tryParse(outlet.id);
        if (currentId == null) return null;
        final history = await ApiServices.getOutletHistory(outletId: currentId);
        if (history != null && history['status'] == true) {
          final List visits = history['visit_history'] ?? [];
          final activeVisit = visits.where(
            (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
          ).firstOrNull;
          if (activeVisit != null) {
            return {
              'outlet_id': currentId,
              'visit_id': int.tryParse(activeVisit['visit_id']?.toString() ?? "") ?? 0,
              'checkin_time': activeVisit['checkin_time']?.toString(),
            };
          }
        }
        return null;
      }).toList();

      final results = await Future.wait(futures);
      final activeCheckIn = results.where((r) => r != null).firstOrNull;

      if (activeCheckIn != null && mounted) {
        final outletId = activeCheckIn['outlet_id'] as int;
        final visitId = activeCheckIn['visit_id'] as int;
        final checkinTimeStr = activeCheckIn['checkin_time'] as String?;
        final checkInTime = DateTime.tryParse(checkinTimeStr ?? "");

        await SessionManager.saveOutletCheckIn(
          outletId: outletId,
          visitId: visitId,
          checkInTime: checkInTime ?? DateTime.now(),
        );

        setState(() {
          _checkedInOutletId = outletId;
          _checkInTimeAndDate = checkinTimeStr;
        });
      }
    } catch (e) {
      debugPrint("Error checking server check-in status: $e");
    }
  }

  Future<void> _loadCheckInStatus() async {
    final provider = Provider.of<OutletProvider>(context, listen: false);
    final id = await SessionManager.getOutletCheckInOutletId();
    if (mounted) {
      setState(() {
        _checkedInOutletId = id;
      });
    }

    if (id != null) {
      try {
        final history = await ApiServices.getOutletHistory(outletId: id);
        if (history != null && history['status'] == true) {
          final List visits = history['visit_history'] ?? [];
          final activeVisit = visits.where(
            (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
          ).firstOrNull;

          if (activeVisit != null) {
            final checkinTime = activeVisit['checkin_time']?.toString();
            if (mounted) {
              setState(() {
                _checkInTimeAndDate = checkinTime;
              });
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Error fetching check-in details: $e");
      }
    } else {
      if (provider.nearbyOutlets.isNotEmpty) {
        _checkServerCheckInStatus(provider.nearbyOutlets);
      }
    }

    if (mounted) {
      setState(() {
        _checkInTimeAndDate = null;
      });
    }
  }

  Widget outletCard(Outlet outlet, BuildContext context) {
    final isCheckedIn = _checkedInOutletId != null && _checkedInOutletId == int.tryParse(outlet.id);
    final distance = _getDistanceToOutlet(outlet);
    final isBlocked = distance != null && distance > 50;

    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  outlet.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isBlocked ? Colors.grey.shade700 : Colors.black,
                  ),
                ),
              ),
              if (isCheckedIn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "CHECKED IN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else if (distance != null)
                Text(
                  "${distance.toStringAsFixed(0)}m",
                  style: TextStyle(
                    color: distance > 50 ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("OUTLET ID: ${outlet.id}", style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
              if (distance != null)
                Text(
                  "${distance.toStringAsFixed(0)}m ${distance > 50 ? '(> 50m limit)' : '(In range)'}",
                  style: TextStyle(
                    color: distance > 50 ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (isCheckedIn && _checkInTimeAndDate != null) ...[
            const SizedBox(height: 4),
            Text(
              "CHECKED-IN: ${DateFormatter.formatDateTime(_checkInTimeAndDate)}",
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          const Divider(height: 24),

          Row(
            children: [
              Icon(Icons.person, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Text(outlet.owner.toUpperCase(), style: TextStyle(color: Colors.grey.shade900, fontSize: 18)),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.phone, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 12),
              Text(outlet.phone, style: TextStyle(color: Colors.grey.shade900, fontSize: 18)),
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
                    fontSize: 15,
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
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.green),
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.green.withValues(alpha: 0.05),
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
                    color: AppColors.green.withValues(alpha: 0.05),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectionsMapScreen(
                            outletLat: outlet.latitude,
                            outletLng: outlet.longitude,
                            outletName: outlet.name,
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
      ),
    );

    return InkWell(
      onTap: () async {
        if (isBlocked) {
          _showBlockedOutletDialog(outlet, distance);
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PosBaseScreen(outlet: outlet),
          ),
        );
        _loadCheckInStatus();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: isBlocked ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isBlocked
              ? Stack(
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                      child: cardContent,
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "BLOCKED (TAP FOR OPTIONS)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : cardContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OutletProvider>();

    return Scaffold(
      drawer: const ProfileDrawer(selectedMenu: "Near Me"),
      appBar: WavyAppBar(
        title: "NEAR ME",
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Icon(
                Icons.menu,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                context.read<OutletProvider>().updateSearch(value);
              },
              decoration: const InputDecoration(
                hintText: "Search by Outlet,Owner or Phone",
                hintStyle: TextStyle(color: Colors.black54),
                suffixIcon: Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(height: 1, color: Colors.grey.shade300),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Outlets with in 5 km radius",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          Expanded(
            child: provider.isLoading
                ? const LogoProgressIndicator()
                : provider.nearbyOutlets.isEmpty
                    ? const Center(child: Text("No nearby outlets found"))
                    : ListView.builder(
              itemCount: provider.nearbyOutlets.length,
              itemBuilder: (context, index) {
                return outletCard(provider.nearbyOutlets[index], context);
              },
            ),
          )
        ],
      ),
    );
  }
}
