import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../profile.dart';
import 'distribution_provider.dart';
import 'outlets/outlets_screen.dart';


class DistributionNetworkScreen extends StatelessWidget {
  const DistributionNetworkScreen({super.key});

  Widget dropdownCard(String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DistributionProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      drawer: const ProfileDrawer(selectedMenu: "Distribution Network"),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 60,
        titleSpacing: 0,

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
        title: const Text(
          "Distribution Network",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: provider.selectedCity,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  items: provider.cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) provider.setCity(value);
                  },
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: provider.selectedPoint,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  items: provider.points.map((point) {
                    return DropdownMenuItem(
                      value: point,
                      child: Text(point),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) provider.setPoint(value);
                  },
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: provider.selectedRoute,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  items: provider.routes.map((route) {
                    return DropdownMenuItem(
                      value: route,
                      child: Text(route),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) provider.setRoute(value);
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
                minimumSize: const Size(double.infinity, 40),

                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OutletsScreen(),
                  ),
                );
              },
              child: const Text(
                "SHOW OUTLETS IN THIS ROUTE",
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}