import 'package:latlong2/latlong.dart';

/// Represents a navigation route
class NavigationRoute {
  final List<LatLng> coordinates;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  NavigationRoute({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  factory NavigationRoute.fromOsrmJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    final geometry = route['geometry'];

    // Parse coordinates from geometry
    List<LatLng> coords = [];
    if (geometry is Map && geometry['coordinates'] != null) {
      for (var coord in geometry['coordinates']) {
        coords.add(LatLng(coord[1], coord[0]));
      }
    }

    // Parse steps
    List<RouteStep> steps = [];
    if (route['legs'] != null && route['legs'].isNotEmpty) {
      final leg = route['legs'][0];
      if (leg['steps'] != null) {
        for (var stepData in leg['steps']) {
          steps.add(RouteStep.fromOsrmJson(stepData));
        }
      }
    }

    return NavigationRoute(
      coordinates: coords,
      distanceMeters: route['distance']?.toDouble() ?? 0.0,
      durationSeconds: route['duration']?.toDouble() ?? 0.0,
      steps: steps,
    );
  }

  factory NavigationRoute.fromOpenRouteServiceJson(Map<String, dynamic> json) {
    print('DEBUG: Parsing OpenRouteService JSON response');
    print('DEBUG: JSON keys: ${json.keys.toList()}');
    
    // Check if response has features
    if (json['features'] == null || json['features'].isEmpty) {
      print('ERROR: No features in response');
      throw Exception('Invalid OpenRouteService response: no features');
    }
    
    final route = json['features'][0];
    final geometry = route['geometry'];
    final properties = route['properties'];

    // Parse coordinates
    List<LatLng> coords = [];
    if (geometry['coordinates'] != null) {
      for (var coord in geometry['coordinates']) {
        coords.add(LatLng(coord[1], coord[0]));
      }
    }

    // Parse steps
    List<RouteStep> steps = [];
    if (properties['segments'] != null && properties['segments'].isNotEmpty) {
      final segment = properties['segments'][0];
      if (segment['steps'] != null) {
        for (var stepData in segment['steps']) {
          steps.add(RouteStep.fromOpenRouteServiceJson(stepData, coords));
        }
      }
    }

    print('DEBUG: Parsed ${coords.length} coordinates and ${steps.length} steps');

    return NavigationRoute(
      coordinates: coords,
      distanceMeters: properties['summary']['distance']?.toDouble() ?? 0.0,
      durationSeconds: properties['summary']['duration']?.toDouble() ?? 0.0,
      steps: steps,
    );
  }
}

/// Represents a step in a navigation route
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng location;

  RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
  });

  factory RouteStep.fromOsrmJson(Map<String, dynamic> json) {
    final location = json['maneuver']['location'];
    return RouteStep(
      instruction: json['maneuver']['modifier'] ?? 'continue',
      distanceMeters: json['distance']?.toDouble() ?? 0.0,
      durationSeconds: json['duration']?.toDouble() ?? 0.0,
      location: LatLng(location[1], location[0]),
    );
  }

  factory RouteStep.fromOpenRouteServiceJson(
      Map<String, dynamic> json, List<LatLng> routeCoordinates) {
    print('DEBUG: Parsing step - instruction: ${json['instruction']}, distance: ${json['distance']}, duration: ${json['duration']}');
    print('DEBUG: way_points: ${json['way_points']}');
    
    // way_points is an array of indices like [0, 3]
    // We need to get the coordinate at the first waypoint index
    LatLng location = LatLng(0.0, 0.0);
    if (json['way_points'] != null && 
        json['way_points'].isNotEmpty && 
        routeCoordinates.isNotEmpty) {
      final waypointIndex = json['way_points'][0] as int;
      if (waypointIndex < routeCoordinates.length) {
        location = routeCoordinates[waypointIndex];
      }
    }
    
    return RouteStep(
      instruction: json['instruction'] ?? 'continue',
      distanceMeters: json['distance']?.toDouble() ?? 0.0,
      durationSeconds: json['duration']?.toDouble() ?? 0.0,
      location: location,
    );
  }
}
