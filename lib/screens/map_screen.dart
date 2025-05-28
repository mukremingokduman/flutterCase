import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late GoogleMapController _mapController;
  late LocationService _locationService;
  bool _isInitialized = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(ref);
    _initialize();
    WakelockPlus.enable();
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationProvider);
    final isTracking = ref.watch(isTrackingProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Konum Takip Uygulaması'),
        actions: [
          IconButton(
            icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
            onPressed: () {
              if (isTracking) {
                _locationService.stopTracking();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rota durduruldu')),
                );
              } else {
                _locationService.startTracking();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rota başlatıldı')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: _isInitialized
          ? GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: LatLng(41.015137, 28.979530), // İstanbul
                zoom: 17,
              ),
              markers: _buildMarkers(locations),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
            )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMapToCurrentLocation,
        child: Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _initialize() async {
    try {
      final hasPermission = await _locationService.checkPermissions();
      if (hasPermission && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerMapToCurrentLocation();
        });
      }
      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _centerMapToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (_isMapReady && mounted) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum alınamadı: ${e.toString()}')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    if (_isInitialized) {
      _centerMapToCurrentLocation();
    }
  }

  Set<Marker> _buildMarkers(List<LocationModel> locations) {
    final markers = locations.map((location) {
      return Marker(
        markerId: MarkerId(location.timestamp.toString()),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: 'Konum',
          snippet:
              'Latitude: ${location.latitude},\nLongitude: ${location.longitude},\nAdress: ${location.address ?? ''}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }).toSet();

    if (markers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMapToLastLocation();
      });
    }

    return markers;
  }

  Future<void> _centerMapToLastLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (_isMapReady && mounted) {
        _mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum alınamadı: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Silme Onayı'),
          content: const Text(
            'Tüm konum verilerini silmek istediğinize emin misiniz?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil'),
              onPressed: () {
                _locationService.stopTracking();
                ref.read(locationProvider.notifier).clearLocations();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konum verileri silindi')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}
