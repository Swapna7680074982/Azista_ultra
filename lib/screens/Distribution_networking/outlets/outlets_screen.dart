import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../constants/app_colors.dart';
import '../../../services/call_service.dart';
import '../../../services/directions_map_screen.dart';
import '../../../services/location_service.dart';
import '../../../permissions/SessionManager.dart';
import 'NewOutletScreen.dart';
import 'PobScreen.dart';
import 'PosBaseScreen.dart';
import 'outlet_provider.dart';
import '../../../utilities/date_formatter.dart';
import '../../../services/api_services.dart';
import '../../../utilities/common_widgets.dart';

class OutletsScreen extends StatefulWidget {
  final int routeId;
  final String routeName;

  const OutletsScreen({
    super.key,
    required this.routeId,
    required this.routeName,
  });

  @override
  State<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends State<OutletsScreen> {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    _loadCheckInStatus();
    final provider = Provider.of<OutletProvider>(context, listen: false);
    await Future.wait([
      _loadUserLocation(),
      provider.fetchOutlets(widget.routeId),
    ]);
    if (mounted) {
      _checkServerCheckInStatus(provider.outlets);
    }
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
      debugPrint("Error loading user location for outlets: $e");
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
      if (provider.outlets.isNotEmpty) {
        _checkServerCheckInStatus(provider.outlets);
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
                    fontSize: 18,
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

          Text("OUTLET ID: ${outlet.id}", style: const TextStyle(fontSize: 15)),
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
          ] else if (distance != null) ...[
            const SizedBox(height: 4),
            Text(
              "DISTANCE: ${distance.toStringAsFixed(0)}m ${distance > 50 ? '(> 50m limit)' : '(Within range)'}",
              style: TextStyle(
                color: distance > 50 ? Colors.red.shade700 : Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          const Divider(),

          Row(
            children: [
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Text(outlet.owner.toUpperCase(), style: const TextStyle(fontSize: 18)),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.phone, size: 20),
              const SizedBox(width: 8),
              Text(outlet.phone, style: const TextStyle(fontSize: 18)),
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
                            outletName: outlet.name.toUpperCase(),
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
      appBar: AppBar(
        title: const Text(
          "OUTLETS",
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewOutletScreen(
                    routeId: widget.routeId,
                    routeName: widget.routeName,
                  ),
                ),
              );
              if (result == true) {
                // Refresh list if registration was successful
                provider.fetchOutlets(widget.routeId);
              }
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ROUTE",
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.routeName.toUpperCase()),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (value) {
                context.read<OutletProvider>().updateSearch(value);
              },
              decoration: InputDecoration(
                hintText: "SEARCH BY OUTLET / OWNER / PHONE",
                suffixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.inputFill,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: provider.isLoading 
                ? const LogoProgressIndicator() 
                : provider.outlets.isEmpty 
                    ? const Center(child: Text("No outlets found")) 
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadUserLocation();
                          await provider.fetchOutlets(widget.routeId);
                          if (mounted) {
                            _checkServerCheckInStatus(provider.outlets);
                          }
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: provider.outlets.length,
                          itemBuilder: (context, index) {
                            return outletCard(provider.outlets[index], context);
                          },
                        ),
                      ),
          )
        ],
      ),
    );
  }
}