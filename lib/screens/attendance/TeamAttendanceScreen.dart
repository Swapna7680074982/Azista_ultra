import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../permissions/AppStateProvider.dart';
import '../../permissions/SessionManager.dart';
import '../../utilities/date_formatter.dart';
import 'team_attendance_provider.dart';

class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    final teamAttendanceProvider = context.read<TeamAttendanceProvider>();
    Future.microtask(() async {
      if (appState.userRole == null) {
        final role = await SessionManager.getUserRole();
        appState.setUserRole(role);
      }
      teamAttendanceProvider.fetchTeamAttendance(
        isToday: true,
        defaultRole: 'ALL',
        currentUserRole: appState.userRole,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    return Scaffold(
      appBar: const WavyAppBar(
        title: "TEAM ATTENDANCE",
      ),
      body: Consumer<TeamAttendanceProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildCalendarFilter(context, provider),
              _buildFilterSection(appState, provider),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.attendanceList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: provider.attendanceList.length,
                            itemBuilder: (context, index) {
                              final user = provider.attendanceList[index];
                              final logs = provider.getAllLogsForUser(user.userId).where((log) {
                                return log['attendance_date']?.toString() == user.attendanceDate;
                              }).toList();
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ExpansionTile(
                                  shape: const Border(),
                                  title: Text(
                                    "${user.employeeId} - ${user.employeeName}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Role: ${user.roleCode}", style: const TextStyle(fontSize: 12)),
                                      Text("Date: ${DateFormatter.formatDateOnly(user.attendanceDate)}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  children: [
                                    Builder(builder: (context) {
                                      DateTime? earliestCheckInTime;
                                      DateTime? latestCheckOutTime;
                                      String? earliestCheckInStr;
                                      String? latestCheckOutStr;
                                      bool hideWorkedHours = false;

                                      for (var log in logs) {
                                        final checkInStr = log['first_checkin']?.toString();
                                        final checkOutStr = log['last_checkout']?.toString();
                                        
                                        final checkInTime = _parseDateTime(checkInStr);
                                        final checkOutTime = _parseDateTime(checkOutStr);

                                        if (checkInTime != null) {
                                          if (earliestCheckInTime == null || checkInTime.isBefore(earliestCheckInTime)) {
                                            earliestCheckInTime = checkInTime;
                                            earliestCheckInStr = checkInStr;
                                          }
                                        }

                                        if (checkOutTime != null) {
                                          if (latestCheckOutTime == null || checkOutTime.isAfter(latestCheckOutTime)) {
                                            latestCheckOutTime = checkOutTime;
                                            latestCheckOutStr = checkOutStr;
                                          }
                                        }
                                      }

                                      int totalMinutes = 0;
                                      final attendanceDate = DateTime.tryParse(user.attendanceDate);
                                      final now = DateTime.now();
                                      final isToday = attendanceDate != null &&
                                          attendanceDate.year == now.year &&
                                          attendanceDate.month == now.month &&
                                          attendanceDate.day == now.day;

                                      if (!isToday && latestCheckOutTime == null) {
                                        hideWorkedHours = true;
                                      }

                                      if (!hideWorkedHours) {
                                        for (var log in logs) {
                                          final checkInStr = log['first_checkin']?.toString();
                                          final checkOutStr = log['last_checkout']?.toString();
                                          
                                          final checkInTime = _parseDateTime(checkInStr);
                                          final checkOutTime = _parseDateTime(checkOutStr);

                                          if (checkInTime != null) {
                                            if (checkOutTime != null) {
                                              final diff = checkOutTime.difference(checkInTime).inMinutes;
                                              if (diff > 0) {
                                                totalMinutes += diff;
                                              }
                                            } else {
                                              if (isToday) {
                                                final diff = DateTime.now().difference(checkInTime).inMinutes;
                                                if (diff > 0) {
                                                  totalMinutes += diff;
                                                }
                                              }
                                            }
                                          }
                                        }
                                      }

                                      return _buildSummaryLogItem(
                                        earliestCheckInStr,
                                        latestCheckOutStr,
                                        totalMinutes,
                                        hideWorkedHours: hideWorkedHours,
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'N/A') return null;
    DateTime? parsed = DateTime.tryParse(dateStr.trim());
    if (parsed == null) {
      try {
        parsed = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateStr.trim());
      } catch (_) {}
    }
    return parsed;
  }

  Widget _buildSummaryLogItem(String? earliestCheckIn, String? latestCheckOut, int totalMinutes, {bool hideWorkedHours = false}) {
    String checkIn = DateFormatter.formatTimeOnly(earliestCheckIn);
    String checkOut = DateFormatter.formatTimeOnly(latestCheckOut);
    final double hours = totalMinutes / 60.0;
    final String workedString = hideWorkedHours
        ? "--"
        : (totalMinutes < 60 ? "${totalMinutes}m" : "${hours.toStringAsFixed(1)}h");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeInfo("FIRST IN", checkIn),
          _buildTimeInfo("LAST OUT", checkOut),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("WORKED", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(workedString, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.button)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            "No attendance records found",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarFilter(BuildContext context, TeamAttendanceProvider provider) {
    final dateText = DateFormat('EEEE, d MMMM yyyy').format(provider.selectedDate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => _selectDate(context, provider),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SELECTED DATE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TeamAttendanceProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      provider.updateDate(picked);
    }
  }

  Widget _buildFilterSection(AppStateProvider appState, TeamAttendanceProvider provider) {
    final roles = appState.userRole == 'AM' ? ['AM', 'SO'] : ['RM', 'AM', 'SO'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: const Text("ALL"),
                selected: provider.selectedRole == 'ALL',
                showCheckmark: false,
                onSelected: (selected) => provider.setRoleFilter('ALL'),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: provider.selectedRole == 'ALL' ? AppColors.primary : Colors.grey.shade300),
                ),
                labelStyle: TextStyle(
                  color: provider.selectedRole == 'ALL' ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...roles.map((role) {
              final isSelected = provider.selectedRole == role;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (selected) {
                    provider.setRoleFilter(selected ? role : 'ALL');
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
