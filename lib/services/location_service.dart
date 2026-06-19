import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<List<String>> getCoordinates({
    bool requestPermission = true,
    bool throwOnError = true,
  }) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (throwOnError) throw Exception("Location services disabled");
        return ["0.0", "0.0"];
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (throwOnError) throw Exception("Location permission denied");
        return ["0.0", "0.0"];
      }

      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return [
          lastPosition.latitude.toString(),
          lastPosition.longitude.toString(),
        ];
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      return [
        position.latitude.toString(),
        position.longitude.toString(),
      ];
    } catch (e) {
      debugPrint("Error getting coordinates: $e");
      if (throwOnError) rethrow;
      return ["0.0", "0.0"];
    }
  }
}