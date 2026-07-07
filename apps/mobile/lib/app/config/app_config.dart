class AppConfig {
  const AppConfig._();

  static const appName = 'SmartKash';
  static const packageName = 'com.imran.smartkash';
  static const backendBaseUrl = String.fromEnvironment(
    'SMARTKASH_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  static const apiConnectTimeout = Duration(seconds: 15);
  static const apiReceiveTimeout = Duration(seconds: 20);
}
