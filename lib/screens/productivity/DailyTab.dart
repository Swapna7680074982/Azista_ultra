import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'productivity_provider.dart';
import '../../permissions/AppStateProvider.dart';

class DailyTab extends StatefulWidget {
  const DailyTab({super.key});

  @override
  State<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<DailyTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      Provider.of<ProductivityProvider>(context, listen: false).fetchCallsInfo(
        date: dateStr,
        distributorId: appState.selectedDistributorId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductivityProvider>(
      builder: (context, provider, child) {
        return provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
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
                        child: Text("Target Calls", style: TextStyle(fontSize: 16, color: Colors.black87)),
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
                child: provider.dailyData.isEmpty
                    ? const Center(child: Text("No call data available"))
                    : ListView.builder(
                  itemCount: provider.dailyData.length,
                  itemBuilder: (context, index) {
                    final data = provider.dailyData[index];

                    // Filter based on dropdown
                    if (provider.selectedDailyCallType == "Productive Calls" &&
                        data["productiveCall"] == "0") {
                      return const SizedBox.shrink();
                    }

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
                              "OUTLET NAME",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data["outletName"]!.toString().toUpperCase(),
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
                                      provider.selectedDailyCallType == "Normal Calls" 
                                          ? "TARGET CALLS" 
                                          : "PRODUCTIVE CALLS",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      provider.selectedDailyCallType == "Normal Calls"
                                          ? data["targetCall"]!
                                          : data["productiveCall"]!,
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "SALE VALUE",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "₹${data["saleValue"]}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
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
