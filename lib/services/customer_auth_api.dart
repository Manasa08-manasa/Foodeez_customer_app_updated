import '../core/constants/api_endpoints.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Mirrors `customerAuthApi` in new_frontend / foodeez_customer.
///
/// Public endpoints go through [defaultApi]; guarded endpoints use [customerApi].
class CustomerAuthApi {
  CustomerAuthApi._();

  // ── Public — no token required ─────────────────────────────────────────────

  /// POST /customer/auth/send-otp
  /// purpose: 'SIGNUP' | 'LOGIN' (email) or 'RESET_PASSWORD' (phone)
  static Future<dynamic> sendOtp({
    String? email,
    String? phone,
    required String purpose,
  }) =>
      defaultApi.post(ApiEndpoints.sendOtp, data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'purpose': purpose,
      });

  /// POST /customer/auth/signup
  static Future<dynamic> signup({
    required String email,
    required String phone,
    required String otp,
    String? name,
    String? referralCode,
    String? deviceId,
    String? deviceName,
  }) async {
    final res = await defaultApi.post(ApiEndpoints.signup, data: {
      'email': email,
      'phone': phone,
      'otp': otp,
      if (name != null) 'name': name,
      if (referralCode != null) 'referralCode': referralCode,
      'deviceId': deviceId ?? await TokenStore.deviceId(),
      if (deviceName != null) 'deviceName': deviceName,
    });
    await _persistTokens(res);
    return res;
  }

  /// POST /customer/auth/login
  static Future<dynamic> login({
    required String email,
    required String otp,
    String? deviceId,
    String? deviceName,
    String? deviceOs,
    String? appVersion,
  }) async {
    final res = await defaultApi.post(ApiEndpoints.login, data: {
      'email': email,
      'otp': otp,
      'deviceId': deviceId ?? await TokenStore.deviceId(),
      if (deviceName != null) 'deviceName': deviceName,
      if (deviceOs != null) 'deviceOs': deviceOs,
      if (appVersion != null) 'appVersion': appVersion,
    });
    await _persistTokens(res);
    return res;
  }

  /// POST /customer/auth/refresh
  static Future<dynamic> refresh() async {
    final rt = TokenStore.refreshToken;
    if (rt == null) throw ApiException('No refresh token stored');
    final res = await defaultApi.post(ApiEndpoints.refresh, data: {
      'refreshToken': rt,
      'deviceId': await TokenStore.deviceId(),
    });
    await _persistTokens(res);
    return res;
  }

  /// POST /customer/auth/reset-password
  static Future<dynamic> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) =>
      defaultApi.post(ApiEndpoints.resetPassword,
          data: {'phone': phone, 'otp': otp, 'newPassword': newPassword});

  // ── Guarded — requires customer JWT ────────────────────────────────────────

  /// POST /customer/auth/logout
  static Future<dynamic> logout({String? deviceId}) async {
    try {
      return await customerApi.post(ApiEndpoints.logout,
          data: {'deviceId': deviceId ?? 'default'});
    } finally {
      await TokenStore.clear();
    }
  }

  /// POST /customer/auth/logout-all
  static Future<dynamic> logoutAll() async {
    try {
      return await customerApi.post(ApiEndpoints.logoutAll);
    } finally {
      await TokenStore.clear();
    }
  }

  /// GET /customer/auth/sessions
  static Future<dynamic> getSessions() =>
      customerApi.get(ApiEndpoints.sessions);

  /// DELETE /customer/auth/sessions/{deviceId}
  static Future<dynamic> revokeSession(String deviceId) =>
      customerApi.delete(ApiEndpoints.revokeSession(deviceId));

  static Future<void> _persistTokens(dynamic res) async {
    if (res is! Map) return;
    final data = res['data'] is Map ? res['data'] as Map : res;
    final tokens = data['tokens'] is Map ? data['tokens'] as Map : data;
    final access =
        tokens['accessToken'] ?? tokens['token'] ?? tokens['access_token'];
    final refresh = tokens['refreshToken'] ?? tokens['refresh_token'];
    if (access != null || refresh != null) {
      await TokenStore.saveTokens(
        accessToken: access?.toString(),
        refreshToken: refresh?.toString(),
      );
    }
  }
}
