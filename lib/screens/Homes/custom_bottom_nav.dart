import 'package:azista_ultra/constants/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import 'main_tab_provider.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MainTabProvider>();

    return SafeArea(
      top: false,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: AppColors.shadow,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                navItem(context, ImageConstants.attendance, "Attend.", 0),
                navItem(context, ImageConstants.marketing, "Marketing", 1),
                const SizedBox(width: 60),
                navItem(context, ImageConstants.distribution, "Dist. Net.", 3),
                navItem(context, ImageConstants.sync, "Sync", 4),
              ],
            ),
            Positioned(
              top: -25,
              child: GestureDetector(
                onTap: () => provider.setTab(2),
                child: Column(
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          ImageConstants.nearme,
                          color: AppColors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Near Me",
                      style: TextStyle(
                        fontSize: 11,
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

  Widget navItem(
      BuildContext context, String imagePath, String text, int index) {
    final provider = context.watch<MainTabProvider>();
    final selected = provider.currentIndex == index;

    return GestureDetector(
      onTap: () => provider.setTab(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image.asset(
          //   imagePath,
          //   height: 22,
          //   color: selected ? AppColors.primary : Colors.black54,
          // ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? AppColors.primary
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}