import 'package:flutter/material.dart';

import '../../../permissions/SessionManager.dart';
import '../../../services/api_services.dart';
import '../../../services/location_service.dart';

class VisitHistoryItem {
  final String visitId;
  final String visitDate;
  final String visitType;
  final String checkinTime;
  final String? checkoutTime;
  final String remarks;
  final List<dynamic> activityHistory;

  VisitHistoryItem({
    required this.visitId,
    required this.visitDate,
    required this.visitType,
    required this.checkinTime,
    this.checkoutTime,
    this.remarks = '',
    this.activityHistory = const [],
  });

  factory VisitHistoryItem.fromJson(Map<String, dynamic> json) {
    final vDate = (json['visit_date'] ??
            json['date'] ??
            json['checkin_time'] ??
            json['check_in_time'] ??
            json['check_in'] ??
            json['last_visit_date'] ??
            json['last_visited_date'] ??
            json['created_on'] ??
            json['created_at'] ??
            '')
        .toString();

    final cInTime = (json['checkin_time'] ??
            json['check_in_time'] ??
            json['check_in'] ??
            json['visit_date'] ??
            json['date'] ??
            '')
        .toString();

    return VisitHistoryItem(
      visitId: (json['visit_id'] ?? json['id'] ?? '').toString(),
      visitDate: vDate == 'null' ? '' : vDate,
      visitType: (json['visit_type'] ?? json['type'] ?? json['call_type'] ?? 'INDIVIDUAL').toString(),
      checkinTime: cInTime == 'null' ? '' : cInTime,
      checkoutTime: json['checkout_time']?.toString() ?? json['check_out_time']?.toString(),
      remarks: (json['remarks'] ?? json['remark'] ?? '').toString(),
      activityHistory: (json['activity_history'] as List<dynamic>?) ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'visit_id': visitId,
    'visit_date': visitDate,
    'visit_type': visitType,
    'checkin_time': checkinTime,
    'checkout_time': checkoutTime,
    'remarks': remarks,
    'activity_history': activityHistory,
  };
}

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
  final List<VisitHistoryItem> visitHistory;
  final int totalVisits;
  final int totalActivities;
  final int totalPobs;
  final double saleValue;

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
    this.visitHistory = const [],
    this.totalVisits = 0,
    this.totalActivities = 0,
    this.totalPobs = 0,
    this.saleValue = 0.0,
  });

  VisitHistoryItem? get latestVisit =>
      visitHistory.isNotEmpty ? visitHistory.first : null;

  Outlet copyWith({
    String? name,
    String? owner,
    String? phone,
    String? id,
    String? type,
    double? latitude,
    double? longitude,
    String? status,
    String? address,
    String? area,
    double? distanceKm,
    List<VisitHistoryItem>? visitHistory,
    int? totalVisits,
    int? totalActivities,
    int? totalPobs,
    double? saleValue,
  }) {
    return Outlet(
      name: name ?? this.name,
      owner: owner ?? this.owner,
      phone: phone ?? this.phone,
      id: id ?? this.id,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      address: address ?? this.address,
      area: area ?? this.area,
      distanceKm: distanceKm ?? this.distanceKm,
      visitHistory: visitHistory ?? this.visitHistory,
      totalVisits: totalVisits ?? this.totalVisits,
      totalActivities: totalActivities ?? this.totalActivities,
      totalPobs: totalPobs ?? this.totalPobs,
      saleValue: saleValue ?? this.saleValue,
    );
  }

  factory Outlet.fromJson(Map<String, dynamic> json) {
    // If json has nested "outlet_details", unpack it
    final outletData = (json['outlet_details'] is Map<String, dynamic>)
        ? json['outlet_details'] as Map<String, dynamic>
        : json;

    // Resolve the category/type name from multiple possible API field names
    final type = (outletData['outlet_category_name']
            ?? outletData['category_name']
            ?? outletData['outlet_type']
            ?? outletData['outlet_category'])
        ?.toString()
        ?? '';

    double lat = 0.0;
    final rawLat = outletData['location']?['latitude'] ??
        outletData['location']?['lat'] ??
        outletData['latitude'] ??
        outletData['lat'] ??
        outletData['outlet_latitude'];
    if (rawLat != null) {
      lat = double.tryParse(rawLat.toString()) ?? 0.0;
    }

    double lng = 0.0;
    final rawLng = outletData['location']?['longitude'] ??
        outletData['location']?['lng'] ??
        outletData['longitude'] ??
        outletData['lng'] ??
        outletData['outlet_longitude'];
    if (rawLng != null) {
      lng = double.tryParse(rawLng.toString()) ?? 0.0;
    }

    if (lat == 0.0 && lng == 0.0 && outletData['coordinates'] is List && (outletData['coordinates'] as List).length >= 2) {
      lat = double.tryParse(outletData['coordinates'][0].toString()) ?? 0.0;
      lng = double.tryParse(outletData['coordinates'][1].toString()) ?? 0.0;
    }

    double? distKm;
    final rawDist = json['distance_km'] ?? json['distance'] ?? json['dist_km'] ?? outletData['distance_km'] ?? outletData['distance'] ?? outletData['dist_km'];
    if (rawDist != null) {
      distKm = double.tryParse(rawDist.toString());
    }

    // Parse visit history if present in either root json or outletData
    final rawVisits = (json['visit_history'] ??
        outletData['visit_history'] ??
        json['visits'] ??
        outletData['visits']);
    List<VisitHistoryItem> parsedVisits = [];
    if (rawVisits is List) {
      for (var v in rawVisits) {
        if (v is Map<String, dynamic>) {
          parsedVisits.add(VisitHistoryItem.fromJson(v));
        } else if (v is Map) {
          parsedVisits.add(VisitHistoryItem.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }

    // Direct last visit field check from multiple possible API keys
    String? lVisitDate = (json['last_visit_date'] ??
            outletData['last_visit_date'] ??
            json['last_visited_date'] ??
            outletData['last_visited_date'] ??
            json['last_visit_on'] ??
            outletData['last_visit_on'] ??
            json['last_visited_on'] ??
            outletData['last_visited_on'] ??
            json['last_visit_time'] ??
            outletData['last_visit_time'] ??
            json['last_visit_datetime'] ??
            outletData['last_visit_datetime'] ??
            json['last_visit_date_time'] ??
            outletData['last_visit_date_time'] ??
            json['last_checkin_time'] ??
            outletData['last_checkin_time'] ??
            json['last_checkin'] ??
            outletData['last_checkin'] ??
            json['visit_date'] ??
            outletData['visit_date'] ??
            json['checkin_time'] ??
            outletData['checkin_time'])
        ?.toString();

    String? lVisitType = (json['last_visit_type'] ??
            outletData['last_visit_type'] ??
            json['visit_type'] ??
            outletData['visit_type'] ??
            json['call_type'] ??
            outletData['call_type'])
        ?.toString();

    final rawLastVisit = json['last_visit'] ??
        outletData['last_visit'] ??
        json['latest_visit'] ??
        outletData['latest_visit'] ??
        json['last_visited'] ??
        outletData['last_visited'];
    if (rawLastVisit is Map) {
      final map = Map<String, dynamic>.from(rawLastVisit);
      lVisitDate ??= (map['visit_date'] ?? map['checkin_time'] ?? map['date'] ?? map['check_in_time'] ?? map['last_visit_date'] ?? map['created_on'])?.toString();
      lVisitType ??= (map['visit_type'] ?? map['type'] ?? map['call_type'])?.toString();
      if (parsedVisits.isEmpty) {
        parsedVisits.add(VisitHistoryItem.fromJson(map));
      }
    } else if (rawLastVisit != null && rawLastVisit.toString().trim().isNotEmpty && rawLastVisit.toString() != 'null' && rawLastVisit.toString() != 'N/A') {
      lVisitDate ??= rawLastVisit.toString();
    }

    if (parsedVisits.isEmpty && lVisitDate != null && lVisitDate.trim().isNotEmpty && lVisitDate != 'null' && lVisitDate != 'N/A' && lVisitDate != '-') {
      parsedVisits.add(VisitHistoryItem(
        visitId: (json['last_visit_id'] ?? outletData['last_visit_id'] ?? json['visit_id'] ?? outletData['visit_id'] ?? '').toString(),
        visitDate: lVisitDate,
        visitType: (lVisitType != null && lVisitType.isNotEmpty && lVisitType != 'null') ? lVisitType : 'INDIVIDUAL',
        checkinTime: lVisitDate,
      ));
    }

    int totalV = int.tryParse((json['total_visits'] ??
            outletData['total_visits'] ??
            json['visit_count'] ??
            outletData['visit_count'] ??
            json['visits_count'] ??
            outletData['visits_count'] ??
            json['total_visit'] ??
            outletData['total_visit'] ??
            json['total_calls'] ??
            outletData['total_calls'] ??
            json['calls_count'] ??
            outletData['calls_count'] ??
            '')
        .toString()) ?? (parsedVisits.isNotEmpty ? parsedVisits.length : 0);
    if (totalV == 0 && parsedVisits.isNotEmpty) {
      totalV = parsedVisits.length;
    }
    final int totalAct = int.tryParse((json['total_activities'] ?? outletData['total_activities'] ?? '').toString()) ?? 0;
    final int totalPob = int.tryParse((json['total_pobs'] ?? outletData['total_pobs'] ?? '').toString()) ?? 0;
    final double saleVal = double.tryParse((json['sale_value'] ?? outletData['sale_value'] ?? '').toString()) ?? 0.0;

    return Outlet(
      id: (outletData['outlet_id'] ?? outletData['id'] ?? json['outlet_id'] ?? json['id'] ?? '').toString(),
      name: (outletData['outlet_name'] ?? outletData['name'] ?? 'Unknown').toString(),
      owner: (outletData['owner_name'] ?? outletData['owner'] ?? outletData['contact_person'] ?? outletData['contact_name'] ?? 'Unknown').toString(),
      phone: (outletData['mobile'] ?? outletData['phone'] ?? outletData['mobile_number'] ?? outletData['contact_number'] ?? '').toString(),
      type: type,
      latitude: lat,
      longitude: lng,
      status: (outletData['status'] ?? json['status'] ?? 'ACTIVE').toString(),
      address: (outletData['address'] ?? json['address'] ?? '').toString(),
      area: (outletData['area'] ?? json['area'] ?? '').toString(),
      distanceKm: distKm,
      visitHistory: parsedVisits,
      totalVisits: totalV,
      totalActivities: totalAct,
      totalPobs: totalPob,
      saleValue: saleVal,
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
  String? _outletsErrorMessage;
  String? _nearbyErrorMessage;

  String? get outletsErrorMessage => _outletsErrorMessage;
  String? get nearbyErrorMessage => _nearbyErrorMessage;
  String get searchQuery => _searchQuery;

  // Reactive active check-in state across NearMe & Outlets screens
  int? _checkedInOutletId;
  DateTime? _checkedInTime;
  int? _checkedInVisitId;

  int? get checkedInOutletId => _checkedInOutletId;
  DateTime? get checkedInTime => _checkedInTime;
  int? get checkedInVisitId => _checkedInVisitId;

  Future<void> loadCheckInFromSession() async {
    _checkedInOutletId = await SessionManager.getOutletCheckInOutletId();
    _checkedInTime = await SessionManager.getOutletCheckInTime();
    _checkedInVisitId = await SessionManager.getOutletCheckInVisitId();
    notifyListeners();
  }

  void setCheckedInOutlet(int? outletId, {DateTime? checkInTime, int? visitId}) {
    _checkedInOutletId = outletId;
    _checkedInTime = checkInTime ?? DateTime.now();
    _checkedInVisitId = visitId;
    notifyListeners();
    if (outletId != null) {
      SessionManager.saveOutletCheckIn(
        outletId: outletId,
        visitId: visitId ?? 0,
        checkInTime: _checkedInTime!,
      );
    } else {
      SessionManager.clearOutletCheckIn();
    }
  }

  void clearCheckIn() {
    _checkedInOutletId = null;
    _checkedInTime = null;
    _checkedInVisitId = null;
    notifyListeners();
    SessionManager.clearOutletCheckIn();
  }

  void updateOutletVisits(String outletId, {List<VisitHistoryItem>? visits, int? totalVisits}) {
    bool updated = false;
    _outlets = _outlets.map((o) {
      if (o.id == outletId) {
        updated = true;
        return o.copyWith(
          visitHistory: visits ?? o.visitHistory,
          totalVisits: totalVisits ?? o.totalVisits,
        );
      }
      return o;
    }).toList();

    _nearbyOutlets = _nearbyOutlets.map((o) {
      if (o.id == outletId) {
        updated = true;
        return o.copyWith(
          visitHistory: visits ?? o.visitHistory,
          totalVisits: totalVisits ?? o.totalVisits,
        );
      }
      return o;
    }).toList();

    if (updated) {
      notifyListeners();
    }
  }

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
    _outletsErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiServices.getUserOutlets(routeId: routeId);
      if (response != null && response['data'] != null && response['data'] is List) {
        final List<dynamic> data = response['data'];
        _outlets = data.map((json) => Outlet.fromJson(json)).toList();
        _outletsErrorMessage = null;
      } else {
        _outlets = [];
        if (response != null && response['message'] != null && response['message'].toString().trim().isNotEmpty) {
          _outletsErrorMessage = response['message'].toString();
        } else if (response != null && response['status'] == 'error') {
          _outletsErrorMessage = response['message']?.toString() ?? "Failed to load outlets";
        } else if (response == null) {
          _outletsErrorMessage = "Unable to connect to server. Please check your internet connection and retry.";
        } else {
          _outletsErrorMessage = null;
        }
      }
    } catch (e) {
      _outlets = [];
      _outletsErrorMessage = "An error occurred: ${e.toString()}";
    }

    isLoading = false;
    notifyListeners();

    // Sync pending geo requests in background
    fetchPendingGeoRequests();
  }

  Future<void> fetchNearbyOutlets(double latitude, double longitude, {int radius = 10, int? routeId}) async {
    isLoading = true;
    _nearbyErrorMessage = null;
    notifyListeners();
    await _fetchNearbyOutletsInternal(latitude, longitude, radius: radius, routeId: routeId);
    isLoading = false;
    notifyListeners();
    fetchPendingGeoRequests();
  }

  Future<void> _fetchNearbyOutletsInternal(double latitude, double longitude, {int radius = 10, int? routeId}) async {
    try {
      final response = await ApiServices.getNearbyOutlets(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        routeId: routeId,
      );
      
      if (response != null && response['data'] != null && response['data'] is List) {
        final List<dynamic> data = response['data'];
        _nearbyOutlets = data.map((json) => Outlet.fromJson(json)).toList();
        _nearbyErrorMessage = null;
      } else {
        _nearbyOutlets = [];
        if (response != null && response['message'] != null && response['message'].toString().trim().isNotEmpty) {
          _nearbyErrorMessage = response['message'].toString();
        } else if (response != null && response['status'] == 'error') {
          _nearbyErrorMessage = response['message']?.toString() ?? "Failed to load nearby outlets";
        } else if (response == null) {
          _nearbyErrorMessage = "Unable to connect to server. Please check your internet connection and retry.";
        } else {
          _nearbyErrorMessage = null;
        }
      }
    } catch (e) {
      _nearbyOutlets = [];
      _nearbyErrorMessage = "An error occurred: ${e.toString()}";
    }
  }

  Future<void> refreshNearbyOutlets({int? routeId}) async {
    isLoading = true;
    _nearbyErrorMessage = null;
    notifyListeners();
    try {
      final coords = await LocationService.getCoordinates();
      final lat = double.parse(coords[0]);
      final lng = double.parse(coords[1]);
      await _fetchNearbyOutletsInternal(lat, lng, radius: 10, routeId: routeId);
    } catch (e) {
      debugPrint("Error refreshing location/outlets: $e");
      _nearbyErrorMessage = "Unable to determine current location: ${e.toString()}";
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