import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import 'ProductListScreen.dart';
import 'SuppliedProductListScreen.dart';

class PobHistoryScreen extends StatefulWidget {
  const PobHistoryScreen({super.key});

  @override
  State<PobHistoryScreen> createState() => _PobHistoryScreenState();
}

class _PobHistoryScreenState extends State<PobHistoryScreen> {
  int selectedTab = 0;

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
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductListScreen(),
              ),
            );
          },
          child: Container(
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
            child: const Text(
              "SUBMITTION ON 22-Apr-2026",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
  Widget _suppliedScreen() {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SuppliedProductListScreen(),
              ),
            );
          },
          child: Container(
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
            child: const Text(
              "SUBMITTION ON 22-Apr-2026",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}