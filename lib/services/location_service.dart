import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<List<String>> getCoordinates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
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
  }

}