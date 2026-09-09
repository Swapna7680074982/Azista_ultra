import 'package:azista_ultra/permissions/AccessValidator.dart';
import 'package:azista_ultra/permissions/AppStateProvider.dart';
import 'package:azista_ultra/permissions/SessionManager.dart';
import 'package:azista_ultra/screens/Homes/HomeProvider.dart';
import 'package:azista_ultra/screens/Homes/change_password.dart';
import 'package:azista_ultra/screens/Homes/main_tab_provider.dart';
import 'package:azista_ultra/screens/Homes/support.dart';
import 'package:azista_ultra/screens/login/login_screen.dart';
import 'package:azista_ultra/screens/geo_requests/my_geo_requests_screen.dart';
import 'package:azista_ultra/screens/geo_requests/outlet_geo_requests_screen.dart';
import 'package:azista_ultra/screens/distribution_list/MyTeamScreen.dart';
import 'package:azista_ultra/screens/attendance/TeamAttendanceScreen.dart';
import 'package:azista_ultra/screens/distribution_list/TeamPosHistoryScreen.dart';
import 'package:azista_ultra/screens/profile_screen.dart';
import 'package:azista_ultra/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';

class ProfileDrawer extends StatelessWidget {
  final String selectedMenu;

  const ProfileDrawer({super.key, required this.selectedMenu});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
            color: AppColors.white,
            child: FutureBuilder<Map<String, String>>(
              future: _loadProfileInfo(),
              builder: (context, snapshot) {
                final name = snapshot.data?["name"] ?? "Loading...";
                final role = snapshot.data?["role"] ?? "Loading...";
                final version = snapshot.data?["version"] ?? "Loading...";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.toUpperCase(),
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Version: $version",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          sectionTitle("GENERAL"),

          menuItem(context, "Dashboard"),
          menuItem(context, "Profile"),
          menuItem(context, "Near Me"),
          menuItem(context, "Distribution Network"),
          menuItem(context, "My Geo Requests"),

          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              if (appState.userRole == 'AM' || appState.userRole == 'RM' || appState.userRole == 'ASM') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    sectionTitle("TEAM MANAGEMENT"),
                    menuItem(context, "My Team"),
                    menuItem(context, "Team Attendance"),
                    menuItem(context, "Team POB History"),
                    menuItem(context, "Outlet Geo Requests"),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const Divider(),

          sectionTitle("OTHERS"),

          menuItem(context, "Support"),
          menuItem(context, "Change Password"),
          menuItem(context, "Logout"),
        ],
      ),
    );
  }

  Future<Map<String, String>> _loadProfileInfo() async {
    final name = await SessionManager.getUserName();
    final role = await SessionManager.getUserRole();
    String version = "Unknown";
    try {
      final pubspec = await rootBundle.loadString('pubspec.yaml');
      final lines = pubspec.split('\n');
      for (var line in lines) {
        if (line.startsWith('version:')) {
          version = line.split(':')[1].trim();
          break;
        }
      }
    } catch (e) {
      version = "1.0.0";
    }
    return {"name": name, "role": role, "version": version};
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget menuItem(BuildContext context, String title) {
    final bool isSelected = title == selectedMenu;

    return Container(
      color: isSelected ? AppColors.primary : Colors.transparent,
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          final navProvider = Provider.of<MainTabProvider>(
            context,
            listen: false,
          );

          final appState = Provider.of<AppStateProvider>(
            context,
            listen: false,
          );

          bool allowed = true;

          if (title == "Dashboard") {
            allowed = AccessValidator.validate(
              context: context,
              isOnline: appState.isOnline,
              hasDistributor: true,
              isLeave: false,
              checkDistributor: false,
            );
          } else if (title == "Near Me" || title == "Distribution Network") {
            allowed = AccessValidator.validate(
              context: context,
              isOnline: appState.isOnline,
              hasDistributor: appState.selectedDistributor != null,
              isLeave: false,
              checkDistributor: true,
            );
          }

          if (!allowed) return;

          Navigator.pop(context);

          switch (title) {
            case "Dashboard":
              navProvider.setTab(0);
              break;

            case "Profile":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;

            case "Near Me":
              navProvider.setTab(2);
              break;

            case "Distribution Network":
              navProvider.setTab(3);
              break;

            case "My Geo Requests":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyGeoRequestsScreen()),
              );
              break;

            case "My Team":
              if (!appState.isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please turn on attendance first.")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyTeamScreen()),
              );
              break;

            case "Team Attendance":
              if (!appState.isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please turn on attendance first.")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamAttendanceScreen()),
              );
              break;

            case "Team POB History":
              if (!appState.isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please turn on attendance first.")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamPosHistoryScreen()),
              );
              break;

            case "Outlet Geo Requests":
              if (!appState.isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please turn on attendance first.")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OutletGeoRequestsScreen()),
              );
              break;

            case "Support":
              navProvider.setTab(0);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
              break;

            case "Change Password":
              navProvider.setTab(0);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
              break;

            case "Logout":
              navProvider.setTab(0);
              _showLogoutDialog(context);
              break;
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          content: const Text(
            "Do you want to log out?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: Colors.pink)),
            ),
            TextButton(
              onPressed: () async {
                final appState = Provider.of<AppStateProvider>(dialogContext, listen: false);
                final homeProvider = Provider.of<HomeProvider>(dialogContext, listen: false);
                final navigator = Navigator.of(dialogContext, rootNavigator: true);

                navigator.pop();
                await ApiServices.logout();
                await SessionManager.clearSession();

                // Clear active in-memory providers to prevent leakage
                appState.reset();
                homeProvider.reset();

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              },
              child: const Text("OK", style: TextStyle(color: Colors.pink)),
            ),
          ],
        );
      },
    );
  }
}
