import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/widgets/tag_tree_item.dart';

void main() {
  group('TagNode', () {
    test('counts notes instead of unique tag paths', () {
      final nodes = TagNode.buildTreeFromNoteTags([
        ['工作/项目A', '灵感'],
        ['工作/项目A'],
        ['工作/项目B'],
        ['生活'],
      ]);

      final work = nodes.singleWhere((node) => node.fullPath == '工作');
      final projectA =
          work.children.singleWhere((node) => node.fullPath == '工作/项目A');
      final projectB =
          work.children.singleWhere((node) => node.fullPath == '工作/项目B');

      expect(work.noteCount, 3);
      expect(projectA.noteCount, 2);
      expect(projectB.noteCount, 1);
    });

    test('deduplicates repeated tags within one note for parent counts', () {
      final nodes = TagNode.buildTreeFromNoteTags([
        ['医学/胰腺癌', '医学/胰腺癌'],
        ['医学/营养'],
      ]);

      final medical = nodes.singleWhere((node) => node.fullPath == '医学');

      expect(medical.noteCount, 2);
    });

    test('deduplicates parent count when one note has parent and child tags',
        () {
      final nodes = TagNode.buildTreeFromNoteTags([
        ['工作', '工作/项目A'],
        ['工作/项目B'],
      ]);

      final work = nodes.singleWhere((node) => node.fullPath == '工作');

      expect(work.noteCount, 2);
    });

    test('normalizes blank path segments and whitespace', () {
      final nodes = TagNode.buildTreeFromNoteTags([
        [' 工作 / / 项目A '],
      ]);

      final work = nodes.singleWhere((node) => node.fullPath == '工作');
      final projectA =
          work.children.singleWhere((node) => node.fullPath == '工作/项目A');

      expect(work.noteCount, 1);
      expect(projectA.noteCount, 1);
    });

    test('sorts siblings by note count desc then path asc', () {
      final nodes = TagNode.buildTreeFromNoteTags([
        ['B'],
        ['A'],
        ['B'],
        ['C'],
      ]);

      expect(
        nodes.map((node) => node.fullPath).toList(),
        ['B', 'A', 'C'],
      );
    });
  });
}
