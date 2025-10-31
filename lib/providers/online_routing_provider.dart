import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/api_keys.dart';
import '../models/route.dart';

/// Routing provider using OpenRouteService for online fallback
class OnlineRoutingProvider {
  static final OnlineRoutingProvider _instance =
      OnlineRoutingProvider._internal();
  factory OnlineRoutingProvider() => _instance;
  OnlineRoutingProvider._internal();

  /// Get a route from start to end using OpenRouteService
  Future<NavigationRoute?> getRoute(LatLng start, LatLng end) async {
    // Check if API key is configured
    if (ApiKeys.openRouteServiceKey == 'YOUR_OPENROUTESERVICE_KEY_HERE' ||
        ApiKeys.openRouteServiceKey.isEmpty) {
      print('OpenRouteService API key not configured');
      return null;
    }

    try {
      print('OpenRouteService: Calculating route from $start to $end');

      final url = Uri.parse(
          'https://api.openrouteservice.org/v2/directions/foot-walking/geojson');

      final response = await http.post(
        url,
        headers: {
          'Authorization': ApiKeys.openRouteServiceKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
          'instructions': true,
          'units': 'm',
        }),
      );

      if (response.statusCode == 200) {
        print('OpenRouteService: Route calculation successful');
        final data = jsonDecode(response.body);
        
        // Debug: Print the structure of steps
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          if (feature['properties']?['segments'] != null && 
              feature['properties']['segments'].isNotEmpty) {
            final segment = feature['properties']['segments'][0];
            if (segment['steps'] != null && segment['steps'].isNotEmpty) {
              print('DEBUG: First step structure:');
              print(jsonEncode(segment['steps'][0]));
            }
          }
        }
        
        return NavigationRoute.fromOpenRouteServiceJson(data);
      } else {
        print('OpenRouteService error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('OpenRouteService routing error: $e');
      return null;
    }
  }
}
