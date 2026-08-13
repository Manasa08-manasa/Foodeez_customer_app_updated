import '../core/constants/env.dart';

/// API configuration — mirrors foodeez customer web [Env] / api.ts.
class ApiConfig {
  ApiConfig._();

  static String get defaultBaseUrl => Env.apiBaseUrl;
  static String get customerBaseUrl => Env.customerApiBaseUrl;

  static String get backendOrigin =>
      defaultBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  /// INT nearby restaurants live around this Hyderabad pin.
  static const double fallbackLat = 17.434897863129663;
  static const double fallbackLng = 78.38829382541574;

  /// Live device (or last-known) coordinates used by discovery/search.
  static double lat = fallbackLat;
  static double lng = fallbackLng;
  static String locationLabel = 'Finding your location…';
  static bool locationReady = false;

  /// When true, [LocationService.ensureLocation] must not overwrite with GPS
  /// (user picked saved place / search / map pin for Home).
  static bool locationManual = false;

  static void setLocation({
    required double latitude,
    required double longitude,
    String? label,
    bool? manual,
  }) {
    lat = latitude;
    lng = longitude;
    if (label != null && label.isNotEmpty) locationLabel = label;
    locationReady = true;
    if (manual != null) locationManual = manual;
  }

  static const Duration timeout = Duration(seconds: 20);
}

String? resolveMediaUrl(String? mediaPath) {
  if (mediaPath == null || mediaPath.isEmpty) return null;
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(mediaPath) ||
      mediaPath.startsWith('//')) {
    return mediaPath;
  }
  final sep = mediaPath.startsWith('/') ? '' : '/';
  return '${ApiConfig.backendOrigin}$sep$mediaPath';
}
