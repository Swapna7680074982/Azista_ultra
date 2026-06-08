import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../User_transactions/UserTransactionScreen.dart';
import '../../constants/app_colors.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../permissions/AccessValidator.dart';
import '../../permissions/AppStateProvider.dart';
import '../../profile.dart';
import '../attendance/Attendancescreen.dart';
import '../distribution_list/DistributorStockScreen.dart';
import '../leave_management/leave_management_screen.dart';
import '../productivity/ProductivityScreen.dart';
import 'HomeProvider.dart';
import 'main_tab_provider.dart';
import 'widgets/DonutChart.dart';
import '../../utilities/date_formatter.dart';
import '../../permissions/SessionManager.dart';
import '../attendance/TeamAttendanceScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MainTabProvider _tabProvider;

  void _onTabChanged() {
    if (_tabProvider.currentIndex == 0) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    homeProvider.fetchTodayAttendance();
    homeProvider.fetchDailyCallSummary(appState.selectedDistributorId);
    homeProvider.fetchMonthlyCallSummary(appState.selectedDistributorId);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!mounted) return;
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      await homeProvider.loadDistributors(appState);
      await homeProvider.initializeAttendance(appState);

      homeProvider.fetchTodayAttendance();
      homeProvider.fetchDailyCallSummary(appState.selectedDistributorId);
      homeProvider.fetchMonthlyCallSummary(appState.selectedDistributorId);

      final role = await SessionManager.getUserRole();
      appState.setUserRole(role);

      _tabProvider = Provider.of<MainTabProvider>(context, listen: false);
      _tabProvider.addListener(_onTabChanged);
    });
  }

  @override
  void dispose() {
    _tabProvider.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    return Scaffold(
      drawer: const ProfileDrawer(selectedMenu: "Attendance"),
      appBar: WavyAppBar(
        title: "DASHBOARD",
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 12),
            child: GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Icon(Icons.menu, color: AppColors.white, size: 26),
            ),
          ),
        ),
        actions: [
          Consumer<HomeProvider>(
            builder: (context, homeProvider, _) {
              final appState = Provider.of<AppStateProvider>(context);

              return Transform.scale(
                scale: 0.75,
                child: homeProvider.isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
                    : Switch(
                  value: appState.isOnline,

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

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(homeProvider.message ?? "")),
                    );
                  },
                  activeThumbColor: Colors.green,
                  activeTrackColor: Colors.green.withValues(
                    alpha: 0.35,
                  ),
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.white.withValues(
                    alpha: 0.4,
                  ),

                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),

          const SizedBox(width: 6),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications,
                  color: AppColors.white,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.border,
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

              child: Column(
                children: [
                  Consumer<HomeProvider>(
                    builder: (context, provider, _) {
                      if (provider.isSummaryLoading || provider.isMonthlySummaryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Daily Call Summary
                      final dailySummary = provider.dailyCallSummary;
                      final dailyTarget = (dailySummary?["target_calls"] ?? 0).toDouble();
                      final dailyProductive = (dailySummary?["productive_calls"] ?? 0).toDouble();

                      // Monthly Call Summary
                      final monthlySummary = provider.monthlyCallSummary;
                      final monthlyTarget = (monthlySummary?["target_calls"] ?? 0).toDouble();
                      final monthlyProductive = (monthlySummary?["productive_calls"] ?? 0).toDouble();

                      // Dynamic total targets
                      final dailyTotalTarget = dailyTarget > 30.0 ? dailyTarget : 30.0;
                      final monthlyTotalTarget = monthlyTarget > 500.0 ? monthlyTarget : 500.0;

                      return Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "DAILY CALL SUMMARY",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              DonutChart(
                                value: dailyTarget,
                                total: dailyTotalTarget,
                                label: "Total Calls",
                                color: Colors.green,
                              ),
                              DonutChart(
                                value: dailyProductive,
                                total: dailyTotalTarget,
                                label: "Target Productive",
                                color: Colors.green,
                              ),
                            ],
                          ),
                          const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "MONTHLY CALL SUMMARY",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              DonutChart(
                                value: monthlyTarget,
                                total: monthlyTotalTarget,
                                label: "Total Calls",
                                color: Colors.green,
                              ),
                              DonutChart(
                                value: monthlyProductive,
                                total: monthlyTotalTarget,
                                label: "Target Productive",
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          if (!appState.isOnline) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please turn on attendance first"),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductivityScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "VIEW DETAILS >>",
                          style: TextStyle(
                            color: appState.isOnline ? Colors.red.shade700 : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Consumer<HomeProvider>(
              builder: (context, provider, _) {
                if (provider.isAttendanceLoading) {
                  return const CircularProgressIndicator();
                }

                if (provider.todayAttendance == null) {
                  if (appState.isOnline && provider.localCheckInTime != null) {
                    final checkInTime = provider.localCheckInTime!;
                    final diff = DateTime.now().difference(checkInTime);
                    final totalHours = diff.inMinutes / 60.0;
                    final workingHours = totalHours.toStringAsFixed(1);
                    return Column(
                      children: [
                        Text(
                          "CHECK-IN: ${DateFormatter.formatDateTime(checkInTime.toIso8601String())}",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "WORKING HOURS: $workingHours hrs",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    );
                  }
                  return const Text("NO ATTENDANCE DATA");
                }

                final data = provider.todayAttendance!;
                final sessions = data["sessions"] ?? [];

                double totalHours = 0.0;
                String checkIn = "-";
                bool hasActiveSession = false;

                for (var session in sessions) {
                  final sCheckIn = session["check_in"];
                  final sCheckOut = session["check_out"];
                  final sHours = double.tryParse(session["working_hours"]?.toString() ?? "0") ?? 0.0;

                  if (sCheckOut != null) {
                    totalHours += sHours;
                  } else {
                    if (sCheckIn != null) {
                      checkIn = sCheckIn;
                      hasActiveSession = true;
                      try {
                        final checkInTime = DateTime.parse(sCheckIn);
                        final diff = DateTime.now().difference(checkInTime);
                        totalHours += diff.inMinutes / 60.0;
                      } catch (e) {
                        totalHours += sHours;
                      }
                    }
                  }
                }

                if (appState.isOnline && !hasActiveSession && provider.localCheckInTime != null) {
                  final checkInTime = provider.localCheckInTime!;
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
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "WORKING HOURS: $workingHours hrs",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ActionBox(
                      Icons.access_time,
                      "ATTENDANCE",
                      enabled: appState.isOnline,
                      onTap: () {
                        if (AccessValidator.validate(
                          context: context,
                          isOnline: appState.isOnline,
                          hasDistributor: appState.selectedDistributor != null,
                          checkDistributor: false,
                          isLeave: false,
                        )) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionBox(
                      Icons.receipt,
                      "USER\nTRANSACTIONS",
                      enabled: appState.isOnline,
                      onTap: () {
                        if (AccessValidator.validate(
                          context: context,
                          isOnline: appState.isOnline,
                          hasDistributor: appState.selectedDistributor != null,
                          isLeave: false,
                        )) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserTransactionScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ActionBox(
                      Icons.inventory_2_outlined,
                      "SECONDARY\nSTOCK UPDATE",
                      enabled: appState.isOnline,
                      onTap: () {
                        if (AccessValidator.validate(
                          context: context,
                          isOnline: appState.isOnline,
                          hasDistributor: appState.selectedDistributor != null,
                          checkDistributor: false,
                          isLeave: false,
                        )) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecondaryStockUpdateScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: (appState.userRole == 'AM' || appState.userRole == 'RM')
                        ? ActionBox(
                            Icons.group,
                            "TEAM\nATTENDANCE",
                            enabled: appState.isOnline,
                            onTap: () {
                              if (AccessValidator.validate(
                                context: context,
                                isOnline: appState.isOnline,
                                hasDistributor: appState.selectedDistributor != null,
                                checkDistributor: false,
                                isLeave: false,
                              )) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TeamAttendanceScreen(),
                                  ),
                                );
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}