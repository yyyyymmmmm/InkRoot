import 'package:inkroot/models/note_model.dart';

List<String> extractTags(String content) =>
    Note.extractTagsFromContent(content);

bool tagsChanged({
  required List<String> oldTags,
  required List<String> newTags,
}) {
  if (oldTags.length != newTags.length) {
    return true;
  }
  return !oldTags.toSet().containsAll(newTags);
}
