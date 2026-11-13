import '../entities/showroom_asset.dart';

abstract class ShowroomRepository {
  Future<ShowroomAsset> getShowroomAsset({required String variantId, String? colorId});
}
