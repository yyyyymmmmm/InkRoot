import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/models/load_more_state.dart';
import 'package:inkroot/services/notes_pagination_helper.dart';

void main() {
  test('PAGE-01 initial state is page 0, hasMore, idle', () {
    final s = initialNotesPaginationState();
    expect(s.currentPage, 0);
    expect(s.hasMoreData, isTrue);
    expect(s.loadMoreState, LoadMoreState.idle);
  });

  test('PAGE-02 canStartLoadMore requires hasMoreData and canLoadMore state',
      () {
    expect(
      canStartLoadMore(
        const NotesPaginationState(
          currentPage: 0,
          hasMoreData: true,
          loadMoreState: LoadMoreState.idle,
        ),
      ),
      isTrue,
    );
    expect(
      canStartLoadMore(
        const NotesPaginationState(
          currentPage: 0,
          hasMoreData: false,
          loadMoreState: LoadMoreState.idle,
        ),
      ),
      isFalse,
    );
    expect(
      canStartLoadMore(
        const NotesPaginationState(
          currentPage: 0,
          hasMoreData: true,
          loadMoreState: LoadMoreState.loadingMore,
        ),
      ),
      isFalse,
    );
  });

  test('PAGE-03 beginLoadMore increments page and sets loadingMore', () {
    final s = beginLoadMore(
      const NotesPaginationState(
        currentPage: 3,
        hasMoreData: true,
        loadMoreState: LoadMoreState.idle,
      ),
    );
    expect(s.currentPage, 4);
    expect(s.loadMoreState, LoadMoreState.loadingMore);
  });

  test('PAGE-04 applyLoadMoreResult noMore on empty, success otherwise', () {
    const base = NotesPaginationState(
      currentPage: 1,
      hasMoreData: true,
      loadMoreState: LoadMoreState.loadingMore,
    );

    final empty = applyLoadMoreResult(state: base, itemCount: 0);
    expect(empty.hasMoreData, isFalse);
    expect(empty.loadMoreState, LoadMoreState.noMore);

    final nonEmpty = applyLoadMoreResult(state: base, itemCount: 10);
    expect(nonEmpty.hasMoreData, isTrue);
    expect(nonEmpty.loadMoreState, LoadMoreState.success);
  });

  test('PAGE-05 applyLoadMoreFailure decrements page and marks failed', () {
    final s = applyLoadMoreFailure(
      const NotesPaginationState(
        currentPage: 5,
        hasMoreData: true,
        loadMoreState: LoadMoreState.loadingMore,
      ),
    );
    expect(s.currentPage, 4);
    expect(s.loadMoreState, LoadMoreState.failed);
  });

  test('PAGE-06 endLoadAttempt resets to idle unless noMore', () {
    final idle = endLoadAttempt(
      const NotesPaginationState(
        currentPage: 1,
        hasMoreData: true,
        loadMoreState: LoadMoreState.success,
      ),
    );
    expect(idle.loadMoreState, LoadMoreState.idle);

    final noMore = endLoadAttempt(
      const NotesPaginationState(
        currentPage: 1,
        hasMoreData: false,
        loadMoreState: LoadMoreState.noMore,
      ),
    );
    expect(noMore.loadMoreState, LoadMoreState.noMore);
  });
}
