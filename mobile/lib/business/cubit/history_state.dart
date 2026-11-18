import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';

enum HistoryStatus { initial, loading, ready, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.items = const [],
    this.detail,
    this.errorMessage,
    this.deleting = false,
  });

  final HistoryStatus status;
  final List<HistoryItem> items;
  final HistoryItem? detail;
  final String? errorMessage;
  final bool deleting;

  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryItem>? items,
    HistoryItem? detail,
    String? errorMessage,
    bool? deleting,
    bool clearDetail = false,
    bool clearError = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      deleting: deleting ?? this.deleting,
    );
  }

  @override
  List<Object?> get props => [status, items, detail, errorMessage, deleting];
}
