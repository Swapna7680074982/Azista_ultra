import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../profile.dart';
import 'distribution_provider.dart';
import 'outlets/outlets_screen.dart';
import '../../utilities/common_widgets.dart';

class DistributionNetworkScreen extends StatefulWidget {
  final bool isFromDashboard;
  const DistributionNetworkScreen({super.key, this.isFromDashboard = false});

  @override
  State<DistributionNetworkScreen> createState() =>
      _DistributionNetworkScreenState();
}

class _DistributionNetworkScreenState
    extends State<DistributionNetworkScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<DistributionProvider>(context, listen: false)
            .fetchRoutes());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DistributionProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: widget.isFromDashboard ? null : const ProfileDrawer(selectedMenu: "Distribution Network"),
      appBar: AppBar(
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
        toolbarHeight: 60,
        titleSpacing: 0,
        leading: widget.isFromDashboard
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              )
            : Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: const Icon(Icons.menu,
                        color: AppColors.white, size: 26),
                  ),
                ),
              ),
        title: const Text(
          "Distribution Network",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: provider.isLoading
          ? const Center(child: LogoProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: provider.selectedRegion,
                  hint: const Text("Select Region"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                  ),
                  items: provider.regions.map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setRegion(value);
                    }
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: provider.selectedArea,
                  hint: const Text("Select Area"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                  ),
                  items: provider.areas.map((area) {
                    return DropdownMenuItem(
                      value: area,
                      child: Text(area.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setArea(value);
                    }
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: provider.selectedHq,
                  hint: const Text("Select HQ"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                  ),
                  items: provider.hqs.map((hq) {
                    return DropdownMenuItem(
                      value: hq,
                      child: Text(hq.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setHq(value);
                    }
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: provider.selectedBeat,
                  hint: const Text("Select Beat"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                  ),
                  items: provider.beats.map((beat) {
                    return DropdownMenuItem(
                      value: beat,
                      child: Text(beat.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      provider.setBeat(value);
                    }
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlue,
                minimumSize: const Size(double.infinity, 45),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: provider.selectedBeat == null || provider.selectedRouteId == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OutletsScreen(
                      routeId: int.tryParse(provider.selectedRouteId!) ?? 0,
                      routeName: provider.selectedBeat!,
                    ),
                  ),
                );
              },
              child: const Text(
                "SHOW OUTLETS IN THIS BEAT",
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}