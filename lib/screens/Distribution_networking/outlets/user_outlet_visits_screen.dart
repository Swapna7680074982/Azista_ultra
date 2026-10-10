import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../permissions/SessionManager.dart';
import '../../../services/api_services.dart';
import '../../../utilities/common_widgets.dart';
import '../../../utilities/date_formatter.dart';
import '../../../utilities/wavy_app_bar.dart';
import '../../Homes/main_tab_provider.dart';
import 'outlet_provider.dart';

class UserVisitRecord {
  final String outletId;
  final String outletName;
  final String outletType;
  final String visitId;
  final String visitDate;
  final String visitType;
  final String checkinTime;
  final String? checkoutTime;
  final int? durationMinutes;
  final bool isActive;
  final String? personName;

  UserVisitRecord({
    required this.outletId,
    required this.outletName,
    required this.outletType,
    required this.visitId,
    required this.visitDate,
    required this.visitType,
    required this.checkinTime,
    this.checkoutTime,
    this.durationMinutes,
    this.isActive = false,
    this.personName,
  });

  String get workingHoursFormatted {
    int duration = durationMinutes ?? 0;
    if (duration == 0 && checkinTime.isNotEmpty) {
      try {
        final parsedCheckIn = DateTime.tryParse(checkinTime.trim())?.toLocal();
        if (parsedCheckIn != null) {
          DateTime end = DateTime.now();
          if (!isActive && checkoutTime != null && checkoutTime!.isNotEmpty && checkoutTime != 'null' && checkoutTime != 'N/A') {
            final parsedCheckOut = DateTime.tryParse(checkoutTime!.trim())?.toLocal();
            if (parsedCheckOut != null) end = parsedCheckOut;
          }
          final diff = end.difference(parsedCheckIn).inMinutes;
          if (diff > 0) duration = diff;
        }
      } catch (_) {}
    }

    if (duration >= 60) {
      final hrs = duration ~/ 60;
      final mins = duration % 60;
      return mins > 0 ? "$hrs hr $mins mins" : "$hrs hr";
    }
    return "$duration mins";
  }
}

class UserOutletVisitsScreen extends StatefulWidget {
  const UserOutletVisitsScreen({super.key});

  @override
  State<UserOutletVisitsScreen> createState() => _UserOutletVisitsScreenState();
}

