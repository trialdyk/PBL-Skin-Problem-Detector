import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/history_state.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(
    this._history, {
    this.pollInterval = const Duration(seconds: 2),
    this.maxPollAttempts = 20,
  }) : super(const HistoryState());

  final HistoryService _history;
  final Duration pollInterval;
  final int maxPollAttempts;

  Future<void> loadList() async {
    emit(state.copyWith(status: HistoryStatus.loading, clearError: true));
    try {
      final result = await _history.list();
      emit(state.copyWith(
        status: HistoryStatus.ready,
        items: result.items,
      ));
    } on HistoryException catch (error) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: error.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: 'Gagal memuat riwayat.',
      ));
    }
  }

  Future<void> loadDetail(String id) async {
    emit(state.copyWith(
      status: HistoryStatus.loading,
      clearError: true,
      clearDetail: true,
    ));
    try {
      final item = await _history.detail(id);
      emit(state.copyWith(
        status: HistoryStatus.ready,
        detail: item,
      ));
    } on HistoryException catch (error) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: error.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: 'Gagal memuat detail riwayat.',
      ));
    }
  }

  Future<String?> retryRecommendation() async {
    final id = state.detail?.id;
    if (id == null) return null;
    emit(state.copyWith(retryingRecommendation: true, clearError: true));
    try {
      final updated = await _history.retryRecommendation(id);
      if (isClosed) return null;
      emit(state.copyWith(detail: updated));

      if (updated.recommendation.status == RecommendationStatus.pending) {
        for (var i = 0; i < maxPollAttempts; i++) {
          await Future<void>.delayed(pollInterval);
          if (isClosed) return null;
          final refreshed = await _history.detail(id);
          if (isClosed) return null;
          emit(state.copyWith(detail: refreshed));
          if (refreshed.recommendation.status != RecommendationStatus.pending) {
            break;
          }
        }
      }
      if (!isClosed) emit(state.copyWith(retryingRecommendation: false));
      return null;
    } on HistoryException catch (error) {
      if (!isClosed) emit(state.copyWith(retryingRecommendation: false));
      return error.message;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(retryingRecommendation: false));
      return 'Gagal meminta ulang rekomendasi.';
    }
  }

  Future<bool> deleteCurrent() async {
    final id = state.detail?.id;
    if (id == null) return false;
    emit(state.copyWith(deleting: true, clearError: true));
    try {
      await _history.delete(id);
      emit(state.copyWith(
        deleting: false,
        clearDetail: true,
        items: [
          for (final item in state.items)
            if (item.id != id) item,
        ],
      ));
      return true;
    } on HistoryException catch (error) {
      emit(state.copyWith(deleting: false, errorMessage: error.message));
      return false;
    } catch (_) {
      emit(state.copyWith(
        deleting: false,
        errorMessage: 'Gagal menghapus riwayat.',
      ));
      return false;
    }
  }
}
