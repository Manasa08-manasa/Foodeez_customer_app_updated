import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent location searches for Select Location.
class RecentLocationsStore {
  RecentLocationsStore._();

  static const _key = 'foodeez_recent_location_searches';
  static const _maxItems = 8;

  static List<Map<String, dynamic>> items = [];
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      items = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final lat = e['lat'];
            final lng = e['lng'];
            return lat != null && lng != null;
          })
          .toList();
    } catch (_) {
      items = [];
    }
  }

  static Future<void> add({
    required String name,
    required double lat,
    required double lng,
    String? subtitle,
  }) async {
    await ensureLoaded();
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return;

    items.removeWhere((e) {
      final sameName =
          (e['name']?.toString() ?? '').toLowerCase() == cleanedName.toLowerCase();
      final elat = (e['lat'] as num?)?.toDouble();
      final elng = (e['lng'] as num?)?.toDouble();
      final samePoint = elat != null &&
          elng != null &&
          (elat - lat).abs() < 0.00015 &&
          (elng - lng).abs() < 0.00015;
      return sameName || samePoint;
    });

    items.insert(0, {
      'name': cleanedName,
      'lat': lat,
      'lng': lng,
      if (subtitle != null && subtitle.trim().isNotEmpty)
        'subtitle': subtitle.trim(),
    });

    if (items.length > _maxItems) {
      items = items.take(_maxItems).toList();
    }
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(items));
    } catch (_) {/* ignore */}
  }
}
