import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';
import 'package:intl/intl.dart';

class TeamOutletHistoryScreen extends StatefulWidget {
  final int outletId;
  final String outletName;
  final int month;
  final int year;

  const TeamOutletHistoryScreen({
    super.key,
    required this.outletId,
    required this.outletName,
    required this.month,
    required this.year,
  });

  @override
  State<TeamOutletHistoryScreen> createState() => _TeamOutletHistoryScreenState();
}

class _TeamOutletHistoryScreenState extends State<TeamOutletHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingPob = true;
  bool _isLoadingVisits = true;
  List<dynamic> _pobHistory = [];
  List<dynamic> _visitHistory = [];
  String? _pobError;
  String? _visitError;

  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (now.month == widget.month && now.year == widget.year) {
      selectedDate = now;
    } else {
      selectedDate = DateTime(widget.year, widget.month, 1);
    }
    _tabController = TabController(length: 2, vsync: this);
    _fetchPobHistory();
    _fetchVisitHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPobHistory() async {
    setState(() {
      _isLoadingPob = true;
      _pobError = null;
    });

    try {
      final res = await ApiServices.getOutletPobHistory(
        outletId: widget.outletId,
        month: selectedDate.month,
        year: selectedDate.year,
      );

      if (mounted) {
        setState(() {
          if (res != null && res["status"] == true) {
            _pobHistory = res["data"] as List<dynamic>? ?? [];
          } else {
            _pobError = "Failed to load POB history";
          }
          _isLoadingPob = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching outlet POB history: $e");
      if (mounted) {
        setState(() {
          _pobError = "Error loading POB history";
          _isLoadingPob = false;
        });
      }
    }
  }

  Future<void> _fetchVisitHistory() async {
    setState(() {
      _isLoadingVisits = true;
      _visitError = null;
    });

    try {
      final res = await ApiServices.getOutletVisitActivityHistory(
        outletId: widget.outletId,
        month: selectedDate.month,
        year: selectedDate.year,
      );

      if (mounted) {
        setState(() {
          if (res != null && res["status"] == true) {
            _visitHistory = res["visit_history"] as List<dynamic>? ?? [];
          } else {
            _visitError = "Failed to load visit history";
          }
          _isLoadingVisits = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching outlet visit history: $e");
      if (mounted) {
        setState(() {
          _visitError = "Error loading visit history";
          _isLoadingVisits = false;
        });
      }
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final oldMonth = selectedDate.month;
      final oldYear = selectedDate.year;
      setState(() {
        selectedDate = picked;
      });
      if (picked.month != oldMonth || picked.year != oldYear) {
        _fetchPobHistory();
        _fetchVisitHistory();
      }
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

  List<dynamic> get filteredPobs {
    return _pobHistory.where((pob) {
      final dateStr = pob["created_at"]?.toString() ?? pob["created_on"]?.toString() ?? "";
      if (dateStr.isEmpty) return false;
      final parsed = _parseDate(dateStr);
      if (parsed == null) return false;
      return parsed.year == selectedDate.year &&
             parsed.month == selectedDate.month &&
             parsed.day == selectedDate.day;
    }).toList();
  }

  List<dynamic> get filteredVisits {
    return _visitHistory.where((visit) {
      final dateStr = visit["visit_date"]?.toString() ?? visit["checkin_time"]?.toString() ?? "";
      if (dateStr.isEmpty) return false;
      final parsed = _parseDate(dateStr);
      if (parsed == null) return false;
      return parsed.year == selectedDate.year &&
             parsed.month == selectedDate.month &&
             parsed.day == selectedDate.day;
    }).toList();
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open attachment")),
        );
      }
    }
  }

  bool _isTelePob(dynamic pob) {
    if (pob is! Map) return false;

    final pobType = pob['pob_type']?.toString().toLowerCase() ?? '';
    if (pobType.contains('tele')) return true;

    final type = pob['type']?.toString().toLowerCase() ?? '';
    if (type.contains('tele')) return true;

    final orderType = pob['order_type']?.toString().toLowerCase() ?? '';
    if (orderType.contains('tele')) return true;

    if (pob['is_tele'] == true || pob['is_tele'] == 1 || pob['is_tele'] == '1' || pob['is_tele'] == 'true') return true;
    if (pob['is_tele_pob'] == true || pob['is_tele_pob'] == 1 || pob['is_tele_pob'] == '1' || pob['is_tele_pob'] == 'true') return true;

    final pobNumber = pob['pob_number']?.toString().toUpperCase() ?? '';
    if (pobNumber.contains('TELE')) return true;

    final remarks = pob['remarks']?.toString().toLowerCase() ?? '';
    if (remarks.contains('tele')) return true;

    return false;
  }

  Widget _buildPobTypeBadge(dynamic pob) {
    final isTele = _isTelePob(pob);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isTele ? Colors.purple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isTele ? Colors.purple.shade300 : Colors.blue.shade300,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTele ? Icons.phone_in_talk : Icons.storefront,
            size: 11,
            color: isTele ? Colors.purple.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isTele ? "TELE POB" : "REGULAR POB",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTele ? Colors.purple.shade800 : Colors.blue.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.outletName.toUpperCase(),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "POB HISTORY"),
            Tab(text: "VISITS & ACTIVITIES"),
          ],
        ),
      ),
      body: Column(
        children: [
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPobHistoryTab(),
                _buildVisitsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPobHistoryTab() {
    if (_isLoadingPob) {
      return const Center(child: LogoProgressIndicator(size: 80));
    }

    if (_pobError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_pobError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchPobHistory,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    final filteredList = filteredPobs;
    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          "No POB records found for this period",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPobHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final pob = filteredList[index];
          final pobNum = pob["pob_number"]?.toString() ?? "POB-${pob["id"]}";
          final dateStr = pob["created_at"]?.toString() ?? "";
          final status = pob["status"]?.toString() ?? "pending";
          final items = pob["items"] as List<dynamic>? ?? [];
          double saleVal = double.tryParse(pob["sale_value"]?.toString() ?? '') ?? 0.0;
          double totalAmt = double.tryParse(pob["ptr_incl_gst_total_amount"]?.toString() ?? '') ?? 0.0;

          if (saleVal == 0.0 && items.isNotEmpty) {
            for (var item in items) {
              final sub = double.tryParse(item["ptr_subtotal"]?.toString() ?? '');
              if (sub != null && sub > 0) {
                saleVal += sub;
              } else {
                final price = double.tryParse(item["ptr_price"]?.toString() ?? item["price"]?.toString() ?? item["sku_retailerprice"]?.toString() ?? '') ?? 0.0;
                final qty = int.tryParse(item["quantity"]?.toString() ?? '') ?? 0;
                saleVal += price * qty;
              }
            }
          }

          if (totalAmt == 0.0 && items.isNotEmpty) {
            for (var item in items) {
              final gstSub = double.tryParse(item["ptr_incl_gst_subtotal"]?.toString() ?? '');
              if (gstSub != null && gstSub > 0) {
                totalAmt += gstSub;
              } else {
                final gstPrice = double.tryParse(item["ptr_incl_gst_price"]?.toString() ?? '');
                final qty = int.tryParse(item["quantity"]?.toString() ?? '') ?? 0;
                if (gstPrice != null && gstPrice > 0) {
                  totalAmt += gstPrice * qty;
                }
              }
            }
            if (totalAmt == 0.0) {
              totalAmt = saleVal;
            }
          }
          final orderCopy = pob["order_copy"]?.toString();

          final isSupplied = status.toLowerCase().trim() == "supplied";

          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                pobNum,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPobTypeBadge(pob),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSupplied ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: isSupplied ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (dateStr.isNotEmpty)
                    Text(
                      "Date: ${DateFormatter.formatDateTime(dateStr)}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("SALE VALUE", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text("₹${saleVal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TOTAL (INCL GST)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text("₹${totalAmt.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("SKUS", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(items.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => _showPobItemsPopup(context, items, pobNum, status),
                            icon: const Icon(Icons.list, size: 16, color: AppColors.primary),
                            label: const Text("VIEW ITEMS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                      if (orderCopy != null && orderCopy.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: () => _openFile(orderCopy),
                              icon: const Icon(Icons.file_present, size: 16, color: Colors.white),
                              label: const Text("ORDER COPY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.button,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisitsTab() {
    if (_isLoadingVisits) {
      return const Center(child: LogoProgressIndicator(size: 80));
    }

    if (_visitError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_visitError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchVisitHistory,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    final filteredList = filteredVisits;
    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          "No visits logged for this period",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVisitHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final visit = filteredList[index];
          final visitDate = visit["visit_date"]?.toString() ?? "";
          final checkin = visit["checkin_time"]?.toString() ?? "";
          final checkout = visit["checkout_time"]?.toString() ?? "";
          final address = visit["checkin_address"]?.toString() ?? "N/A";
          int durationMins = int.tryParse(visit["duration_minutes"]?.toString() ?? '') ?? 0;
          // If visit is active (no checkout), compute live duration from check-in time
          if (durationMins == 0 && checkout.isEmpty && checkin.isNotEmpty) {
            try {
              final parsedCheckIn = DateTime.tryParse(checkin.trim())?.toLocal();
              if (parsedCheckIn != null) {
                final liveDiff = DateTime.now().difference(parsedCheckIn).inMinutes;
                if (liveDiff > 0) durationMins = liveDiff;
              }
            } catch (_) {}
          }
          final durationStr = durationMins >= 60
              ? "${(durationMins / 60.0).toStringAsFixed(1)} Hours"
              : "$durationMins Mins";
          final remarks = visit["remarks"]?.toString() ?? "N/A";
          final activities = visit["activities"] as List<dynamic>? ?? [];

          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Visit date: $visitDate",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          durationStr,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildVisitRow(Icons.login, "Check In", checkin.isNotEmpty ? DateFormatter.formatDateTime(checkin) : "N/A"),
                  const SizedBox(height: 6),
                  _buildVisitRow(Icons.logout, "Check Out", checkout.isNotEmpty ? DateFormatter.formatDateTime(checkout) : "Active (In progress)"),
                  const SizedBox(height: 6),
                  _buildVisitRow(Icons.location_on, "Address", address),
                  const SizedBox(height: 6),
                  _buildVisitRow(Icons.notes, "Remarks", remarks),
                  
                  if (activities.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    const Text(
                      "ACTIVITIES LOGGED",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    ...activities.map((act) => _buildActivityTile(act)),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisitRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(dynamic act) {
    final actName = act["activity_name"]?.toString() ?? "Activity";
    final remarks = act["remarks"]?.toString() ?? "No remarks";
    final date = act["activity_date"]?.toString() ?? "";
    final files = act["files"] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                actName.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              if (date.isNotEmpty)
                Text(
                  DateFormatter.formatDateTime(date),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Remarks: $remarks",
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              "ATTACHMENTS:",
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            ...files.map((file) {
              final fileName = file["file_name"]?.toString() ?? "Attachment";
              final filePath = file["file_path"]?.toString();
              final isPdf = fileName.toLowerCase().endsWith(".pdf");

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  onTap: () => _openFile(filePath),
                  child: Row(
                    children: [
                      Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.image,
                        size: 14,
                        color: isPdf ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ]
        ],
      ),
    );
  }

  void _showPobItemsPopup(BuildContext context, List<dynamic> items, String pobNum, String status) {
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
                    "ITEMS: $pobNum",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: items.map((item) {
                        final prodName = item["product_name"]?.toString() ?? "Unknown Product";
                        final skuName = item["sku_displayname"]?.toString() ?? item["sku_name"]?.toString() ?? "N/A";
                        final qty = item["quantity"]?.toString() ?? "0";
                        final price = double.tryParse(item["ptr_price"]?.toString() ?? '') ?? 0.0;
                        final subtotal = double.tryParse(item["ptr_subtotal"]?.toString() ?? '') ?? 0.0;
                        
                        final supplied = item["supplied_qty"]?.toString() ?? "0";
                        final int totalQty = int.tryParse(qty) ?? 0;
                        final int suppliedQty = int.tryParse(supplied) ?? 0;
                        final int remaining = totalQty - suppliedQty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prodName.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                skuName,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Ordered: $qty",
                                      style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Supplied: $supplied",
                                      style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Remaining: $remaining",
                                      style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "₹${price.toStringAsFixed(2)} each",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Subtotal Amount",
                                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "₹${subtotal.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.button),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 10.0),
                                child: Divider(height: 1, thickness: 0.5, color: Colors.black12),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
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
}