class _UserOutletVisitsScreenState extends State<UserOutletVisitsScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  String? _errorMessage;
  List<UserVisitRecord> _allVisits = [];
  int _lastRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadVisitsData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final tabProvider = Provider.of<MainTabProvider>(context);
      if (tabProvider.currentIndex == 2 && tabProvider.visitsRefreshTick != _lastRefreshTick) {
        _lastRefreshTick = tabProvider.visitsRefreshTick;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadVisitsData();
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVisitsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<UserVisitRecord> loadedRecords = [];
      final Map<String, Outlet> outletMap = {};

      // 1. Seed outletMap from OutletProvider if available
      final providerOutlets = context.read<OutletProvider>().outlets;
      for (var o in providerOutlets) {
        outletMap[o.id] = o;
      }
      final nearbyOutlets = context.read<OutletProvider>().nearbyOutlets;
      for (var o in nearbyOutlets) {
        outletMap[o.id] = o;
      }

      // 2. Fetch routes and outlets dictionary
      final Set<int> candidateOutletIds = {};
      try {
        final routesRes = await ApiServices.getRoutes();
        final rawRoutes = routesRes != null
            ? (routesRes["routes"] ?? routesRes["beats"] ?? routesRes["data"])
            : null;

        List<int> routeIds = [];
        if (rawRoutes is List) {
          for (var r in rawRoutes) {
            if (r is Map) {
              final id = int.tryParse((r["ROUTE_ID"] ?? r["route_id"] ?? r["id"] ?? "").toString());
              if (id != null && !routeIds.contains(id)) routeIds.add(id);
            }
          }
        } else if (rawRoutes is Map) {
          for (var item in rawRoutes.values) {
            if (item is Map) {
              final id = int.tryParse((item["ROUTE_ID"] ?? item["route_id"] ?? item["id"] ?? "").toString());
              if (id != null && !routeIds.contains(id)) routeIds.add(id);
            }
          }
        }

        for (var rId in routeIds) {
          final oRes = await ApiServices.getUserOutlets(routeId: rId);
          if (oRes != null && oRes['data'] is List) {
            for (var j in (oRes['data'] as List)) {
              if (j is Map) {
                final o = Outlet.fromJson(Map<String, dynamic>.from(j));
                outletMap[o.id] = o;
                final oIdInt = int.tryParse(o.id);
                if (oIdInt != null) candidateOutletIds.add(oIdInt);
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching routes/outlets: $e");
      }

      // 3. Fetch candidate outlet IDs from calls_info API for selected date
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final monthStr = "${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}";

      try {
        final callsRes = await ApiServices.getCallsInfo(date: dateStr) ??
            await ApiServices.getCallsInfo(month: monthStr);

        if (callsRes != null && callsRes["data"] is List) {
          for (var item in callsRes["data"]) {
            if (item is Map) {
              final oId = int.tryParse((item["outlet_id"] ?? item["id"] ?? '').toString());
              if (oId != null) candidateOutletIds.add(oId);
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching calls info: $e");
      }

      // Also include active check-in outlet ID if present and selected date is today
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      final activeOutletId = await SessionManager.getOutletCheckInOutletId();
      final activeCheckInTime = await SessionManager.getOutletCheckInTime();
      final activeVisitId = await SessionManager.getOutletCheckInVisitId();
      if (isToday && activeOutletId != null) {
        candidateOutletIds.add(activeOutletId);
      }

      // 4. Fetch getOutletHistory for candidate outlets to extract real visit records
      for (var oId in candidateOutletIds) {
        Map<String, dynamic>? hist;
        for (int attempt = 0; attempt < 2; attempt++) {
          try {
            hist = await ApiServices.getOutletHistory(
              outletId: oId,
              fromDate: dateStr,
              toDate: dateStr,
              month: _selectedDate.month,
              year: _selectedDate.year,
            );
            if (hist != null &&
                (hist['status'] == true ||
                    hist['status'] == 1 ||
                    hist['status'] == '1' ||
                    hist['status'] == 'success' ||
                    hist['status_code'] == 200)) {
              break;
            }
          } catch (_) {}
          if (attempt < 1) await Future.delayed(const Duration(milliseconds: 150));
        }

        if (hist != null &&
            (hist['status'] == true ||
                hist['status'] == 1 ||
                hist['status'] == '1' ||
                hist['status'] == 'success' ||
                hist['status_code'] == 200)) {
          final matchedOutlet = outletMap[oId.toString()];
          final details = hist['outlet_details'] is Map ? Map<String, dynamic>.from(hist['outlet_details']) : null;
          final String outletName = (details?['outlet_name'] ?? details?['name'] ?? matchedOutlet?.name ?? "Outlet #$oId").toString();
          final String outletType = (details?['outlet_category_name'] ?? details?['category_name'] ?? matchedOutlet?.type ?? "").toString();

          final rawVisits = (hist['visit_history'] ??
              hist['visits'] ??
              hist['data']?['visit_history'] ??
              hist['data']?['visits'] ??
              (hist['data'] is List ? hist['data'] : null) ??
              []) as List;

          for (var v in rawVisits) {
            if (v is Map) {
              final vMap = Map<String, dynamic>.from(v);
              final vId = (vMap['visit_id'] ?? vMap['id'] ?? '').toString();
              final vDate = (vMap['visit_date'] ?? vMap['date'] ?? vMap['checkin_time'] ?? '').toString();
              final vType = (vMap['visit_type'] ?? vMap['call_type'] ?? 'INDIVIDUAL').toString();
              final cIn = (vMap['checkin_time'] ?? vMap['check_in'] ?? vDate).toString();
              final cOut = vMap['checkout_time']?.toString();
              final bool isAct = (cOut == null || cOut.isEmpty || cOut == 'N/A' || cOut == 'null');

              final pName = (vMap['employee_name'] ??
                      vMap['user_name'] ??
                      vMap['fullname'] ??
                      vMap['created_by_name'] ??
                      vMap['submitted_by'])
                  ?.toString();

              loadedRecords.add(UserVisitRecord(
                outletId: oId.toString(),
                outletName: outletName,
                outletType: outletType,
                visitId: vId,
                visitDate: vDate,
                visitType: vType,
                checkinTime: cIn,
                checkoutTime: cOut,
                durationMinutes: int.tryParse((vMap['duration_minutes'] ?? vMap['duration'] ?? '').toString()),
                isActive: isAct,
                personName: pName,
              ));
            }
          }
        }
      }

      // 5. Prepend currently active check-in session if present, not in list, and selected date is today
      if (isToday && activeOutletId != null && activeCheckInTime != null) {
        final formattedActiveTime = activeCheckInTime.toIso8601String();
        final matchedOutlet = outletMap[activeOutletId.toString()];
        final bool alreadyActive = loadedRecords.any((r) => r.outletId == activeOutletId.toString() && r.isActive);

        if (!alreadyActive) {
          loadedRecords.insert(
            0,
            UserVisitRecord(
              outletId: activeOutletId.toString(),
              outletName: (matchedOutlet != null && matchedOutlet.name.isNotEmpty && matchedOutlet.name != 'Unknown')
                  ? matchedOutlet.name
                  : "Outlet #$activeOutletId",
              outletType: matchedOutlet?.type ?? "",
              visitId: (activeVisitId ?? 0).toString(),
              visitDate: formattedActiveTime,
              visitType: "INDIVIDUAL",
              checkinTime: formattedActiveTime,
              checkoutTime: null,
              isActive: true,
            ),
          );
        }
      }

      // 6. Deduplicate and filter by selected date
      final List<UserVisitRecord> uniqueRecords = [];
      final Set<String> seenKeys = {};
      for (var r in loadedRecords) {
        final key = "${r.outletId}_${r.visitId}_${r.checkinTime}";
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          final rDate = _getRecordDate(r);
          if (rDate != null) {
            if (rDate.year == _selectedDate.year &&
                rDate.month == _selectedDate.month &&
                rDate.day == _selectedDate.day) {
              uniqueRecords.add(r);
            }
          } else {
            final ymd = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
            final dmy = "${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}";
            if (r.checkinTime.contains(ymd) || r.checkinTime.contains(dmy) || r.visitDate.contains(ymd) || r.visitDate.contains(dmy)) {
              uniqueRecords.add(r);
            }
          }
        }
      }

      // Sort: active visits first, then newest checkin time descending
      uniqueRecords.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.checkinTime.compareTo(a.checkinTime);
      });

      if (mounted) {
        setState(() {
          _allVisits = uniqueRecords;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint("Error loading user visits: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading visits: $e";
        });
      }
    }
  }

  DateTime? _getRecordDate(UserVisitRecord record) {
    if (record.checkinTime.trim().isNotEmpty) {
      final dt = _parseDateTime(record.checkinTime);
      if (dt != null) return dt;
    }
    if (record.visitDate.trim().isNotEmpty) {
      final dt = _parseDateTime(record.visitDate);
      if (dt != null) return dt;
    }
    return null;
  }

  DateTime? _parseDateTime(String str) {
    final cleaned = str.trim();
    if (cleaned.isEmpty || cleaned == 'null' || cleaned == 'N/A') return null;

    final dt = DateTime.tryParse(cleaned);
    if (dt != null) return dt.toLocal();

    final patterns = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd HH:mm",
      "yyyy-MM-dd",
      "dd-MM-yyyy HH:mm:ss",
      "dd-MM-yyyy HH:mm",
      "dd-MM-yyyy",
      "dd/MM/yyyy HH:mm:ss",
      "dd/MM/yyyy HH:mm",
      "dd/MM/yyyy",
      "yyyy/MM/dd HH:mm:ss",
      "yyyy/MM/dd",
      "d MMM yyyy, hh:mm a",
      "d MMM yyyy",
    ];

    for (final p in patterns) {
      try {
        return DateFormat(p).parse(cleaned).toLocal();
      } catch (_) {}
    }
    return null;
  }

  List<UserVisitRecord> get _filteredVisits {
    if (_searchQuery.trim().isEmpty) {
      return _allVisits;
    }
    final q = _searchQuery.toLowerCase();
    return _allVisits.where((record) {
      return record.outletName.toLowerCase().contains(q) ||
          record.outletId.toLowerCase().contains(q) ||
          record.outletType.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateText = isToday
        ? "TODAY, ${DateFormat('dd MMM yyyy').format(_selectedDate).toUpperCase()}"
        : DateFormat('EEEE, dd MMM yyyy').format(_selectedDate).toUpperCase();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "VISIT DATE",
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
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null &&
        (picked.year != _selectedDate.year ||
            picked.month != _selectedDate.month ||
            picked.day != _selectedDate.day)) {
      setState(() {
        _selectedDate = picked;
      });
      _loadVisitsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVisits;

    return Scaffold(
      appBar: WavyAppBar(
        title: "VISITS",
        actions: [
          IconButton(
            tooltip: "Refresh Visits",
            icon: const Icon(Icons.sync, color: AppColors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Syncing visits..."),
                  duration: Duration(milliseconds: 800),
                ),
              );
              _loadVisitsData();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Calendar / Selected Date Selector
          _buildDateSelector(),

          // 2. Search & Counter Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search visits by outlet name or ID...",
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search,
                            size: 20, color: Colors.grey),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 18, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    "${filtered.length} ${filtered.length == 1 ? 'VISIT' : 'VISITS'}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Visits List
          Expanded(
            child: _isLoading
                ? const Center(child: LogoProgressIndicator(size: 60))
                : _errorMessage != null && _allVisits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.red),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadVisitsData,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text("Retry"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadVisitsData,
                            color: AppColors.primary,
                            child: ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Icon(Icons.history_toggle_off,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  "No Visits Found",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    _searchQuery.isNotEmpty
                                        ? "No visits matching '$_searchQuery'"
                                        : "No visits recorded for ${DateFormat('dd MMMM yyyy').format(_selectedDate)}.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Center(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = "";
                                        });
                                      },
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: const Text("Clear Search"),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadVisitsData,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final record = filtered[index];
                                return _buildSimpleVisitCard(record);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleVisitCard(UserVisitRecord record) {
    final isJoint = record.visitType.toUpperCase() == 'JOINT';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: record.isActive
              ? Colors.green.shade300
              : Colors.grey.shade200,
          width: record.isActive ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Outlet Name & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: record.isActive
                  ? Colors.green.shade50
                  : isJoint
                      ? Colors.teal.shade50
                      : Colors.blue.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.outletName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            "OUTLET ID: ${record.outletId}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (record.outletType.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                record.outletType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                        if (record.personName != null && record.personName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  record.personName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                if (record.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radio_button_checked,
                            size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "ACTIVE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isJoint
                          ? Colors.teal.shade700
                          : Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      record.visitType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body: Check-in Time, Check-out Time & Working Hours
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CHECK-IN TIME",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.login,
                                  size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  record.checkinTime.isNotEmpty
                                      ? DateFormatter.formatDateTime(
                                          record.checkinTime)
                                      : (record.visitDate.isNotEmpty
                                          ? DateFormatter.formatDate(
                                              record.visitDate)
                                          : 'N/A'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CHECK-OUT TIME",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.logout,
                                size: 14,
                                color: record.isActive
                                    ? Colors.orange.shade700
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  record.isActive
                                      ? "In Progress"
                                      : (record.checkoutTime != null &&
                                              record.checkoutTime!.isNotEmpty &&
                                              record.checkoutTime != 'null' &&
                                              record.checkoutTime != 'N/A'
                                          ? DateFormatter.formatDateTime(
                                              record.checkoutTime!)
                                          : "Not Recorded"),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: record.isActive
                                        ? Colors.orange.shade800
                                        : Colors.black87,
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hourglass_bottom,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          "WORKING HOURS: ",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: record.isActive
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: record.isActive
                                  ? Colors.orange.shade300
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Text(
                            record.isActive
                                ? "${record.workingHoursFormatted} (Live)"
                                : record.workingHoursFormatted,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: record.isActive
                                  ? Colors.orange.shade800
                                  : Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
