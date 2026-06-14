String shortFirstLine(Object error) => error.toString().split('\n').first;

bool isTokenExpiredError(Object error) {
  final s = error.toString();
  return s.contains('Token无效或已过期');
}

String syncFailedMessage(Object error) => '同步失败: ${shortFirstLine(error)}';
