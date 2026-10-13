import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/team_progress_model.dart';
import '../../services/api_services.dart';
import '../../utilities/common_widgets.dart';
import '../../utilities/date_formatter.dart';
import '../../utilities/mylogger.dart';
import '../../utilities/role_helper.dart';
import '../../utilities/wavy_app_bar.dart';
import 'team_progress_provider.dart';
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
    // 1. MUST load outlets first so candidate outlets exist
    await _loadMemberOutlets();
    // 2. Then load active category data
    await _loadCategoryData(_activeCategory);
  }

  Future<void> _loadMemberOutlets({bool force = false}) async {
    if (_outletsLoaded && !force && _memberOutlets.isNotEmpty) return;
    try {

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
            final existingIdx = _memberOutlets.indexWhere((existing) => existing['outlet_id']?.toString() == id);
            final assignedName = (o['assigned_user_name'] ?? o['assigned_name'] ?? o['assigned_to'])?.toString().trim() ?? '';
            final createdByName = (o['created_by_name'] ?? o['created_by_user_name'] ?? o['creator_name'] ?? o['employee_name'])?.toString().trim() ?? '';
            final personName = createdByName.isNotEmpty
                ? createdByName
                : (assignedName.isNotEmpty ? assignedName : widget.member.fullName);

            final outletData = {
              'outlet_id': id,
              'outlet_name': cleanName,
              'owner_name': o['owner_name'] ?? o['owner'] ?? '',
              'mobile': o['mobile'] ?? o['phone'] ?? '',
              'address': o['address'] ?? '',
              'route_id': o['route_id'],
              'route_code': o['route_code'],
              'assigned_user_id': o['assigned_user_id'] ?? o['created_by'],
              'assigned_user_name': assignedName,
              'created_by_name': createdByName.isNotEmpty ? createdByName : personName,
              'person_name': personName,
              'total_visits': o['total_visits'] ?? 0,
              'total_activities': o['total_activities'] ?? 0,
              'total_pobs': o['total_pobs'] ?? 0,
              'sale_value': o['sale_value'] ?? 0,
            };
            if (existingIdx >= 0) {
              _memberOutlets[existingIdx] = outletData;
            } else {
              _memberOutlets.add(outletData);
            }
          }
        }
      }

      if (force) {
        _memberOutlets.clear();
        _outletNameMap.clear();
      }

      // 1. Query team_member_outlets for team members
      final List<int> userIdsToLoad = [];
      final memberUid = int.tryParse(widget.member.userId);
      if (memberUid != null && memberUid > 0) {
        userIdsToLoad.add(memberUid);
      }

      try {
        final teamProvider = Provider.of<TeamProgressProvider>(context, listen: false);
        for (var m in teamProvider.members) {
          final uid = int.tryParse(m.userId);
          if (uid != null && uid > 0 && !userIdsToLoad.contains(uid)) {
            userIdsToLoad.add(uid);
          }
        }
      } catch (_) {}

      for (var uId in userIdsToLoad) {
        try {
          final memberOutletsRes = await ApiServices.getTeamMemberOutlets(
            userId: uId,
            month: _selectedMonth,
            year: _selectedYear,
          );
          if (memberOutletsRes != null && memberOutletsRes['data'] is List) {
            parseAndStoreOutlets(memberOutletsRes['data']);
          }
        } catch (e) {
          AppLogger.error("getTeamMemberOutlets error for $uId", e);
        }
      }

      _outletsLoaded = true;
      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.error("_loadMemberOutlets error", e);
    }
  }

  Future<void> _loadCategoryData(String category, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _dataCache.clear();
      await _loadMemberOutlets(force: true);
    } else if (_dataCache.containsKey(category)) {
      return;
    }

    setState(() {
      _isLoading[category] = true;
    });

    try {
      if (!_outletsLoaded || _memberOutlets.isEmpty) {
        await _loadMemberOutlets();
      }

      List<dynamic> items = [];

      switch (category) {
        case "POB History":
          final List<dynamic> pobsList = [];

          // 1. Primary: Query team POB history by month/year (and outlet if selected)
          try {
            final allTeamPobs = await ApiServices.getTeamPobHistory(
              outletId: _selectedOutletId,
              month: _selectedMonth,
              year: _selectedYear,
            );
            if (allTeamPobs.isNotEmpty) {
              for (var p in allTeamPobs) {
                if (p is Map) {
                  final pCopy = Map<String, dynamic>.from(p);
                  final oId = p['outlet_id']?.toString() ?? '';
                  final rawName = p['outlet_name']?.toString() ?? _outletNameMap[oId];
                  pCopy['outlet_name'] = (rawName != null && rawName.isNotEmpty && !rawName.toLowerCase().startsWith('outlet #'))
                      ? rawName
                      : 'Outlet';
                  pCopy['employee_name'] = p['employee_name'] ?? p['created_by_name'] ?? p['fullname'] ?? 'Team Member';
                  pCopy['employee_id'] = p['employee_id'] ?? p['created_by_employee_id'] ?? '';
                  pCopy['rolecode'] = p['rolecode'] ?? p['designation'] ?? p['created_by_role'] ?? p['created_by_designation'] ?? '';
                  pCopy['user_id'] = p['created_by'] ?? p['user_id'];
                  pCopy['pts_total_amount'] = p['pts_total_amount'] ?? p['sale_value'];
                  pCopy['sale_value'] = p['sale_value'] ?? p['pts_total_amount'];
                  pCopy['supplied_by_name'] = p['supplied_by_name'];
                  pCopy['supplied_at'] = p['supplied_at'];
                  pCopy['order_copy'] = (p['order_copy_url'] != null && p['order_copy_url'].toString().isNotEmpty && p['order_copy_url'] != 'null')
                      ? p['order_copy_url'].toString()
                      : (p['order_copy']?.toString() ?? '');
                  pobsList.add(pCopy);
                }
              }
            }
          } catch (e) {
            AppLogger.error("getTeamPobHistory general query error", e);
          }

          // 2. Query candidate outlets sequentially to prevent MySQL connection limits from failing
          final candidateOutlets = _selectedOutletId != null
              ? (_memberOutlets.any((o) => o['outlet_id']?.toString() == _selectedOutletId.toString())
                  ? _memberOutlets.where((o) => o['outlet_id']?.toString() == _selectedOutletId.toString()).toList()
                  : [{'outlet_id': _selectedOutletId, 'outlet_name': _outletNameMap[_selectedOutletId.toString()]}])
              : _memberOutlets;

          if (pobsList.isEmpty || _selectedOutletId != null) {
            for (var o in candidateOutlets) {
              final oId = int.tryParse(o['outlet_id']?.toString() ?? '');
              if (oId == null) continue;

              try {
                final teamPobs = await ApiServices.getTeamPobHistory(
                  outletId: oId,
                );
                for (var p in teamPobs) {
                  if (p is Map) {
                    final pId = (p['pob_id'] ?? p['id'] ?? p['pob_number'])?.toString();
                    if (pId != null && pobsList.any((existing) => (existing['pob_id'] ?? existing['id'] ?? existing['pob_number'])?.toString() == pId)) {
                      continue;
                    }
                    final pCopy = Map<String, dynamic>.from(p);
                    final rawName = o['outlet_name']?.toString() ?? p['outlet_name']?.toString() ?? _outletNameMap[oId.toString()];
                    pCopy['outlet_name'] = (rawName != null && rawName.isNotEmpty && !rawName.toLowerCase().startsWith('outlet #'))
                        ? rawName
                        : 'Outlet';
                    pCopy['outlet_id'] = oId;
                    pCopy['employee_name'] = p['employee_name'] ?? p['created_by_name'] ?? p['fullname'] ?? 'Team Member';
                    pCopy['employee_id'] = p['employee_id'] ?? p['created_by_employee_id'] ?? '';
                    pCopy['rolecode'] = p['rolecode'] ?? p['designation'] ?? p['created_by_role'] ?? p['created_by_designation'] ?? '';
                    pCopy['user_id'] = p['created_by'] ?? p['user_id'];
                    pCopy['pts_total_amount'] = p['pts_total_amount'] ?? p['sale_value'];
                    pCopy['sale_value'] = p['sale_value'] ?? p['pts_total_amount'];
                    pCopy['supplied_by_name'] = p['supplied_by_name'];
                    pCopy['supplied_at'] = p['supplied_at'];
                    pCopy['order_copy'] = (p['order_copy_url'] != null && p['order_copy_url'].toString().isNotEmpty && p['order_copy_url'] != 'null')
                        ? p['order_copy_url'].toString()
                        : (p['order_copy']?.toString() ?? '');
                    pobsList.add(pCopy);
                  }
                }
              } catch (e) {
                AppLogger.error("getTeamPobHistory sequential outlet query error for $oId", e);
              }
            }
          }

          _extractOutletIds(pobsList);
          AppLogger.printFull(
            "Whole Team POB History loaded (${pobsList.length} items): ${jsonEncode(pobsList)}",
            tag: "TEAM_POB_LOADED",
          );
          items = pobsList;
          break;

        case "Sale":
          final allSales = await ApiServices.getTeamPosHistory(
            posType: "sale",
            month: _selectedMonth,
            year: _selectedYear,
            outletId: _selectedOutletId,
          );
          _extractOutletIds(allSales);
          items = _groupPosItems(allSales);
          break;

        case "Stock":
          final allStock = await ApiServices.getTeamPosHistory(
            posType: "stock",
            month: _selectedMonth,
            year: _selectedYear,
            outletId: _selectedOutletId,
          );
          _extractOutletIds(allStock);
          items = _groupPosItems(allStock);
          break;

        case "Sample":
          final allSamples = await ApiServices.getTeamPosHistory(
            posType: "sampling",
            month: _selectedMonth,
            year: _selectedYear,
            outletId: _selectedOutletId,
          );
          _extractOutletIds(allSamples);
          items = _groupPosItems(allSamples);
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
              final actHist = await ApiServices.getOutletVisitActivityHistory(
                outletId: oId,
                month: _selectedMonth,
                year: _selectedYear,
              );

              final rawVisits = (actHist != null && actHist['visit_history'] is List)
                  ? actHist['visit_history'] as List
                  : ((actHist != null && actHist['data'] is List) ? actHist['data'] as List : []);

              for (var v in rawVisits) {
                if (v is Map) {
                  final vCopy = Map<String, dynamic>.from(v);
                  final oName = o['outlet_name'] ?? _outletNameMap[oId.toString()] ?? 'OUTLET';
                  vCopy['outlet_name'] = oName;
                  vCopy['outlet_id'] = oId;
                  vCopy['employee_name'] = v['visited_by_name'] ?? v['employee_name'] ?? widget.member.fullName;
                  vCopy['employee_id'] = v['visited_by_employee_id'] ?? v['employee_id'] ?? widget.member.employeeId;
                  vCopy['rolecode'] = v['visited_by_role'] ?? v['visited_by_designation'] ?? v['rolecode'] ?? widget.member.roleCode;
                  vCopy['mobile'] = v['visited_by_mobile'] ?? v['mobile'] ?? '';
                  visitsList.add(vCopy);
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
              final actHist = await ApiServices.getOutletVisitActivityHistory(
                outletId: oId,
                month: _selectedMonth,
                year: _selectedYear,
              );

              final rawVisits = (actHist != null && actHist['visit_history'] is List)
                  ? actHist['visit_history'] as List
                  : ((actHist != null && actHist['data'] is List) ? actHist['data'] as List : []);

              for (var v in rawVisits) {
                if (v is Map) {
                  final activities = v['activities'] ?? v['activity_history'];
                  if (activities is List) {
                    for (var a in activities) {
                      if (a is Map) {
                        final actCopy = Map<String, dynamic>.from(a);
                        final oName = o['outlet_name'] ?? _outletNameMap[oId.toString()] ?? 'OUTLET';
                        actCopy['outlet_name'] = oName;
                        actCopy['outlet_id'] = oId;
                        actCopy['employee_name'] = a['activity_by_name'] ?? v['visited_by_name'] ?? widget.member.fullName;
                        actCopy['employee_id'] = v['visited_by_employee_id'] ?? widget.member.employeeId;
                        actCopy['rolecode'] = v['visited_by_role'] ?? v['visited_by_designation'] ?? widget.member.roleCode;
                        actCopy['activity_name'] = a['activity_name'] ?? a['activity_type'] ?? 'Activity';
                        actCopy['activity_date'] = a['activity_date'] ?? v['visit_date'] ?? v['checkin_time'] ?? v['created_at'];
                        actCopy['remarks'] = (a['remarks'] != null && a['remarks'].toString().trim().isNotEmpty)
                            ? a['remarks']
                            : ((v['remarks'] != null && v['remarks'].toString().trim().isNotEmpty) ? v['remarks'] : '');
                        actCopy['files'] = a['files'] ?? [];
                        actCopy['product_id'] = a['product_id'] ?? a['productId'];
                        actCopy['sku_id'] = a['sku_id'] ?? a['skuId'];
                        actCopy['product_name'] = a['product_name'] ?? a['product'] ?? a['item_name'];
                        actCopy['sku_displayname'] = a['sku_displayname'] ?? a['sku_name'] ?? a['sku'];
                        actCopy['sku_name'] = a['sku_name'] ?? a['sku_displayname'] ?? a['sku'];
                        actCopy['quantity'] = a['quantity'] ?? a['qty'];
                        actCopy['products'] = a['products'] ?? a['items'] ?? a['skus'] ?? a['product_details'];
                        acts.add(actCopy);
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
            final cleanName = oName.trim();
            _outletNameMap[oId] = cleanName;
            if (!_memberOutlets.any((m) => m['outlet_id']?.toString() == oId)) {
              final createdByName = (it['employee_name'] ?? it['created_by_name'] ?? it['fullname'])?.toString().trim() ?? '';
              _memberOutlets.add({
                'outlet_id': oId,
                'outlet_name': cleanName,
                'owner_name': it['owner_name'] ?? '',
                'mobile': it['outlet_mobile'] ?? it['mobile'] ?? '',
                'address': it['outlet_address'] ?? it['address'] ?? '',
                'created_by_name': createdByName,
                'person_name': createdByName,
              });
            }
          }
        }
      }
    }
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
      final name = item['created_by_name'] ??
          item['visited_by_name'] ??
          item['activity_by_name'] ??
          item['employee_name'] ??
          item['fullname'] ??
          item['user_name'];
      if (name != null && name.toString().isNotEmpty && name.toString() != 'null') {
        return name.toString();
      }
    }
    return widget.member.fullName;
  }

  String _getPersonRole(dynamic item) {
    if (item is Map) {
      final r = item['created_by_role'] ??
          item['created_by_designation'] ??
          item['visited_by_role'] ??
          item['visited_by_designation'] ??
          item['rolecode'] ??
          item['role'];
      if (r != null && r.toString().isNotEmpty && r.toString() != 'null') {
        return RoleHelper.formatRole(r.toString());
      }
    }
    return RoleHelper.formatRole(widget.member.roleCode);
  }

  String _getEmployeeId(dynamic item) {
    if (item is Map) {
      final id = item['created_by_employee_id'] ??
          item['visited_by_employee_id'] ??
          item['employee_id'];
      if (id != null && id.toString().isNotEmpty && id.toString() != 'null') {
        return id.toString();
      }
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

      // 2. Search Query Filter - ONLY person name and outlet name
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        final outlet = _getOutletName(item).toLowerCase();
        final person = _getPersonName(item).toLowerCase();
        if (!outlet.contains(q) && !person.contains(q)) {
          return false;
        }
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
                        if (_selectedOutletId != null) ...[
                          () {
                            final sel = _memberOutlets.firstWhere(
                              (m) => m['outlet_id']?.toString() == _selectedOutletId.toString(),
                              orElse: () => {},
                            );
                            String pName = '';
                            for (final key in [
                              'created_by_name',
                              'created_by_user_name',
                              'creator_name',
                              'assigned_user_name',
                              'assigned_name',
                              'assigned_to',
                              'person_name',
                            ]) {
                              final val = sel[key]?.toString().trim() ?? '';
                              if (val.isNotEmpty && val != 'null') {
                                pName = val;
                                break;
                              }
                            }
                            if (pName.isEmpty) {
                              pName = widget.member.fullName;
                            }

                            if (pName.isNotEmpty && pName != 'null') {
                              return Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  "Created by: $pName",
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }(),
                        ],
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
                hintText: "Search by person or outlet name...",
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

                        String personName = '';
                        for (final key in [
                          'created_by_name',
                          'created_by_user_name',
                          'creator_name',
                          'assigned_user_name',
                          'assigned_name',
                          'assigned_to',
                          'person_name',
                          'employee_name',
                        ]) {
                          final val = o[key]?.toString().trim() ?? '';
                          if (val.isNotEmpty && val != 'null') {
                            personName = val;
                            break;
                          }
                        }
                        if (personName.isEmpty) {
                          personName = widget.member.fullName;
                        }
                        final ownerName = (o['owner_name'] ?? '')?.toString().trim() ?? '';
                        final mobile = (o['mobile'] ?? '')?.toString().trim() ?? '';

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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((ownerName.isNotEmpty && ownerName != 'null') || (mobile.isNotEmpty && mobile != 'null'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    [
                                      if (ownerName.isNotEmpty && ownerName != 'null') ownerName,
                                      if (mobile.isNotEmpty && mobile != 'null') mobile,
                                    ].join(' • '),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ),
                              if (personName.isNotEmpty && personName != 'null')
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "Created by: $personName",
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
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
    final totalAmount = double.tryParse(item['pts_total_amount']?.toString() ?? item['ptr_total_amount']?.toString() ?? item['sale_value']?.toString() ?? '') ?? 0.0;
    final totalWithGst = double.tryParse(item['ptr_incl_gst_total_amount']?.toString() ?? item['sale_value']?.toString() ?? item['pts_total_amount']?.toString() ?? '') ?? totalAmount;
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

    // Extract products & SKUs
    final List<Map<String, dynamic>> activityProducts = [];
    final rawProductsList = item['products'] ?? item['items'] ?? item['skus'] ?? item['product_details'];

    if (rawProductsList is List && rawProductsList.isNotEmpty) {
      for (var p in rawProductsList) {
        if (p is Map) {
          final pName = (p['product_name'] ?? p['name'] ?? p['product'])?.toString() ?? 'Product';
          final sName = (p['sku_displayname'] ?? p['sku_name'] ?? p['sku'])?.toString() ?? '';
          final q = (p['quantity'] ?? p['qty'])?.toString();
          activityProducts.add({
            'product_name': pName,
            'sku_name': sName,
            'quantity': q,
          });
        }
      }
    } else {
      final pName = (item['product_name'] ?? item['product'] ?? item['item_name'])?.toString();
      final sName = (item['sku_displayname'] ?? item['sku_name'] ?? item['sku'])?.toString();
      final q = (item['quantity'] ?? item['qty'])?.toString();

      if ((pName != null && pName.trim().isNotEmpty && pName.trim() != 'null') ||
          (sName != null && sName.trim().isNotEmpty && sName.trim() != 'null')) {
        activityProducts.add({
          'product_name': (pName != null && pName.trim().isNotEmpty && pName.trim() != 'null') ? pName.trim() : 'Product',
          'sku_name': (sName != null && sName.trim().isNotEmpty && sName.trim() != 'null') ? sName.trim() : '',
          'quantity': (q != null && q.trim().isNotEmpty && q.trim() != 'null' && q.trim() != '0') ? q.trim() : null,
        });
      }
    }

    final bool isDefaultVisitRemark = remarks.trim().isEmpty ||
        remarks.trim() == 'No remarks' ||
        remarks.toLowerCase().contains('individual visit');

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

            // PRODUCT & SKU SECTION
            if (activityProducts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.blue.shade800),
                        const SizedBox(width: 6),
                        Text(
                          "PRODUCTS & SKU (${activityProducts.length})",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...activityProducts.map((p) {
                      final pName = p['product_name'] ?? 'Product';
                      final sName = p['sku_name'] ?? '';
                      final q = p['quantity'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pName.toString().toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (sName.toString().isNotEmpty && sName.toString().toLowerCase() != pName.toString().toLowerCase())
                                    Text(
                                      sName.toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (q != null && q.toString().isNotEmpty && q.toString() != '0')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  "$q Qty",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Remarks Container (hidden if default "Individual Visit" remarks)
            if (!isDefaultVisitRemark) ...[
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
            ],

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
