import 'dart:async';
import '../constants/app_constants.dart';
import '../models/route.dart';
import '../providers/online_routing_provider.dart';
import 'geocoding_service.dart';
import 'connectivity_service.dart';
import 'location_service.dart';
import 'audio_manager.dart';

enum NavigationState { idle, geocoding, routing, navigating, paused }

/// Manages navigation using OpenStreetMap and OpenRouteService
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GeocodingService _geocodingService = GeocodingService();
  final OnlineRoutingProvider _onlineProvider = OnlineRoutingProvider();
  final ConnectivityService _connectivityService = ConnectivityService();
  final LocationService _locationService = LocationService();
  final AudioManager _audioManager = AudioManager();

  NavigationRoute? _activeRoute;
  NavigationState _state = NavigationState.idle;
  int _currentStepIndex = 0;
  Timer? _navigationTimer;

  final StreamController<NavigationState> _stateController =
      StreamController<NavigationState>.broadcast();

  Stream<NavigationState> get stateStream => _stateController.stream;
  NavigationState get state => _state;
  NavigationRoute? get activeRoute => _activeRoute;

  /// Start navigation to a destination
  Future<bool> startNavigation(String destination) async {
    // STAGE 1: Geocoding - Find destination coordinates
    _setState(NavigationState.geocoding);

    // Check for internet connectivity
    final hasInternet = await _connectivityService.checkConnectivity();
    if (!hasInternet) {
      await _audioManager.speak('Internet connection required for navigation');
      _setState(NavigationState.idle);
      return false;
    }

    // Geocode the destination using Nominatim
    await _audioManager.speak('Finding $destination');
    print('NavigationService: Starting geocoding for "$destination"');
    final destinationCoords = await _geocodingService.geocode(destination);

    if (destinationCoords == null) {
      print('NavigationService: Geocoding failed for "$destination"');
      await _audioManager.speak('Could not find $destination');
      _setState(NavigationState.idle);
      return false;
    }
    print('NavigationService: Geocoding successful: ${destinationCoords.latitude}, ${destinationCoords.longitude}');

    // Get current location
    final startCoords = await _locationService.getCurrentLocation();
    if (startCoords == null) {
      print('NavigationService: Failed to get current location');
      await _audioManager.speak('Unable to get your current location');
      _setState(NavigationState.idle);
      return false;
    }
    print('NavigationService: Current location: ${startCoords.latitude}, ${startCoords.longitude}');

    // STAGE 2: Routing - Calculate route using OpenRouteService
    _setState(NavigationState.routing);

    await _audioManager.speak('Calculating route');
    print('NavigationService: Calling OpenRouteService routing...');
    final route = await _onlineProvider.getRoute(
      startCoords,
      destinationCoords,
    );

    if (route == null) {
      print('NavigationService: Routing failed - got null route');
      await _audioManager.speak('Could not calculate route');
      _setState(NavigationState.idle);
      return false;
    }
    print('NavigationService: Routing successful - ${route.steps.length} steps, ${route.distanceMeters}m');

    // Start navigation with the calculated route
    _activeRoute = route;
    _currentStepIndex = 0;

    final distanceKm = route.distanceMeters / 1000;
    final durationMin = route.durationSeconds / 60;

    await _audioManager.speak(
      'Route calculated. Distance: ${distanceKm.toStringAsFixed(1)} kilometers. '
      'Estimated time: ${durationMin.toStringAsFixed(0)} minutes. Starting navigation.',
    );

    _startTurnByTurnGuidance();
    _setState(NavigationState.navigating);

    return true;
  }

  /// Start turn-by-turn guidance
  void _startTurnByTurnGuidance() {
    _locationService.startTracking();

    _navigationTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.navigationUpdateIntervalMs),
      (_) => _updateNavigation(),
    );
  }

  /// Update navigation based on current location
  void _updateNavigation() {
    if (_state != NavigationState.navigating || _activeRoute == null) {
      return;
    }

    final currentLocation = _locationService.currentLocation;
    if (currentLocation == null) return;

    final route = _activeRoute!;

    // Check if reached destination
    final destination = route.coordinates.last;
    final distanceToDestination = _locationService.calculateDistance(
      currentLocation,
      destination,
    );

    if (distanceToDestination <= AppConstants.arrivalThresholdMeters) {
      _onArrival();
      return;
    }

    // Check progress through steps
    if (_currentStepIndex < route.steps.length) {
      final currentStep = route.steps[_currentStepIndex];
      final distanceToWaypoint = _locationService.calculateDistance(
        currentLocation,
        currentStep.location,
      );

      if (distanceToWaypoint <= AppConstants.waypointThresholdMeters) {
        _announceStep(currentStep);
        _currentStepIndex++;
      }
    }
  }

  /// Announce a navigation step
  void _announceStep(RouteStep step) {
    final distanceMeters = step.distanceMeters.toInt();
    _audioManager.speak('In $distanceMeters meters, ${step.instruction}');
  }

  /// Handle arrival at destination
  void _onArrival() {
    _audioManager.speak('You have arrived at your destination');
    stopNavigation();
  }

  /// Get current trip status
  Future<String> getTripStatus() async {
    if (_state != NavigationState.navigating || _activeRoute == null) {
      return 'No active navigation';
    }

    final currentLocation = _locationService.currentLocation;
    if (currentLocation == null) {
      return 'Unable to get current location';
    }

    final destination = _activeRoute!.coordinates.last;
    final remainingDistance = _locationService.calculateDistance(
      currentLocation,
      destination,
    );

    final remainingKm = remainingDistance / 1000;
    return 'You have ${remainingKm.toStringAsFixed(1)} kilometers remaining';
  }

  /// Stop navigation
  void stopNavigation() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    _activeRoute = null;
    _currentStepIndex = 0;
    _setState(NavigationState.idle);
    _audioManager.speak('Navigation stopped');
  }

  /// Pause navigation (e.g., when GPS is lost)
  void pauseNavigation() {
    if (_state == NavigationState.navigating) {
      _navigationTimer?.cancel();
      _setState(NavigationState.paused);
    }
  }

  /// Resume navigation
  void resumeNavigation() {
    if (_state == NavigationState.paused && _activeRoute != null) {
      _startTurnByTurnGuidance();
      _setState(NavigationState.navigating);
    }
  }

  /// Set navigation state
  void _setState(NavigationState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Dispose resources
  void dispose() {
    _navigationTimer?.cancel();
    _stateController.close();
  }
}
