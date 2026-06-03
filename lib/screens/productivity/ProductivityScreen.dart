import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'DailyTab.dart';
import 'MonthlyTab.dart';

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "PRODUCTIVITY",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
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
          elevation: 0,
          toolbarHeight: 60,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.white,
              child:  TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF8C7B87),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3.0,
                tabs: const [
                  Tab(text: "Daily"),
                  Tab(text: "Monthly"),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            DailyTab(),
            MonthlyTab(),
          ],
        ),
      ),
    );
  }
}
