import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.validationErrors = const {},
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, String> validationErrors;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  static ApiException fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final errors = <String, String>{};
      final rawErrors = data['errors'];
      if (rawErrors is List) {
        for (final item in rawErrors) {
          if (item is Map && item['field'] != null) {
            errors[item['field'].toString()] = item['message']?.toString() ?? 'Invalid value';
          }
        }
      }

      return ApiException(
        data['message']?.toString() ?? _fallbackMessage(error),
        statusCode: response?.statusCode ?? error.response?.statusCode,
        validationErrors: errors,
      );
    }

    return ApiException(
      _fallbackMessage(error),
      statusCode: response?.statusCode,
      isNetworkError: _isNetwork(error),
    );
  }

  static bool _isNetwork(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  static String _fallbackMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The dealership is taking too long to respond. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to reach the dealership. Check your connection and try again.',
      DioExceptionType.cancel => 'Request cancelled.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}
