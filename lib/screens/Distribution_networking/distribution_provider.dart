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

  // Backward compatibility getters
  List<String> get regions => _states;
  List<String> get areas => cities;
  List<String> get hqs => cities;
  List<String> get beats => routes;
  String? get selectedRegion => _selectedState;
  String? get selectedArea => _selectedCity;
  String? get selectedHq => _selectedCity;
  String? get selectedBeat => _selectedRoute;

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
    final routesData = response != null ? (response["routes"] ?? response["beats"] ?? response["data"]) : null;

    if (response != null && routesData != null) {
      Map<String, dynamic> routesMap = {};
      if (routesData is Map) {
        routesMap = Map<String, dynamic>.from(routesData);
      } else if (routesData is List) {
        for (int i = 0; i < routesData.length; i++) {
          routesMap[i.toString()] = routesData[i];
        }
      }

      List<String> tempStates = [];
      Map<String, List<String>> tempCitiesByState = {};
      Map<String, List<String>> tempRoutesByStateCity = {};
      Map<String, String> tempIds = {};

      for (var entry in routesMap.entries) {
        final key = entry.key;
        final item = entry.value;
        if (item is! Map) continue;

        final state = (item["STATE"] ?? item["STATE_NAME"] ?? item["REGION"] ?? "State").toString().trim();
        final city = (item["CITY"] ?? item["CITY_NAME"] ?? item["AREA"] ?? item["CLUSTER"] ?? item["HQ"] ?? item["TERRITORY"] ?? "City").toString().trim();
        final route = (item["ROUTE"] ?? item["ROUTE_NAME"] ?? item["BEAT"] ?? item["BEAT_NAME"] ?? "Route").toString().trim();
        final routeId = (item["ROUTE_ID"] ?? item["BEAT_ID"] ?? item["URM_autoID"] ?? key).toString().trim();

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

        tempIds["$state-$city-$route"] = routeId;
      }

      _states = tempStates;
      _citiesByState = tempCitiesByState;
      _routesByStateCity = tempRoutesByStateCity;
      _routeIds = tempIds;

      if (_states.isNotEmpty) {
        if (_selectedState == null || !_states.contains(_selectedState)) {
          _selectedState = _states.first;
        }
        final citiesForState = _citiesByState[_selectedState] ?? [];
        if (citiesForState.isNotEmpty) {
          if (_selectedCity == null || !citiesForState.contains(_selectedCity)) {
            _selectedCity = citiesForState.first;
          }
          final routesForCity = _routesByStateCity["$_selectedState-$_selectedCity"] ?? [];
          if (routesForCity.isNotEmpty) {
            if (_selectedRoute == null || !routesForCity.contains(_selectedRoute)) {
              _selectedRoute = routesForCity.first;
            }
          } else {
            _selectedRoute = null;
          }
        } else {
          _selectedCity = null;
          _selectedRoute = null;
        }
      } else {
        _selectedState = null;
        _selectedCity = null;
        _selectedRoute = null;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void setStateValue(String state) {
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

  // Backward compatibility methods
  void setRegion(String region) => setStateValue(region);
  void setArea(String area) => setCity(area);
  void setHq(String hq) => setCity(hq);
  void setBeat(String beat) => setRoute(beat);
}