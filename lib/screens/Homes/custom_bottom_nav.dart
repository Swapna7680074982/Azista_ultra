import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../permissions/AccessValidator.dart';
import '../../permissions/AppStateProvider.dart';
import '../Distribution_networking/outlets/outlet_provider.dart';
import '../Distribution_networking/distribution_provider.dart';
import 'HomeProvider.dart';
import '../attendance/attendance_provider.dart';
import 'main_tab_provider.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MainTabProvider>();

    return SafeArea(
      top: false,
      child:  Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: AppColors.shadow,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItemIcon(context, Icons.access_time, "Home", 0),
              navItemIcon(context, Icons.receipt_long, "User Trans.", 1),
              const SizedBox(width: 70),

              navItemIcon(context, Icons.account_tree_outlined, "Dist. Net.", 3),
              navItemIcon(context, Icons.check_circle, "Attendance", 4),
            ],
          ),

          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: () {
                final appState =
                Provider.of<AppStateProvider>(context, listen: false);

                if (!AccessValidator.validateTab(
                  context: context,
                  isOnline: appState.isOnline,
                  hasDistributor: appState.selectedDistributor != null,
                  index: 2,
                )) {
                  return;
                }

                if (provider.currentIndex != 2) {
                  provider.setTab(2);
                }
              },
              child: Column(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8E0E13), // dark red outer circle
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935), // light red middle circle
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: const BoxDecoration(
                              color: Colors.white, // white inner circle
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on,
                                color: Color(0xFF8E0E13), // dark red icon
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Near Me",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: provider.currentIndex == 2
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: provider.currentIndex == 2
                          ? AppColors.button
                          : const Color(0xFF8C7B87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget navItemIcon(
      BuildContext context,
      IconData icon,
      String text,
      int index,
      ) {
    final provider = context.watch<MainTabProvider>();
    final selected = provider.currentIndex == index;

    return GestureDetector(
      onTap: () {
        final appState =
        Provider.of<AppStateProvider>(context, listen: false);

        if (!AccessValidator.validateTab(
          context: context,
          isOnline: appState.isOnline,
          hasDistributor: appState.selectedDistributor != null,
          index: index,
        )) {
          return;
        }

        if (index == 0) {
          appState.setSelectedDistributor(null, null);
        }

        if (provider.currentIndex != index) {
          provider.setTab(index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? AppColors.button : const Color(0xFF8C7B87),
          ),
          const SizedBox(height: 6),
          Text(
            text.length > 12 ? "${text.substring(0, 12)}..." : text,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.button : const Color(0xFF8C7B87),
            ),
          ),
        ],
      ),
    );
  }
}