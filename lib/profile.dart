import 'package:azista_ultra/permissions/AccessValidator.dart';
import 'package:azista_ultra/permissions/AppStateProvider.dart';
import 'package:azista_ultra/permissions/SessionManager.dart';
import 'package:azista_ultra/screens/Distribution_networking/distribution_network_screen.dart';
import 'package:azista_ultra/screens/Homes/HomeScreen.dart';
import 'package:azista_ultra/screens/Homes/change_password.dart';
import 'package:azista_ultra/screens/Homes/main_tab_provider.dart';
import 'package:azista_ultra/screens/Homes/near_me_screen.dart';
import 'package:azista_ultra/screens/Homes/support.dart';
import 'package:azista_ultra/screens/login/login_screen.dart';
import 'package:azista_ultra/services/api_services.dart';
import 'package:flutter/cupertino.dart';
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
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(role.toUpperCase()),
                    const SizedBox(height: 4),
                    Text("Version: $version"),
                  ],
                );
              },
            ),
          ),

          sectionTitle("GENERAL"),

          menuItem(context, "Dashbard"),
          menuItem(context, "Near Me"),
          menuItem(context, "Distribution Network"),

          const Divider(),

          sectionTitle("OTHERS"),

          menuItem(context, "Support"),
          //menuItem(context, "FAQ"),
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
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
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
        title: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black),
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

            case "Near Me":
              navProvider.setTab(2);
              break;

            case "Distribution Network":
              navProvider.setTab(3);
              break;

            case "Support":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
              break;

            case "Change Password":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
              break;

            case "Logout":
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
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          content: const Text(
            "Do you want to log out?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.pink)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                navigator.pop();
                await ApiServices.logout();
                await SessionManager.clearSession();
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
