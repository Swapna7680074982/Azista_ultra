import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../profile.dart';
import '../../services/call_service.dart';
import '../Distribution_networking/distribution_provider.dart';
import '../Distribution_networking/outlets/outlet_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCheckInStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final distProvider = Provider.of<DistributionProvider>(context, listen: false);
      final routeId = distProvider.selectedRouteId != null 
          ? int.tryParse(distProvider.selectedRouteId!) 
          : null;
      final provider = context.read<OutletProvider>();
      await provider.refreshNearbyOutlets(routeId: routeId);
      if (mounted) {
        _checkServerCheckInStatus(provider.nearbyOutlets);
      }
    });
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
    return InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PosBaseScreen(outlet: outlet),
            ),
          );
          _loadCheckInStatus();
        },
    child :Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(outlet.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("OUTLET ID: ${outlet.id}", style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
                  if (outlet.distanceKm != null)
                    Text("${outlet.distanceKm!.toStringAsFixed(2)} km away", style: TextStyle(color: Colors.red.shade700, fontSize: 15, fontWeight: FontWeight.bold)),
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
                  Text(outlet.owner.toUpperCase(), style: TextStyle(color: Colors.grey.shade900,fontSize: 18)),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(Icons.phone, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 12),
                  Text(outlet.phone, style: TextStyle(color: Colors.grey.shade900,fontSize: 18)),
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
          if (outlet.name.toUpperCase() == "TESTING")
            Positioned(
              top: 50,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primary,
                alignment: Alignment.center,
                child: const Text(
                  "UNFREEZE OUTLET",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    )
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
