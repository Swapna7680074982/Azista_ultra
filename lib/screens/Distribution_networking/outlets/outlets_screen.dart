import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../services/call_service.dart';
import '../../../services/directions_map_screen.dart';
import '../../../permissions/SessionManager.dart';
import 'NewOutletScreen.dart';
import 'PosBaseScreen.dart';
import 'outlet_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCheckInStatus();
    Future.microtask(() {
      Provider.of<OutletProvider>(context, listen: false)
          .fetchOutlets(widget.routeId);
    });
  }

  Future<void> _loadCheckInStatus() async {
    final id = await SessionManager.getOutletCheckInOutletId();
    if (mounted) {
      setState(() {
        _checkedInOutletId = id;
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
                ? const Center(child: CircularProgressIndicator()) 
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