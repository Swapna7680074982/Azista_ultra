import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AppStateProvider.dart';
import '../profile_screen.dart';
import '../Homes/HomeProvider.dart';
import '../Distribution_networking/distribution_network_screen.dart';
import '../../utilities/date_formatter.dart';
import '../attendance/TeamAttendanceScreen.dart';

class RmDashboardScreen extends StatefulWidget {
  const RmDashboardScreen({super.key});

  @override
  State<RmDashboardScreen> createState() => _RmDashboardScreenState();
}

class _RmDashboardScreenState extends State<RmDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await homeProvider.initializeAttendance(appState);
      await homeProvider.loadDistributors(appState);
      await homeProvider.fetchTodayAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final hasValidDistributor = appState.selectedDistributor != null &&
        homeProvider.distributors.any((d) => d["distributor_name"] == appState.selectedDistributor);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(80),
                bottomRight: Radius.circular(80),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "AZISTA RM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Attendance Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "ATTENDANCE: ",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      homeProvider.isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: appState.isOnline,
                                activeColor: Colors.white,
                                activeTrackColor: Colors.greenAccent,
                                onChanged: (val) async {
                                  bool success = false;
                                  if (val) {
                                    success = await homeProvider.checkIn();
                                    if (success) {
                                      appState.setOnline(true);
                                      await homeProvider.fetchTodayAttendance();
                                    }
                                  } else {
                                    success = await homeProvider.checkOut();
                                    if (success) {
                                      appState.setOnline(false);
                                      await homeProvider.fetchTodayAttendance();
                                    }
                                  }
                                  if (homeProvider.message != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(homeProvider.message!)),
                                    );
                                  }
                                },
                              ),
                            ),
                    ],
                  ),
                  // Session Details
                  if (appState.isOnline && homeProvider.todayAttendance != null)
                    _buildSessionInfo(homeProvider.todayAttendance!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("SELECT DISTRIBUTOR", style: TextStyle(fontSize: 13)),
                  value: homeProvider.distributors.any((d) => d["distributor_name"] == appState.selectedDistributor)
                      ? appState.selectedDistributor
                      : null,
                  items: homeProvider.distributors.map<DropdownMenuItem<String>>((d) {
                    return DropdownMenuItem<String>(
                      value: d["distributor_name"],
                      child: Text(d["distributor_name"], style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),

                  onChanged: appState.isOnline ? (value) {
                    final selected = homeProvider.distributors.firstWhere(
                          (d) => d["distributor_name"] == value,
                      orElse: () => null,
                    );
                    int? id;
                    if (selected != null) {
                      if (selected["distributor_id"] is int) {
                        id = selected["distributor_id"];
                      } else if (selected["distributor_id"] != null) {
                        id = int.tryParse(selected["distributor_id"].toString());
                      }
                    }
                    appState.setDistributor(value, id: id);
                  } : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Error Message Box
          if (!appState.isOnline || !hasValidDistributor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        !appState.isOnline
                            ? "Please turn on attendance to access dashboard features."
                            : "Please select a distributor to continue.",
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              children: [
                _buildMenuItem(
                  iconPath: Icons.people_outline,
                  label: "Team Attendance",
                  enabled: appState.isOnline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamAttendanceScreen()),
                    );
                  },
                ),
                // _buildMenuItem(
                //   iconPath: Icons.track_changes,
                //   label: "SO Daily Targets",
                //   enabled: appState.isOnline,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (_) => const SelectSoScreen()),
                //     );
                //   },
                // ),
                _buildMenuItem(
                  iconPath: Icons.track_changes,
                  label: "Distribution Network",
                  enabled: appState.isOnline && hasValidDistributor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DistributionNetworkScreen(isFromDashboard: true),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.person_outline,
                  label: "Profile",
                  enabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(Map<String, dynamic> data) {
    final sessions = data["sessions"] ?? [];
    String checkIn = "-";
    String workingHours = "0";

    if (sessions.isNotEmpty) {
      final lastSession = sessions.last;
      checkIn = lastSession["check_in"] ?? "-";
      workingHours = lastSession["working_hours"]?.toString() ?? "0";
    }

    return Column(
      children: [
        Text(
          "CHECK-IN: ${checkIn != "-" ? DateFormatter.formatDateTime(checkIn) : "-"}",
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          "WORKING HOURS: $workingHours hrs",
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData iconPath,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: Icon(iconPath, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 25),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
