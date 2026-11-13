import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    String baseUrl = AppConfig.apiBaseUrl,
    Dio? dio,
  })  : _tokenStore = tokenStore,
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.requestTimeout,
      sendTimeout: AppConfig.requestTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Dealer-Code': AppConfig.dealerCode,
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStore.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get<dynamic>(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _request(() => _dio.post<dynamic>(path, data: body, queryParameters: _clean(query)));

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) =>
      _request(() => _dio.put<dynamic>(path, data: body, queryParameters: _clean(query)));

  Future<dynamic> _request(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  dynamic _unwrap(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is Map<String, dynamic> && payload.containsKey('success')) {
      if (payload['success'] == true) {
        return payload['data'];
      }
      throw ApiException(
        payload['message']?.toString() ?? 'Request failed.',
        statusCode: payload['statusCode'] is int ? payload['statusCode'] as int : null,
      );
    }

    return payload;
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) {
      return null;
    }

    return Map<String, dynamic>.fromEntries(
      query.entries.where((entry) => entry.value != null),
    );
  }
}
