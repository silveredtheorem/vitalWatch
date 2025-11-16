
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vitalwatch/config.dart';
import 'package:vitalwatch/models/place.dart';
import 'package:vitalwatch/screens/map_ping_screen.dart';
import 'package:vitalwatch/screens/contacts_screen.dart';
import 'package:vitalwatch/screens/logs_screen.dart';
import 'package:vitalwatch/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseFunctions.instanceFor(region: 'us-central1').useFunctionsEmulator(AppConfig.emulatorHost, 5001);
  FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.emulatorHost, 8085);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitalWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _accelerometerSubscription;
  bool _isFallDialogShowing = false;
  bool _isFallDetectionEnabled = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const double FREE_FALL_THRESHOLD = 1.0;
  static const double IMPACT_THRESHOLD = 20.0;
  bool _inFreeFall = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFallDetectionEnabled = prefs.getBool('fallDetection') ?? true;
      if (_isFallDetectionEnabled) {
        _startFallDetection();
      }
    });
  }

  Future<void> _toggleFallDetection(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fallDetection', enabled);
    setState(() {
      _isFallDetectionEnabled = enabled;
      if (enabled) {
        _startFallDetection();
      } else {
        _stopFallDetection();
      }
    });
  }

  void _startFallDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final double force = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      if (force < FREE_FALL_THRESHOLD) {
        _inFreeFall = true;
      } else if (_inFreeFall && force > IMPACT_THRESHOLD) {
        _inFreeFall = false;
        if (!_isFallDialogShowing) {
          _showFallDetectionDialog();
        }
      }
    });
  }

  void _stopFallDetection() {
    _accelerometerSubscription?.cancel();
  }

  void _showFallDetectionDialog() {
    _isFallDialogShowing = true;
    _audioPlayer.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return FallCountdownDialog(
          onSafe: () {
            _audioPlayer.stop();
            Navigator.of(dialogContext).pop();
            _isFallDialogShowing = false;
          },
          onSos: () {
            _audioPlayer.stop();
            Navigator.of(dialogContext).pop();
            _isFallDialogShowing = false;
            _handleAuthorityPing(context, 'Medical');
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  List<Widget> get _widgetOptions => <Widget>[
        const HomeScreen(),
        const ContactsScreen(),
        const LogsScreen(),
        SettingsScreen(
          isFallDetectionEnabled: _isFallDetectionEnabled,
          onToggleFallDetection: _toggleFallDetection,
        ),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Logs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      );
  }
}

class FallCountdownDialog extends StatefulWidget {
  final VoidCallback onSafe;
  final VoidCallback onSos;

  const FallCountdownDialog({super.key, required this.onSafe, required this.onSos});

  @override
  State<FallCountdownDialog> createState() => _FallCountdownDialogState();
}

class _FallCountdownDialogState extends State<FallCountdownDialog> {
  int _countdown = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        widget.onSos();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            const Text('Potential Fall Detected!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Text('Sending SOS in $_countdown seconds...', style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                widget.onSafe();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
              child: const Text("I'm Safe", style: TextStyle(fontSize: 20, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VitalWatch'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () => _showSosOptions(context),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Colors.red, Color.fromARGB(255, 139, 0, 0)],
                  center: Alignment.center,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 56,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showSosOptions(BuildContext homeScreenContext) {
  showModalBottomSheet(
    context: homeScreenContext,
    builder: (bottomSheetContext) {
      Widget sosTile(String type, IconData icon, Color color, VoidCallback onTap) {
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(type),
          onTap: () {
            Navigator.pop(bottomSheetContext);
            onTap();
          },
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            sosTile('Police', Icons.local_police, Colors.blue, () => _handleAuthorityPing(homeScreenContext, 'Police')),
            sosTile('Fire', Icons.local_fire_department, Colors.orange, () => _handleAuthorityPing(homeScreenContext, 'Fire')),
            sosTile('Medical', Icons.local_hospital, Colors.red, () => _handleAuthorityPing(homeScreenContext, 'Medical')),
          ],
        ),
      );
    },
  );
}

void _handleAuthorityPing(BuildContext context, String type) async {
  try {
    final position = await _getCurrentLocation();
    final result = await sendPing(type, position.latitude, position.longitude);

    final List<dynamic> placesData = result.data['nearbyPlaces'] ?? [];
    final List<Place> nearbyPlaces = placesData
        .map((data) => Place.fromJson(Map<String, dynamic>.from(data)))
        .toList();
        
    final String sessionId = result.data['sessionId'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPingScreen(
          userLocation: LatLng(position.latitude, position.longitude),
          nearbyPlaces: nearbyPlaces,
          sessionId: sessionId,
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

Future<HttpsCallableResult> sendPing(String type, double lat, double lon) async {
  try {
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('sendEmergencyPing');
    final result = await callable.call({
      'type': type,
      'latitude': lat,
      'longitude': lon,
    });

    print('SOS sent: ${result.data}');
    return result;
  } catch (e) {
    print('Error sending ping: $e');
    rethrow;
  }
}

Future<Position> _getCurrentLocation() async {
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
