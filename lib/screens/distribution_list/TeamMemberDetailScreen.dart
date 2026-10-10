import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/role_helper.dart';
import 'TeamOutletHistoryScreen.dart';

class TeamMemberDetailScreen extends StatefulWidget {
  final int userId;
  final String fullname;
  final String rolecode;
  final int month;
  final int year;

  const TeamMemberDetailScreen({
    super.key,
    required this.userId,
    required this.fullname,
    required this.rolecode,
    required this.month,
    required this.year,
  });

  @override
  State<TeamMemberDetailScreen> createState() => _TeamMemberDetailScreenState();
}

class _TeamMemberDetailScreenState extends State<TeamMemberDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardCounts;
  List<dynamic> _outlets = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Map<String, String> _userNameLookup = {};

  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.month;
    _selectedYear = widget.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDetails();
      }
    });
  }

  Future<void> _showMonthPicker() async {
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                    onPressed: () {
                      setDialogState(() {
                        tempYear--;
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
                    icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                    onPressed: () {
                      setDialogState(() {
                        tempYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, idx) {
                    final monthIndex = idx + 1;
                    final isSelected = (monthIndex == tempMonth && tempYear == _selectedYear);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedMonth = monthIndex;
                          _selectedYear = tempYear;
                        });
                        _fetchDetails();
                      },
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
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryFuture = ApiServices.getTeamMembersSummary(
        month: _selectedMonth,
        year: _selectedYear,
      );

      final outletsFuture = ApiServices.getTeamMemberOutlets(
        userId: widget.userId,
        month: _selectedMonth,
        year: _selectedYear,
      );

      final results = await Future.wait([summaryFuture, outletsFuture]);

      final summaryRes = results[0];
      final outletsRes = results[1];

      if (summaryRes != null && summaryRes["status"] == true) {
        final List members = summaryRes["data"] ?? [];
        for (var m in members) {
          final uId = m["user_id"]?.toString();
          final name = m["fullname"]?.toString() ?? m["employee_name"]?.toString();
          final role = m["rolecode"]?.toString() ?? m["role"]?.toString() ?? "";
          if (uId != null && name != null) {
            final roleStr = role.isNotEmpty ? " ($role)" : "";
            _userNameLookup[uId] = "$name$roleStr";
          }
        }
        final memberData = members.where(
          (m) => m["user_id"]?.toString() == widget.userId.toString(),
        ).firstOrNull;
        if (memberData != null) {
          _dashboardCounts = {
            "new_outlets": memberData["new_outlets"],
            "outlet_visits": memberData["total_visits"],
            "pobs_done": memberData["total_pobs"],
            "pob_sale_value": memberData["pob_sale_value"],
          };
        }
      }

      List<dynamic> loadedOutlets = outletsRes != null && outletsRes["status"] == true
          ? (outletsRes["data"] as List<dynamic>? ?? [])
          : [];

      // If direct outlets list is empty (e.g. for AM/ASM or RM whose outlets are mapped under subordinates,
      // or if backend returned empty due to database access issues), query subordinate team members' outlets
      if (loadedOutlets.isEmpty) {
        try {
          final teamRes = await ApiServices.getMyTeam();
          if (teamRes != null && teamRes["status"] == true) {
            final List teamList = teamRes["data"] ?? [];
            for (var m in teamList) {
              final uId = m["user_id"]?.toString();
              final name = m["fullname"]?.toString() ?? m["name"]?.toString();
              final role = m["rolecode"]?.toString() ?? m["role"]?.toString() ?? "";
              if (uId != null && name != null && !_userNameLookup.containsKey(uId)) {
                final roleStr = role.isNotEmpty ? " ($role)" : "";
                _userNameLookup[uId] = "$name$roleStr";
              }
            }

            // 1. Find direct subordinates reporting to this member
            List subs = teamList.where((m) =>
              m["reporting_manager_id"]?.toString() == widget.userId.toString()
            ).toList();

            // 2. If none matched reporting_manager_id, but member is AM/ASM, get SOs
            final normalizedRole = RoleHelper.normalizeRole(widget.rolecode);
            if (subs.isEmpty && (normalizedRole == "AM" || normalizedRole == "RM")) {
              subs = teamList.where((m) {
                final r = RoleHelper.normalizeRole(m["rolecode"]?.toString() ?? "");
                return r == "SO";
              }).toList();
            }

            final Map<String, dynamic> combinedMap = {};
            for (var sub in subs) {
              final subId = int.tryParse(sub["user_id"]?.toString() ?? '');
              if (subId != null) {
                final subOutletsRes = await ApiServices.getTeamMemberOutlets(
                  userId: subId,
                  month: _selectedMonth,
                  year: _selectedYear,
                );
                if (subOutletsRes != null && subOutletsRes["status"] == true) {
                  final list = subOutletsRes["data"] as List<dynamic>? ?? [];
                  for (var o in list) {
                    final oId = o["outlet_id"]?.toString();
                    if (oId != null && !combinedMap.containsKey(oId)) {
                      final Map<String, dynamic> oCopy = Map<String, dynamic>.from(o);
                      oCopy["assigned_user_id"] = sub["user_id"];
                      final subName = sub["fullname"] ?? sub["name"];
                      final subRole = sub["rolecode"] ?? sub["role"] ?? "";
                      oCopy["assigned_user_name"] = (subRole != null && subRole.toString().isNotEmpty)
                          ? "$subName ($subRole)"
                          : subName;
                      combinedMap[oId] = oCopy;
                    }
                  }
                }
              }
            }
            if (combinedMap.isNotEmpty) {
              loadedOutlets = combinedMap.values.toList();
            }
          }
        } catch (subErr) {
          debugPrint("Error fetching subordinate outlets: $subErr");
        }
      }

      if (mounted) {
        setState(() {
          _outlets = loadedOutlets;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching team member details: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load dashboard metrics. Please try again.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.fullname.toUpperCase(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.white),
            tooltip: "Sync Details",
            onPressed: () {
              _fetchDetails();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Refreshing team member details..."),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                  tooltip: "Previous Month",
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                    _fetchDetails();
                  },
                ),
                InkWell(
                  onTap: _showMonthPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${_getMonthName(_selectedMonth)} $_selectedYear",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                  tooltip: "Next Month",
                  onPressed: () {
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                    _fetchDetails();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: LogoProgressIndicator(size: 80))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text("Retry", style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDetails,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _buildHeaderRoleCard(),
                            const SizedBox(height: 12),
                            _buildDashboardCountsGrid(),
                            const SizedBox(height: 16),
                            const Text(
                              "ASSIGNED OUTLETS & PERFORMANCE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Outlet Search Bar
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Search outlets by name...",
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                  });
                                },
                              ),
                            ),
                            (() {
                              var filteredOutlets = _outlets;
                              if (_searchQuery.isNotEmpty) {
                                filteredOutlets = filteredOutlets.where((outlet) {
                                  final name = (outlet["outlet_name"]?.toString() ?? "").toLowerCase();
                                  return name.contains(_searchQuery);
                                }).toList();
                              }

                              if (filteredOutlets.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(30.0),
                                    child: Text(
                                      "No outlets found for this member",
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: filteredOutlets.map((outlet) {
                                  return _buildOutletCard(outlet);
                                }).toList(),
                              );
                            })(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRoleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Role: ${RoleHelper.formatRole(widget.rolecode)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCountsGrid() {
    final newOutlets = _dashboardCounts?["new_outlets"] ?? 0;
    final outletVisits = _dashboardCounts?["outlet_visits"] ?? 0;
    final pobsDone = _dashboardCounts?["pobs_done"] ?? 0;
    final pobSaleValue = double.tryParse(_dashboardCounts?["pob_sale_value"]?.toString() ?? '') ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildMetricGridTile("NEW OUTLETS", newOutlets.toString(), Icons.store, Colors.blue.shade700),
        _buildMetricGridTile("OUTLET VISITS", outletVisits.toString(), Icons.pin_drop, Colors.orange.shade800),
        _buildMetricGridTile("POBS DONE", pobsDone.toString(), Icons.description, Colors.purple.shade700),
        _buildMetricGridTile("SALE VALUE", "₹${pobSaleValue.toStringAsFixed(2)}", Icons.currency_rupee, AppColors.green),
      ],
    );
  }

  Widget _buildMetricGridTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletCard(dynamic outlet) {
    final name = outlet["outlet_name"]?.toString() ?? "Unknown Outlet";
    final owner = outlet["owner_name"]?.toString() ?? "N/A";
    final mobile = outlet["mobile"]?.toString() ?? "N/A";
    final address = outlet["address"]?.toString() ?? "No Address Provided";
    final visits = int.tryParse(outlet["total_visits"]?.toString() ?? '') ?? 0;
    final activities = int.tryParse(outlet["total_activities"]?.toString() ?? '') ?? 0;
    final pobs = int.tryParse(outlet["total_pobs"]?.toString() ?? '') ?? 0;
    final value = double.tryParse(outlet["sale_value"]?.toString() ?? '') ?? 0.0;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final outletId = int.tryParse(outlet["outlet_id"]?.toString() ?? '') ?? 0;
          final assignedName = outlet["assigned_user_name"]?.toString();
          final directRole = widget.rolecode.isNotEmpty ? " (${widget.rolecode})" : "";
          final fallbackName = "${widget.fullname}$directRole";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamOutletHistoryScreen(
                outletId: outletId,
                outletName: name,
                month: _selectedMonth,
                year: _selectedYear,
                memberName: (assignedName != null && assignedName.isNotEmpty) ? assignedName : fallbackName,
                userNameLookup: _userNameLookup,
                outletAssignedUserId: outlet["assigned_user_id"]?.toString() ?? widget.userId.toString(),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: visits > 0 ? Colors.orange.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: visits > 0 ? Colors.orange.shade300 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 13,
                          color: visits > 0 ? Colors.orange.shade800 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$visits Visits",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: visits > 0 ? Colors.orange.shade800 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("Owner: $owner", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 12),
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(mobile, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOutletStat("Visits", "$visits"),
                  _buildOutletStat("Activities", "$activities"),
                  _buildOutletStat("POBs", "$pobs"),
                  _buildOutletStat("Sale Value", "₹${value.toStringAsFixed(2)}"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutletStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  String _getMonthName(int m) {
    const months = [
      "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
      "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return "";
  }
}
