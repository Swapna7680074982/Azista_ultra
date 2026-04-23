import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'outlet_activity_provider.dart';
import '../../../constants/app_colors.dart';

class SamplingBody extends StatelessWidget {
  const SamplingBody({super.key});

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
          margin: const EdgeInsets.symmetric(vertical: 10),
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
              "SUBMIT SAMPLING",
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
          ...items.map((item) => _inputRow(item)).toList(),
        ],
      ),
    );
  }
  Widget _inputRow(String text) {
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
          SizedBox(
            width: 60,
            height: 30,
            child: TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                print("Entered value: $value");
              },
            ),
          ),
        ],
      ),
    );
  }
}