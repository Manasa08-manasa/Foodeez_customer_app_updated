import '../core/constants/env.dart';

/// API configuration — mirrors foodeez customer web [Env] / api.ts.
class ApiConfig {
  ApiConfig._();

  static String get defaultBaseUrl => Env.apiBaseUrl;
  static String get customerBaseUrl => Env.customerApiBaseUrl;

  static String get backendOrigin =>
      defaultBaseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  /// Fallback when GPS is unavailable — matches a known working nearby call.
  static const double fallbackLat = 17.434933173394903;
  static const double fallbackLng = 78.38825416305876;

  /// Live device (or last-known) coordinates used by discovery/search.
  static double lat = fallbackLat;
  static double lng = fallbackLng;
  static String locationLabel = 'Finding your location…';
  static bool locationReady = false;

  static void setLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    lat = latitude;
    lng = longitude;
    if (label != null && label.isNotEmpty) locationLabel = label;
    locationReady = true;
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
