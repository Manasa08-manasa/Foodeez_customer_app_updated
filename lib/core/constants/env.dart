/// Runtime environment configuration via `--dart-define`.
///
/// Mirrors the website (`new_frontend` `lib/api.ts`):
/// - Auth: `API_BASE_URL` (default production customer gateway)
/// - Customer REST: `CUSTOMER_API_URL` (falls back to API_BASE_URL)
class Env {
  Env._();

  static const String productionApiBaseUrl =
      'https://int.foodeez.in/customer/api/v1';

  static const String apiBaseUrl = productionApiBaseUrl;

  static String get customerApiBaseUrl => apiBaseUrl;

  /// Google Maps / Geocoding key (restrict in Google Cloud Console).
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyDW9niCHIcWO0h096PG7ES8MMw8o9cliAU',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: true,
  );

  static bool get isProductionHost =>
      apiBaseUrl.startsWith('https://int.foodeez.in') ||
      customerApiBaseUrl.startsWith('https://int.foodeez.in');
}
