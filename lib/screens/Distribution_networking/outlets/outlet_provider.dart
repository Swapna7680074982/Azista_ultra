import 'package:flutter/material.dart';

import '../../../services/api_services.dart';
import '../../../services/location_service.dart';
import '../../../permissions/SessionManager.dart';

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

    return Outlet(
      id: json['outlet_id'].toString(),
      name: json['outlet_name']?.toString() ?? 'Unknown',
      owner: (json['owner_name'] ?? json['owner'] ?? json['contact_person'] ?? json['contact_name'])?.toString() ?? 'Unknown',
      phone: (json['mobile'] ?? json['phone'] ?? json['mobile_number'] ?? json['contact_number'])?.toString() ?? '',
      type: type,
      latitude: double.tryParse(json['location']?['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['location']?['longitude']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'ACTIVE',
      address: json['address']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
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

  int? _checkedInOutletId;
  String? _checkInTimeAndDate;
  int? _checkedInVisitId;

  int? get checkedInOutletId => _checkedInOutletId;
  String? get checkInTimeAndDate => _checkInTimeAndDate;
  int? get checkedInVisitId => _checkedInVisitId;

  List<OutletCategory> _categories = [];
  bool isCategoriesLoading = false;

  List<OutletCategory> get categories => _categories;

  void updateSearch(String value) {
    _searchQuery = value.toLowerCase();
    notifyListeners();
  }

  void updateLocalCheckIn({required int outletId, required int visitId, required String checkInTime}) {
    _checkedInOutletId = outletId;
    _checkedInVisitId = visitId;
    _checkInTimeAndDate = checkInTime;
    notifyListeners();
  }

  void clearLocalCheckIn() {
    _checkedInOutletId = null;
    _checkedInVisitId = null;
    _checkInTimeAndDate = null;
    notifyListeners();
  }

  Future<void> syncCheckInStatus({List<Outlet>? checkOutlets}) async {
    final id = await SessionManager.getOutletCheckInOutletId();
    final savedTime = await SessionManager.getOutletCheckInTime();
    final visitId = await SessionManager.getOutletCheckInVisitId();

    if (id != null) {
      _checkedInOutletId = id;
      _checkedInVisitId = visitId;
      _checkInTimeAndDate = savedTime?.toIso8601String();
      notifyListeners();

      try {
        final history = await ApiServices.getOutletHistory(outletId: id);
        if (history != null && (history['status'] == true || history['status'] == 'success' || history['visit_history'] != null)) {
          final List visits = history['visit_history'] ?? [];
          final activeVisit = visits.firstWhere(
            (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
            orElse: () => null,
          );

          if (activeVisit != null) {
            final checkinTime = activeVisit['checkin_time']?.toString();
            final vId = int.tryParse(activeVisit['visit_id']?.toString() ?? "") ?? 0;
            final parsedTime = DateTime.tryParse(checkinTime ?? "");

            await SessionManager.saveOutletCheckIn(
              outletId: id,
              visitId: vId,
              checkInTime: parsedTime ?? DateTime.now(),
            );

            _checkedInOutletId = id;
            _checkedInVisitId = vId;
            _checkInTimeAndDate = checkinTime;
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint("Error verifying check-in with server: $e");
      }

      // If active visit was not found for this outlet, clear local check-in
      await SessionManager.clearOutletCheckIn();
      _checkedInOutletId = null;
      _checkedInVisitId = null;
      _checkInTimeAndDate = null;
      notifyListeners();
    }

    final targetList = checkOutlets ?? (_nearbyOutlets.isNotEmpty ? _nearbyOutlets : _outlets);
    if (targetList.isNotEmpty) {
      try {
        final futures = targetList.map((outlet) async {
          final currentId = int.tryParse(outlet.id);
          if (currentId == null) return null;
          final history = await ApiServices.getOutletHistory(outletId: currentId);
          if (history != null && (history['status'] == true || history['status'] == 'success' || history['visit_history'] != null)) {
            final List visits = history['visit_history'] ?? [];
            final activeVisit = visits.firstWhere(
              (v) => v['checkout_time'] == null || v['checkout_time'].toString().isEmpty || v['checkout_time'] == 'N/A',
              orElse: () => null,
            );
            if (activeVisit != null) {
              return {
                'outlet_id': currentId,
                'visit_id': int.tryParse(activeVisit['visit_id']?.toString() ?? "") ?? 0,
                'checkin_time': activeVisit['checkin_time']?.toString(),
              };
            }
          }
          return null;
        }).toList();

        final results = await Future.wait(futures);
        final activeCheckIn = results.firstWhere((r) => r != null, orElse: () => null);

        if (activeCheckIn != null) {
          final outletId = activeCheckIn['outlet_id'] as int;
          final vId = activeCheckIn['visit_id'] as int;
          final checkinTimeStr = activeCheckIn['checkin_time'] as String?;
          final checkInTime = DateTime.tryParse(checkinTimeStr ?? "");

          await SessionManager.saveOutletCheckIn(
            outletId: outletId,
            visitId: vId,
            checkInTime: checkInTime ?? DateTime.now(),
          );

          _checkedInOutletId = outletId;
          _checkedInVisitId = vId;
          _checkInTimeAndDate = checkinTimeStr;
          notifyListeners();
        } else {
          await SessionManager.clearOutletCheckIn();
          _checkedInOutletId = null;
          _checkedInVisitId = null;
          _checkInTimeAndDate = null;
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error checking server check-in status: $e");
      }
    }
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

    try {
      final response = await ApiServices.getUserOutlets(routeId: routeId);
      if (response != null && (response['status'] == true || response['status'] == 'success' || response['data'] != null)) {
        final List<dynamic> data = response['data'] ?? [];
        _outlets = data.map((json) => Outlet.fromJson(json)).toList();
      } else {
        _outlets = [];
      }
      await syncCheckInStatus(checkOutlets: _outlets);
    } catch (e) {
      debugPrint("Error fetching outlets: $e");
      _outlets = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyOutlets(double latitude, double longitude, {int radius = 5, int? routeId}) async {
    isLoading = true;
    notifyListeners();
    try {
      await _fetchNearbyOutletsInternal(latitude, longitude, radius: radius, routeId: routeId);
      await syncCheckInStatus(checkOutlets: _nearbyOutlets);
    } catch (e) {
      debugPrint("Error fetching nearby outlets: $e");
      _nearbyOutlets = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNearbyOutletsInternal(double latitude, double longitude, {int radius = 5, int? routeId}) async {
    try {
      final response = await ApiServices.getNearbyOutlets(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        routeId: routeId,
      );
      
      if (response != null && (response['status'] == true || response['status'] == 'success' || response['data'] != null)) {
        final List<dynamic> data = response['data'] ?? [];
        _nearbyOutlets = data.map((json) => Outlet.fromJson(json)).toList();
      } else {
        _nearbyOutlets = [];
      }
    } catch (e) {
      debugPrint("Error in _fetchNearbyOutletsInternal: $e");
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
      await _fetchNearbyOutletsInternal(lat, lng, radius: 5, routeId: routeId);
      await syncCheckInStatus(checkOutlets: _nearbyOutlets);
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