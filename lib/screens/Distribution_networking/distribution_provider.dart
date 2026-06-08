import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class DistributionProvider extends ChangeNotifier {
  String? _selectedRegion;
  String? _selectedArea;
  String? _selectedHq;
  String? _selectedBeat;

  List<String> _regions = [];
  Map<String, List<String>> _areasByRegion = {};
  Map<String, List<String>> _hqsByArea = {};
  Map<String, List<String>> _beatsByHq = {};
  Map<String, String> _routeIds = {}; // Format: "region-area-hq-beat": "routeId"

  List<String> get regions => _regions;
  List<String> get areas => _areasByRegion[_selectedRegion] ?? [];
  List<String> get hqs => _hqsByArea["$_selectedRegion-$_selectedArea"] ?? [];
  List<String> get beats => _beatsByHq["$_selectedRegion-$_selectedArea-$_selectedHq"] ?? [];

  String? get selectedRegion => _selectedRegion;
  String? get selectedArea => _selectedArea;
  String? get selectedHq => _selectedHq;
  String? get selectedBeat => _selectedBeat;
  
  String? get selectedRouteId {
    if (_selectedRegion != null && _selectedArea != null && _selectedHq != null && _selectedBeat != null) {
      return _routeIds["$_selectedRegion-$_selectedArea-$_selectedHq-$_selectedBeat"];
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

      List<String> tempRegions = [];
      Map<String, List<String>> tempAreasByRegion = {};
      Map<String, List<String>> tempHqsByArea = {};
      Map<String, List<String>> tempBeatsByHq = {};
      Map<String, String> tempIds = {};

      for (var item in routes.values) {
        final region = item["REGION"]?.toString() ?? item["STATE"]?.toString() ?? "Region 1";
        final area = item["AREA"]?.toString() ?? item["CITY"]?.toString() ?? "Area 1";
        final hq = item["HQ"]?.toString() ?? (item["CITY"] != null ? "${item["CITY"]} HQ" : "HQ 1");
        final beat = item["BEAT"]?.toString() ?? item["ROUTE"]?.toString() ?? "Beat 1";
        final routeId = item["ROUTE_ID"]?.toString();

        if (!tempRegions.contains(region)) {
          tempRegions.add(region);
        }

        if (!tempAreasByRegion.containsKey(region)) {
          tempAreasByRegion[region] = [];
        }
        if (!tempAreasByRegion[region]!.contains(area)) {
          tempAreasByRegion[region]!.add(area);
        }

        final regionAreaKey = "$region-$area";
        if (!tempHqsByArea.containsKey(regionAreaKey)) {
          tempHqsByArea[regionAreaKey] = [];
        }
        if (!tempHqsByArea[regionAreaKey]!.contains(hq)) {
          tempHqsByArea[regionAreaKey]!.add(hq);
        }

        final regionAreaHqKey = "$region-$area-$hq";
        if (!tempBeatsByHq.containsKey(regionAreaHqKey)) {
          tempBeatsByHq[regionAreaHqKey] = [];
        }
        if (!tempBeatsByHq[regionAreaHqKey]!.contains(beat)) {
          tempBeatsByHq[regionAreaHqKey]!.add(beat);
        }
        
        if (routeId != null) {
          tempIds["$region-$area-$hq-$beat"] = routeId;
        }
      }

      _regions = tempRegions;
      _areasByRegion = tempAreasByRegion;
      _hqsByArea = tempHqsByArea;
      _beatsByHq = tempBeatsByHq;
      _routeIds = tempIds;

      if (_regions.isNotEmpty) {
        _selectedRegion = _regions.first;
        final areasForRegion = _areasByRegion[_selectedRegion] ?? [];
        if (areasForRegion.isNotEmpty) {
          _selectedArea = areasForRegion.first;
          final hqsForArea = _hqsByArea["$_selectedRegion-$_selectedArea"] ?? [];
          if (hqsForArea.isNotEmpty) {
            _selectedHq = hqsForArea.first;
            final beatsForHq = _beatsByHq["$_selectedRegion-$_selectedArea-$_selectedHq"] ?? [];
            _selectedBeat = beatsForHq.isNotEmpty ? beatsForHq.first : null;
          } else {
            _selectedHq = null;
            _selectedBeat = null;
          }
        } else {
          _selectedArea = null;
          _selectedHq = null;
          _selectedBeat = null;
        }
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void setRegion(String region) {
    _selectedRegion = region;
    final areasForRegion = _areasByRegion[region] ?? [];
    if (areasForRegion.isNotEmpty) {
      _selectedArea = areasForRegion.first;
      final hqsForArea = _hqsByArea["$region-$_selectedArea"] ?? [];
      if (hqsForArea.isNotEmpty) {
        _selectedHq = hqsForArea.first;
        final beatsForHq = _beatsByHq["$region-$_selectedArea-$_selectedHq"] ?? [];
        _selectedBeat = beatsForHq.isNotEmpty ? beatsForHq.first : null;
      } else {
        _selectedHq = null;
        _selectedBeat = null;
      }
    } else {
      _selectedArea = null;
      _selectedHq = null;
      _selectedBeat = null;
    }
    notifyListeners();
  }

  void setArea(String area) {
    _selectedArea = area;
    final hqsForArea = _hqsByArea["$_selectedRegion-$area"] ?? [];
    if (hqsForArea.isNotEmpty) {
      _selectedHq = hqsForArea.first;
      final beatsForHq = _beatsByHq["$_selectedRegion-$area-$_selectedHq"] ?? [];
      _selectedBeat = beatsForHq.isNotEmpty ? beatsForHq.first : null;
    } else {
      _selectedHq = null;
      _selectedBeat = null;
    }
    notifyListeners();
  }

  void setHq(String hq) {
    _selectedHq = hq;
    final beatsForHq = _beatsByHq["$_selectedRegion-$_selectedArea-$hq"] ?? [];
    _selectedBeat = beatsForHq.isNotEmpty ? beatsForHq.first : null;
    notifyListeners();
  }

  void setBeat(String beat) {
    _selectedBeat = beat;
    notifyListeners();
  }
}