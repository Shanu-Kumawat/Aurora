import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/navigation_service.dart';
import '../services/location_service.dart';
import '../models/route.dart';

/// Navigation screen with map and turn-by-turn guidance
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationService _navigationService = NavigationService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  NavigationRoute? _route;
  LatLng? _currentLocation;
  int _currentStepIndex = 0;
  double _remainingDistance = 0;
  Timer? _updateTimer;
  bool _autoCenter = true; // Auto-center on user location

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  void _initializeNavigation() {
    _route = _navigationService.activeRoute;
    _currentLocation = _locationService.currentLocation;

    // Update UI every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentLocation = _locationService.currentLocation;
        _updateNavigationProgress();
      });

      // Center map on current location only if auto-center is enabled
      if (_autoCenter && _currentLocation != null) {
        _mapController.move(_currentLocation!, _mapController.camera.zoom);
      }
    });

    // Listen to navigation state changes
    _navigationService.stateStream.listen((state) {
      if (state == NavigationState.idle && mounted) {
        // Navigation finished or cancelled, go back
        Navigator.of(context).pop();
      }
    });
  }

  void _updateNavigationProgress() {
    if (_route == null || _currentLocation == null) return;

    final destination = _route!.coordinates.last;
    _remainingDistance = _locationService.calculateDistance(
      _currentLocation!,
      destination,
    );

    // Update current step index based on proximity
    if (_currentStepIndex < _route!.steps.length) {
      final currentStep = _route!.steps[_currentStepIndex];
      final distanceToWaypoint = _locationService.calculateDistance(
        _currentLocation!,
        currentStep.location,
      );

      if (distanceToWaypoint <= 20) {
        // Passed this waypoint
        _currentStepIndex++;
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_route == null || _currentLocation == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Loading navigation...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final currentStep = _currentStepIndex < _route!.steps.length
        ? _route!.steps[_currentStepIndex]
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // Map view
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 17.0,
              minZoom: 10.0,
              maxZoom: 19.0,
              keepAlive: true,
              // Disable auto-center when user manually pans the map
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _autoCenter = false;
                  });
                }
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aurora',
                maxZoom: 19,
              ),

              // Route polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route!.coordinates,
                    strokeWidth: 5.0,
                    color: Colors.blue.withOpacity(0.7),
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // Current location marker
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Destination marker
                  Marker(
                    point: _route!.coordinates.last,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top instruction panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current instruction
                    if (currentStep != null) ...[
                      Row(
                        children: [
                          Icon(
                            _getInstructionIcon(currentStep.instruction),
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${currentStep.distanceMeters.toInt()}m',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentStep.instruction,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                    ],

                    // Trip info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REMAINING',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${(_remainingDistance / 1000).toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'ETA',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              _calculateETA(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Cancel navigation button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _navigationService.stopNavigation();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text(
                          'STOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Recenter button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentLocation != null) {
                          setState(() {
                            _autoCenter = true; // Re-enable auto-center
                          });
                          _mapController.move(_currentLocation!, 17.0);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _autoCenter ? Colors.blue : Colors.grey.shade600,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon for instruction
  IconData _getInstructionIcon(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('left')) return Icons.turn_left;
    if (lower.contains('right')) return Icons.turn_right;
    if (lower.contains('straight') || lower.contains('continue')) {
      return Icons.straight;
    }
    if (lower.contains('arrive')) return Icons.flag;
    return Icons.navigation;
  }

  /// Calculate ETA based on remaining distance and average walking speed
  String _calculateETA() {
    const walkingSpeedKmh = 5.0; // Average walking speed
    final remainingKm = _remainingDistance / 1000;
    final remainingHours = remainingKm / walkingSpeedKmh;
    final remainingMinutes = (remainingHours * 60).round();

    if (remainingMinutes < 1) return '< 1 min';
    if (remainingMinutes < 60) return '$remainingMinutes min';

    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
