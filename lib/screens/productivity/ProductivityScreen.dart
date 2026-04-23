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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          toolbarHeight: 60,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.white,
              child:  TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.black,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3.0,
                tabs: [
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
