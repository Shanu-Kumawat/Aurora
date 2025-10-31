import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../models/route.dart';

/// Routing provider using OSRM on Raspberry Pi
class OsrmRoutingProvider {
  static final OsrmRoutingProvider _instance = OsrmRoutingProvider._internal();
  factory OsrmRoutingProvider() => _instance;
  OsrmRoutingProvider._internal();

  /// Get a route from start to end using Pi's OSRM server
  Future<NavigationRoute?> getRoute(LatLng start, LatLng end) async {
    try {
      final url =
          '${AppConstants.piOsrmUrl}/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          return NavigationRoute.fromOsrmJson(data);
        }
      }

      return null;
    } catch (e) {
      print('OSRM routing error: $e');
      return null;
    }
  }
}
