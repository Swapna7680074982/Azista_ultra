import 'package:flutter/material.dart';

class DistributionProvider extends ChangeNotifier {
  String _selectedCity = "HYDERABAD";
  String _selectedPoint = "POINT 1";
  String _selectedRoute = "UPPAL";
  final Map<String, Map<String, List<String>>> _data = {
    "HYDERABAD": {
      "POINT 1": ["UPPAL", "MIYAPUR"],
      "POINT 2": ["KUKATPALLY", "LB NAGAR"],
    },
    "BANGALORE": {
      "POINT A": ["WHITEFIELD", "BTM"],
      "POINT B": ["INDIRANAGAR", "MG ROAD"],
    },
  };
  List<String> get cities => _data.keys.toList();

  List<String> get points =>
      _data[_selectedCity]?.keys.toList() ?? [];

  List<String> get routes =>
      _data[_selectedCity]?[_selectedPoint] ?? [];

  String get selectedCity => _selectedCity;
  String get selectedPoint => _selectedPoint;
  String get selectedRoute => _selectedRoute;

  void setCity(String city) {
    _selectedCity = city;
    _selectedPoint = points.first;
    _selectedRoute = routes.first;

    notifyListeners();
  }

  void setPoint(String point) {
    _selectedPoint = point;
    _selectedRoute = routes.first;

    notifyListeners();
  }

  void setRoute(String route) {
    _selectedRoute = route;
    notifyListeners();
  }
}