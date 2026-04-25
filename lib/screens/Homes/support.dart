import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/call_service.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            "Support",
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconTheme: const IconThemeData(
            color: AppColors.white,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child:  TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: "TECH"),
                  Tab(text: "PRODUCT"),
                ],
              ),
            ),
          ),
        ),

        body: TabBarView(
          children: [

            ListView(
              children: [
                ListTile(
                  title: Text("Subani Shaik"),
                  subtitle: Text("IT Coordinator"),
                  trailing: Icon(Icons.call),
                  onTap: () {
                    CallService.makeCall("9876543210");
                  },
                ),
                Divider(),
                ListTile(
                  title: Text("Sai Ram Duggi"),
                  subtitle: Text("Developer"),
                  trailing: Icon(Icons.call),
                  onTap: () {
                    CallService.makeCall("9123456780");
                  },
                ),
              ],
            ),


            ListView(
              children: [
                ListTile(
                  title: Text("Product Team 1"),
                  subtitle: Text("Manager"),
                  trailing: Icon(Icons.call),
                  onTap: () {
                    CallService.makeCall("9012345678");
                  },
                ),
                Divider(),
                ListTile(
                  title: Text("Product Team 2"),
                  subtitle: Text("Executive"),
                  trailing: Icon(Icons.call),
                  onTap: () {
                    CallService.makeCall("9988776655");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}