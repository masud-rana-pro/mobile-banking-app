class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.path,
    this.errors = const [],
  });

  final String message;
  final int? statusCode;
  final String? path;
  final List<String> errors;

  factory ApiException.fromJson(Map<String, dynamic> json) {
    return ApiException(
      message: json['message'] as String? ?? 'Request failed.',
      statusCode: json['status'] as int?,
      path: json['path'] as String?,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((error) => error.toString())
              .toList() ??
          const [],
    );
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message)';
  }
}
