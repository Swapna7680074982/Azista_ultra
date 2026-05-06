import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

class DirectionsMapScreen extends StatefulWidget {
  final double outletLat;
  final double outletLng;
  final String outletName;

  const DirectionsMapScreen({
    super.key,
    required this.outletLat,
    required this.outletLng,
    required this.outletName,
  });

  @override
  State<DirectionsMapScreen> createState() => _DirectionsMapScreenState();
}

class _DirectionsMapScreenState extends State<DirectionsMapScreen> {
  LatLng? currentLatLng;
  late LatLng outletLatLng;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    outletLatLng = LatLng(widget.outletLat, widget.outletLng);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLatLng = LatLng(position.latitude, position.longitude);
    });

    _moveCamera();
  }

  void _moveCamera() {
    if (mapController == null || currentLatLng == null) return;

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            currentLatLng!.latitude < outletLatLng.latitude
                ? currentLatLng!.latitude
                : outletLatLng.latitude,
            currentLatLng!.longitude < outletLatLng.longitude
                ? currentLatLng!.longitude
                : outletLatLng.longitude,
          ),
          northeast: LatLng(
            currentLatLng!.latitude > outletLatLng.latitude
                ? currentLatLng!.latitude
                : outletLatLng.latitude,
            currentLatLng!.longitude > outletLatLng.longitude
                ? currentLatLng!.longitude
                : outletLatLng.longitude,
          ),
        ),
        80,
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.outletLat},${widget.outletLng}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Google Maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.outletName.toUpperCase(),
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: outletLatLng,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (controller) {
          mapController = controller;
          if (currentLatLng != null) {
            _moveCamera();
          }
        },
        markers: {
          if (currentLatLng != null)
            Marker(
              markerId: const MarkerId("current"),
              position: currentLatLng!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          Marker(
            markerId: const MarkerId("outlet"),
            position: outletLatLng,
          ),
        },
        circles: {
          if (currentLatLng != null)
            Circle(
              circleId: const CircleId("accuracy"),
              center: currentLatLng!,
              radius: 50,
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 1,
            ),
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _launchGoogleMaps,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.directions, color: Colors.white),
        label: const Text("GET DIRECTIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}