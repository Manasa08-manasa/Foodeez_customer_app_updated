import 'package:shared_preferences/shared_preferences.dart';

/// Persists the customer JWT — the Flutter equivalent of
/// `localStorage.getItem('customer_auth_token')` in api.ts.
class TokenStore {
  TokenStore._();

  /// Same key name the web frontend uses (`CUSTOMER_TOKEN_KEY`).
  static const String customerTokenKey = 'customer_auth_token';
  static const String refreshTokenKey = 'customer_refresh_token';
  static const String deviceIdKey = 'customer_device_id';

  static String? _cachedToken;
  static String? _cachedRefresh;

  static String? get token => _cachedToken;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(customerTokenKey);
    _cachedRefresh = prefs.getString(refreshTokenKey);
  }

  static Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      _cachedToken = accessToken;
      await prefs.setString(customerTokenKey, accessToken);
    }
    if (refreshToken != null) {
      _cachedRefresh = refreshToken;
      await prefs.setString(refreshTokenKey, refreshToken);
    }
  }

  static String? get refreshToken => _cachedRefresh;

  static Future<void> clear() async {
    _cachedToken = null;
    _cachedRefresh = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(customerTokenKey);
    await prefs.remove(refreshTokenKey);
  }

  static bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Stable per-install device id sent with login/signup (mirrors the
  /// `deviceId` field in the web payloads).
  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(deviceIdKey);
    if (id == null) {
      id = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(deviceIdKey, id);
    }
    return id;
  }
}
