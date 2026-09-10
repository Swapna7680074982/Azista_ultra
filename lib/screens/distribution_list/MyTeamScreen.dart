import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../services/call_service.dart';
import '../../utilities/common_widgets.dart';
import '../../permissions/SessionManager.dart';
import '../attendance/TeamAttendanceScreen.dart';
import 'TeamMemberDetailScreen.dart';
import 'TeamPosHistoryScreen.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  bool _isLoading = true;
  List<dynamic> _teamMembers = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedRole = "ALL";
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRoleAndFetchTeam();
      }
    });
  }

  Future<void> _loadRoleAndFetchTeam() async {
    try {
      final role = await SessionManager.getUserRole();
      _currentUserRole = _normalizeRole(role);
      if (_currentUserRole == 'AM') {
        _selectedRole = "SO";
      } else {
        _selectedRole = "ALL";
      }
    } catch (_) {}
    await _fetchTeam();
  }

  String _normalizeRole(String role) {
    final norm = role.trim().toUpperCase();
    if (norm == 'ASM' || norm == 'AM') return 'AM';
    if (norm == 'RM') return 'RM';
    if (norm == 'SO' || norm.contains('SALE') || norm.contains('SALES')) return 'SO';
    return norm;
  }

  Future<void> _fetchTeam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiServices.getMyTeam();
      if (mounted) {
        setState(() {
          if (res != null && (res["status"] == true || res["status"] == "success" || res["status_code"] == 200)) {
            _teamMembers = res["data"] as List<dynamic>? ?? [];
          } else {
            _teamMembers = [];
            _errorMessage = res?["message"]?.toString() ?? "No team members found";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching my team: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load team members. Please try again.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get filteredMembers {
    return _teamMembers.where((member) {
      final role = _normalizeRole(member["rolecode"]?.toString() ?? "");

      if (_currentUserRole == 'AM') {
        // AM only manages and sees SO
        if (role != 'SO') return false;
      } else if (_currentUserRole == 'RM') {
        // RM manages AM and SO (excludes RM)
        if (role == 'RM') return false;
        if (role != 'AM' && role != 'SO') return false;
      }

      if (_selectedRole != "ALL" && role != _selectedRole) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final name = (member["fullname"]?.toString() ?? "").toLowerCase();
        final empId = (member["employee_id"]?.toString() ?? "").toLowerCase();
        final mobile = (member["mobile"]?.toString() ?? "").toLowerCase();
        final email = (member["email"]?.toString() ?? "").toLowerCase();
        final repName = (member["reporting_manager_name"]?.toString() ?? "").toLowerCase();
        final match = name.contains(_searchQuery) ||
            empId.contains(_searchQuery) ||
            mobile.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            repName.contains(_searchQuery);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) return;
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error launching email client: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = filteredMembers;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "MY TEAM",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.button,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search by Name, Employee ID, Mobile...",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_currentUserRole == 'RM') ...[
                        _buildFilterChip("ALL"),
                        const SizedBox(width: 8),
                        _buildFilterChip("AM"),
                        const SizedBox(width: 8),
                        _buildFilterChip("SO"),
                      ] else if (_currentUserRole == 'AM') ...[
                        _buildFilterChip("SO"),
                      ] else ...[
                        _buildFilterChip("ALL"),
                        const SizedBox(width: 8),
                        _buildFilterChip("AM"),
                        const SizedBox(width: 8),
                        _buildFilterChip("SO"),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),

          // Loading bar
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Color(0x1F000000),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

          // Member count banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentUserRole == 'AM' ? "SO MEMBERS (${members.length})" : "TEAM MEMBERS (${members.length})",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                if (members.isNotEmpty)
                  Text(
                    "Total: ${members.length}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading && _teamMembers.isEmpty
                ? const Center(child: LogoProgressIndicator(size: 70))
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _fetchTeam,
                    child: members.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        _errorMessage ?? "No team members found",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              return _buildMemberCard(members[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          role,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final name = (member["fullname"]?.toString() ?? "Unknown").toUpperCase();
    final empId = member["employee_id"]?.toString() ?? member["user_id"]?.toString() ?? "-";
    final role = _normalizeRole(member["rolecode"]?.toString() ?? "SO");
    final mobile = member["mobile"]?.toString() ?? "";
    final email = member["email"]?.toString() ?? "";
    final repManagerName = member["reporting_manager_name"]?.toString() ?? "";

    Color roleColor;
    if (role == "RM") {
      roleColor = Colors.purple.shade700;
    } else if (role == "AM" || role == "ASM") {
      roleColor = Colors.orange.shade800;
    } else {
      roleColor = Colors.blue.shade700;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final userId = int.tryParse(member['user_id']?.toString() ?? '') ?? 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamMemberDetailScreen(
                userId: userId,
                fullname: name,
                rolecode: role,
                month: DateTime.now().month,
                year: DateTime.now().year,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.12),
                    radius: 22,
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1) : "U",
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                role,
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "Employee ID: $empId",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 10),

            // Contact & Reporting details
            if (mobile.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      mobile,
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => CallService.makeCall(mobile),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, size: 12, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "CALL",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _sendEmail(email),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mail, size: 12, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "EMAIL",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (repManagerName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.supervisor_account_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Reporting to: $repManagerName",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.primary),
                    label: const Text(
                      "ATTENDANCE",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeamAttendanceScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.button.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.history, size: 14, color: AppColors.button),
                    label: const Text(
                      "POB HISTORY",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.button),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeamPosHistoryScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
