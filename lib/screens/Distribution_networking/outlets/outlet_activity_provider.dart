import 'package:flutter/material.dart';

class OutletActivityProvider extends ChangeNotifier {
  final Map<String, List<String>> _sectionsData = {
    "Kwik Mint": [
      "Burst (Boxes)",
      "1X 44'S (1X 2'S) (Boxes)",
      "BURST'S CASSETS(10 X 20S) (Pcs)",
      "PREMIUM STRONG CASSET 20",
      "KWIK MINT STRONG CASSETS(10 X 20'S)",
      "KWIK MINT BURST",
    ],
    "Menthopas": ["3 PATCHES POUCHES (Pcs)"],
    "Sparkel": [
      "FACIAL MASK (Pcs)",
      "GLOW FACIAL MASK (Pcs)",
      "YOUTH FACIAL MASK (Pcs)",
    ],
    "Spice Sip": ["(1X6) (Boxes)"],
    "Taste Good": [
      "PREGAEND KIT ULTRA",
      "PREGAF LASH KIT ULTRA",
    ],
  };

  Map<String, List<String>> get sectionsData => _sectionsData;

  List<String> get products => _sectionsData.keys.toList();
}
