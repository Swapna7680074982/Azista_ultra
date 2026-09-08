import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../services/call_service.dart';
import '../../../services/directions_map_screen.dart';
import '../../../permissions/SessionManager.dart';
import 'NewOutletScreen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCheckInStatus();
    final provider = Provider.of<OutletProvider>(context, listen: false);
    Future.microtask(() async {
      await provider.fetchOutlets(widget.routeId);
      if (mounted) {
        _checkServerCheckInStatus(provider.outlets);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(outlet.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

          Text("OUTLET ID: ${outlet.id}",style: const TextStyle(fontSize: 15)),
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
    )
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
                    : ListView.builder(
              itemCount: provider.outlets.length,
              itemBuilder: (context, index) {
                return outletCard(provider.outlets[index], context);
              },
            ),
          )
        ],
      ),
    );
  }
}