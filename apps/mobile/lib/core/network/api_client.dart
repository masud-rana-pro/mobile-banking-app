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
      final fallbackResponse = await _tryFallbackBaseUrls<T>(error);
      if (fallbackResponse != null) {
        return fallbackResponse;
      }
      throw _toApiException(error);
    }
  }

  Future<Response<T>?> _tryFallbackBaseUrls<T>(DioException error) async {
    if (error.type != DioExceptionType.connectionError) {
      return null;
    }

    final requestOptions = error.requestOptions;
    final currentBaseUrl = _normalizeBaseUrl(_dio.options.baseUrl);
    final fallbackBaseUrls = [
      AppConfig.backendBaseUrl,
      ...AppConfig.backendFallbackBaseUrls,
    ]
        .map(_normalizeBaseUrl)
        .where((url) => url.isNotEmpty)
        .toSet()
        .where((url) => url != currentBaseUrl)
        .toList();

    DioException? lastError;
    for (final baseUrl in fallbackBaseUrls) {
      final fallbackDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: AppConfig.apiConnectTimeout,
          receiveTimeout: AppConfig.apiReceiveTimeout,
          headers: const {'Accept': 'application/json'},
        ),
      );

      final headers = Map<String, dynamic>.from(requestOptions.headers);
      if (requestOptions.path != '/api/auth/firebase-login') {
        final token = await _tokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          final tokenType = await _tokenStorage.readTokenType();
          headers['Authorization'] = '$tokenType $token';
        }
      }

      try {
        final response = await fallbackDio.request<T>(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: headers,
            contentType: requestOptions.contentType,
            responseType: requestOptions.responseType,
            followRedirects: requestOptions.followRedirects,
            validateStatus: requestOptions.validateStatus,
          ),
        );
        _dio.options.baseUrl = baseUrl;
        return response;
      } on DioException catch (fallbackError) {
        lastError = fallbackError;
      }
    }

    if (lastError != null && lastError.response != null) {
      throw _toApiException(lastError);
    }
    return null;
  }

  String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/$'), '');
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
            'Cannot reach SmartKash backend. Tried ${AppConfig.backendBaseUrl} and local fallback URLs. Start Spring Boot, keep USB debugging connected and run scripts/dev/run_mobile_real_phone.ps1, or run Flutter with --dart-define=SMARTKASH_API_BASE_URL=http://<PC-LAN-IP>:8080 for WiFi testing.',
      );
    }

    return ApiException(
      message: error.message ?? 'Network request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}
