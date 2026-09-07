import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static List<String> _cachedCoordinates = ["17.4297436", "78.3806493"];

  static Future<List<String>> getCoordinates({
    bool requestPermission = true,
    bool throwOnError = false,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (throwOnError) throw Exception("Location services disabled");
        return _cachedCoordinates;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (throwOnError) throw Exception("Location permission denied");
        return _cachedCoordinates;
      }

      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && lastPosition.latitude != 0.0) {
        _cachedCoordinates = [
          lastPosition.latitude.toString(),
          lastPosition.longitude.toString(),
        ];
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 6),
        );

        if (position.latitude != 0.0) {
          _cachedCoordinates = [
            position.latitude.toString(),
            position.longitude.toString(),
          ];
          return _cachedCoordinates;
        }
      } catch (_) {}

      return _cachedCoordinates;
    } catch (e) {
      debugPrint("Error getting coordinates: $e");
      if (throwOnError) rethrow;
      return _cachedCoordinates;
    }
  }
}