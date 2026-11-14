class AppConfig {
  const AppConfig._();

  /// Production Azure Gateway URL (routed via service-backend)
  static const azureApiBaseUrl =
      'https://app-service-api-c3hwa9dpeggseyb5.centralindia-01.azurewebsites.net/automobile/api/v1';

  /// Local development endpoint URL
  static const localApiBaseUrl = 'http://localhost:5053/api/v1';

  /// Active Base URL resolved via `--dart-define=API_BASE_URL=...` (defaults to azureApiBaseUrl)
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: azureApiBaseUrl,
  );

  static const dealerCode = String.fromEnvironment(
    'DEALER_CODE',
    defaultValue: 'ALAGENDRA',
  );

  static const requestTimeout = Duration(seconds: 25);
  static const connectTimeout = Duration(seconds: 12);

  static const appName = 'MotoSaaS';
  static const supportFallbackPhone = '+91 90000 00000';
}
