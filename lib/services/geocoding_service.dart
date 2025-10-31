import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';

/// Service to convert destination names to coordinates using Nominatim
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Geocode a destination string to coordinates
  Future<LatLng?> geocode(String destination) async {
    try {
      final encodedDestination = Uri.encodeComponent(destination);
      final url =
          '${AppConstants.nominatimUrl}?q=$encodedDestination&format=json&limit=1';

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Aurora/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);

        if (results.isNotEmpty) {
          final result = results[0];
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);

          return LatLng(lat, lon);
        }
      }

      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  /// Reverse geocode coordinates to an address
  Future<String?> reverseGeocode(LatLng location) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?'
          'lat=${location.latitude}&lon=${location.longitude}&format=json';

      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Aurora/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['display_name'] as String?;
      }

      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }
}
