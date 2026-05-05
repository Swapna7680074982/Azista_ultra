import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';

import 'package:provider/provider.dart';
import '../../../permissions/AppStateProvider.dart';
import 'outlet_activity_provider.dart';

class PobHistoryScreen extends StatefulWidget {
  final int outletId;
  const PobHistoryScreen({super.key, required this.outletId});

  @override
  State<PobHistoryScreen> createState() => _PobHistoryScreenState();
}

class _PobHistoryScreenState extends State<PobHistoryScreen> {
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedDistributorId != null) {
        Provider.of<OutletActivityProvider>(context, listen: false)
            .fetchPobHistory(widget.outletId, appState.selectedDistributorId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          "POB History",
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
        children: [
          _tabs(),
          const SizedBox(height: 6),
          Expanded(
            child: selectedTab == 0
                ? _pendingScreen()
                : _suppliedScreen(),
          ),
        ],
      ),
    );
  }
  Widget _tabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedTab = 0);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: selectedTab == 0 ? Colors.white : Colors.grey[300],
              child: Center(
                child: Text(
                  "POB Pendings",
                  style: TextStyle(
                    color: selectedTab == 0 ? AppColors.primary : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => selectedTab = 1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: selectedTab == 1 ? Colors.white : Colors.grey[300],
              child: Center(
                child: Text(
                  "POB Supplied",
                  style: TextStyle(
                    color: selectedTab == 1 ? AppColors.primary : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _pendingScreen() {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPobHistory) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.pendingPobs.isEmpty) {
          return const Center(child: Text("No pending POBs"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: provider.pendingPobs.length,
          itemBuilder: (context, index) {
            final pob = provider.pendingPobs[index];
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListScreen(pobData: pob),
                  ),
                );
                if (result == true) {
                  final appState = Provider.of<AppStateProvider>(context, listen: false);
                  if (appState.selectedDistributorId != null) {
                    Provider.of<OutletActivityProvider>(context, listen: false)
                        .fetchPobHistory(widget.outletId, appState.selectedDistributorId!);
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 3,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "POB NUMBER: ${pob['pob_number'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    //Text("Total Amount: \$${pob['total_amount'] ?? '0.00'}"),
                    Text("Date: ${pob['created_at'] ?? 'N/A'}"),
                    Text("Status: ${pob['status'] ?? 'N/A'}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _suppliedScreen() {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingPobHistory) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.suppliedPobs.isEmpty) {
          return const Center(child: Text("No supplied POBs"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: provider.suppliedPobs.length,
          itemBuilder: (context, index) {
            final pob = provider.suppliedPobs[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuppliedProductListScreen(pobData: pob),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 3,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "POB NUMBER: ${pob['pob_number'] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    //Text("Total Amount: \$${pob['total_amount'] ?? '0.00'}"),
                    Text("Date: ${pob['created_at'] ?? 'N/A'}"),
                    Text("Status: ${pob['status'] ?? 'N/A'}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}