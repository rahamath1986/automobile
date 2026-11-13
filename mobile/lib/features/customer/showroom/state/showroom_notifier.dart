import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/showroom_asset.dart';
import '../services/showroom_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────
enum ShowroomLoadStatus { idle, loading, success, error }

class ShowroomState {
  final ShowroomLoadStatus status;
  final ShowroomAsset? asset;
  final String? errorMessage;

  const ShowroomState({
    required this.status,
    this.asset,
    this.errorMessage,
  });

  ShowroomState copyWith({
    ShowroomLoadStatus? status,
    ShowroomAsset? asset,
    String? errorMessage,
  }) =>
      ShowroomState(
        status: status ?? this.status,
        asset: asset ?? this.asset,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final showroomNotifierProvider =
    StateNotifierProvider<ShowroomNotifier, ShowroomState>((ref) {
  final service = ref.read(showroomServiceProvider);
  return ShowroomNotifier(service);
});

// ─── Notifier ─────────────────────────────────────────────────────────────────
class ShowroomNotifier extends StateNotifier<ShowroomState> {
  final ShowroomService _service;

  ShowroomNotifier(this._service)
      : super(const ShowroomState(status: ShowroomLoadStatus.idle));

  Future<void> loadAsset({required String variantId, String? colorId}) async {
    state = state.copyWith(status: ShowroomLoadStatus.loading);
    try {
      final asset = await _service.getAsset(variantId: variantId, colorId: colorId);
      state = state.copyWith(status: ShowroomLoadStatus.success, asset: asset);
    } catch (e) {
      state = state.copyWith(
        status: ShowroomLoadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

