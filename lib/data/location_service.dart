import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'mock_fuel_repository.dart';

class UserLocation {
  const UserLocation(
    this.position, {
    required this.label,
    this.isFallback = false,
  });

  final LatLng position;
  final String label;

  /// `true` quando il GPS non è disponibile e si usa una posizione di default.
  final bool isFallback;
}

abstract interface class LocationService {
  Future<UserLocation> current();
}

class GeolocatorLocationService implements LocationService {
  static const _fallback = UserLocation(
    MockFuelRepository.defaultCenter,
    label: 'Milano · posizione di esempio',
    isFallback: true,
  );

  @override
  Future<UserLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return _fallback;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // TODO: nome della zona con il reverse geocoding.
      return UserLocation(
        LatLng(p.latitude, p.longitude),
        label: 'La tua posizione',
      );
    } catch (_) {
      return _fallback;
    }
  }
}

/// Posizione fissa, per i test e le anteprime.
class FixedLocationService implements LocationService {
  const FixedLocationService([
    this.location = const UserLocation(
      MockFuelRepository.defaultCenter,
      label: 'Milano · Città Studi',
    ),
  ]);

  final UserLocation location;

  @override
  Future<UserLocation> current() async => location;
}
