import 'package:flutter/material.dart';
import '../services/app_coordinator.dart';
import '../services/command_service.dart';
import '../services/navigation_service.dart';
import '../services/hardware_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_service.dart';
import 'navigation_screen.dart';

/// Main screen with minimal, high-contrast UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppCoordinator _coordinator = AppCoordinator();
  final CommandService _commandService = CommandService();
  final NavigationService _navigationService = NavigationService();
  final HardwareService _hardwareService = HardwareService();
  final LocationService _locationService = LocationService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final TextEditingController _destinationController = TextEditingController();

  NavigationState _navState = NavigationState.idle;
  bool _isHardwareConnected = false;
  bool _hasGpsSignal = false;
  bool _hasInternet = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _coordinator.initialize();

    // Listen to navigation state changes and open navigation screen
    _navigationService.stateStream.listen((state) {
      setState(() {
        _navState = state;
      });

      // Open navigation screen when navigation starts
      if (state == NavigationState.navigating && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const NavigationScreen()),
        );
      }
    });

    _hardwareService.connectionStream.listen((isConnected) {
      setState(() {
        _isHardwareConnected = isConnected;
      });
    });

    _locationService.gpsStatusStream.listen((hasSignal) {
      setState(() {
        _hasGpsSignal = hasSignal;
      });
    });

    _connectivityService.connectivityStream.listen((hasInternet) {
      setState(() {
        _hasInternet = hasInternet;
      });
    });

    // Listen to recognized text for debugging
    _commandService.recognizedTextStream.listen((text) {
      setState(() {
        _recognizedText = text;
      });
    });

    // Update initial states
    setState(() {
      _isHardwareConnected = _hardwareService.isConnected;
      _hasGpsSignal = _locationService.hasGpsSignal;
      _hasInternet = _connectivityService.isConnected;
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Title
                const Text(
                  'AURORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),

              // Status Indicators in a Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusIndicator(
                    'GPS',
                    _hasGpsSignal,
                    Icons.gps_fixed,
                    Icons.gps_off,
                  ),
                  _buildStatusIndicator(
                    'Hardware',
                    _isHardwareConnected,
                    Icons.bluetooth_connected,
                    Icons.bluetooth_disabled,
                  ),
                  _buildStatusIndicator(
                    'Internet',
                    _hasInternet,
                    Icons.wifi,
                    Icons.wifi_off,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Navigation State
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: _getNavigationStateColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getNavigationStateText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Recognized text display (for debugging)
              if (_recognizedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'LISTENING...',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _recognizedText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Manual trigger button (for testing without wake word)
              ElevatedButton(
                onPressed: () => _coordinator.triggerCommandListening(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'TAP TO SPEAK',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Or say "Hey Aurora"',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 12),

              // Divider for testing section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: const Divider(color: Colors.white24, thickness: 1),
              ),

              const SizedBox(height: 12),

              // Testing section label
              const Text(
                'TESTING',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 12),

              // Destination text field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _destinationController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Type destination...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.greenAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Test navigation button
              ElevatedButton.icon(
                onPressed: () async {
                  final destination = _destinationController.text.trim();
                  if (destination.isNotEmpty) {
                    await _navigationService.startNavigation(destination);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a destination'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.navigation, color: Colors.white),
                label: const Text(
                  'START NAVIGATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    String label,
    bool isActive,
    IconData activeIcon,
    IconData inactiveIcon,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isActive ? activeIcon : inactiveIcon,
          color: isActive ? Colors.green : Colors.red,
          size: 32,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getNavigationStateColor() {
    switch (_navState) {
      case NavigationState.idle:
        return Colors.grey.shade800;
      case NavigationState.geocoding:
      case NavigationState.routing:
        return Colors.orange;
      case NavigationState.navigating:
        return Colors.green;
      case NavigationState.paused:
        return Colors.yellow.shade700;
    }
  }

  String _getNavigationStateText() {
    switch (_navState) {
      case NavigationState.idle:
        return 'READY';
      case NavigationState.geocoding:
        return 'FINDING...';
      case NavigationState.routing:
        return 'ROUTING...';
      case NavigationState.navigating:
        return 'NAVIGATING';
      case NavigationState.paused:
        return 'PAUSED';
    }
  }
}
