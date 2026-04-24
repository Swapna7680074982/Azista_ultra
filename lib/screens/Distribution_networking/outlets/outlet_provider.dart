import 'package:flutter/material.dart';

class Outlet {
  final String name;
  final String owner;
  final String phone;
  final String id;
  final String type;
  final double latitude;
  final double longitude;

  Outlet({
    required this.name,
    required this.owner,
    required this.phone,
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
  });
}
class OutletProvider extends ChangeNotifier {
  final List<Outlet> _outlets = [
    Outlet(
      name: "SUBARTHA PAN",
      owner: "ROSHAN",
      phone: "8328112325",
      id: "8046",
      type: "Retailer",
      latitude: 17.4435,
      longitude: 78.3772,
    ),
    Outlet(
      name: "RAJU PAN SHOP",
      owner: "RAJU",
      phone: "8804384873",
      id: "4939",
      type: "Others",
      latitude: 17.4450,
      longitude: 78.3790,
    ),
  ];

  String _searchQuery = "";

  void updateSearch(String value) {
    _searchQuery = value.toLowerCase();
    notifyListeners();
  }

  List<Outlet> get outlets {
    if (_searchQuery.isEmpty) return _outlets;

    return _outlets.where((outlet) {
      return outlet.name.toLowerCase().contains(_searchQuery) ||
          outlet.owner.toLowerCase().contains(_searchQuery) ||
          outlet.phone.contains(_searchQuery);
    }).toList();
  }
}