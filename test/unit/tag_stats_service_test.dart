import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/tag_stats_service.dart';

void main() {
  group('buildTagTreePayloadFromNoteJson', () {
    test('aggregates parent counts by unique notes', () {
      final payload = buildTagTreePayloadFromNoteJson([
        {
          'id': '1',
          'tags': ['工作', '工作/项目A'],
        },
        {
          'id': '2',
          'tags': ['工作/项目A'],
        },
        {
          'id': '3',
          'tags': ['工作/项目B'],
        },
      ]);

      final roots = (payload['roots'] as List).cast<Map<String, dynamic>>();
      final work = roots.singleWhere((node) => node['path'] == '工作');
      expect(work['count'], 3);

      final children = (work['children'] as List).cast<Map<String, dynamic>>();
      expect(children.first['path'], '工作/项目A');
      expect(children.first['count'], 2);
      expect(children[1]['path'], '工作/项目B');
      expect(children[1]['count'], 1);
    });

    test('normalizes whitespace and empty path segments', () {
      final payload = buildTagTreePayloadFromNoteJson([
        {
          'id': '1',
          'tags': [' 工作 / 项目A ', '工作//项目A', '  '],
        },
      ]);

      final roots = (payload['roots'] as List).cast<Map<String, dynamic>>();
      final work = roots.singleWhere((node) => node['path'] == '工作');
      expect(work['count'], 1);

      final children = (work['children'] as List).cast<Map<String, dynamic>>();
      expect(children.single['path'], '工作/项目A');
      expect(children.single['count'], 1);
    });

    test('creates implicit parent nodes', () {
      final payload = buildTagTreePayloadFromNoteJson([
        {
          'id': '1',
          'tags': ['工作/项目A'],
        },
      ]);

      final roots = (payload['roots'] as List).cast<Map<String, dynamic>>();
      expect(payload['totalUniqueTags'], 2);
      final work = roots.singleWhere((node) => node['path'] == '工作');
      expect(work['count'], 1);
      final children = (work['children'] as List).cast<Map<String, dynamic>>();
      expect(children.single['path'], '工作/项目A');
    });

    test('sorts siblings by count desc then path asc', () {
      final payload = buildTagTreePayloadFromNoteJson([
        {
          'id': '1',
          'tags': ['工作/A'],
        },
        {
          'id': '2',
          'tags': ['工作/B'],
        },
        {
          'id': '3',
          'tags': ['工作/B'],
        },
      ]);

      final roots = (payload['roots'] as List).cast<Map<String, dynamic>>();
      final work = roots.singleWhere((node) => node['path'] == '工作');
      final children = (work['children'] as List).cast<Map<String, dynamic>>();
      expect(children.map((node) => node['path']), ['工作/B', '工作/A']);
    });
  });

  group('buildTagStatsPayloadFromNoteJson', () {
    test('counts duplicate tags in one note once', () {
      final payload = buildTagStatsPayloadFromNoteJson([
        {
          'id': '1',
          'tags': ['阅读', ' 阅读 ', '阅读'],
        },
        {
          'id': '2',
          'tags': ['阅读'],
        },
      ]);

      final snapshot = tagStatsSnapshotFromPayload(payload);
      expect(snapshot.counts['阅读'], 2);
      expect(snapshot.totalUniqueTags, 1);
    });

    test('handles topN boundaries', () {
      final notes = [
        {
          'id': '1',
          'tags': ['A', 'B'],
        },
      ];

      expect(
        buildTagStatsPayloadFromNoteJson(notes, topN: -1)['topTags'] as List,
        isEmpty,
      );
      expect(
        buildTagStatsPayloadFromNoteJson(notes, topN: 0)['topTags'] as List,
        isEmpty,
      );
      expect(
        (buildTagStatsPayloadFromNoteJson(notes, topN: 99)['topTags'] as List)
            .length,
        2,
      );
    });
  });
}
