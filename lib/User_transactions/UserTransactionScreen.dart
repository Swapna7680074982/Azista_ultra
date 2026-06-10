import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../utilities/wavy_app_bar.dart';
import '../screens/Homes/main_tab_provider.dart';
import 'SaleItem.dart';
import 'TransactionDetailsScreen.dart';
import '../services/api_services.dart';
import '../permissions/AppStateProvider.dart';

class UserTransactionScreen extends StatefulWidget {
  const UserTransactionScreen({super.key});

  @override
  State<UserTransactionScreen> createState() =>
      _UserTransactionScreenState();
}

class _UserTransactionScreenState extends State<UserTransactionScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  late Future<Map<String, Map<String, dynamic>>> _dataFuture;
  late MainTabProvider _tabProvider;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabProvider = Provider.of<MainTabProvider>(context, listen: false);
      _tabProvider.addListener(_onTabChanged);
    });
  }

  @override
  void dispose() {
    _tabProvider.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabProvider.currentIndex == 1) {
      _reload();
    }
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _dataFuture = _fetchData();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WavyAppBar(
        title: "USER TRANSACTIONS",
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _monthYearFilter(),

            Expanded(
              child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text("No Data Found"));
                  }
                  
                  final outletsMap = snapshot.data!;
                  final outlets = outletsMap.values.toList();
                  
                  if (outlets.isEmpty) {
                    return const Center(child: Text("No Data Found"));
                  }
                  
                  return ListView.builder(
                    itemCount: outlets.length,
                    itemBuilder: (context, index) {
                      final outlet = outlets[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailsScreen(outletId: int.tryParse(outlet['outlet_id']) ?? 0),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Text(
                                  "OUTLET NAME: ${outlet['outlet_name']}".toUpperCase(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _monthYearFilter() {
    final dateText = DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: GestureDetector(
        onTap: () => _selectMonth(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                dateText.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear, selectedMonth, 1),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedMonth = picked.month;
        selectedYear = picked.year;
        _dataFuture = _fetchData(); // reload when date changes
      });
    }
  }

  Widget tabItem(String title, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.red : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _fetchData() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final distributorId = appState.selectedDistributorId ?? 6;
    final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;
    Map<String, dynamic> payload = {
      "distributor_id": distributorId,
      "from_date": "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-01",
      "to_date": "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}",
    };

    final results = await Future.wait([
      ApiServices.getPobHistory(payload: payload),
      ApiServices.getPosHistory(payload: {...payload, "pos_type": "sale"}),
      ApiServices.getPosHistory(payload: {...payload, "pos_type": "stock"}),
      ApiServices.getUserOutlets(),
    ]);
    
    final pobRes = results[0];
    final saleRes = results[1];
    final stockRes = results[2];
    final outletsResponse = results[3];

    debugPrint("--- DEBUG USER TRANSACTIONS ---");
    debugPrint("POB HISTORY RESPONSE: $pobRes");
    debugPrint("SALE HISTORY RESPONSE: $saleRes");
    debugPrint("STOCK HISTORY RESPONSE: $stockRes");

    final Map<String, String> nameLookup = {};
    if (outletsResponse != null && outletsResponse['status'] == true) {
      final list = outletsResponse['data'] as List<dynamic>? ?? [];
      for (var o in list) {
        final id = o['outlet_id']?.toString();
        final name = o['outlet_name']?.toString() ?? o['name']?.toString();
        if (id != null && name != null) {
          nameLookup[id] = name;
        }
      }
    }

    final Map<String, Map<String, dynamic>> outletsMap = {};
    
    if (pobRes != null && pobRes['status'] == 'success') {
      final data = (pobRes['data'] as List<dynamic>? ?? []).where((item) {
        final rawDate = item['created_at'] ?? item['created_on'];
        if (rawDate == null) return false;
        try {
          final date = DateTime.parse(rawDate.toString().trim());
          return date.year == selectedYear && date.month == selectedMonth;
        } catch (e) {
          return true;
        }
      }).toList();
      for (var item in data) {
        final outletId = item['outlet_id']?.toString() ?? "0";
        final outletName = item['outlet_name'] ?? nameLookup[outletId] ?? 'Unknown';
        if (!outletsMap.containsKey(outletId)) {
          outletsMap[outletId] = {'outlet_id': outletId, 'outlet_name': outletName, 'pob_count': 0, 'sale_count': 0, 'stock_count': 0};
        }
        outletsMap[outletId]!['pob_count'] = (outletsMap[outletId]!['pob_count'] as int) + 1;
      }
    }

    if (saleRes != null && saleRes['status'] == 'success') {
      final data = (saleRes['data'] as List<dynamic>? ?? []).where((item) {
        final rawDate = item['created_on'] ?? item['created_at'];
        if (rawDate == null) return false;
        try {
          final date = DateTime.parse(rawDate.toString().trim());
          return date.year == selectedYear && date.month == selectedMonth;
        } catch (e) {
          return true;
        }
      }).toList();
      for (var item in data) {
        final outletId = item['outlet_id']?.toString() ?? "0";
        final outletName = item['outlet_name'] ?? nameLookup[outletId] ?? 'Unknown';
        if (!outletsMap.containsKey(outletId)) {
          outletsMap[outletId] = {'outlet_id': outletId, 'outlet_name': outletName, 'pob_count': 0, 'sale_count': 0, 'stock_count': 0};
        }
        outletsMap[outletId]!['sale_count'] = (outletsMap[outletId]!['sale_count'] as int) + 1;
      }
    }

    if (stockRes != null && stockRes['status'] == 'success') {
      final data = (stockRes['data'] as List<dynamic>? ?? []).where((item) {
        final rawDate = item['created_on'] ?? item['created_at'];
        if (rawDate == null) return false;
        try {
          final date = DateTime.parse(rawDate.toString().trim());
          return date.year == selectedYear && date.month == selectedMonth;
        } catch (e) {
          return true;
        }
      }).toList();
      for (var item in data) {
        final outletId = item['outlet_id']?.toString() ?? "0";
        final outletName = item['outlet_name'] ?? nameLookup[outletId] ?? 'Unknown';
        if (!outletsMap.containsKey(outletId)) {
          outletsMap[outletId] = {'outlet_id': outletId, 'outlet_name': outletName, 'pob_count': 0, 'sale_count': 0, 'stock_count': 0};
        }
        outletsMap[outletId]!['stock_count'] = (outletsMap[outletId]!['stock_count'] as int) + 1;
      }
    }

    return outletsMap;
  }
}