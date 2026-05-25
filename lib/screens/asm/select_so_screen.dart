import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'asm_provider.dart';
import 'daily_activities_screen.dart';

class SelectSoScreen extends StatelessWidget {
  const SelectSoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select SO",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          Switch(
            value: true,
            onChanged: (val) {},
            activeColor: Colors.white,
            activeTrackColor: Colors.red.shade900,
          ),
        ],
      ),
      body: Consumer<AmProvider>(
        builder: (context, amProvider, child) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: amProvider.allSoList.length,
            itemBuilder: (context, index) {
              final so = amProvider.allSoList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyActivitiesScreen(soName: so["name"]),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Name",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                so["name"],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Employee Id",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                so["id"],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_double_arrow_right,
                          color: Colors.red,
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
    );
  }
}
