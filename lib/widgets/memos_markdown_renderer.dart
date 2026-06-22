import 'package:flutter/material.dart';
import 'package:inkroot/models/note_model.dart';
import 'package:inkroot/utils/memos_content_helper.dart';
import 'package:inkroot/widgets/simple_memo_content.dart';

enum MemosMarkdownMode {
  cardPreview,
  detail,
  review,
  share,
}

class MemosMarkdownRenderer extends StatelessWidget {
  const MemosMarkdownRenderer({
    required this.content,
    super.key,
    this.serverUrl,
    this.onTagTap,
    this.onLinkTap,
    this.selectable = true,
    this.maxLines,
    this.note,
    this.onCheckboxTap,
    this.mode = MemosMarkdownMode.detail,
    this.highlightQuery,
    this.referenceNotes,
  });

  MemosMarkdownRenderer.fromNote({
    required Note note,
    super.key,
    this.serverUrl,
    this.onTagTap,
    this.onLinkTap,
    this.selectable = true,
    this.maxLines,
    this.onCheckboxTap,
    this.mode = MemosMarkdownMode.detail,
    this.highlightQuery,
    this.referenceNotes,
    bool appendResourceImages = true,
  })  : note = note,
        content = appendResourceImages
            ? MemosContentHelper.contentWithResourceImages(note)
            : note.content;

  final String content;
  final String? serverUrl;
  final Function(String)? onTagTap;
  final Function(String)? onLinkTap;
  final bool selectable;
  final int? maxLines;
  final Note? note;
  final Function(int todoIndex)? onCheckboxTap;
  final MemosMarkdownMode mode;
  final String? highlightQuery;
  final List<Note>? referenceNotes;

  @override
  Widget build(BuildContext context) => SimpleMemoContent(
        content: content,
        serverUrl: serverUrl,
        onTagTap: onTagTap,
        onLinkTap: onLinkTap,
        selectable: selectable,
        maxLines: maxLines,
        note: note,
        onCheckboxTap: onCheckboxTap,
        highlightQuery: highlightQuery,
        referenceNotes: referenceNotes,
        compactHeadings: mode == MemosMarkdownMode.cardPreview,
      );
}
