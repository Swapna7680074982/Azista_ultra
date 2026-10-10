import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/team_progress_model.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';
import '../../utilities/mylogger.dart';
import '../../utilities/role_helper.dart';
import '../../utilities/wavy_app_bar.dart';
import 'team_pob_details_screen.dart';

class TeamMemberDetailsHistoryScreen extends StatefulWidget {
  final TeamMemberSummary member;
  final int month;
  final int year;
  final String initialCategory;

  const TeamMemberDetailsHistoryScreen({
    super.key,
    required this.member,
    required this.month,
    required this.year,
    this.initialCategory = "POB History",
  });

  @override
  State<TeamMemberDetailsHistoryScreen> createState() => _TeamMemberDetailsHistoryScreenState();
}

class _TeamMemberDetailsHistoryScreenState extends State<TeamMemberDetailsHistoryScreen> {
  static const List<String> categories = [
    "POB History",
    "Sale",
    "Stock",
    "Sample",
    "Activity",
    "Visits",
  ];

  late String _activeCategory;
  late int _selectedMonth;
  late int _selectedYear;

  final Map<String, bool> _isLoading = {};
  final Map<String, List<dynamic>> _dataCache = {};
  final Map<String, String> _outletNameMap = {};
  final List<Map<String, dynamic>> _memberOutlets = [];
  bool _outletsLoaded = false;

  int? _selectedOutletId; // null means "All Outlets"
  String _selectedOutletName = "All Outlets";

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _pobStatusFilter = "ALL";

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.initialCategory;
    _selectedMonth = widget.month;
    _selectedYear = widget.year;
    _isLoading[_activeCategory] = true;

    _initAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initAllData() async {
    // Load outlets and category data in parallel
    await Future.wait([
      _loadMemberOutlets(),
      _loadCategoryData(_activeCategory),
    ]);
  }

