import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String name;
  final LatLng location;

  Place({required this.name, required this.location});

  factory Place.fromJson(Map<String, dynamic> json) {
    final locationData = json['geometry']?['location'];
    if (locationData == null) {
      throw Exception('Invalid place data format');
    }
    return Place(
      name: json['name'] ?? 'Unnamed Place',
      location: LatLng(locationData['lat'], locationData['lng']),
    );
  }
}
