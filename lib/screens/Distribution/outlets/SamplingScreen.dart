import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class SamplingBody extends StatelessWidget {
  const SamplingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _section(
          "Kwik Mint",
          [
            "Burst (Boxes)",
            "1X 44'S (1X 2'S) (Boxes)",
            "BURST'S CASSETS(10 X 20S) (Pcs)",
            "PREMIUM STRONG CASSET 20",
            "KWIK MINT STRONG CASSETS(10 X 20'S)",
            "KWIK MINT BURST",
          ],
        ),
        _section(
          "Menthopas",
          ["3 PATCHES POUCHES (Pcs)"],
        ),
        _section(
          "Sparkel",
          [
            "FACIAL MASK (Pcs)",
            "GLOW FACIAL MASK (Pcs)",
            "YOUTH FACIAL MASK (Pcs)",
          ],
        ),
        _section(
          "Spice Sip",
          ["(1X6) (Boxes)"],
        ),
        _section(
          "Taste Good",
          [
            "PREGAEND KIT ULTRA",
            "PREGAF LASH KIT ULTRA",
          ],
        ),
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