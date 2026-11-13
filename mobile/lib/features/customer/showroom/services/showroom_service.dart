import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/showroom_asset.dart';

final showroomServiceProvider = Provider<ShowroomService>((ref) {
  final dio = ref.read(dioProvider);
  return ShowroomService(dio);
});

class ShowroomService {
  final Dio _dio;
  ShowroomService(this._dio);

  /// GET /api/v1/showroom/variants/{variantId}
  /// Returns the 3-tier progressive showroom manifest for the given variant.
  Future<ShowroomAsset> getAsset({
    required String variantId,
    String? colorId,
  }) async {
    final response = await _dio.get(
      '/api/v1/showroom/variants/$variantId',
      queryParameters: {
        if (colorId != null) 'colorId': colorId,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final data = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return ShowroomAsset.fromJson(data);
  }
}

