import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/sync_status_helper.dart';

class _Err implements Exception {
  _Err(this.msg);
  final String msg;
  @override
  String toString() => msg;
}

void main() {
  test('SYNC-STATUS-01 shortFirstLine uses first line', () {
    expect(shortFirstLine(_Err('a\nb\nc')), 'a');
  });

  test('SYNC-STATUS-02 isTokenExpiredError matches message', () {
    expect(isTokenExpiredError(_Err('Token无效或已过期')), isTrue);
    expect(isTokenExpiredError(_Err('other')), isFalse);
  });

  test('SYNC-STATUS-03 syncFailedMessage prefixes first line', () {
    expect(syncFailedMessage(_Err('oops\ntrace')), '同步失败: oops');
  });
}
