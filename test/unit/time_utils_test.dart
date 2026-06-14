// ============================================================
// 第一档测试 · TimeUtils
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/utils/time_utils.dart';

void main() {
  group('TimeUtils.parseTimeStamp', () {
    test('TU-01 秒级 10 位 int 时间戳正确解析', () {
      // 1700000000 秒 = 2023-11-14 22:13:20 UTC
      final dt = TimeUtils.parseTimeStamp(1700000000);
      expect(dt.millisecondsSinceEpoch, 1700000000 * 1000);
    });

    test('TU-02 毫秒级 13 位 int 时间戳正确解析', () {
      const ms = 1700000000000;
      final dt = TimeUtils.parseTimeStamp(ms);
      expect(dt.millisecondsSinceEpoch, ms);
    });

    test('TU-03 ISO 字符串正确解析', () {
      const iso = '2024-05-01T10:00:00.000Z';
      final dt = TimeUtils.parseTimeStamp(iso);
      expect(dt.year, 2024);
      expect(dt.month, 5);
      expect(dt.day, 1);
    });

    test('TU-04 带时区的 ISO 字符串正确解析', () {
      const iso = '2024-06-15T08:30:00+08:00';
      final dt = TimeUtils.parseTimeStamp(iso);
      // UTC 时间 = 2024-06-15 00:30:00
      expect(dt.year, isIn([2024]));
      expect(dt.month, 6);
      expect(dt.day, 15);
    });

    test('TU-05 null 值返回 DateTime.now() 不抛异常', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final dt = TimeUtils.parseTimeStamp(null);
      expect(dt.isAfter(before), isTrue);
    });

    test('TU-06 无法解析的字符串不抛异常，返回当前时间', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final dt = TimeUtils.parseTimeStamp('not-a-date');
      expect(dt.isAfter(before), isTrue);
    });
  });

  group('TimeUtils.formatDateTime', () {
    test('TU-07 默认格式 yyyy-MM-dd HH:mm', () {
      final dt = DateTime(2024, 6, 15, 9, 30);
      final s = TimeUtils.formatDateTime(dt);
      expect(s, '2024-06-15 09:30');
    });

    test('TU-08 自定义格式 yyyy/MM/dd', () {
      final dt = DateTime(2024, 1, 5);
      final s = TimeUtils.formatDateTime(dt, format: 'yyyy/MM/dd');
      expect(s, '2024/01/05');
    });
  });

  group('TimeUtils.getRelativeTime', () {
    test('TU-09 刚刚 — 不足一分钟', () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(TimeUtils.getRelativeTime(now), '刚刚');
    });

    test('TU-10 分钟前', () {
      final fiveMin = DateTime.now().subtract(const Duration(minutes: 5));
      expect(TimeUtils.getRelativeTime(fiveMin), '5分钟前');
    });
  });
}
