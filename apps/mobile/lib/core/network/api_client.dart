import 'package:dio/dio.dart';

import '../../app/config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_token_storage.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    SecureTokenStorage? tokenStorage,
    String baseUrl = AppConfig.backendBaseUrl,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: AppConfig.apiConnectTimeout,
                receiveTimeout: AppConfig.apiReceiveTimeout,
                headers: const {'Accept': 'application/json'},
              ),
            ),
        _tokenStorage = tokenStorage ?? SecureTokenStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path != '/api/auth/firebase-login') {
            final token = await _tokenStorage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              final tokenType = await _tokenStorage.readTokenType();
              options.headers['Authorization'] = '$tokenType $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      return ApiException.fromJson(responseData);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message:
            'Backend request timed out for ${AppConfig.backendBaseUrl}. Make sure Spring Boot is running on port 8080, then try again.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message:
            'Cannot reach SmartKash backend at ${AppConfig.backendBaseUrl}. For real phone or emulator development, run scripts/dev/run_mobile_real_phone.ps1 so adb reverse maps device port 8080 to your PC backend. If you use WiFi instead, pass --dart-define=SMARTKASH_API_BASE_URL=http://<PC-LAN-IP>:8080 and allow port 8080 in firewall.',
      );
    }

    return ApiException(
      message: error.message ?? 'Network request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}
