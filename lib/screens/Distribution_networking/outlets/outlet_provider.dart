import 'package:flutter/material.dart';

import '../../../services/api_services.dart';

class Outlet {
  final String name;
  final String owner;
  final String phone;
  final String id;
  final String type;
  final double latitude;
  final double longitude;
  final String status;
  final String address;
  final String area;
  final double? distanceKm;

  Outlet({
    required this.name,
    required this.owner,
    required this.phone,
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.status = "ACTIVE",
    this.address = "",
    this.area = "",
    this.distanceKm,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['outlet_id'].toString(),
      name: json['outlet_name']?.toString() ?? 'Unknown',
      owner: json['owner_name']?.toString() ?? 'Unknown',
      phone: json['mobile']?.toString() ?? '',
      type: json['outlet_type']?.toString() ?? 'Unknown',
      latitude: double.tryParse(json['location']?['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['location']?['longitude']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'ACTIVE',
      address: json['address']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
    );
  }
}

class OutletProvider extends ChangeNotifier {
  List<Outlet> _outlets = [];
  List<Outlet> _nearbyOutlets = [];
  bool isLoading = false;
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

  List<Outlet> get nearbyOutlets {
    if (_searchQuery.isEmpty) return _nearbyOutlets;

    return _nearbyOutlets.where((outlet) {
      return outlet.name.toLowerCase().contains(_searchQuery) ||
          outlet.owner.toLowerCase().contains(_searchQuery) ||
          outlet.phone.contains(_searchQuery);
    }).toList();
  }

  Future<void> fetchOutlets(int routeId) async {
    isLoading = true;
    notifyListeners();

    final response = await ApiServices.getUserOutlets(routeId: routeId);
    if (response != null && response['data'] != null) {
      final List<dynamic> data = response['data'];
      _outlets = data.map((json) => Outlet.fromJson(json)).toList();
    } else {
      _outlets = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNearbyOutlets(double latitude, double longitude, {int radius = 5, int? routeId}) async {
    isLoading = true;
    notifyListeners();

    final response = await ApiServices.getNearbyOutlets(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      routeId: routeId,
    );
    
    if (response != null && response['data'] != null) {
      final List<dynamic> data = response['data'];
      _nearbyOutlets = data.map((json) => Outlet.fromJson(json)).toList();
    } else {
      _nearbyOutlets = [];
    }

    isLoading = false;
    notifyListeners();
  }
}