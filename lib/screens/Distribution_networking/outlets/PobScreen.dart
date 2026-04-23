import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../constants/app_colors.dart';
import 'PobHistoryScreen.dart';

class PobBody extends StatelessWidget {
  const PobBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OutletActivityProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ...provider.sectionsData.entries.map((entry) {
              return _section(entry.key, entry.value);
            }).toList(),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () {},
            child: const Text(
              "SUBMIT POB",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PobHistoryScreen(),
                ),
              );
            },
            child: const Text(
              "POS HISTORY",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
          ],
        );
      },
    );
  }
  Widget _section(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...items.map((item) => _pobRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _pobRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),

          _box(),

          const SizedBox(width: 10),
          _box(red: true),
        ],
      ),
    );
  }
  Widget _box({bool red = false}) {
    if (red) {
      return SizedBox(
        width: 55,
        height: 30,
        child: TextField(
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderSide:  BorderSide(color: AppColors.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide:  BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:  BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onSubmitted: (value) {
            print("Entered red box value: $value");
          },
        ),
      );
    }
    return Container(
      width: 55,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: const Text(
        "0",
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}