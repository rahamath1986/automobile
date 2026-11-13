class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5053/api/v1',
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
