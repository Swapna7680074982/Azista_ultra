import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'productivity_provider.dart';

class DailyTab extends StatefulWidget {
  const DailyTab({super.key});

  @override
  State<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: provider.selectedDailyCallType,
                icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                items: const [
                  DropdownMenuItem(
                    value: "Normal Calls",
                    child: Text("Normal Calls", style: TextStyle(fontSize: 16, color: Colors.black87)),
                  ),
                  DropdownMenuItem(
                    value: "Productive Calls",
                    child: Text("Productive Calls", style: TextStyle(fontSize: 16, color: Colors.black87)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.setDailyCallType(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: provider.dailyData.length,
              itemBuilder: (context, index) {
                final data = provider.dailyData[index];
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Outlet Name",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data["outletName"]!,
                          style: const TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Owner Name",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data["ownerName"]!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Phone Number",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data["phoneNumber"]!,
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
