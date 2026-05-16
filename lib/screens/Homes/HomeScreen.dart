import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../User_transactions/UserTransactionScreen.dart';
import '../../constants/app_colors.dart';
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
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!mounted) return;
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final appState = Provider.of<AppStateProvider>(context, listen: false);

      await homeProvider.loadDistributors();
      await homeProvider.initializeAttendance(appState);

      homeProvider.fetchTodayAttendance();
      homeProvider.fetchDailyCallSummary(appState.selectedDistributorId);

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
      backgroundColor: AppColors.white,
      drawer: const ProfileDrawer(selectedMenu: "Attendance"),
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
              child: const Icon(Icons.menu, color: AppColors.white, size: 26),
            ),
          ),
        ),
        title: const Text(
          "DASHBOARD",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
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
                  activeThumbColor: AppColors.button,
                  activeTrackColor: AppColors.button.withOpacity(
                    0.35,
                  ),
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.white.withOpacity(
                    0.4,
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Consumer2<HomeProvider, AppStateProvider>(
                          builder: (context, homeProvider, appState, _) {
                            return DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text("SELECT DISTRIBUTOR"),
                              value: homeProvider.distributors.any((d) => d["distributor_name"] == appState.selectedDistributor)
                                  ? appState.selectedDistributor
                                  : null,
                              items: homeProvider.distributors.map<DropdownMenuItem<String>>((d) {
                                return DropdownMenuItem<String>(
                                  value: d["distributor_name"],
                                  child: Text(d["distributor_name"]),
                                );
                              }).toList(),

                              onChanged: appState.isOnline ? (value) {
                                final selected = homeProvider.distributors.firstWhere(
                                      (d) => d["distributor_name"] == value,
                                  orElse: () => null,
                                );
                                int? id;
                                if (selected != null) {
                                  // ID can be string or int in JSON, ensure it's parsed to int
                                  if (selected["distributor_id"] is int) {
                                    id = selected["distributor_id"];
                                  } else if (selected["distributor_id"] != null) {
                                    id = int.tryParse(selected["distributor_id"].toString());
                                  }
                                }
                                appState.setDistributor(value, id: id);
                                homeProvider.fetchDailyCallSummary(id);
                              } : null,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
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

                      if (appState.selectedDistributor == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select a distributor first"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DistributorStockScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 45,
                      width: 65,
                      decoration: BoxDecoration(
                        color: (appState.selectedDistributor == null || !appState.isOnline)
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "GO",
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      if (provider.isSummaryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final summary = provider.dailyCallSummary;
                      final targetCalls = (summary?["target_calls"] ?? 0).toDouble();
                      final productiveCalls = (summary?["productive_calls"] ?? 0).toDouble();

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          DonutChart(
                            value: targetCalls,
                            total: 30.0,
                            label: "Total Calls",
                            color: Colors.green,
                          ),
                          DonutChart(
                            value: productiveCalls,
                            total: 30.0,
                            label: "Target Productive",
                            color: Colors.green,
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
                  return const Text("NO ATTENDANCE DATA");
                }

                final data = provider.todayAttendance!;
                final sessions = data["sessions"] ?? [];

                String checkIn = "-";
                String workingHours = "0";

                if (sessions.isNotEmpty) {
                  final lastSession = sessions.last;

                  checkIn = lastSession["check_in"] ?? "-";
                  workingHours =
                      lastSession["working_hours"]?.toString() ?? "0";
                }

                return Column(
                  children: [
                    Text(
                      "CHECK-IN: ${DateFormatter.formatDateTime(checkIn)}",
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
            if (appState.userRole == 'AM' || appState.userRole == 'RM')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ActionBox(
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}