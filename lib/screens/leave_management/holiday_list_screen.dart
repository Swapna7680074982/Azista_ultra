import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import 'leave_provider.dart';

class HolidayListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday List'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Occassion', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<LeaveProvider>(
              builder: (context, provider, child) {
                return ListView.separated(
                  itemCount: provider.holidays.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                  itemBuilder: (context, index) {
                    final holiday = provider.holidays[index];
                    DateTime holidayDate =
                    DateFormat("dd-MMM-yyyy").parse(holiday.date);
                    bool isFuture = holidayDate.isAfter(DateTime.now());

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              holiday.date,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: isFuture ? AppColors.primary : Colors.black,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              holiday.occasion,
                              style: TextStyle(
                                fontSize: 13,
                                color: isFuture ? AppColors.primary : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
