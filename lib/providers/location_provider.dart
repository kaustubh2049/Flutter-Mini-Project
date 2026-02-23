import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';

final locationProvider = FutureProvider<LocationResult>((ref) async {
  return LocationService.instance.getCurrentLocation();
});
