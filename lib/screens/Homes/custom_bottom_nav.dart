import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/image_constants.dart';
import '../../permissions/AccessValidator.dart';
import '../../permissions/AppStateProvider.dart';
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
              navItemIcon(context, Icons.access_time, "Attend.", 0),
              navItemIcon(context, Icons.event_note, "Leave Management", 1),
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

                provider.setTab(2);
              },
              child: Column(
                children: [
                  Image.asset(
                    ImageConstants.nearme,
                    height: 70,
                    width: 70,
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
                          ? AppColors.primary
                          : Colors.black54,
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

        provider.setTab(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? AppColors.primary : Colors.black54,
          ),
          const SizedBox(height: 6),
          Text(
            text.length > 12 ? "${text.substring(0, 12)}..." : text,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.primary : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}