import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'asm_provider.dart';

class SoAttendanceScreen extends StatelessWidget {
  const SoAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AmProvider>(
      builder: (context, amProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "SO Attendance",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download, color: Colors.white),
                onPressed: () {
                  // Download logic
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Date Pickers
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        context,
                        DateFormat('MMM dd, yyyy').format(amProvider.fromDate),
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: amProvider.fromDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            amProvider.updateDateRange(picked, amProvider.toDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        context,
                        DateFormat('MMM dd, yyyy').format(amProvider.toDate),
                        () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: amProvider.toDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            amProvider.updateDateRange(amProvider.fromDate, picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  onChanged: (val) => amProvider.updateSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: "Search by Employee Id or Name",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    suffixIcon: const Icon(Icons.search, color: Colors.red),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),

              if (amProvider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: amProvider.filteredSoList.length,
                    itemBuilder: (context, index) {
                      final so = amProvider.filteredSoList[index];
                      return ExpansionTile(
                        shape: const Border(),
                        leading: const Icon(Icons.arrow_right, color: Colors.grey),
                        title: Text(
                          "${so["id"]} - ${so["name"]}(${so["role"]})",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        children: [
                          if (so["logs"].isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("No logs found for this range"),
                            )
                          else
                            ...so["logs"].map<Widget>((log) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log["date"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildTimeRow("In", log["in"]),
                                        _buildTimeRow("Out", log["out"]),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStatusRow("Status", log["status"]),
                                        _buildStatusRow("Net Hours", log["netHours"]),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
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

  Widget _buildDatePicker(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const Icon(Icons.calendar_month, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Row(
      children: [
        Text("$label : ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      children: [
        Text("$label : ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: value == "PRESENT" ? Colors.black : (value == "ABSENT" ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }
}
