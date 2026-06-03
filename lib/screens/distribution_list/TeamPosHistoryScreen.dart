import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';

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

  final List<Map<String, String>> _tabs = [
    {"label": "STOCK", "code": "stock"},
    {"label": "SAMPLING", "code": "sampling"},
    {"label": "SALE", "code": "sale"},
    {"label": "POB", "code": "pob"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _transactions = [];
    });

    final type = _tabs[_tabController.index]["code"]!;
    try {
      final data = (type == "pob")
          ? await ApiServices.getTeamPobHistory()
          : await ApiServices.getTeamPosHistory(posType: type);
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
    }
  }

  List<dynamic> get filteredTransactions {
    return _transactions.where((tx) {
      final createdOn = tx["created_at"]?.toString() ?? tx["created_on"]?.toString() ?? "";
      if (createdOn.isEmpty) return false;
      final parsedDate = DateTime.tryParse(createdOn);
      if (parsedDate == null) return false;
      return parsedDate.year == selectedDate.year && parsedDate.month == selectedDate.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredTransactions;
    final Map<String, List<dynamic>> grouped = {};
    final List<dynamic> groupedKeys;
    final type = _tabs[_tabController.index]["code"]!;

    if (type == "pob") {
      groupedKeys = filtered;
    } else {
      for (var tx in filtered) {
        final userId = tx["user_id"]?.toString() ?? tx["employee_id"]?.toString() ?? "unknown";
        final createdOn = tx["created_on"]?.toString() ?? "unknown";
        final key = "${userId}_${createdOn}";
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(tx);
      }
      groupedKeys = grouped.keys.toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "TEAM POS HISTORY",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: AppColors.primary,
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
          // Month picker
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
                    DateFormat('MMMM yyyy').format(selectedDate).toUpperCase(),
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
                            final pob = groupedKeys[index];
                            final items = pob["items"] as List<dynamic>? ?? [];
                            return _buildPobGroupedCard(pob, items);
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

  Widget _buildPobGroupedCard(dynamic pob, List<dynamic> items) {
    final empName = pob["employee_name"]?.toString() ?? "Unknown SO";
    final empId = pob["employee_id"]?.toString() ?? pob["user_id"]?.toString() ?? "-";
    final role = pob["rolecode"]?.toString() ?? "SO";
    final outletName = pob["outlet_name"]?.toString() ?? "Unknown Outlet";
    final status = pob["status"]?.toString() ?? "pending";
    final totalAmount = pob["total_amount"]?.toString() ?? "0.00";
    final createdAt = pob["created_at"]?.toString() ?? "";
    final totalSkus = items.length;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProductPopup(context, items, title: "POB DETAILS: ${pob["pob_number"]}", isPob: true),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: $empId | $role | Outlet: ${outletName.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (createdAt.isNotEmpty)
                    Text(
                      DateFormatter.formatDateTime(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
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
                      Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        "$totalSkus SKU(s) | Value: ₹$totalAmount",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (status.toLowerCase().trim() == "supplied")
                          ? AppColors.button.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: (status.toLowerCase().trim() == "supplied") ? AppColors.button : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    final createdOn = first["created_on"]?.toString() ?? "";
    final totalSkus = items.length;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProductPopup(context, items, title: "${empName.toUpperCase()} - DETAILS"),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ID: $empId | $role",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (createdOn.isNotEmpty)
                    Text(
                      DateFormatter.formatDateTime(createdOn),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
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
                      Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
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
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.primary,
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
