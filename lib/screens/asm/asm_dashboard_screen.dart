import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AppStateProvider.dart';
import '../../permissions/SessionManager.dart';
import '../profile_screen.dart';
import '../Distribution_networking/distribution_network_screen.dart';
import '../../utilities/date_formatter.dart';
import '../Homes/HomeProvider.dart';
import '../attendance/TeamAttendanceScreen.dart';
import '../distribution_list/TeamPosHistoryScreen.dart';
import '../distribution_list/MyTeamScreen.dart';
import '../geo_requests/outlet_geo_requests_screen.dart';

class AmDashboardScreen extends StatefulWidget {
  const AmDashboardScreen({super.key});

  @override
  State<AmDashboardScreen> createState() => _AmDashboardScreenState();
}

class _AmDashboardScreenState extends State<AmDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    Future.microtask(() async {
      final role = await SessionManager.getUserRole();
      appState.setUserRole(role);
      await homeProvider.initializeAttendance(appState);
      await homeProvider.loadDistributors(appState);
      await homeProvider.fetchTodayAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.button,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(80),
                bottomRight: Radius.circular(80),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ULTRA AM",
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
                                activeThumbColor: Colors.green,
                                activeTrackColor: Colors.green.withValues(alpha: 0.35),
                                inactiveThumbColor: AppColors.white,
                                inactiveTrackColor: AppColors.white.withValues(alpha: 0.4),
                                onChanged: (val) async {
                                  bool success = false;
                                  if (val) {
                                    success = await homeProvider.handleCheckInWithPhotoIfNeeded(context);
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
                                  if (homeProvider.message != null && context.mounted) {
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
                  if (appState.isOnline)
                    _buildSessionInfo(homeProvider.todayAttendance),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Error Message Box
          if (!appState.isOnline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please turn on attendance to access dashboard features.",
                        style: const TextStyle(
                          color: AppColors.primary,
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
                  iconPath: Icons.groups_outlined,
                  label: "My Team",
                  enabled: appState.isOnline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTeamScreen()),
                    );
                  },
                ),
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
                _buildMenuItem(
                  iconPath: Icons.history,
                  label: "Team POB History",
                  enabled: appState.isOnline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamPosHistoryScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  iconPath: Icons.edit_location_alt_outlined,
                  label: "Outlet Geo Requests",
                  enabled: appState.isOnline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OutletGeoRequestsScreen()),
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
                  enabled: appState.isOnline,
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
                  enabled: true, // Profile usually always accessible
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

  Widget _buildSessionInfo(Map<String, dynamic>? data) {
    final homeProvider = context.read<HomeProvider>();
    final sessions = data?["sessions"] ?? [];
    double totalHours = 0.0;
    String checkIn = "-";
    bool hasActiveSession = false;

    final today = DateTime.now();

    // Separate completed sessions and find the single latest active session
    Map<String, dynamic>? latestActiveSession;

    for (var session in sessions) {
      final sCheckIn = session["check_in"];
      // Only count sessions from today
      if (sCheckIn != null) {
        try {
          final sessionDate = DateTime.parse(sCheckIn.toString()).toLocal();
          if (sessionDate.year != today.year ||
              sessionDate.month != today.month ||
              sessionDate.day != today.day) {
            continue;
          }
        } catch (_) {}
      }

      final sCheckOut = session["check_out"];
      final sHours = double.tryParse(session["working_hours"]?.toString() ?? "0") ?? 0.0;

      if (sCheckOut != null) {
        // Completed session — add its recorded working hours
        totalHours += sHours;
      } else {
        // Active (no check-out) — keep only the latest one
        if (sCheckIn != null) {
          latestActiveSession = session;
        }
      }
    }

    // Add elapsed time for the single latest active session only
    if (latestActiveSession != null) {
      final sCheckIn = latestActiveSession["check_in"];
      checkIn = sCheckIn;
      hasActiveSession = true;
      try {
        final checkInTime = DateTime.parse(sCheckIn.toString()).toLocal();
        final diff = DateTime.now().difference(checkInTime);
        totalHours += diff.inMinutes / 60.0;
      } catch (e) {
        totalHours += double.tryParse(latestActiveSession["working_hours"]?.toString() ?? "0") ?? 0.0;
      }
    }

    if (homeProvider.localCheckInTime != null && !hasActiveSession) {
      final checkInTime = homeProvider.localCheckInTime!;
      final diff = DateTime.now().difference(checkInTime);
      totalHours += diff.inMinutes / 60.0;
      if (checkIn == "-") {
        checkIn = checkInTime.toIso8601String();
      }
    }

    if (sessions.isNotEmpty && checkIn == "-") {
      checkIn = sessions.last["check_in"] ?? "-";
    }

    String workingHours = totalHours.toStringAsFixed(1);

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
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Icon(iconPath, color: AppColors.primary, size: 28),
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
