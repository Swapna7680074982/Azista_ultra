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
        actions: [
          IconButton(
            tooltip: "Refresh Routes",
            icon: const Icon(Icons.sync, color: AppColors.white),
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Refreshing routes..."),
                  duration: Duration(milliseconds: 900),
                ),
              );
              await context.read<DistributionProvider>().fetchRoutes();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async => context.read<DistributionProvider>().fetchRoutes(),
        color: AppColors.primary,
        child: provider.isLoading
            ? const Center(child: LogoProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // State Dropdown
                          DropdownButtonFormField<String>(
                            icon: provider.states.length <= 1 ? const SizedBox.shrink() : null,
                            value: provider.selectedState,
                            hint: const Text("Select State"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: InputBorder.none,
                            ),
                            items: provider.states.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(state.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                provider.setStateValue(value);
                              }
                            },
                          ),

                          const SizedBox(height: 14),

                          // City Dropdown
                          DropdownButtonFormField<String>(
                            icon: provider.cities.length <= 1 ? const SizedBox.shrink() : null,
                            value: provider.selectedCity,
                            hint: const Text("Select HQ"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: InputBorder.none,
                            ),
                            items: provider.cities.map((city) {
                              return DropdownMenuItem(
                                value: city,
                                child: Text(city.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                provider.setCity(value);
                              }
                            },
                          ),

                          const SizedBox(height: 14),

                          // Route Dropdown
                          DropdownButtonFormField<String>(
                            icon: provider.routes.length <= 1 ? const SizedBox.shrink() : null,
                            value: provider.selectedRoute,
                            hint: const Text("Select Route"),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputFill,
                              border: InputBorder.none,
                            ),
                            items: provider.routes.map((route) {
                              return DropdownMenuItem(
                                value: route,
                                child: Text(route.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                provider.setRoute(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button positioned neatly above bottom bar
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlue,
                            foregroundColor: Colors.white,
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: provider.selectedRoute == null || provider.selectedRouteId == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OutletsScreen(
                                        routeId: int.tryParse(provider.selectedRouteId!) ?? 0,
                                        routeName: provider.selectedRoute!,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            "SHOW OUTLETS IN THIS ROUTE",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}