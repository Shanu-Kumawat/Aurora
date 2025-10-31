import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service to manage device location
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();
  final StreamController<bool> _gpsStatusController =
      StreamController<bool>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;
  Stream<bool> get gpsStatusStream => _gpsStatusController.stream;

  LatLng? _currentLocation;
  bool _hasGpsSignal = false;
  bool _isTracking = false;

  LatLng? get currentLocation => _currentLocation;
  bool get hasGpsSignal => _hasGpsSignal;

  /// Request location permission
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location once
  Future<LatLng?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      return _currentLocation;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      print('Location permission not granted');
      return;
    }

    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return;
    }

    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final newLocation = LatLng(position.latitude, position.longitude);
            _currentLocation = newLocation;
            _locationController.add(newLocation);

            // Check GPS signal quality
            final hasSignal =
                position.accuracy <= 50; // Good accuracy under 50m
            if (hasSignal != _hasGpsSignal) {
              _hasGpsSignal = hasSignal;
              _gpsStatusController.add(hasSignal);
            }
          },
          onError: (error) {
            print('Location stream error: $error');
            if (_hasGpsSignal) {
              _hasGpsSignal = false;
              _gpsStatusController.add(false);
            }
          },
        );
  }

  /// Stop location tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calculate bearing between two points
  double calculateBearing(LatLng start, LatLng end) {
    return Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _locationController.close();
    _gpsStatusController.close();
  }
}
