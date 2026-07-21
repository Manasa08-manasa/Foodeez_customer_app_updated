import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/constants/env.dart';
import 'api_config.dart';

/// Resolves device GPS (guest or logged-in) and reverse-geocodes a short label.
class LocationService {
  LocationService._();

  static Future<Position?> currentPosition() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        debugPrint('[Location] services disabled — using fallback coords');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[Location] permission denied — using fallback coords');
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (e) {
      debugPrint('[Location] getCurrentPosition failed: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Updates [ApiConfig] lat/lng + label. Always succeeds with fallback.
  static Future<void> ensureLocation() async {
    final pos = await currentPosition();
    final lat = pos?.latitude ?? ApiConfig.fallbackLat;
    final lng = pos?.longitude ?? ApiConfig.fallbackLng;
    final label = await reverseGeocode(lat, lng) ??
        (pos == null ? 'Hyderabad' : 'Current location');
    ApiConfig.setLocation(latitude: lat, longitude: lng, label: label);
    debugPrint('[Location] using lat=$lat lng=$lng ($label)');
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    // 1) Google Geocoding (same key as Maps)
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '$lat,$lng',
        'key': Env.googleMapsApiKey,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['status'] == 'OK') {
          final results = body['results'];
          if (results is List && results.isNotEmpty) {
            final first = results.first;
            if (first is Map) {
              final comps = first['address_components'];
              String? neighborhood;
              String? sublocality;
              String? locality;
              if (comps is List) {
                for (final c in comps.whereType<Map>()) {
                  final types = c['types'];
                  if (types is! List) continue;
                  final name = c['short_name']?.toString() ?? '';
                  if (types.contains('sublocality') ||
                      types.contains('sublocality_level_1')) {
                    sublocality ??= name;
                  } else if (types.contains('neighborhood')) {
                    neighborhood ??= name;
                  } else if (types.contains('locality')) {
                    locality ??= name;
                  }
                }
              }
              final parts = [
                neighborhood ?? sublocality,
                locality,
              ].whereType<String>().where((s) => s.isNotEmpty).toList();
              if (parts.isNotEmpty) return parts.join(', ');
              final formatted = first['formatted_address']?.toString();
              if (formatted != null && formatted.isNotEmpty) {
                return formatted.split(',').take(2).join(',').trim();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Location] Google geocode failed: $e');
    }

    // 2) Nominatim fallback (same as website layout)
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'json',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'FoodeezCustomerApp/1.0',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map) {
          final addr = body['address'];
          if (addr is Map) {
            final area = (addr['suburb'] ??
                    addr['neighbourhood'] ??
                    addr['residential'] ??
                    addr['city_district'] ??
                    '')
                .toString();
            final city =
                (addr['city'] ?? addr['town'] ?? addr['state'] ?? '').toString();
            final parts = [area, city]
                .where((s) => s.isNotEmpty)
                .toList();
            if (parts.isNotEmpty) return parts.join(', ');
          }
          final display = body['display_name']?.toString();
          if (display != null && display.isNotEmpty) {
            return display.split(',').take(2).join(',').trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[Location] Nominatim failed: $e');
    }
    return null;
  }

  /// Full address fields for checkout (mirrors website cart `useCurrentLocation`).
  static Future<ResolvedAddress> resolveAddressDetails(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'jsonv2',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'FoodeezCustomerApp/1.0',
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map) {
          final addr = body['address'];
          if (addr is Map) {
            final city = (addr['city'] ??
                    addr['town'] ??
                    addr['village'] ??
                    addr['county'] ??
                    addr['state_district'] ??
                    'Your city')
                .toString();
            final exact = [
              addr['house_number'],
              addr['road'],
              addr['suburb'],
              addr['neighbourhood'],
            ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
            final line1 = exact.isNotEmpty
                ? exact
                : (body['display_name']?.toString() ?? 'Current location');
            return ResolvedAddress(
              addressLine1: line1,
              city: city,
              state: (addr['state'] ?? '').toString(),
              pincode: (addr['postcode'] ?? '').toString(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[Location] resolveAddressDetails failed: $e');
    }

    final label = await reverseGeocode(lat, lng) ?? 'Current location';
    return ResolvedAddress(
      addressLine1: label,
      city: 'Your city',
      state: '',
      pincode: '',
    );
  }
}

class ResolvedAddress {
  const ResolvedAddress({
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
  });

  final String addressLine1;
  final String city;
  final String state;
  final String pincode;
}
