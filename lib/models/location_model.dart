class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}