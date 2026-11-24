import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_services.dart';
import '../../utilities/wavy_app_bar.dart';

class VisitsScreen extends StatefulWidget {
  final int? initialOutletId;
  final DateTime? initialDate;

  const VisitsScreen({
    super.key,
    this.initialOutletId,
    this.initialDate,
  });

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  static const List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = true;
  List<dynamic> _visits = [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _selectedMonth = initial.month;
    _selectedYear = initial.year;
    _fetchVisits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      final monthStr = _selectedMonth.toString().padLeft(2, '0');
      final fromDateStr = "$_selectedYear-$monthStr-01";
      final toDateStr = "$_selectedYear-$monthStr-$lastDay";
      final monthYearStr = "$_selectedYear-$monthStr";

      final response = await ApiServices.getOutletVisitsHistory(
        month: _selectedMonth,
        year: _selectedYear,
        fromDate: fromDateStr,
        toDate: toDateStr,
        visitDate: monthYearStr,
      );

      if (response != null &&
          (response['status'] == true ||
              response['status'] == 'success' ||
              response['visits'] != null ||
              response['data'] != null ||
              response['visit_history'] != null)) {
        final list = response['visits'] ??
            response['data'] ??
            response['visit_history'] ??
            [];
        setState(() {
          _visits = list is List ? List<dynamic>.from(list) : [];
        });
      } else {
        setState(() {
          _visits = [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching outlet visits: $e");
      setState(() {
        _visits = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isCombinedVisit(Map<String, dynamic> visit) {
    final rawType = (visit['visit_type'] ?? visit['type'] ?? visit['visitType'] ?? '').toString().trim().toUpperCase();
    if (rawType.contains('COMBIN') ||
        rawType.contains('JOINT') ||
        rawType.contains('TEAM') ||
        rawType == '2') {
      return true;
    }
    if (visit['is_combined'] == true ||
        visit['is_combined'] == 1 ||
        visit['is_combined'] == '1' ||
        visit['is_combined'] == 'true' ||
        visit['is_combine'] == true ||
        visit['is_combine'] == 1 ||
        visit['is_combine'] == '1' ||
        visit['is_combine'] == 'true' ||
        visit['is_joint'] == true) {
      return true;
    }
    return false;
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty || dateTimeStr == 'null' || dateTimeStr == 'N/A' || dateTimeStr == '-') {
      return "-";
    }
    try {
      final dt = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat("dd MMM yyyy hh:mm a").format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  List<dynamic> get _filteredVisits {
    if (_searchQuery.isEmpty) return _visits;
    return _visits.where((v) {
      if (v is! Map) return false;
      final vMap = Map<String, dynamic>.from(v);
      final name = (vMap['outlet_name'] ?? '').toString().toLowerCase();
      final id = (vMap['outlet_id'] ?? '').toString().toLowerCase();
      final user = (vMap['fullname'] ?? vMap['user_name'] ?? '').toString().toLowerCase();
      final rawType = (vMap['visit_type'] ?? vMap['type'] ?? '').toString().toLowerCase();
      final date = (vMap['visit_date'] ?? vMap['checkin_time'] ?? '').toString().toLowerCase();
      final isComb = _isCombinedVisit(vMap);
      return name.contains(_searchQuery) ||
          id.contains(_searchQuery) ||
          user.contains(_searchQuery) ||
          rawType.contains(_searchQuery) ||
          date.contains(_searchQuery) ||
          (isComb && "combined".contains(_searchQuery)) ||
          (!isComb && "single".contains(_searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVisits;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: WavyAppBar(
        title: "VISITS",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh visits",
            onPressed: _fetchVisits,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Month Selector Card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        items: List.generate(
                          12,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              "${_months[index].toUpperCase()} $_selectedYear",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null && val != _selectedMonth) {
                            setState(() {
                              _selectedMonth = val;
                            });
                            _fetchVisits();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedYear--;
                          });
                          _fetchVisits();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.chevron_left, size: 20, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedYear++;
                          });
                          _fetchVisits();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search and Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        hintText: "Search visits by outlet name or ID...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Text(
                    "${filtered.length} VISITS",
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Visits List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              "No visits recorded for ${_months[_selectedMonth - 1]} $_selectedYear",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchVisits,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final visit = filtered[index] is Map ? Map<String, dynamic>.from(filtered[index]) : <String, dynamic>{};
                            final outletName = (visit['outlet_name'] ?? 'UNKNOWN OUTLET').toString().toUpperCase();
                            final outletId = visit['outlet_id']?.toString() ?? '-';
                            final isCombined = _isCombinedVisit(visit);
                            final displayVisitType = isCombined ? "COMBINED" : "SINGLE";
                            final outletCategory = (visit['outlet_category'] ?? visit['category_name'] ?? 'OUTLET').toString().toUpperCase();

                            final checkinTime = _formatTime(visit['checkin_time']?.toString());
                            final rawCheckout = visit['checkout_time']?.toString();
                            final isCheckedOut = rawCheckout != null &&
                                rawCheckout.isNotEmpty &&
                                rawCheckout != 'null' &&
                                rawCheckout != 'N/A' &&
                                rawCheckout != '-';
                            final checkoutTime = isCheckedOut ? _formatTime(rawCheckout) : "Checked-in (Active)";

                            final duration = visit['duration_minutes']?.toString() ?? '0';

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header with Light Blue Background
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEBF5FF),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                outletName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Single vs Combined representation badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isCombined ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isCombined ? const Color(0xFFFFB74D) : const Color(0xFF90CAF9),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isCombined ? Icons.groups_rounded : Icons.person,
                                                    size: 13,
                                                    color: isCombined ? const Color(0xFFE65100) : const Color(0xFF1565C0),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    displayVisitType,
                                                    style: TextStyle(
                                                      color: isCombined ? const Color(0xFFE65100) : const Color(0xFF1565C0),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              "OUTLET ID: $outletId",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            if (outletCategory.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  outletCategory,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Body
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Check-In Column
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "CHECK-IN TIME",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.arrow_forward, color: Colors.green, size: 14),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          checkinTime,
                                                          style: TextStyle(
                                                            color: Colors.green.shade700,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Check-Out Column
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "CHECK-OUT TIME",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color: isCheckedOut ? Colors.grey.shade700 : Colors.orange,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          checkoutTime,
                                                          style: TextStyle(
                                                            color: isCheckedOut ? Colors.black87 : Colors.orange.shade800,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),
                                        Divider(height: 1, color: Colors.grey.shade200),
                                        const SizedBox(height: 10),

                                        // Working Hours Row
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.hourglass_bottom,
                                              color: Colors.red,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              "WORKING HOURS: ",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3F2FD),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFF90CAF9)),
                                              ),
                                              child: Text(
                                                "$duration mins",
                                                style: const TextStyle(
                                                  color: Color(0xFF1976D2),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
