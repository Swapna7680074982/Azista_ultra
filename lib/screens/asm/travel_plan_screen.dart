import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'asm_provider.dart';

class TravelPlanScreen extends StatelessWidget {
  const TravelPlanScreen({super.key});

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
          "Travel Plan",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Consumer<AsmProvider>(
        builder: (context, asmProvider, child) {
          return Column(
            children: [
              // Month Picker
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("May 2026", style: TextStyle(fontSize: 16)),
                    Icon(Icons.calendar_month, color: AppColors.primary),
                  ],
                ),
              ),

              // Plans List
              Expanded(
                child: asmProvider.travelPlans.isEmpty
                    ? const Center(child: Text("No travel plans for this month"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: asmProvider.travelPlans.length,
                        itemBuilder: (context, index) {
                          final plan = asmProvider.travelPlans[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(plan["area"] ?? ""),
                              subtitle: Text(plan["reason"] ?? ""),
                              trailing: Text(plan["date"] ?? ""),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTravelRequestDialog(context),
        backgroundColor: Colors.red.shade900,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTravelRequestDialog(BuildContext context) {
    final areaController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedDate = "Select Date";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Travel Request",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.cancel, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Date Picker Field
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = "${picked.day}-${picked.month}-${picked.year}";
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedDate, style: const TextStyle(color: Colors.black54)),
                                Icon(Icons.calendar_month, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Area Field
                        TextField(
                          controller: areaController,
                          decoration: InputDecoration(
                            labelText: "Area",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Reason Field
                        TextField(
                          controller: reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: "Reason for Travel",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (areaController.text.isNotEmpty && selectedDate != "Select Date") {
                                Provider.of<AsmProvider>(context, listen: false).addTravelRequest({
                                  "date": selectedDate,
                                  "area": areaController.text,
                                  "reason": reasonController.text,
                                });
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F8FB5), // Blue from image
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "SUBMIT",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
