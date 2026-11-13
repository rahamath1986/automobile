import '../datasources/showroom_api.dart';
import '../../domain/entities/showroom_asset.dart';
import '../../domain/repositories/showroom_repository.dart';

class ShowroomRepositoryImpl implements ShowroomRepository {
  ShowroomRepositoryImpl(this._api);

  final ShowroomApi _api;

  @override
  Future<ShowroomAsset> getShowroomAsset({required String variantId, String? colorId}) =>
      _api.getShowroomAsset(variantId: variantId, colorId: colorId);
}
