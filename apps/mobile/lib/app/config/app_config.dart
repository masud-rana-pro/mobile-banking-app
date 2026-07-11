class AppConfig {
  const AppConfig._();

  static const appName = 'SmartKash';
  static const packageName = 'com.smartkash.app';
  static const backendBaseUrl = String.fromEnvironment(
    'SMARTKASH_API_BASE_URL',
    defaultValue: 'http://192.168.0.102:8080',
  );
  static const apiConnectTimeout = Duration(seconds: 45);
  static const apiReceiveTimeout = Duration(seconds: 60);
}
