
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitalwatch/models/authority.dart';
import 'package:vitalwatch/screens/map_screen.dart';
import 'package:vitalwatch/services/nearby_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSosOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text('Police / Law Enforcement'),
              onTap: () => _handleSosOption(context, 'Police'),
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text('Medical / Ambulance'),
              onTap: () => _handleSosOption(context, 'Medical'),
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.orange),
              title: const Text('Fire & Rescue'),
              onTap: () => _handleSosOption(context, 'Fire'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Personal Contact'),
              onTap: () => _handleSosOption(context, 'Personal Contact'),
            ),
          ],
        );
      },
    );
  }

  void _handleSosOption(BuildContext context, String category) async {
    Navigator.pop(context); // Close the bottom sheet

    try {
      Position position = await _determinePosition();
      NearbyService nearbyService = NearbyService();
      List<Authority> authorities = await nearbyService.getNearbyAuthorities(category);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            userLocation: LatLng(position.latitude, position.longitude),
            authorities: authorities,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ping sent to nearest $category!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VitalWatch'),
      ),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: ElevatedButton(
            onPressed: () => _showSosOptions(context),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'SOS',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
