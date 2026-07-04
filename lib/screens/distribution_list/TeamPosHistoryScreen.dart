import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';
import '../../permissions/SessionManager.dart';
import 'TeamMemberDetailScreen.dart';

class TeamPosHistoryScreen extends StatefulWidget {
  const TeamPosHistoryScreen({super.key});

  @override
  State<TeamPosHistoryScreen> createState() => _TeamPosHistoryScreenState();
}

class _TeamPosHistoryScreenState extends State<TeamPosHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _transactions = [];
  DateTime selectedDate = DateTime.now();
  final Map<String, String> _outletNameLookup = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _currentUserRole;
  String? _currentUserId;


  final List<Map<String, String>> _tabs = [
    {"label": "POB", "code": "pob"},
    {"label": "STOCK", "code": "stock"},
    {"label": "SAMPLING", "code": "sampling"},
    {"label": "SALE", "code": "sale"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUserRoleAndId();
    _loadOutletNames();
    _fetchHistory();
  }

  Future<void> _loadUserRoleAndId() async {
    try {
      final role = await SessionManager.getUserRole();
      final userInfo = await SessionManager.getUserInfo();
      _currentUserRole = _normalizeRole(role);
      _currentUserId = userInfo?['user_id']?.toString();
    } catch (_) {}
  }

  String _normalizeRole(String role) {
    final norm = role.trim().toUpperCase();
    if (norm == 'ASM' || norm == 'AM') return 'AM';
    if (norm == 'RM') return 'RM';
    if (norm == 'SO' || norm.contains('SALE') || norm.contains('SALES')) return 'SO';
    return norm;
  }


  Future<void> _loadOutletNames() async {
    if (!mounted) return;
    try {
      final userOutletsRes = await ApiServices.getUserOutlets();
      if (userOutletsRes != null && userOutletsRes["status"] == true) {
        final list = userOutletsRes["data"] as List<dynamic>? ?? [];
        for (var o in list) {
          final id = o['outlet_id']?.toString();
          final name = o['outlet_name']?.toString() ?? o['name']?.toString();
          if (id != null && name != null) {
            _outletNameLookup[id] = name;
          }
        }
      }

      if (!mounted) return;
      final summaryRes = await ApiServices.getTeamMembersSummary(
        month: selectedDate.month,
        year: selectedDate.year,
      );
      if (summaryRes != null && summaryRes["status"] == true) {
        final List members = summaryRes["data"] ?? [];
        for (var member in members) {
          final userId = int.tryParse(member['user_id']?.toString() ?? '');
          if (userId != null) {
            if (!mounted) return;
            final outletsRes = await ApiServices.getTeamMemberOutlets(
              userId: userId,
              month: selectedDate.month,
              year: selectedDate.year,
            );
            if (outletsRes != null && outletsRes["status"] == true) {
              final list = outletsRes["data"] as List<dynamic>? ?? [];
              for (var o in list) {
                final id = o['outlet_id']?.toString();
                final name = o['outlet_name']?.toString() ?? o['name']?.toString();
                if (id != null && name != null) {
                  _outletNameLookup[id] = name;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading outlet names lookup: $e");
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _searchController.clear();
    setState(() {
      _searchQuery = "";
    });
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _transactions = [];
    });

    final type = _tabs[_tabController.index]["code"]!;
    try {
      dynamic data;
      if (type == "pob") {
        final now = DateTime.now();
        final res = await ApiServices.getTeamMembersSummary(
          month: now.month,
          year: now.year,
        );
        data = res != null ? res["data"] : null;
      } else {
        data = await ApiServices.getTeamPosHistory(posType: type);
      }
      if (mounted) {
        setState(() {
          _transactions = data ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching team history: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickMonth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      _outletNameLookup.clear();
      _loadOutletNames();
      _fetchHistory();
    }
  }

  DateTime? _parseDate(String dateStr) {
    final cleaned = dateStr.trim();
    DateTime? dt = DateTime.tryParse(cleaned);
    if (dt == null) {
      try {
        dt = DateFormat("yyyy-MM-dd HH:mm:ss").parse(cleaned);
      } catch (_) {
        try {
          dt = DateFormat("yyyy-MM-dd").parse(cleaned);
        } catch (_) {
          try {
            dt = DateFormat("dd-MM-yyyy HH:mm:ss").parse(cleaned);
          } catch (_) {
            try {
              dt = DateFormat("dd-MM-yyyy").parse(cleaned);
            } catch (_) {}
          }
        }
      }
    }
    return dt;
  }

  List<dynamic> get filteredTransactions {
    return _transactions.where((tx) {
      final createdOn = tx["created_at"]?.toString() ?? tx["created_on"]?.toString() ?? "";
      if (createdOn.isEmpty) return false;
      final parsedDate = _parseDate(createdOn);
      if (parsedDate == null) return false;
      return parsedDate.year == selectedDate.year &&
             parsedDate.month == selectedDate.month &&
             parsedDate.day == selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final type = _tabs[_tabController.index]["code"]!;
    final List<dynamic> groupedKeys;
    final Map<String, List<dynamic>> grouped = {};

    if (type == "pob") {
      var list = _transactions;
      // Apply hierarchical role filter same as TeamAttendanceProvider
      if (_currentUserRole != null) {
        list = list.where((member) {
          final memberRole = _normalizeRole(member["rolecode"]?.toString() ?? '');
          final memberId = member['user_id']?.toString();
          if (_currentUserRole == 'AM') {
            if (memberRole == 'RM') return false;
            if (memberRole == 'AM') return _currentUserId == null || memberId == _currentUserId;
            return true; // SO and others
          } else if (_currentUserRole == 'RM') {
            if (memberRole == 'RM') return _currentUserId == null || memberId == _currentUserId;
            return true; // AM and SO
          }
          return true;
        }).toList();
      }
      if (_searchQuery.isNotEmpty) {
        list = list.where((member) {
          final name = (member["fullname"]?.toString() ?? "").toLowerCase();
          final empId = (member["employee_id"]?.toString() ?? member["user_id"]?.toString() ?? "").toLowerCase();
          return name.contains(_searchQuery) || empId.contains(_searchQuery);
        }).toList();
      }
      groupedKeys = list;
    } else {
      var filtered = filteredTransactions;
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((tx) {
          final empName = (tx["employee_name"]?.toString() ?? "").toLowerCase();
          final empId = (tx["employee_id"]?.toString() ?? tx["user_id"]?.toString() ?? "").toLowerCase();
          return empName.contains(_searchQuery) || empId.contains(_searchQuery);
        }).toList();
      }
      for (var tx in filtered) {
        final userId = tx["user_id"]?.toString() ?? tx["employee_id"]?.toString() ?? "unknown";
        final createdOn = tx["created_on"]?.toString() ?? "unknown";
        final outletId = tx["outlet_id"]?.toString() ?? tx["outlet_name"]?.toString() ?? "unknown";
        final key = "${userId}_${outletId}_$createdOn";
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(tx);
      }
      groupedKeys = grouped.keys.toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "TEAM POB HISTORY",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((tab) => Tab(text: tab["label"])).toList(),
        ),
      ),
      body: Column(
        children: [
          if (type != "pob")
            GestureDetector(
              onTap: _pickMonth,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate).toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name or ID...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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

          Expanded(
            child: _isLoading
                ? const Center(child: LogoProgressIndicator(size: 85))
                : groupedKeys.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: groupedKeys.length,
                        itemBuilder: (context, index) {
                          if (type == "pob") {
                            final member = groupedKeys[index];
                            return _buildTeamMemberCard(member);
                          } else {
                            final key = groupedKeys[index];
                            final items = grouped[key]!;
                            return _buildGroupedCard(items);
                          }
                        },
                      ),
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
          Icon(
            Icons.history_toggle_off_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No team transactions found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(dynamic member) {
    final name = member["fullname"]?.toString() ?? "Unknown User";
    final empId = member["employee_id"]?.toString() ?? member["user_id"]?.toString() ?? "-";
    final role = member["rolecode"]?.toString() ?? "SO";
    final outlets = member["total_outlets"] ?? 0;
    final visits = member["total_visits"] ?? 0;
    final activities = member["total_activities"] ?? 0;
    final pobs = member["total_pobs"] ?? 0;
    final pobVal = double.tryParse(member["pob_sale_value"]?.toString() ?? '') ?? 0.0;

    Color roleColor;
    if (role.toUpperCase() == "RM") {
      roleColor = Colors.purple.shade700;
    } else if (role.toUpperCase() == "AM") {
      roleColor = Colors.orange.shade800;
    } else {
      roleColor = Colors.blue.shade700;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamMemberDetailScreen(
                userId: int.tryParse(member['user_id']?.toString() ?? '') ?? 0,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: roleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: 0.1),
                    radius: 18,
                    child: Text(
                      role.substring(0, role.length > 2 ? 2 : role.length).toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: roleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Employee ID: $empId",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricCol("Outlets", "$outlets", Colors.blue.shade700),
                  _buildMetricCol("Visits/Acts", "$visits/$activities", Colors.orange.shade800),
                  _buildMetricCol("POBs Done", "$pobs", Colors.purple.shade700),
                  _buildMetricCol("POB Value", "₹${pobVal.toStringAsFixed(0)}", AppColors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildGroupedCard(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final first = items.first;
    final empName = first["employee_name"]?.toString() ?? "Unknown SO";
    final empId = first["employee_id"]?.toString() ?? first["user_id"]?.toString() ?? "-";
    final role = first["rolecode"]?.toString() ?? "SO";
    final createdOn = first["created_on"]?.toString() ?? first["created_at"]?.toString() ?? "";
    final totalSkus = items.length;
    final outletIdStr = first["outlet_id"]?.toString() ?? "";
    final outletName = first["outlet_name"]?.toString() ?? _outletNameLookup[outletIdStr] ?? "Unknown Outlet";

    Color roleColor;
    if (role.toUpperCase() == "RM") {
      roleColor = Colors.purple.shade700;
    } else if (role.toUpperCase() == "AM") {
      roleColor = Colors.orange.shade800;
    } else {
      roleColor = Colors.blue.shade700;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProductPopup(context, items, title: "${outletName.toUpperCase()} - DETAILS"),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: roleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outletName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Submitted by: $empName ($role)",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Employee ID: $empId",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (createdOn.isNotEmpty)
                    Text(
                      DateFormatter.formatDateTime(createdOn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
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
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 16, color: roleColor),
                      const SizedBox(width: 6),
                      Text(
                        "$totalSkus SKU(s) Submitted",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "VIEW DETAILS",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: roleColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductPopup(BuildContext context, List<dynamic> items, {String? title, bool isPob = false}) {
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String name = item['product_name'] ?? "Product ID: ${item['product_id'] ?? 'N/A'}";
      if (!grouped.containsKey(name)) {
        grouped[name] = [];
      }
      grouped[name]!.add(item);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    title ?? "PRODUCT LIST",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...entry.value.map((item) {
                              String qty = item['quantity']?.toString() ?? '0';
                              String sku = item['sku_name'] ?? item['sku_displayname'] ?? item['sku_id']?.toString() ?? 'N/A';
                              String val = item['sale_value']?.toString() ?? item['subtotal']?.toString() ?? '0.00';
                              String price = item['sku_retailerprice']?.toString() ?? item['price']?.toString() ?? '0.00';
                              String supplied = item['supplied_qty']?.toString() ?? '0';
                              String remaining = item['remaining_qty']?.toString() ?? '0';
                              return _skuRow(sku, qty, price, val, isPob: isPob, supplied: supplied, remaining: remaining);
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CLOSE",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _skuRow(String sku, String qty, String price, String val, {bool isPob = false, String supplied = "0", String remaining = "0"}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sku,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                if (isPob)
                  Text(
                    "Ordered: $qty | Supplied: $supplied | Remaining: $remaining\nPrice: ₹$price | Subtotal: ₹$val",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  )
                else
                  Text(
                    "Price: ₹$price | Val: ₹$val",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              qty,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
