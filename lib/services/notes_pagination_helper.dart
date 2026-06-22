import 'package:inkroot/models/load_more_state.dart';

class NotesPaginationState {
  const NotesPaginationState({
    required this.currentPage,
    required this.hasMoreData,
    required this.loadMoreState,
  });

  final int currentPage;
  final bool hasMoreData;
  final LoadMoreState loadMoreState;

  NotesPaginationState copyWith({
    int? currentPage,
    bool? hasMoreData,
    LoadMoreState? loadMoreState,
  }) =>
      NotesPaginationState(
        currentPage: currentPage ?? this.currentPage,
        hasMoreData: hasMoreData ?? this.hasMoreData,
        loadMoreState: loadMoreState ?? this.loadMoreState,
      );
}

NotesPaginationState initialNotesPaginationState() =>
    const NotesPaginationState(
      currentPage: 0,
      hasMoreData: true,
      loadMoreState: LoadMoreState.idle,
    );

bool canStartLoadMore(NotesPaginationState state) =>
    state.loadMoreState.canLoadMore && state.hasMoreData;

NotesPaginationState beginLoadMore(NotesPaginationState state) =>
    state.copyWith(
      currentPage: state.currentPage + 1,
      loadMoreState: LoadMoreState.loadingMore,
    );

NotesPaginationState applyInitialPageResult({
  required NotesPaginationState state,
  required int loadedCount,
  required int totalCount,
}) {
  final hasMore = loadedCount < totalCount;
  return state.copyWith(
    currentPage: 0,
    hasMoreData: hasMore,
    loadMoreState: hasMore ? LoadMoreState.idle : LoadMoreState.noMore,
  );
}

NotesPaginationState applyLoadMoreResult({
  required NotesPaginationState state,
  required int itemCount,
  required int loadedCount,
  required int totalCount,
}) {
  if (itemCount == 0 || loadedCount >= totalCount) {
    return state.copyWith(
      hasMoreData: false,
      loadMoreState: LoadMoreState.noMore,
    );
  }

  return state.copyWith(loadMoreState: LoadMoreState.success);
}

NotesPaginationState applyLoadMoreFailure(NotesPaginationState state) =>
    state.copyWith(
      currentPage: state.currentPage - 1,
      loadMoreState: LoadMoreState.failed,
    );

NotesPaginationState endLoadAttempt(NotesPaginationState state) {
  if (state.loadMoreState == LoadMoreState.noMore) {
    return state;
  }
  return state.copyWith(loadMoreState: LoadMoreState.idle);
}
