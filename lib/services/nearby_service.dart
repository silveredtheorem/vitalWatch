
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitalwatch/models/authority.dart';

class NearbyService {
  // TODO: Replace with your actual Google Maps API key
  final String _apiKey = 'YOUR_API_KEY';

  Future<List<Authority>> getNearbyAuthorities(String category) async {
    // Mock implementation
    // In a real app, you would use the Google Places API here.
    print('Fetching nearby authorities for category: $category with API key: $_apiKey');

    // Fake a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Generate some fake authority data
    final random = Random();
    return List.generate(3, (index) {
      return Authority(
        name: '$category Station ${index + 1}',
        type: category,
        location: LatLng(
          37.42796133580664 + (random.nextDouble() - 0.5) * 0.1, // Near Googleplex
          -122.08574865596466 + (random.nextDouble() - 0.5) * 0.1,
        ),
      );
    });
  }
}
