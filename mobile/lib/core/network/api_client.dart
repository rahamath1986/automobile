import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base API client used by all mobile services.
///
/// The [baseUrl] should point to the deployed backend (e.g. https://api.motosaas.local).
/// For local development you can set it to `http://10.0.2.2:5000` (Android emulator) or
/// `http://localhost:5000` (iOS simulator). The value is read from the `.env` file at runtime.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
    },
  ));

  // You can add interceptors here for logging, error handling, etc.
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

