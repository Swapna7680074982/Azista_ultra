import 'package:flutter/material.dart';

import '../../services/api_services.dart';

class DistributionProvider extends ChangeNotifier {
  String? _selectedCity;
  String? _selectedRoute;

  List<String> _cities = [];
  Map<String, List<String>> _routesByCity = {};
  Map<String, String> _routeIds = {}; // Format: "city-route": "routeId"

  List<String> get cities => _cities;
  List<String> get routes => _routesByCity[_selectedCity] ?? [];

  String? get selectedCity => _selectedCity;
  String? get selectedRoute => _selectedRoute;
  
  String? get selectedRouteId {
    if (_selectedCity != null && _selectedRoute != null) {
      return _routeIds["${_selectedCity!}-${_selectedRoute!}"];
    }
    return null;
  }

  bool isLoading = false;

  Future<void> fetchRoutes() async {
    isLoading = true;
    notifyListeners();

    final response = await ApiServices.getRoutes();

    if (response != null) {
      final routes = response["routes"] as Map<String, dynamic>;

      Map<String, List<String>> tempMap = {};
      Map<String, String> tempIds = {};

      for (var item in routes.values) {
        final city = item["CITY"]?.toString() ?? "Unknown";
        final route = item["ROUTE"]?.toString() ?? "Unknown";
        final routeId = item["ROUTE_ID"]?.toString();

        if (!tempMap.containsKey(city)) {
          tempMap[city] = [];
        }

        if (!tempMap[city]!.contains(route)) {
          tempMap[city]!.add(route);
        }
        
        if (routeId != null) {
          tempIds["$city-$route"] = routeId;
        }
      }

      _routesByCity = tempMap;
      _cities = tempMap.keys.toList();
      _routeIds = tempIds;

      if (_cities.isNotEmpty) {
        _selectedCity = _cities.first;
        _selectedRoute = _routesByCity[_selectedCity]!.isNotEmpty ? _routesByCity[_selectedCity]!.first : null;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    _selectedRoute = _routesByCity[city]!.isNotEmpty ? _routesByCity[city]!.first : null;
    notifyListeners();
  }

  void setRoute(String route) {
    _selectedRoute = route;
    notifyListeners();
  }
}