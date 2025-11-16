
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vitalwatch/models/place.dart';

class MapPingScreen extends StatefulWidget {
  final LatLng userLocation;
  final List<Place> nearbyPlaces;
  final String sessionId;

  const MapPingScreen({
    super.key,
    required this.userLocation,
    required this.nearbyPlaces,
    required this.sessionId,
  });

  @override
  State<MapPingScreen> createState() => _MapPingScreenState();
}

class _MapPingScreenState extends State<MapPingScreen> with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Position>? _positionStreamSubscription;

  late AnimationController _pingAnimationController;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _startPingAnimation();
    _startAlarmSound();
    _startLiveLocationTracking();
  }

  void _startLiveLocationTracking() {
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      print("Live location update: ${position.latitude}, ${position.longitude}");
      // Update the user's marker on the map
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'userLocation');
        _markers.add(
          Marker(
            markerId: const MarkerId('userLocation'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });

      // Animate map to the new location
      _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );

      // Update the session in Firestore
      if (widget.sessionId.isNotEmpty) {
        FirebaseFirestore.instance.collection('sos_sessions').doc(widget.sessionId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    });
  }


  void _startPingAnimation() {
    _pingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pingAnimationController.addListener(() {
      setState(() {
        _updatePingCircle();
      });
    });

    _pingAnimationController.repeat();
  }

  void _startAlarmSound() {
    _audioPlayer.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _updatePingCircle() {
    _circles.clear();
    double animationValue = _pingAnimationController.value;
    double radius = 1000 * animationValue; // Max radius of 1km
    double opacity = 1.0 - animationValue;

    _circles.add(
      Circle(
        circleId: const CircleId('ping_circle'),
        center: widget.userLocation,
        radius: radius,
        fillColor: Colors.red.withOpacity(0.3 * opacity),
        strokeColor: Colors.red.withOpacity(opacity),
        strokeWidth: 2,
      ),
    );
  }

  void _setupMarkers() {
    // User's location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('userLocation'),
        position: widget.userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // Nearby places markers
    for (final place in widget.nearbyPlaces) {
      _markers.add(
        Marker(
          markerId: MarkerId(place.name),
          position: place.location,
          infoWindow: InfoWindow(title: place.name),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pingAnimationController.dispose();
    _audioPlayer.dispose();
    _positionStreamSubscription?.cancel();
    // End the live session in Firestore
    if (widget.sessionId.isNotEmpty) {
      FirebaseFirestore.instance.collection('sos_sessions').doc(widget.sessionId).update({
        'isActive': false,
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinging Nearby Authorities')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.userLocation,
          zoom: 13,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        circles: _circles, // Use the circles property to draw the animation
      ),
    );
  }
}
