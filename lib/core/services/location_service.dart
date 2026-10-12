import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final double accuracyMeters;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    required this.accuracyMeters,
  });
}

class LocationService {
  /// Requests permission, gets current GPS position, and reverse-geocodes
  /// it into a human-readable address + city.
  static Future<LocationResult> getCurrentLocationWithAddress() async {
    // 1. Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }


    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Enable it in app settings.');
    }


    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    
    String? address;
    String? city;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = [p.street, p.subLocality, p.locality]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
        city = p.locality ?? p.subAdministrativeArea;
      }
    } catch (_) {
      // Reverse geocoding failed (e.g. no internet) — GPS coords are still valid,
      // just leave address/city null and let the user fill manually.
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      city: city,
      accuracyMeters: position.accuracy,
    );
  }
}