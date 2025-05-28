import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationService {
  final WidgetRef ref;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;

  LocationService(this.ref);

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void startTracking() {
    ref.read(isTrackingProvider.notifier).state = true;
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 100,
          ),
        ).listen((Position position) async {
          if (_lastPosition == null ||
              Geolocator.distanceBetween(
                    _lastPosition!.latitude,
                    _lastPosition!.longitude,
                    position.latitude,
                    position.longitude,
                  ) >=
                  100) {
            final address = await getAddressFromLatLng(
              position.latitude,
              position.longitude,
            );

            ref
                .read(locationProvider.notifier)
                .addLocation(
                  LocationModel(
                    latitude: position.latitude,
                    longitude: position.longitude,
                    address: address,
                    timestamp: DateTime.now(),
                  ),
                );

            _lastPosition = position;
          }
        });
  }

  void stopTracking() {
    ref.read(isTrackingProvider.notifier).state = false;
    _positionStream?.cancel();
    _positionStream = null;
    _lastPosition = null;
  }

  void dispose() {
    _positionStream?.cancel();
  }
}
