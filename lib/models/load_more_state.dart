/// 大厂标准：精细化的加载状态管理
/// 参考：阿里巴巴、字节跳动的列表加载最佳实践
enum LoadMoreState {
  idle, // 空闲状态，可以开始加载
  loading, // 首次加载中
  loadingMore, // 加载更多中
  success, // 加载成功
  failed, // 加载失败
  noMore, // 没有更多数据
  error, // 发生错误
}

extension LoadMoreStateExtension on LoadMoreState {
  /// 是否正在加载中
  bool get isLoading => this == LoadMoreState.loading || this == LoadMoreState.loadingMore;

  /// 是否可以加载更多
  bool get canLoadMore => this == LoadMoreState.idle || this == LoadMoreState.success || this == LoadMoreState.failed;

  /// 是否有错误
  bool get hasError => this == LoadMoreState.failed || this == LoadMoreState.error;

  /// 状态描述（用于日志和调试）
  String get description {
    switch (this) {
      case LoadMoreState.idle:
        return '空闲';
      case LoadMoreState.loading:
        return '首次加载中';
      case LoadMoreState.loadingMore:
        return '加载更多中';
      case LoadMoreState.success:
        return '加载成功';
      case LoadMoreState.failed:
        return '加载失败';
      case LoadMoreState.noMore:
        return '没有更多数据';
      case LoadMoreState.error:
        return '发生错误';
    }
  }
}
