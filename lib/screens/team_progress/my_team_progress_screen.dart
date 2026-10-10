import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utilities/wavy_app_bar.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/role_helper.dart';
import '../../permissions/AppStateProvider.dart';
import '../../permissions/SessionManager.dart';
import '../../models/team_progress_model.dart';
import 'team_progress_provider.dart';
import 'team_member_details_history_screen.dart';

class MyTeamProgressScreen extends StatefulWidget {
  const MyTeamProgressScreen({super.key});

  @override
  State<MyTeamProgressScreen> createState() => _MyTeamProgressScreenState();
}

class _MyTeamProgressScreenState extends State<MyTeamProgressScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    final progressProvider = context.read<TeamProgressProvider>();

    Future.microtask(() async {
      final role = appState.userRole ?? await SessionManager.getUserRole();
      progressProvider.setCurrentUserRole(role);
      progressProvider.fetchTeamProgress();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: WavyAppBar(
        title: "MY TEAM PROGRESS",
        actions: [
          IconButton(
            tooltip: "Refresh Team Progress",
            icon: const Icon(Icons.sync, color: AppColors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Refreshing team progress..."),
                  duration: Duration(milliseconds: 900),
                ),
              );
              context.read<TeamProgressProvider>().fetchTeamProgress();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<TeamProgressProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await provider.fetchTeamProgress();
            },
            child: Column(
              children: [
                // Month Selector Bar
                _buildMonthSelector(provider),

                // Team Overview Summary Card
                _buildTeamOverviewHeader(provider),

                // Search & Hierarchy Role Filter Bar
                _buildSearchAndFilters(provider),

                // Member List or Empty/Loading State
                Expanded(
                  child: provider.isLoading
                      ? const LogoProgressIndicator()
                      : provider.errorMessage != null
                          ? _buildErrorState(provider)
                          : provider.filteredMembers.isEmpty
                              ? _buildEmptyState()
                              : _buildMembersList(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(TeamProgressProvider provider) {
    final monthYearText = DateFormat('MMMM yyyy').format(provider.selectedDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: provider.isLoading ? null : provider.previousMonth,
            tooltip: "Previous Month",
          ),
          Expanded(
            child: InkWell(
              onTap: provider.isLoading ? null : () => _showMonthPicker(context, provider),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      monthYearText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: provider.isLoading ? null : provider.nextMonth,
            tooltip: "Next Month",
          ),
        ],
      ),
    );
  }

  Widget _buildTeamOverviewHeader(TeamProgressProvider provider) {
    if (provider.members.isEmpty && !provider.isLoading) {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.button,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "TEAM SUMMARY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${provider.totalMembersCount} Members",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  label: "OUTLETS",
                  value: "${provider.totalOutletsCount}",
                ),
              ),
              _buildHeaderDivider(),
              Expanded(
                child: _buildHeaderMetric(
                  label: "VISITS",
                  value: "${provider.totalVisitsCount}",
                ),
              ),
              _buildHeaderDivider(),
              Expanded(
                child: _buildHeaderMetric(
                  label: "ACTIVITIES",
                  value: "${provider.totalActivitiesCount}",
                ),
              ),
              _buildHeaderDivider(),
              Expanded(
                child: _buildHeaderMetric(
                  label: "POBS",
                  value: "${provider.totalPobsCount}",
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total POB Sale Value",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                currencyFormatter.format(provider.totalPobSaleValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      height: 28,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildSearchAndFilters(TeamProgressProvider provider) {
    final availableRoles = provider.availableRoles;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => provider.setSearchQuery(val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: "Search team member by name, ID...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),

          // Hierarchy Role Filter Chips (if more than 1 role exists)
          if (availableRoles.length > 2) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableRoles.map((role) {
                  final isSelected = provider.selectedRoleFilter == role;
                  final count = role == 'ALL'
                      ? provider.members.length
                      : provider.members
                          .where((m) => RoleHelper.formatRole(m.roleCode) == role)
                          .length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        "$role ($count)",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          provider.setRoleFilter(role);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersList(TeamProgressProvider provider) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      itemCount: provider.filteredMembers.length,
      itemBuilder: (context, index) {
        final member = provider.filteredMembers[index];
        return _buildMemberCard(member, provider);
      },
    );
  }

  Widget _buildMemberCard(TeamMemberSummary member, TeamProgressProvider provider) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final displayRole = RoleHelper.formatRole(member.roleCode);
    final isManager = displayRole == 'ASM' || displayRole == 'RSM';

    // Role-specific badge styling
    Color roleBgColor;
    Color roleTextColor;
    if (displayRole == 'RSM') {
      roleBgColor = Colors.purple.shade50;
      roleTextColor = Colors.purple.shade700;
    } else if (displayRole == 'ASM') {
      roleBgColor = Colors.orange.shade50;
      roleTextColor = Colors.orange.shade800;
    } else {
      roleBgColor = Colors.blue.shade50;
      roleTextColor = Colors.blue.shade800;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isManager ? roleTextColor.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: isManager ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamMemberDetailsHistoryScreen(
                  member: member,
                  month: provider.selectedMonth,
                  year: provider.selectedYear,
                  initialCategory: "POB History",
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Employee ID & Role Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                // Initials Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isManager
                      ? roleTextColor.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    member.fullName.isNotEmpty
                        ? member.fullName.trim()[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isManager ? roleTextColor : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Employee ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName.isNotEmpty ? member.fullName : "Unknown Member",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            "ID: ${member.employeeId.isNotEmpty ? member.employeeId : 'N/A'}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleTextColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    displayRole,
                    style: TextStyle(
                      color: roleTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.8),

          // Metrics Grid (Outlets, Visits, Activities, POBs)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: "OUTLETS",
                    value: "${member.totalOutlets}",
                    icon: Icons.storefront_outlined,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: "VISITS",
                    value: "${member.totalVisits}",
                    icon: Icons.location_on_outlined,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: "ACTIVITIES",
                    value: "${member.totalActivities}",
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    label: "POBS",
                    value: "${member.totalPobs}",
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            ),
          ),

          // POB Sale Value Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(
                top: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 15,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "POB Sale Value",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  currencyFormatter.format(member.pobSaleValue),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Tap Action Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  "POB • SALE • STOCK • SAMPLE • ACTIVITY • VISITS",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? chip,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
        if (chip != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              chip,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            "No team progress data found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No records for the selected month and filter.",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TeamProgressProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 14),
            Text(
              provider.errorMessage ?? "An error occurred",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchTeamProgress(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, TeamProgressProvider provider) {
    int tempYear = provider.selectedYear;
    int tempMonth = provider.selectedMonth;

    final months = [
      "January", "February", "March", "April",
      "May", "June", "July", "August",
      "September", "October", "November", "December"
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Month & Year",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Year Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setModalState(() {
                            tempYear -= 1;
                          });
                        },
                      ),
                      Text(
                        "$tempYear",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setModalState(() {
                            tempYear += 1;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Month Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final monthIndex = idx + 1;
                      final isSelected = tempMonth == monthIndex;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          provider.selectMonthAndYear(monthIndex, tempYear);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            months[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

