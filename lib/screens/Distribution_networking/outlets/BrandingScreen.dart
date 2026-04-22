import 'package:flutter/material.dart';

class BrandingBody extends StatefulWidget {
  const BrandingBody({super.key});

  @override
  State<BrandingBody> createState() => _BrandingBodyState();
}

class _BrandingBodyState extends State<BrandingBody> {
  final items = [
    "Azilium",
    "Defend 99",
    "Menthopas",
    "Sparkel",
    "Spice Sip",
    "Taste Good",
    "Combo Pack",
    "B BOLD",
    "Ultra Division",
  ];
  Map<String, bool> shelfValues = {};
  Map<String, bool> outletValues = {};

  @override
  void initState() {
    super.initState();

    for (var item in items) {
      shelfValues[item] = false;
      outletValues[item] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ...items.map((e) => _brandingRow(e)).toList(),

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
            onPressed: () {
              print("Shelf: $shelfValues");
              print("Outlet: $outletValues");
            },
            child: const Text(
              "SUBMIT BRANDING",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandingRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          _checkWithLabel(
            "Shelf",
            shelfValues[text] ?? false,
                (val) {
              setState(() {
                shelfValues[text] = val!;
              });
            },
          ),

          const SizedBox(width: 20),

          _checkWithLabel(
            "Outlet",
            outletValues[text] ?? false,
                (val) {
              setState(() {
                outletValues[text] = val!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _checkWithLabel(
      String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            side: const BorderSide(color: Colors.green, width: 2),
            activeColor: Colors.green,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}