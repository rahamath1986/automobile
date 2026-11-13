import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/datasources/showroom_api.dart';
import '../data/repositories/showroom_repository_impl.dart';
import '../domain/entities/showroom_asset.dart';
import '../domain/repositories/showroom_repository.dart';

final showroomApiProvider = Provider<ShowroomApi>((ref) => ShowroomApi(ref.watch(apiClientProvider)));

final showroomRepositoryProvider = Provider<ShowroomRepository>((ref) {
  return ShowroomRepositoryImpl(ref.watch(showroomApiProvider));
});

typedef ShowroomQuery = ({String variantId, String? colorId});

final showroomAssetProvider = FutureProvider.autoDispose.family<ShowroomAsset, ShowroomQuery>(
  (ref, query) => ref.watch(showroomRepositoryProvider).getShowroomAsset(
        variantId: query.variantId,
        colorId: query.colorId,
      ),
);
