import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

final locationProvider =
    StateNotifierProvider<LocationNotifier, List<LocationModel>>(
      (ref) => LocationNotifier(),
    );

class LocationNotifier extends StateNotifier<List<LocationModel>> {
  LocationNotifier() : super([]) {
    loadLocations();
  }

  static const String _locationsKey = 'saved_locations';

  Future<void> loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList(_locationsKey);
    if (savedData != null) {
      state = savedData
          .map((e) => LocationModel.fromMap(json.decode(e)))
          .toList();
    }
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _locationsKey,
      state.map((e) => json.encode(e.toMap())).toList(),
    );
  }

  Future<void> addLocation(LocationModel point) async {
    state = [...state, point];
    await _saveLocations();
  }

  Future<void> clearLocations() async {
    state = [];
    await _saveLocations();
  }
}

final isTrackingProvider = StateProvider<bool>((ref) => false);
