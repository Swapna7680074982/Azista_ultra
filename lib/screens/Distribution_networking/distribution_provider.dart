import 'package:flutter/material.dart';

import '../../services/api_services.dart';

class DistributionProvider extends ChangeNotifier {
  String? _selectedCity;
  String? _selectedRoute;

  List<String> _cities = [];
  Map<String, List<String>> _routesByCity = {};

  List<String> get cities => _cities;
  List<String> get routes => _routesByCity[_selectedCity] ?? [];

  String? get selectedCity => _selectedCity;
  String? get selectedRoute => _selectedRoute;

  bool isLoading = false;

  Future<void> fetchRoutes() async {
    isLoading = true;
    notifyListeners();

    final response = await ApiServices.getRoutes();

    if (response != null) {
      final routes = response["routes"] as Map<String, dynamic>;

      Map<String, List<String>> tempMap = {};

      for (var item in routes.values) {
        final city = item["CITY"];
        final route = item["ROUTE"];

        if (!tempMap.containsKey(city)) {
          tempMap[city] = [];
        }

        tempMap[city]!.add(route);
      }

      _routesByCity = tempMap;
      _cities = tempMap.keys.toList();

      if (_cities.isNotEmpty) {
        _selectedCity = _cities.first;
        _selectedRoute = _routesByCity[_selectedCity]!.first;
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void setCity(String city) {
    _selectedCity = city;
    _selectedRoute = _routesByCity[city]!.first;
    notifyListeners();
  }

  void setRoute(String route) {
    _selectedRoute = route;
    notifyListeners();
  }
}