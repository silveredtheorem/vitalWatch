
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vitalwatch/models/authority.dart';

class MapScreen extends StatefulWidget {
  final LatLng userLocation;
  final List<Authority> authorities;

  const MapScreen({
    super.key,
    required this.userLocation,
    required this.authorities,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Map'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: widget.userLocation,
          zoom: 14.0,
        ),
        markers: _createMarkers(),
      ),
    );
  }

  Set<Marker> _createMarkers() {
    var markers = <Marker>{
      Marker(
        markerId: const MarkerId('userLocation'),
        position: widget.userLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      )
    };

    for (var authority in widget.authorities) {
      markers.add(
        Marker(
          markerId: MarkerId(authority.name),
          position: authority.location,
          infoWindow: InfoWindow(title: authority.name, snippet: authority.type),
        ),
      );
    }

    return markers;
  }
}

