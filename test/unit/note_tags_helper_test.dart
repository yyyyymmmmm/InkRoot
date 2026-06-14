import 'package:flutter_test/flutter_test.dart';
import 'package:inkroot/services/note_tags_helper.dart';

void main() {
  test('TAGS-01 extractTags delegates to Note.extractTagsFromContent behavior',
      () {
    final tags = extractTags('hello #A #B and https://x.y/#nope');
    expect(tags, containsAll(['A', 'B']));
  });

  test('TAGS-02 tagsChanged detects same set', () {
    expect(tagsChanged(oldTags: ['a', 'b'], newTags: ['a', 'b']), isFalse);
    expect(tagsChanged(oldTags: ['a', 'b'], newTags: ['b', 'a']), isFalse);
  });

  test('TAGS-03 tagsChanged detects differences', () {
    expect(tagsChanged(oldTags: ['a'], newTags: ['a', 'b']), isTrue);
    expect(tagsChanged(oldTags: ['a'], newTags: ['b']), isTrue);
  });
}
