import '../../../../core/network/api_client.dart';
import '../../domain/entities/showroom_asset.dart';

class ShowroomApi {
  ShowroomApi(this._client);

  final ApiClient _client;

  Future<ShowroomAsset> getShowroomAsset({required String variantId, String? colorId}) async {
    final payload = await _client.get(
      '/showroom/variants/$variantId',
      query: {'colorId': colorId},
    );

    if (payload is Map<String, dynamic>) {
      return ShowroomAsset.fromJson(payload);
    }

    throw StateError('Showroom manifest was not returned.');
  }
}
