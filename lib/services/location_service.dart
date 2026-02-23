import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final String locality; // e.g. "Mahim"
  final String city;     // e.g. "Mumbai"
  final double? lat;
  final double? lng;

  const LocationResult({
    required this.locality,
    required this.city,
    this.lat,
    this.lng,
  });

  String get display => '$locality, $city';

  // Fallback near Mahim, Mumbai
  static const fallback = LocationResult(
    locality: 'Mahim',
    city: 'Mumbai',
    lat: 19.0390,
    lng: 72.8422,
  );
}

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// Returns real location if permission granted, else Mahim fallback.
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return LocationResult.fallback;

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult.fallback;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.fallback;
      }

      // Get position (timeout 8 seconds)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return LocationResult.fallback;

      final place = placemarks.first;
      final locality = place.subLocality?.isNotEmpty == true
          ? place.subLocality!
          : place.locality ?? 'Mahim';
      final city = place.locality?.isNotEmpty == true
          ? place.locality!
          : place.administrativeArea ?? 'Mumbai';

      return LocationResult(
        locality: locality,
        city: city,
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (_) {
      // Any error → Mahim fallback
      return LocationResult.fallback;
    }
  }
}
