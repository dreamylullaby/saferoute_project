import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition();
  }
}