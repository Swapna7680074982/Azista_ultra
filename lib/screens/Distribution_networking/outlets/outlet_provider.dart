import 'package:flutter/material.dart';

import '../../../services/api_services.dart';
import '../../../services/location_service.dart';

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
    // Resolve the category/type name from multiple possible API field names
    final type = (json['outlet_category_name']
            ?? json['category_name']
            ?? json['outlet_type']
            ?? json['outlet_category'])
        ?.toString()
        ?? '';

    double lat = 0.0;
    final rawLat = json['location']?['latitude'] ??
        json['location']?['lat'] ??
        json['latitude'] ??
        json['lat'] ??
        json['outlet_latitude'];
    if (rawLat != null) {
      lat = double.tryParse(rawLat.toString()) ?? 0.0;
    }

    double lng = 0.0;
    final rawLng = json['location']?['longitude'] ??
        json['location']?['lng'] ??
        json['longitude'] ??
        json['lng'] ??
        json['outlet_longitude'];
    if (rawLng != null) {
      lng = double.tryParse(rawLng.toString()) ?? 0.0;
    }

    if (lat == 0.0 && lng == 0.0 && json['coordinates'] is List && (json['coordinates'] as List).length >= 2) {
      lat = double.tryParse(json['coordinates'][0].toString()) ?? 0.0;
      lng = double.tryParse(json['coordinates'][1].toString()) ?? 0.0;
    }

    double? distKm;
    final rawDist = json['distance_km'] ?? json['distance'] ?? json['dist_km'];
    if (rawDist != null) {
      distKm = double.tryParse(rawDist.toString());
    }

    return Outlet(
      id: (json['outlet_id'] ?? json['id'] ?? '').toString(),
      name: (json['outlet_name'] ?? json['name'] ?? 'Unknown').toString(),
      owner: (json['owner_name'] ?? json['owner'] ?? json['contact_person'] ?? json['contact_name'] ?? 'Unknown').toString(),
      phone: (json['mobile'] ?? json['phone'] ?? json['mobile_number'] ?? json['contact_number'] ?? '').toString(),
      type: type,
      latitude: lat,
      longitude: lng,
      status: json['status']?.toString() ?? 'ACTIVE',
      address: json['address']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      distanceKm: distKm,
    );
  }
}

class OutletCategory {
  final String categoryId;
  final String categoryName;
  final String categoryImage;

  OutletCategory({
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
  });

  factory OutletCategory.fromJson(Map<String, dynamic> json) {
    return OutletCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      categoryImage: json['category_image']?.toString() ?? '',
    );
  }
}

class OutletProvider extends ChangeNotifier {
  List<Outlet> _outlets = [];
  List<Outlet> _nearbyOutlets = [];
  bool isLoading = false;
  String _searchQuery = "";

  List<OutletCategory> _categories = [];
  bool isCategoriesLoading = false;

  List<OutletCategory> get categories => _categories;

  // Pending Geo Requests by Outlet ID
  final Map<int, Map<String, dynamic>> _pendingGeoRequestsByOutlet = {};
  Map<int, Map<String, dynamic>> get pendingGeoRequestsByOutlet => _pendingGeoRequestsByOutlet;

  bool hasPendingGeoRequest(int outletId) => _pendingGeoRequestsByOutlet.containsKey(outletId);
  Map<String, dynamic>? getPendingGeoRequest(int outletId) => _pendingGeoRequestsByOutlet[outletId];

  void markGeoRequestPending(int outletId, {Map<String, dynamic>? requestData}) {
    _pendingGeoRequestsByOutlet[outletId] = requestData ?? {
      "status": "pending",
      "outlet_id": outletId.toString(),
    };
    notifyListeners();
  }

  void removePendingGeoRequest(int outletId) {
    _pendingGeoRequestsByOutlet.remove(outletId);
    notifyListeners();
  }

  Future<void> fetchPendingGeoRequests() async {
    try {
      final res = await ApiServices.getMyOutletGeoRequests(status: "pending");
      if (res != null && res["data"] is List) {
        _pendingGeoRequestsByOutlet.clear();
        for (var item in res["data"]) {
          final oId = int.tryParse(item["outlet_id"]?.toString() ?? "");
          if (oId != null) {
            _pendingGeoRequestsByOutlet[oId] = Map<String, dynamic>.from(item);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching pending geo requests: $e");
    }
  }

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

    // Sync pending geo requests in background
    fetchPendingGeoRequests();
  }

  Future<void> fetchNearbyOutlets(double latitude, double longitude, {int radius = 10, int? routeId}) async {
    isLoading = true;
    notifyListeners();
    await _fetchNearbyOutletsInternal(latitude, longitude, radius: radius, routeId: routeId);
    isLoading = false;
    notifyListeners();
    fetchPendingGeoRequests();
  }

  Future<void> _fetchNearbyOutletsInternal(double latitude, double longitude, {int radius = 10, int? routeId}) async {
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
  }

  Future<void> refreshNearbyOutlets({int? routeId}) async {
    isLoading = true;
    notifyListeners();
    try {
      final coords = await LocationService.getCoordinates();
      final lat = double.parse(coords[0]);
      final lng = double.parse(coords[1]);
      await _fetchNearbyOutletsInternal(lat, lng, radius: 10, routeId: routeId);
    } catch (e) {
      debugPrint("Error refreshing location/outlets: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    isCategoriesLoading = true;
    notifyListeners();

    try {
      final response = await ApiServices.getOutletCategories();
      if (response != null && response['data'] != null) {
        final List<dynamic> data = response['data'];
        _categories = data.map((json) => OutletCategory.fromJson(json)).toList();
      } else {
        _categories = [];
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      _categories = [];
    } finally {
      isCategoriesLoading = false;
      notifyListeners();
    }
  }
}