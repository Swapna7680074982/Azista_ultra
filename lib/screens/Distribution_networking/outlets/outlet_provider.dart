import 'package:flutter/material.dart';

class Outlet {
  final String name;
  final String owner;
  final String phone;
  final String id;
  final String type;

  Outlet({
    required this.name,
    required this.owner,
    required this.phone,
    required this.id,
    required this.type,
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
    ),
    Outlet(
      name: "RAJU PAN SHOP",
      owner: "RAJU",
      phone: "8804384873",
      id: "4939",
      type: "Others",
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