import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../User_transactions/UserTransactionScreen.dart';
import '../../constants/app_colors.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../utilities/common_widgets.dart';
import '../../permissions/AccessValidator.dart';
import '../../permissions/AppStateProvider.dart';
import '../../profile.dart';
import '../attendance/Attendancescreen.dart';
import '../distribution_list/DistributorStockScreen.dart';
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
  String _selectedSummaryType = "Monthly";

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
    homeProvider.fetchDashboardCounts(distributorId: appState.selectedDistributorId);
    homeProvider.fetchTargets();
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
      homeProvider.fetchDashboardCounts(distributorId: appState.selectedDistributorId);
      homeProvider.fetchTargets();

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

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(homeProvider.message ?? "")),
                      );
                    }
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

          const SizedBox(width: 12),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Header container with neat styling
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "CALL SUMMARY",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSummaryType,
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedSummaryType = newValue;
                                    });
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: "Daily",
                                    child: Text("DAILY"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Monthly",
                                    child: Text("MONTHLY"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Consumer<HomeProvider>(
                        builder: (context, provider, _) {
                          if (provider.isSummaryLoading || provider.isMonthlySummaryLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: LogoProgressIndicator(size: 45),
                            );
                          }

                          // Daily Call Summary
                          final dailySummary = provider.dailyCallSummary;
                          final dailyTarget = (dailySummary?["target_calls"] ?? 0).toDouble();
                          final dailyProductive = (dailySummary?["productive_calls"] ?? 0).toDouble();

                          // Monthly Call Summary
                          final monthlySummary = provider.monthlyCallSummary;
                          final monthlyTarget = (monthlySummary?["target_calls"] ?? 0).toDouble();
                          final monthlyProductive = (monthlySummary?["productive_calls"] ?? 0).toDouble();

                          // Target values from API
                          final targets = provider.targetsData;
                          
                          // Daily targets from API (daily_target map)
                          final dailyTargetMap = targets?["daily_target"] as Map<String, dynamic>?;
                          final dailyTcTarget = double.tryParse(dailyTargetMap?["tc_target"]?.toString() ?? "25") ?? 25.0;
                          final dailyPcTarget = double.tryParse(dailyTargetMap?["pc_target"]?.toString() ?? "12") ?? 12.0;

                          // Monthly targets from API (monthly_target map)
                          final monthlyTargetMap = targets?["monthly_target"] as Map<String, dynamic>?;
                          final monthlyTcTarget = double.tryParse(monthlyTargetMap?["tc_target"]?.toString() ?? "600") ?? 600.0;
                          final monthlyPcTarget = double.tryParse(monthlyTargetMap?["pc_target"]?.toString() ?? "300") ?? 300.0;

                          // Dynamic total targets (removing static/assumed values)
                          final dailyTotalTarget = dailyTarget > dailyTcTarget ? dailyTarget : dailyTcTarget;
                          final dailyProductiveTotalTarget = dailyProductive > dailyPcTarget ? dailyProductive : dailyPcTarget;

                          final monthlyTotalTarget = monthlyTarget > monthlyTcTarget ? monthlyTarget : monthlyTcTarget;
                          final monthlyProductiveTotalTarget = monthlyProductive > monthlyPcTarget ? monthlyProductive : monthlyPcTarget;

                          if (_selectedSummaryType == "Daily") {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: DonutChart(
                                      value: dailyTarget,
                                      total: dailyTotalTarget,
                                      label: "Total Calls",
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: DonutChart(
                                      value: dailyProductive,
                                      total: dailyProductiveTotalTarget,
                                      label: "Target Productive",
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: DonutChart(
                                      value: monthlyTarget,
                                      total: monthlyTotalTarget,
                                      label: "Total Calls",
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: DonutChart(
                                      value: monthlyProductive,
                                      total: monthlyProductiveTotalTarget,
                                      label: "Target Productive",
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0), indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              color: appState.isOnline ? AppColors.primary : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Consumer<HomeProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      children: [
                        // Header container with neat styling
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: Colors.grey.shade50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "PERFORMANCE OVERVIEW",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.black,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              if (provider.selectedCountsFilter == "custom" && provider.customCountsRange != null)
                                Text(
                                  "${DateFormat('dd/MM').format(provider.customCountsRange!.start)} - ${DateFormat('dd/MM').format(provider.customCountsRange!.end)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildFilterChip(context, provider, appState, "today", "TODAY"),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(context, provider, appState, "month", "THIS MONTH"),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(context, provider, appState, "custom", "CUSTOM"),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (provider.isCountsLoading)
                                const SizedBox(
                                  height: 120,
                                  child: LogoProgressIndicator(size: 45),
                                )
                              else if (provider.dashboardCounts == null)
                                const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      "NO DATA AVAILABLE",
                                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              else ...[
                                (() {
                                  final counts = provider.dashboardCounts ?? {};
                                  final newOutlets = counts["new_outlets"] ?? 0;
                                  final outletVisits = counts["outlet_visits"] ?? 0;
                                  final pobsDone = counts["pobs_done"] ?? 0;
                                  final pobSaleValue = counts["pob_sale_value"] ?? 0.0;

                                  final targets = provider.targetsData ?? {};
                                  Map<String, dynamic>? selectedTargetMap;
                                  if (provider.selectedCountsFilter == "today") {
                                    selectedTargetMap = targets["daily_target"] as Map<String, dynamic>?;
                                  } else if (provider.selectedCountsFilter == "month") {
                                    selectedTargetMap = targets["monthly_target"] as Map<String, dynamic>?;
                                  }

                                  final newOutletsTarget = selectedTargetMap?["new_outlets_target"]?.toString();
                                  final outletVisitsTarget = selectedTargetMap?["outlet_visits_target"]?.toString();
                                  final saleValueTarget = selectedTargetMap?["sale_value_target"];
                                  
                                  String? saleValueTargetStr;
                                  if (saleValueTarget != null) {
                                    final val = double.tryParse(saleValueTarget.toString()) ?? 0.0;
                                    saleValueTargetStr = "₹ ${val.toStringAsFixed(2)}";
                                  }

                                  return GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                    children: [
                                      _buildMetricTile(
                                        "NEW OUTLETS",
                                        newOutlets.toString(),
                                        Icons.storefront,
                                        Colors.blue.shade700,
                                        targetValue: newOutletsTarget,
                                      ),
                                      _buildMetricTile(
                                        "OUTLET VISITS",
                                        outletVisits.toString(),
                                        Icons.pin_drop_outlined,
                                        Colors.orange.shade800,
                                        targetValue: outletVisitsTarget,
                                      ),
                                      _buildMetricTile(
                                        "POBS DONE",
                                        pobsDone.toString(),
                                        Icons.description_outlined,
                                        Colors.purple.shade700,
                                      ),
                                      _buildMetricTile(
                                        "SALE VALUE",
                                        "₹ ${double.tryParse(pobSaleValue.toString())?.toStringAsFixed(2) ?? "0.00"}",
                                        Icons.currency_rupee,
                                        AppColors.green,
                                        targetValue: saleValueTargetStr,
                                      ),
                                    ],
                                  );
                                })(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Consumer<HomeProvider>(
              builder: (context, provider, _) {
                if (provider.isAttendanceLoading) {
                  return const LogoProgressIndicator(size: 40);
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

                // Add elapsed time for the active session only when online
                if (appState.isOnline && latestActiveSession != null) {
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

  Widget _buildFilterChip(
    BuildContext context,
    HomeProvider provider,
    AppStateProvider appState,
    String filterCode,
    String label,
  ) {
    final isSelected = provider.selectedCountsFilter == filterCode;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (filterCode == "custom") {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: provider.customCountsRange ??
                  DateTimeRange(
                    start: DateTime.now().subtract(const Duration(days: 7)),
                    end: DateTime.now(),
                  ),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.button,
                      onPrimary: Colors.white,
                      onSurface: AppColors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              provider.setCountsFilter("custom", range: picked, distributorId: appState.selectedDistributorId);
            }
          } else {
            provider.setCountsFilter(filterCode, distributorId: appState.selectedDistributorId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.button : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.button : Colors.grey.shade400,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? targetValue,
  }) {
    final isPrice = value.contains('₹');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isPrice ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (targetValue != null && targetValue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Target: $targetValue",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}