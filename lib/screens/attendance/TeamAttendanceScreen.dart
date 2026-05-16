import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'TeamAttendanceDetailScreen.dart';
import '../../constants/app_colors.dart';
import '../../permissions/AppStateProvider.dart';
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
    Future.microtask(() {
      final appState = context.read<AppStateProvider>();
      context.read<TeamAttendanceProvider>().fetchTeamAttendance(
        isToday: true,
        defaultRole: appState.userRole == 'AM' ? 'SO' : (appState.userRole == 'RM' ? 'AM' : null),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStateProvider>();
    final userRole = appState.userRole?.toUpperCase() ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("TEAM ATTENDANCE", style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<TeamAttendanceProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildFilterSection(provider, userRole),
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
                              final logs = provider.getAllLogsForUser(user.userId);
                              
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
                                  subtitle: Text("Role: ${user.roleCode}", style: const TextStyle(fontSize: 12)),
                                  children: logs.map<Widget>((log) {
                                    return _buildDetailLogItem(log);
                                  }).toList(),
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

  Widget _buildDetailLogItem(dynamic log) {
    String checkIn = log['first_checkin'] ?? "--:--";
    String checkOut = log['last_checkout'] ?? "--:--";
    
    // Extract time from YYYY-MM-DD HH:mm:ss
    if (checkIn.contains(" ")) checkIn = checkIn.split(" ")[1];
    if (checkOut.contains(" ")) checkOut = checkOut.split(" ")[1];

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
              Text("${log['working_minutes']}m", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
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

  Widget _buildFilterSection(TeamAttendanceProvider provider, String userRole) {
    List<String> roles = [];
    if (userRole == 'RM') {
      roles = ['RM', 'AM', 'SO'];
    } else if (userRole == 'AM') {
      roles = ['AM', 'SO'];
    } else {
      roles = ['SO'];
    }

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
    String formattedTime = time;
    if (time != "--:--" && time.contains(" ")) {
      formattedTime = time.split(" ")[1];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          formattedTime,
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
