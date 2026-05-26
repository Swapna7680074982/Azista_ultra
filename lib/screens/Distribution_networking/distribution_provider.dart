import 'package:flutter/material.dart';

import '../../services/api_services.dart';

class DistributionProvider extends ChangeNotifier {
  String? _selectedState;
  String? _selectedCity;
  String? _selectedRoute;

  List<String> _states = [];
  Map<String, List<String>> _citiesByState = {};
  Map<String, List<String>> _routesByStateCity = {};
  Map<String, String> _routeIds = {}; // Format: "state-city-route": "routeId"

  List<String> get states => _states;
  List<String> get cities => _citiesByState[_selectedState] ?? [];
  List<String> get routes => _routesByStateCity["$_selectedState-$_selectedCity"] ?? [];

  String? get selectedState => _selectedState;
  String? get selectedCity => _selectedCity;
  String? get selectedRoute => _selectedRoute;
  
  String? get selectedRouteId {
    if (_selectedState != null && _selectedCity != null && _selectedRoute != null) {
      return _routeIds["$_selectedState-$_selectedCity-$_selectedRoute"];
    }
    return null;
  }

  bool isLoading = false;

  Future<void> fetchRoutes() async {
    isLoading = true;
    notifyListeners();

    final response = await ApiServices.getRoutes();

    if (response != null && response["routes"] != null) {
      final routes = Map<String, dynamic>.from(response["routes"]);

      List<String> tempStates = [];
      Map<String, List<String>> tempCitiesByState = {};
      Map<String, List<String>> tempRoutesByStateCity = {};
      Map<String, String> tempIds = {};

      for (var item in routes.values) {
        final state = item["STATE"]?.toString() ?? "Unknown";
        final city = item["CITY"]?.toString() ?? "Unknown";
        final route = item["ROUTE"]?.toString() ?? "Unknown";
        final routeId = item["ROUTE_ID"]?.toString();

        if (!tempStates.contains(state)) {
          tempStates.add(state);
        }

        if (!tempCitiesByState.containsKey(state)) {
          tempCitiesByState[state] = [];
        }
        if (!tempCitiesByState[state]!.contains(city)) {
          tempCitiesByState[state]!.add(city);
        }

        final stateCityKey = "$state-$city";
        if (!tempRoutesByStateCity.containsKey(stateCityKey)) {
          tempRoutesByStateCity[stateCityKey] = [];
        }
        if (!tempRoutesByStateCity[stateCityKey]!.contains(route)) {
          tempRoutesByStateCity[stateCityKey]!.add(route);
        }
        
        if (routeId != null) {
          tempIds["$state-$city-$route"] = routeId;
        }
      }

      _states = tempStates;
      _citiesByState = tempCitiesByState;
      _routesByStateCity = tempRoutesByStateCity;
      _routeIds = tempIds;

      if (_states.isNotEmpty) {
        _selectedState = _states.first;
        final citiesForState = _citiesByState[_selectedState] ?? [];
        if (citiesForState.isNotEmpty) {
          _selectedCity = citiesForState.first;
          final routesForCity = _routesByStateCity["$_selectedState-$_selectedCity"] ?? [];
          _selectedRoute = routesForCity.isNotEmpty ? routesForCity.first : null;
        } else {
          _selectedCity = null;
          _selectedRoute = null;
        }
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void setStateName(String state) {
    _selectedState = state;
    final citiesForState = _citiesByState[state] ?? [];
    if (citiesForState.isNotEmpty) {
      _selectedCity = citiesForState.first;
      final routesForCity = _routesByStateCity["$state-$_selectedCity"] ?? [];
      _selectedRoute = routesForCity.isNotEmpty ? routesForCity.first : null;
    } else {
      _selectedCity = null;
      _selectedRoute = null;
    }
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    final routesForCity = _routesByStateCity["$_selectedState-$city"] ?? [];
    _selectedRoute = routesForCity.isNotEmpty ? routesForCity.first : null;
    notifyListeners();
  }

  void setRoute(String route) {
    _selectedRoute = route;
    notifyListeners();
  }
}