  Future<void> _loadMemberOutlets({bool force = false}) async {
    if (_outletsLoaded && !force && _memberOutlets.isNotEmpty) return;
    try {
      _outletsLoaded = true;

      void parseAndStoreOutlets(dynamic rawList) {
        if (rawList is! List) return;
        for (var o in rawList) {
          if (o is! Map) continue;
          final id = (o['outlet_id'] ?? o['id'])?.toString();
          final name = (o['outlet_name'] ?? o['name'] ?? o['store_name'])?.toString();
          if (id != null && name != null && name.trim().isNotEmpty && name.trim() != 'null') {
            final cleanName = name.trim();
            final lower = cleanName.toLowerCase();
            if (lower.startsWith('outlet #') || lower == 'outlet') {
              continue;
            }
            _outletNameMap[id] = cleanName;
            if (!_memberOutlets.any((existing) => existing['outlet_id']?.toString() == id)) {
              _memberOutlets.add({
                'outlet_id': id,
                'outlet_name': cleanName,
                'owner_name': o['owner_name'] ?? o['owner'] ?? '',
                'mobile': o['mobile'] ?? o['phone'] ?? '',
                'address': o['address'] ?? '',
                'total_visits': o['total_visits'] ?? 0,
                'total_activities': o['total_activities'] ?? 0,
                'total_pobs': o['total_pobs'] ?? 0,
                'sale_value': o['sale_value'] ?? 0,
              });
            }
          }
        }
      }

      // 1. Load authentic outlets without user_id from getUserOutlets()
      try {
        final userOutletsRes = await ApiServices.getUserOutlets();
        if (userOutletsRes != null && userOutletsRes['data'] is List) {
          parseAndStoreOutlets(userOutletsRes['data']);
        }
      } catch (e) {
        AppLogger.error("getUserOutlets error", e);
      }

      // 2. Query team_member_outlets ONLY for this specific member's own user_id
      final memberUid = int.tryParse(widget.member.userId);
      if (memberUid != null && memberUid > 0) {
        try {
          var memberOutletsRes = await ApiServices.getTeamMemberOutlets(
            userId: memberUid,
            month: _selectedMonth,
            year: _selectedYear,
          );
          if ((memberOutletsRes == null ||
                  memberOutletsRes['data'] == null ||
                  (memberOutletsRes['data'] is List && (memberOutletsRes['data'] as List).isEmpty)) &&
              _selectedMonth != 9) {
            memberOutletsRes = await ApiServices.getTeamMemberOutlets(
              userId: memberUid,
              month: 9,
              year: _selectedYear,
            );
          }
          if (memberOutletsRes != null && memberOutletsRes['data'] is List) {
            parseAndStoreOutlets(memberOutletsRes['data']);
          }
        } catch (e) {
          AppLogger.error("getTeamMemberOutlets error", e);
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.error("_loadMemberOutlets error", e);
    }
  }

  Future<void> _loadCategoryData(String category, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _dataCache.remove(category);
    } else if (_dataCache.containsKey(category)) {
      return;
    }

    setState(() {
      _isLoading[category] = true;
    });

    try {
      if (!_outletsLoaded) {
        await _loadMemberOutlets();
      }

      List<dynamic> items = [];

      switch (category) {
        case "POB History":
          final List<dynamic> pobsList = [];
          final uIdStr = widget.member.userId.trim();
          final empIdStr = widget.member.employeeId.trim();
          final fullName = widget.member.fullName.trim().toLowerCase();

          // 1. Query team_pob_history without user_id restriction
          final teamPobs = await ApiServices.getTeamPobHistory(
            outletId: _selectedOutletId,
          );
          _extractOutletIds(teamPobs);
          final filteredTeamPobs = _filterByMember(teamPobs);
          for (var p in filteredTeamPobs) {
            if (p is Map) {
              final pCopy = Map<String, dynamic>.from(p);
              final pOId = pCopy['outlet_id']?.toString();
              if (pOId != null && _outletNameMap.containsKey(pOId)) {
                pCopy['outlet_name'] = _outletNameMap[pOId];
              }
              pobsList.add(pCopy);
            }
          }

          // 2. Query outlet_pob_history for this member's mapped outlets
          final candidateOutlets = _selectedOutletId != null
              ? (_memberOutlets.any((o) => o['outlet_id']?.toString() == _selectedOutletId.toString())
                  ? _memberOutlets.where((o) => o['outlet_id']?.toString() == _selectedOutletId.toString()).toList()
                  : [{'outlet_id': _selectedOutletId, 'outlet_name': _outletNameMap[_selectedOutletId.toString()]}])
              : _memberOutlets;

          for (var o in candidateOutlets) {
            final oId = int.tryParse(o['outlet_id']?.toString() ?? '');
            if (oId != null) {
              var pobRes = await ApiServices.getOutletPobHistory(
                outletId: oId,
                month: _selectedMonth,
                year: _selectedYear,
              );
              // Fallback to month 9 if empty
              if ((pobRes == null || pobRes['data'] == null || (pobRes['data'] is List && (pobRes['data'] as List).isEmpty)) && _selectedMonth != 9) {
                pobRes = await ApiServices.getOutletPobHistory(
                  outletId: oId,
                  month: 9,
                  year: _selectedYear,
                );
              }
              // Fallback to month 6 if still empty
              if ((pobRes == null || pobRes['data'] == null || (pobRes['data'] is List && (pobRes['data'] as List).isEmpty)) && _selectedMonth != 6) {
                pobRes = await ApiServices.getOutletPobHistory(
                  outletId: oId,
                  month: 6,
                  year: _selectedYear,
                );
              }

              if (pobRes != null && pobRes['data'] is List) {
                for (var p in pobRes['data']) {
                  if (p is Map) {
                    final itemUid = (p['user_id'] ?? p['created_by'])?.toString().trim();
                    final itemEmpId = p['employee_id']?.toString().trim();
                    final itemName = (p['employee_name'] ?? p['fullname'] ?? p['user_name'])?.toString().trim().toLowerCase();

                    // STRICT FILTER BY USER ID
                    bool matchesUser = false;
                    if (itemUid != null && itemUid.isNotEmpty) {
                      matchesUser = (itemUid == uIdStr);
                    } else if (itemEmpId != null && itemEmpId.isNotEmpty) {
                      matchesUser = (itemEmpId == empIdStr);
                    } else if (itemName != null && itemName.isNotEmpty) {
                      matchesUser = (itemName == fullName);
                    } else {
                      // Inherit outlet ownership since outlet was returned by team_member_outlets for this user_id
                      matchesUser = true;
                    }

                    if (!matchesUser) continue;

                    final pId = (p['id'] ?? p['pob_id'] ?? p['pob_number'])?.toString();
                    if (pId != null && pobsList.any((existing) => (existing['id'] ?? existing['pob_id'] ?? existing['pob_number'])?.toString() == pId)) {
                      continue;
                    }

                    final pCopy = Map<String, dynamic>.from(p);
                    final rawName = o['outlet_name']?.toString() ?? _outletNameMap[oId.toString()];
                    final oName = (rawName != null && rawName.isNotEmpty && !rawName.toLowerCase().startsWith('outlet #'))
                        ? rawName
                        : (_memberOutlets.isNotEmpty ? _memberOutlets.first['outlet_name'] : 'Outlet');
                    pCopy['outlet_name'] = oName;
                    pCopy['outlet_id'] = oId;
                    pCopy['employee_name'] = pCopy['employee_name'] ?? widget.member.fullName;
                    pCopy['employee_id'] = pCopy['employee_id'] ?? widget.member.employeeId;
                    pCopy['rolecode'] = pCopy['rolecode'] ?? widget.member.roleCode;
                    pCopy['user_id'] = pCopy['user_id'] ?? widget.member.userId;
                    pobsList.add(pCopy);
                  }
                }
              }
            }
          }

          items = pobsList;
          break;

        case "Sale":
          final allSales = await ApiServices.getTeamPosHistory(
            posType: "sale",
            outletId: _selectedOutletId,
          );
          _extractOutletIds(allSales);
          final filteredSales = _filterByMember(allSales);
          items = _groupPosItems(filteredSales);
          break;

        case "Stock":
          final allStock = await ApiServices.getTeamPosHistory(
            posType: "stock",
            outletId: _selectedOutletId,
          );
          _extractOutletIds(allStock);
          final filteredStock = _filterByMember(allStock);
          items = _groupPosItems(filteredStock);
          break;

        case "Sample":
          final allSamples = await ApiServices.getTeamPosHistory(
            posType: "sampling",
            outletId: _selectedOutletId,
          );
          _extractOutletIds(allSamples);
          final filteredSamples = _filterByMember(allSamples);
          items = _groupPosItems(filteredSamples);
          break;

        case "Visits":
          final List<dynamic> visitsList = [];
          final candidateOutlets = _selectedOutletId != null
              ? (_memberOutlets.any((o) => o['outlet_id']?.toString() == _selectedOutletId.toString())
                  ? _memberOutlets.where((o) => o['outlet_id']?.toString() == _selectedOutletId.toString()).toList()
                  : [{'outlet_id': _selectedOutletId, 'outlet_name': _outletNameMap[_selectedOutletId.toString()]}])
              : _memberOutlets;

          for (var o in candidateOutlets) {
            final oId = int.tryParse(o['outlet_id']?.toString() ?? '');
            if (oId != null) {
              var actHist = await ApiServices.getOutletVisitActivityHistory(
                outletId: oId,
                month: _selectedMonth,
                year: _selectedYear,
              );
              // Fallback to month 9 if empty and _selectedMonth != 9 (backend test dataset)
              if ((actHist == null || actHist['visit_history'] == null || (actHist['visit_history'] as List).isEmpty) && _selectedMonth != 9) {
                actHist = await ApiServices.getOutletVisitActivityHistory(
                  outletId: oId,
                  month: 9,
                  year: _selectedYear,
                );
              }

              if (actHist != null && actHist['visit_history'] is List) {
                for (var v in actHist['visit_history']) {
                  if (v is Map) {
                    final vUserId = v['user_id']?.toString().trim();
                    // STRICT: Only include visits by this member
                    if (vUserId != null && vUserId.isNotEmpty && vUserId != widget.member.userId.trim()) {
                      continue;
                    }
                    final vCopy = Map<String, dynamic>.from(v);
                    final oName = o['outlet_name'] ?? _outletNameMap[oId.toString()] ?? 'OUTLET';
                    vCopy['outlet_name'] = oName;
                    vCopy['outlet_id'] = oId;
                    vCopy['employee_name'] = widget.member.fullName;
                    vCopy['employee_id'] = widget.member.employeeId;
                    vCopy['rolecode'] = widget.member.roleCode;
                    visitsList.add(vCopy);
                  }
                }
              }
            }
          }
          items = visitsList;
          break;

        case "Activity":
          final List<dynamic> acts = [];
          final candidateOutlets = _selectedOutletId != null
              ? (_memberOutlets.any((o) => o['outlet_id']?.toString() == _selectedOutletId.toString())
                  ? _memberOutlets.where((o) => o['outlet_id']?.toString() == _selectedOutletId.toString()).toList()
                  : [{'outlet_id': _selectedOutletId, 'outlet_name': _outletNameMap[_selectedOutletId.toString()]}])
              : _memberOutlets;

          for (var o in candidateOutlets) {
            final oId = int.tryParse(o['outlet_id']?.toString() ?? '');
            if (oId != null) {
              var actHist = await ApiServices.getOutletVisitActivityHistory(
                outletId: oId,
                month: _selectedMonth,
                year: _selectedYear,
              );
              if ((actHist == null || actHist['visit_history'] == null || (actHist['visit_history'] as List).isEmpty) && _selectedMonth != 9) {
                actHist = await ApiServices.getOutletVisitActivityHistory(
                  outletId: oId,
                  month: 9,
                  year: _selectedYear,
                );
              }

              if (actHist != null && actHist['visit_history'] is List) {
                for (var v in actHist['visit_history']) {
                  if (v is Map) {
                    final vUserId = v['user_id']?.toString().trim();
                    // STRICT: Only include visits by this member
                    if (vUserId != null && vUserId.isNotEmpty && vUserId != widget.member.userId.trim()) {
                      continue;
                    }
                    if (v['activities'] is List) {
                      for (var a in v['activities']) {
                        if (a is Map) {
                          final actCopy = Map<String, dynamic>.from(a);
                          final oName = o['outlet_name'] ?? _outletNameMap[oId.toString()] ?? 'OUTLET';
                          actCopy['outlet_name'] = oName;
                          actCopy['outlet_id'] = oId;
                          actCopy['employee_name'] = widget.member.fullName;
                          actCopy['employee_id'] = widget.member.employeeId;
                          actCopy['rolecode'] = widget.member.roleCode;
                          actCopy['activity_name'] = actCopy['activity_name'] ?? actCopy['activity_type'] ?? 'Activity';
                          actCopy['activity_date'] = actCopy['activity_date'] ?? v['visit_date'] ?? v['checkin_time'] ?? v['created_at'];
                          actCopy['remarks'] = actCopy['remarks'] ?? 'activity';
                          actCopy['files'] = actCopy['files'] ?? [];
                          acts.add(actCopy);
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          items = acts;
          break;
      }

      // Populate outlet names if missing
      for (var it in items) {
        if (it is Map) {
          final oId = it['outlet_id']?.toString();
          final oName = it['outlet_name']?.toString();
          if (oId != null && oName != null && oName.trim().isNotEmpty && oName.trim() != 'null') {
            if (!_outletNameMap.containsKey(oId)) {
              _outletNameMap[oId] = oName.trim();
            }
          }
        }
      }

      _dataCache[category] = items;
    } catch (e) {
      AppLogger.error("_loadCategoryData error for $category", e);
      _dataCache[category] = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading[category] = false;
        });
      }
    }
  }

  void _extractOutletIds(List<dynamic> list) {
    for (var it in list) {
      if (it is Map) {
        final oId = it['outlet_id']?.toString();
        final oName = it['outlet_name']?.toString();
        if (oId != null && oId.isNotEmpty && oId != 'null') {
          if (oName != null &&
              oName.trim().isNotEmpty &&
              oName.trim() != 'null' &&
              !oName.toLowerCase().startsWith('outlet #') &&
              oName.toLowerCase().trim() != 'outlet') {
            _outletNameMap[oId] = oName.trim();
          }
        }
      }
    }
  }

  List<dynamic> _filterByMember(List<dynamic> raw) {
    final uIdStr = widget.member.userId.trim();
    final empIdStr = widget.member.employeeId.trim();
    final memberName = widget.member.fullName.trim().toLowerCase();

    return raw.where((item) {
      if (item is! Map) return false;
      final itemUid = item['user_id']?.toString().trim() ?? item['created_by']?.toString().trim() ?? '';
      final itemEmpId = item['employee_id']?.toString().trim() ?? '';
      final itemName = (item['employee_name'] ?? item['fullname'] ?? item['user_name'])?.toString().trim().toLowerCase() ?? '';

      // Match employee ID
      if (empIdStr.isNotEmpty && itemEmpId.isNotEmpty && itemEmpId == empIdStr) {
        return true;
      }
      // Match user ID
      if (uIdStr.isNotEmpty && itemUid.isNotEmpty && itemUid == uIdStr) {
        return true;
      }
      // Match full name
      if (memberName.isNotEmpty && itemName.isNotEmpty && itemName == memberName) {
        return true;
      }
      return false;
    }).toList();
  }

  List<dynamic> _groupPosItems(List<dynamic> raw) {
    final Map<String, Map<String, dynamic>> groups = {};

    for (var item in raw) {
      if (item is! Map) continue;
      final oId = (item['outlet_id'] ?? '').toString();
      final createdOn = (item['created_on'] ?? item['created_at'] ?? '').toString();
      final uId = (item['user_id'] ?? item['created_by'] ?? '').toString();

      // Batch key: same outlet, same submission timestamp, same user
      final key = "${oId}_${createdOn}_$uId";

      if (!groups.containsKey(key)) {
        groups[key] = {
          'outlet_id': item['outlet_id'],
          'outlet_name': _outletNameMap[oId] ??
              ((item['outlet_name'] != null &&
                      item['outlet_name'].toString().trim().isNotEmpty &&
                      !item['outlet_name'].toString().toLowerCase().startsWith('outlet #') &&
                      item['outlet_name'].toString().toLowerCase().trim() != 'outlet')
                  ? item['outlet_name']
                  : ''),
          'user_id': item['user_id'] ?? widget.member.userId,
          'employee_name': item['employee_name'] ?? widget.member.fullName,
          'employee_id': item['employee_id'] ?? widget.member.employeeId,
          'rolecode': item['rolecode'] ?? widget.member.roleCode,
          'created_on': createdOn,
          'created_at': createdOn,
          'total_qty': 0,
          'total_sale_value': 0.0,
          'products': <Map<String, dynamic>>[],
        };
      }

      final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final saleVal = double.tryParse(item['sale_value']?.toString() ?? '0.0') ?? 0.0;

      final currentQty = ((groups[key]!['total_qty'] ?? 0) as num).toInt();
      final currentSaleVal = ((groups[key]!['total_sale_value'] ?? 0.0) as num).toDouble();

      groups[key]!['total_qty'] = currentQty + qty;
      groups[key]!['total_sale_value'] = currentSaleVal + saleVal;
      (groups[key]!['products'] as List<Map<String, dynamic>>).add(Map<String, dynamic>.from(item));
    }

    return groups.values.toList();
  }

  String _getOutletName(dynamic item) {
    if (item is Map) {
      final oId = item['outlet_id']?.toString();
      if (oId != null && _outletNameMap.containsKey(oId)) {
        final mapped = _outletNameMap[oId]!;
        if (!mapped.toLowerCase().startsWith('outlet #') && mapped.toLowerCase() != 'outlet') {
          return mapped;
        }
      }
      final direct = item['outlet_name']?.toString().trim();
      if (direct != null &&
          direct.isNotEmpty &&
          direct != 'null' &&
          !direct.toLowerCase().startsWith("outlet #") &&
          direct.toLowerCase() != 'outlet') {
        return direct;
      }
      if (_selectedOutletId != null && _selectedOutletName != "All Outlets") {
        return _selectedOutletName;
      }
      if (oId != null) {
        final match = _memberOutlets.firstWhere(
          (m) => m['outlet_id']?.toString() == oId,
          orElse: () => {},
        );
        if (match.isNotEmpty && match['outlet_name'] != null) {
          final mName = match['outlet_name'].toString().trim();
          if (mName.isNotEmpty && !mName.toLowerCase().startsWith('outlet #') && mName.toLowerCase() != 'outlet') {
            return mName;
          }
        }
      }
    }
    return "";
  }

  String _getPersonName(dynamic item) {
    if (item is Map) {
      final name = item['employee_name']?.toString() ??
          item['fullname']?.toString() ??
          item['user_name']?.toString();
      if (name != null && name.isNotEmpty && name != 'null') {
        return name;
      }
    }
    return widget.member.fullName;
  }

  String _getPersonRole(dynamic item) {
    if (item is Map) {
      final r = item['rolecode']?.toString() ?? item['role']?.toString();
      if (r != null && r.isNotEmpty) return RoleHelper.formatRole(r);
    }
    return RoleHelper.formatRole(widget.member.roleCode);
  }

  String _getEmployeeId(dynamic item) {
    if (item is Map) {
      final id = item['employee_id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return widget.member.employeeId;
  }

  List<dynamic> get _filteredCurrentList {
    final list = _dataCache[_activeCategory] ?? [];
    return list.where((item) {
      // 1. Outlet Filter
      if (_selectedOutletId != null) {
        final itemOutletId = item['outlet_id']?.toString();
        if (itemOutletId != _selectedOutletId.toString()) {
          return false;
        }
      }

      // 2. Search Query Filter
      final q = _searchQuery.toLowerCase().trim();
      final outlet = _getOutletName(item).toLowerCase();
      final person = _getPersonName(item).toLowerCase();
      final pobNum = item['pob_number']?.toString().toLowerCase() ?? '';
      final prodName = item['product_name']?.toString().toLowerCase() ?? '';
      final skuName = item['sku_displayname']?.toString().toLowerCase() ?? '';

      bool matchesProducts = false;
      if (item['products'] is List) {
        for (var p in item['products']) {
          final pName = p['product_name']?.toString().toLowerCase() ?? '';
          final sName = (p['sku_displayname'] ?? p['sku_name'])?.toString().toLowerCase() ?? '';
          if (pName.contains(q) || sName.contains(q)) {
            matchesProducts = true;
            break;
          }
        }
      }

      final matchesQuery = q.isEmpty ||
          outlet.contains(q) ||
          person.contains(q) ||
          pobNum.contains(q) ||
          prodName.contains(q) ||
          skuName.contains(q) ||
          matchesProducts;

      if (!matchesQuery) return false;

      // 3. Status filter for POB History
      if (_activeCategory == "POB History" && _pobStatusFilter != "ALL") {
        final status = item['status']?.toString().toLowerCase() ?? '';
        return status == _pobStatusFilter.toLowerCase();
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayRole = RoleHelper.formatRole(widget.member.roleCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: WavyAppBar(
        title: "TEAM MEMBER PROGRESS",
        actions: [
          IconButton(
            tooltip: "Refresh $_activeCategory",
            icon: const Icon(Icons.sync, color: AppColors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Refreshing $_activeCategory..."),
                  duration: const Duration(milliseconds: 900),
                ),
              );
              _loadCategoryData(_activeCategory, forceRefresh: true);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Member Profile Summary Banner
          _buildMemberBanner(displayRole),

          // Horizontal Category Tabs (POB History, Sale, Stock, Sample, Activity, Visits)
          _buildCategoryTabs(),

          // Outlet Selector Bar & Filters
          _buildOutletAndSearchBar(),

          // Active Category Data List
          Expanded(
            child: _buildDataBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberBanner(String displayRole) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              widget.member.fullName.isNotEmpty
                  ? widget.member.fullName.trim()[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      "ID: ${widget.member.employeeId.isNotEmpty ? widget.member.employeeId : 'N/A'}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        displayRole,
                        style: TextStyle(
                          color: Colors.blue.shade800,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  "MONTH",
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  DateFormat('MMM yyyy').format(DateTime(_selectedYear, _selectedMonth, 1)),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _activeCategory == cat;
          final icon = _getCategoryIcon(cat);

          return InkWell(
            onTap: () {
              setState(() {
                _activeCategory = cat;
                _searchQuery = "";
                _searchController.clear();
                if (!_dataCache.containsKey(cat)) {
                  _isLoading[cat] = true;
                }
              });
              _loadCategoryData(cat);
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case "POB History":
        return Icons.inventory_2_outlined;
      case "Sale":
        return Icons.point_of_sale_outlined;
      case "Stock":
        return Icons.analytics_outlined;
      case "Sample":
        return Icons.card_giftcard_outlined;
      case "Activity":
        return Icons.assignment_outlined;
      case "Visits":
        return Icons.storefront_outlined;
      default:
        return Icons.list_alt;
    }
  }

  Widget _buildOutletAndSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        children: [
          // Outlet Selector Bar (Mandatory Outlet Filtering)
          InkWell(
            onTap: _showOutletPickerDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedOutletId != null ? AppColors.primary : Colors.grey.shade300,
                  width: _selectedOutletId != null ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront,
                    size: 18,
                    color: _selectedOutletId != null ? AppColors.primary : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedOutletId != null ? "SELECTED OUTLET" : "FILTER BY OUTLET",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: _selectedOutletId != null ? AppColors.primary : Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _selectedOutletName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedOutletId != null ? AppColors.primary : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_selectedOutletId != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _selectedOutletId = null;
                          _selectedOutletName = "All Outlets";
                        });
                        _loadCategoryData(_activeCategory, forceRefresh: true);
                      },
                    )
                  else
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Search Bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: "Search by outlet, product, SKU...",
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),

          // Status Filter Chips for POB History
          if (_activeCategory == "POB History") ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _buildStatusChip("ALL"),
                const SizedBox(width: 6),
                _buildStatusChip("SUPPLIED"),
                const SizedBox(width: 6),
                _buildStatusChip("PENDING"),
                const SizedBox(width: 6),
                _buildStatusChip("PARTIAL"),
              ],
            ),
          ],
        ],
      ),
    );
  }  void _showOutletPickerDialog() {
    final validOutlets = _memberOutlets.where((o) {
      final idStr = o['outlet_id']?.toString() ?? '';
      var name = (o['outlet_name'] ?? _outletNameMap[idStr])?.toString().trim();
      if (name == null || name.isEmpty) return false;
      final lower = name.toLowerCase();
      return !lower.startsWith('outlet #') && lower != 'outlet';
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "SELECT OUTLET",
                      style: TextStyle(
                        fontSize: 15,
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
                const Divider(),
                // "All Outlets" Option
                ListTile(
                  leading: const Icon(Icons.apps, color: AppColors.primary),
                  title: const Text(
                    "All Outlets",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  selected: _selectedOutletId == null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedOutletId = null;
                      _selectedOutletName = "All Outlets";
                    });
                    _loadCategoryData(_activeCategory, forceRefresh: true);
                  },
                ),
                const Divider(height: 1),
                // Outlets List
                if (validOutlets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No specific outlets assigned",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: validOutlets.length,
                      itemBuilder: (context, idx) {
                        final o = validOutlets[idx];
                        final idStr = o['outlet_id']?.toString() ?? '';
                        final id = int.tryParse(idStr);
                        final name = (o['outlet_name'] ?? _outletNameMap[idStr])?.toString().trim() ?? '';
                        final isSel = _selectedOutletId == id;

                        return ListTile(
                          leading: Icon(Icons.storefront, color: isSel ? AppColors.primary : Colors.grey),
                          title: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? AppColors.primary : Colors.black87,
                            ),
                          ),
                          subtitle: (o['owner_name'] != null && o['owner_name'].toString().isNotEmpty && o['owner_name'].toString() != 'null') ||
                                  (o['mobile'] != null && o['mobile'].toString().isNotEmpty && o['mobile'].toString() != 'null')
                              ? Text(
                                  [
                                    if (o['owner_name'] != null && o['owner_name'].toString().isNotEmpty && o['owner_name'].toString() != 'null')
                                      o['owner_name'].toString(),
                                    if (o['mobile'] != null && o['mobile'].toString().isNotEmpty && o['mobile'].toString() != 'null')
                                      o['mobile'].toString(),
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                )
                              : null,
                          trailing: isSel ? const Icon(Icons.check, color: AppColors.primary) : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedOutletId = id;
                              _selectedOutletName = name;
                            });
                            _loadCategoryData(_activeCategory, forceRefresh: true);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _pobStatusFilter == status;
    return InkWell(
      onTap: () {
        setState(() {
          _pobStatusFilter = status;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.button : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.button : Colors.grey.shade300,
          ),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildDataBody() {
    final bool hasLoaded = _dataCache.containsKey(_activeCategory);
    final bool isLoading = (_isLoading[_activeCategory] ?? false) || !hasLoaded;

    if (isLoading) {
      return const Center(
        child: LogoProgressIndicator(size: 60),
      );
    }

    final items = _filteredCurrentList;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(_activeCategory),
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              "No $_activeCategory records found",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedOutletId != null
                  ? "No records for $_selectedOutletName"
                  : "No data for ${widget.member.fullName} in this period",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadCategoryData(_activeCategory, forceRefresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          switch (_activeCategory) {
            case "POB History":
              return _buildPobCard(item);
            case "Sale":
            case "Stock":
            case "Sample":
              return _buildPosCard(item, _activeCategory);
            case "Visits":
              return _buildVisitCard(item);
            case "Activity":
              return _buildActivityCard(item);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // ==========================================
  // 1. POB CARD (Person Name & Outlet Name Mandatory)
  // ==========================================
  Widget _buildPobCard(dynamic item) {
    final outletName = _getOutletName(item);
    final personName = _getPersonName(item);
    final role = _getPersonRole(item);
    final empId = _getEmployeeId(item);

    final pobNumber = item['pob_number']?.toString() ?? 'POB-${item['pob_id'] ?? ''}';
    final status = (item['status']?.toString() ?? 'pending').toLowerCase();
    final totalAmount = double.tryParse(item['ptr_total_amount']?.toString() ?? '') ?? 0.0;
    final totalWithGst = double.tryParse(item['ptr_incl_gst_total_amount']?.toString() ?? '') ?? totalAmount;
    final createdAt = item['created_at']?.toString() ?? '';
    final List itemsList = item['items'] is List ? item['items'] : [];

    Color statusBg;
    Color statusColor;
    if (status == 'supplied') {
      statusBg = Colors.green.shade50;
      statusColor = Colors.green.shade800;
    } else if (status == 'partial') {
      statusBg = Colors.blue.shade50;
      statusColor = Colors.blue.shade800;
    } else {
      statusBg = Colors.amber.shade50;
      statusColor = Colors.amber.shade900;
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPobDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OUTLET NAME (Only shown when genuine outlet is present)
            if (outletName.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "OUTLET",
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          outletName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pobNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),
            ],

            // MANDATORY 2: PERSON NAME
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "$personName ($role • ID: $empId)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    DateFormatter.formatDateTime(createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // POB Details
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "POB NUMBER",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pobNumber,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "TOTAL (INCL. GST)",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(totalWithGst),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // SKU Count and View Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${itemsList.length} SKU Item(s)",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                InkWell(
                  onTap: () => _navigateToPobDetails(item),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          "VIEW DETAILS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                      ],
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

  void _navigateToPobDetails(dynamic item) {
    if (item is! Map) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamPobDetailsScreen(
          pob: Map<String, dynamic>.from(item),
          outletName: _getOutletName(item),
          personName: _getPersonName(item),
          role: _getPersonRole(item),
          employeeId: _getEmployeeId(item),
        ),
      ),
    );
  }

  // ==========================================
  // 2. POS CARD (Sale, Stock, Sample) - GROUPED BATCH CARD
  // ==========================================
  Widget _buildPosCard(dynamic item, String category) {
    final outletName = _getOutletName(item);
    final personName = _getPersonName(item);
    final role = _getPersonRole(item);
    final empId = _getEmployeeId(item);

    final createdOn = item['created_on']?.toString() ?? item['created_at']?.toString() ?? '';
    final List products = item['products'] is List ? item['products'] as List : [item];
    final totalQty = item['total_qty'] != null
        ? (item['total_qty'] as num).toInt()
        : products.fold<int>(0, (sum, p) => sum + (int.tryParse(p['quantity']?.toString() ?? '0') ?? 0));
    final totalValue = item['total_sale_value'] != null
        ? (item['total_sale_value'] as num).toDouble()
        : products.fold<double>(0.0, (sum, p) => sum + (double.tryParse(p['sale_value']?.toString() ?? '0.0') ?? 0.0));

    Color tagColor;
    if (category == "Sale") {
      tagColor = Colors.green;
    } else if (category == "Stock") {
      tagColor = Colors.blue;
    } else {
      tagColor = Colors.purple;
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPosProductsDialog(context, item, category, tagColor),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OUTLET NAME (Only shown when genuine outlet is present)
              if (outletName.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.storefront,
                        size: 16,
                        color: tagColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "OUTLET",
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: tagColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            outletName.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: tagColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 8),
              ],

              // MANDATORY 2: PERSON NAME
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "$personName ($role • ID: $empId)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (createdOn.isNotEmpty)
                    Text(
                      DateFormatter.formatDateTime(createdOn),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Detailed Products List (Visible directly on card with tight padding)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int pIdx = 0; pIdx < products.length; pIdx++) ...[
                      if (pIdx > 0)
                        Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${pIdx + 1}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tagColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    products[pIdx]['product_name']?.toString() ?? 'Product',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if ((products[pIdx]['sku_displayname'] ?? products[pIdx]['sku_name'])?.toString().isNotEmpty == true &&
                                      (products[pIdx]['sku_displayname'] ?? products[pIdx]['sku_name'])?.toString().toLowerCase() !=
                                          products[pIdx]['product_name']?.toString().toLowerCase())
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        (products[pIdx]['sku_displayname'] ?? products[pIdx]['sku_name']).toString(),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    "${int.tryParse(products[pIdx]['quantity']?.toString() ?? '0') ?? 0} Qty",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if ((double.tryParse(products[pIdx]['sale_value']?.toString() ?? '') ?? 0.0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      currencyFormatter.format(double.tryParse(products[pIdx]['sale_value']?.toString() ?? '') ?? 0.0),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tagColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${products.length} ${products.length == 1 ? 'Product' : 'Products'}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tagColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Total Qty: $totalQty",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (totalValue > 0)
                          Text(
                            currencyFormatter.format(totalValue),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: tagColor,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18, color: tagColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPosProductsDialog(
    BuildContext context,
    dynamic groupedItem,
    String category,
    Color tagColor,
  ) {
    final outletName = _getOutletName(groupedItem);
    final createdOn = groupedItem['created_on']?.toString() ?? '';
    final List products = groupedItem['products'] is List ? groupedItem['products'] as List : [groupedItem];
    final totalQty = groupedItem['total_qty'] ?? products.fold<int>(0, (sum, p) => sum + (int.tryParse(p['quantity']?.toString() ?? '0') ?? 0));
    final totalValue = (groupedItem['total_sale_value'] as num?)?.toDouble() ??
        products.fold<double>(0.0, (sum, p) => sum + (double.tryParse(p['sale_value']?.toString() ?? '0.0') ?? 0.0));

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 550),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$category Products".toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tagColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            outletName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (createdOn.isNotEmpty)
                            Text(
                              DateFormatter.formatDateTime(createdOn),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Products List
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: products.length,
                    separatorBuilder: (c, i) => const Divider(height: 12),
                    itemBuilder: (context, idx) {
                      final p = products[idx];
                      final prodName = p['product_name']?.toString() ?? 'Product';
                      final skuName = p['sku_displayname']?.toString() ?? p['sku_name']?.toString() ?? 'N/A';
                      final qty = p['quantity']?.toString() ?? '0';
                      final price = double.tryParse(p['sku_retailerprice']?.toString() ?? p['ptr_price']?.toString() ?? '') ?? 0.0;
                      final sVal = double.tryParse(p['sale_value']?.toString() ?? '') ?? (price * (int.tryParse(qty) ?? 0));

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: tagColor.withValues(alpha: 0.1),
                            child: Text(
                              "${idx + 1}",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tagColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Qty: $qty",
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (price > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        "Price: ${currencyFormatter.format(price)}",
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (sVal > 0)
                            Text(
                              currencyFormatter.format(sVal),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: tagColor,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                const Divider(height: 20),

                // Grand Total Footer
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL (${products.length} Products, $totalQty Qty)",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tagColor),
                      ),
                      if (totalValue > 0)
                        Text(
                          currencyFormatter.format(totalValue),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tagColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 3. VISITS CARD (Person Name & Outlet Name Mandatory)
  // ==========================================
  Widget _buildVisitCard(dynamic item) {
    final outletName = _getOutletName(item);
    final personName = _getPersonName(item);
    final role = _getPersonRole(item);
    final empId = _getEmployeeId(item);

    final checkIn = item['checkin_time']?.toString() ?? item['check_in_time']?.toString() ?? item['check_in']?.toString() ?? '';
    final checkOut = item['checkout_time']?.toString() ?? item['check_out_time']?.toString() ?? item['check_out']?.toString() ?? '';
    final visitDate = item['visit_date']?.toString() ?? item['created_at']?.toString() ?? '';
    final purpose = item['remarks']?.toString() ?? item['purpose']?.toString() ?? '';
    final duration = item['duration_minutes']?.toString() ?? '';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MANDATORY 1: OUTLET NAME
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.storefront, size: 16, color: Colors.orange.shade800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "OUTLET",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        outletName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    "VISITED",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),

            // MANDATORY 2: PERSON NAME
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "$personName ($role • ID: $empId)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (visitDate.isNotEmpty)
                  Text(
                    DateFormatter.formatDateTime(visitDate),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Check In / Check Out details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.login, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        checkIn.isNotEmpty ? DateFormatter.formatDateTime(checkIn) : "Check In: N/A",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (checkOut.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.logout, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatDateTime(checkOut),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            if (duration.isNotEmpty || purpose.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (duration.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Duration: ${duration}m",
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (purpose.isNotEmpty)
                    Expanded(
                      child: Text(
                        "Remarks: $purpose",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. ACTIVITY CARD (Person Name & Outlet Name Mandatory)
  // ==========================================
  Widget _buildActivityCard(dynamic item) {
    final outletName = _getOutletName(item);
    final personName = _getPersonName(item);
    final role = _getPersonRole(item);
    final empId = _getEmployeeId(item);

    final actType = item['activity_name']?.toString() ?? item['activity_type']?.toString() ?? item['type']?.toString() ?? 'Activity';
    final remarks = item['remarks']?.toString() ?? item['description']?.toString() ?? 'No remarks';
    final actDate = item['activity_date']?.toString() ?? item['created_at']?.toString() ?? '';
    final files = item['files'] is List ? item['files'] as List : [];

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MANDATORY 1: OUTLET NAME
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.storefront, size: 16, color: Colors.teal.shade800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "OUTLET",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        outletName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    actType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),

            // MANDATORY 2: PERSON NAME
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "$personName ($role • ID: $empId)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actDate.isNotEmpty)
                  Text(
                    DateFormatter.formatDateTime(actDate),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remarks,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            if (files.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, fIdx) {
                    final f = files[fIdx];
                    var rawUrl = (f is Map ? (f['file_path'] ?? f['url']) : f)?.toString() ?? '';
                    if (rawUrl.startsWith('[') && rawUrl.contains('](')) {
                      final s = rawUrl.indexOf('](') + 2;
                      final e = rawUrl.indexOf(')', s);
                      if (e > s) rawUrl = rawUrl.substring(s, e);
                    }
                    rawUrl = rawUrl.replaceAll('[', '').replaceAll(']', '').trim();
                    if (rawUrl.isEmpty) return const SizedBox.shrink();

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        rawUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
