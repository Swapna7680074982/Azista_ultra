import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
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
  DateTime? fromDate;
  DateTime? toDate;

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

  Future<void> pickDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
        _dataFuture = _fetchData(); // reload when date changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "USER TRANSACTIONS",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
              child: Text(
                "Distributor: ${(Provider.of<AppStateProvider>(context).selectedDistributor ?? 'Not Selected').toUpperCase()}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => pickDate(context, true),
                      child: dateBox(
                        fromDate != null
                            ? DateFormat('d MMM yyyy').format(fromDate!)
                            : "From Date",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => pickDate(context, false),
                      child: dateBox(
                        toDate != null
                            ? DateFormat('d MMM yyyy').format(toDate!)
                            : "To Date",
                      ),
                    ),
                  ),
                ],
              ),
            ),

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

  Widget dateBox(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 18),
          const SizedBox(width: 8),
          Text(date),
        ],
      ),
    );
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
    Map<String, dynamic> payload = {
      "distributor_id": distributorId,
    };
    if (fromDate != null) {
      payload["from_date"] = "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}";
    }
    if (toDate != null) {
      payload["to_date"] = "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";
    }

    final results = await Future.wait([
      ApiServices.getPobHistory(payload: payload),
      ApiServices.getPosHistory(payload: {...payload, "pos_type": "sale"}),
      ApiServices.getPosHistory(payload: {...payload, "pos_type": "stock"}),
    ]);
    
    final pobRes = results[0];
    final saleRes = results[1];
    final stockRes = results[2];

    final Map<String, Map<String, dynamic>> outletsMap = {};
    
    if (pobRes != null && pobRes['status'] == 'success') {
      final data = pobRes['data'] as List<dynamic>? ?? [];
      for (var item in data) {
        final outletId = item['outlet_id']?.toString() ?? "0";
        if (!outletsMap.containsKey(outletId)) {
          outletsMap[outletId] = {'outlet_id': outletId, 'outlet_name': item['outlet_name'] ?? 'Unknown', 'pob_count': 0, 'sale_count': 0, 'stock_count': 0};
        }
        outletsMap[outletId]!['pob_count'] = (outletsMap[outletId]!['pob_count'] as int) + 1;
      }
    }

    if (saleRes != null && saleRes['status'] == 'success') {
      final data = saleRes['data'] as List<dynamic>? ?? [];
      for (var item in data) {
        final outletId = item['outlet_id']?.toString() ?? "0";
        if (!outletsMap.containsKey(outletId)) {
          outletsMap[outletId] = {'outlet_id': outletId, 'outlet_name': item['outlet_name'] ?? 'Unknown', 'pob_count': 0, 'sale_count': 0, 'stock_count': 0};
        }
        outletsMap[outletId]!['sale_count'] = (outletsMap[outletId]!['sale_count'] as int) + 1;
      }
    }

    if (stockRes != null && stockRes['status'] == 'success') {
      final data = stockRes['data'] as List<dynamic>? ?? [];
      for (var item in data) {
        final outletId = item['outlet_id']?.toString() ?? "0";
        if (!outletsMap.containsKey(outletId)) {
          outletsMap[outletId] = {'outlet_id': outletId, 'outlet_name': item['outlet_name'] ?? 'Unknown', 'pob_count': 0, 'sale_count': 0, 'stock_count': 0};
        }
        outletsMap[outletId]!['stock_count'] = (outletsMap[outletId]!['stock_count'] as int) + 1;
      }
    }

    return outletsMap;
  }
}