import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MemoTextMark {
  bold,
  italic,
  underline,
  strikethrough,
  code,
  heading,
  link,
}

class MemoStyleRange {
  const MemoStyleRange({
    required this.start,
    required this.end,
    required this.mark,
    this.data,
  });

  final int start;
  final int end;
  final MemoTextMark mark;
  final String? data;

  bool get isValid => start >= 0 && end > start;

  MemoStyleRange copyWith({
    int? start,
    int? end,
    MemoTextMark? mark,
    String? data,
  }) =>
      MemoStyleRange(
        start: start ?? this.start,
        end: end ?? this.end,
        mark: mark ?? this.mark,
        data: data ?? this.data,
      );
}

class MemoEditingParseResult {
  const MemoEditingParseResult({
    required this.text,
    required this.ranges,
  });

  final String text;
  final List<MemoStyleRange> ranges;
}

class MemoEditingController extends TextEditingController {
  MemoEditingController({String markdown = ''}) : super() {
    setMarkdown(markdown);
  }

  final List<MemoStyleRange> _ranges = [];
  final Set<MemoTextMark> _activeMarks = {};
  bool _suppressRangeTransform = false;

  List<MemoStyleRange> get ranges => List.unmodifiable(_ranges);

  void setMarkdown(String markdown) {
    final parsed = MemoMarkdownEditingCodec.decode(markdown);
    _suppressRangeTransform = true;
    _ranges
      ..clear()
      ..addAll(parsed.ranges);
    super.value = TextEditingValue(
      text: parsed.text,
      selection: TextSelection.collapsed(offset: parsed.text.length),
    );
    _activeMarks.clear();
    _suppressRangeTransform = false;
  }

  String toMarkdown() => MemoMarkdownEditingCodec.encode(text, _ranges);

  @override
  set value(TextEditingValue newValue) {
    final oldValue = super.value;
    if (!_suppressRangeTransform && oldValue.text != newValue.text) {
      _transformRangesForTextChange(oldValue.text, newValue.text);
    }
    super.value = newValue;
  }

  void insertPlainText(String insertText) {
    final selection = value.selection;
    final start = selection.isValid
        ? math.min(selection.start, selection.end)
        : text.length;
    final end =
        selection.isValid ? math.max(selection.start, selection.end) : start;
    final nextText = text.replaceRange(start, end, insertText);
    value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + insertText.length),
    );
  }

  void insertLink(String label, String url) {
    final safeLabel = label.trim().isEmpty ? url.trim() : label.trim();
    final safeUrl = url.trim();
    if (safeLabel.isEmpty || safeUrl.isEmpty) {
      return;
    }

    final selection = value.selection;
    final start = selection.isValid
        ? math.min(selection.start, selection.end)
        : text.length;
    final end =
        selection.isValid ? math.max(selection.start, selection.end) : start;
    final nextText = text.replaceRange(start, end, safeLabel);

    value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + safeLabel.length),
    );

    _addRange(
      MemoStyleRange(
        start: start,
        end: start + safeLabel.length,
        mark: MemoTextMark.link,
        data: safeUrl,
      ),
    );
    notifyListeners();
  }

  void toggleMark(MemoTextMark mark) {
    if (mark == MemoTextMark.heading || mark == MemoTextMark.link) {
      return;
    }

    final selection = value.selection;
    if (!selection.isValid) {
      return;
    }

    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);

    if (start == end) {
      if (_activeMarks.contains(mark)) {
        _activeMarks.remove(mark);
      } else {
        _activeMarks.add(mark);
      }
      notifyListeners();
      return;
    }

    if (_selectionHasFullMark(start, end, mark)) {
      _removeMark(start, end, mark);
    } else {
      _addRange(MemoStyleRange(start: start, end: end, mark: mark));
    }
    notifyListeners();
  }

  void toggleCurrentLineHeading() {
    final selection = value.selection;
    if (!selection.isValid || text.isEmpty) {
      return;
    }

    final start = _lineStartForOffset(selection.start);
    final end = _lineEndForOffset(selection.end);
    if (start == end) {
      return;
    }

    if (_selectionHasFullMark(start, end, MemoTextMark.heading)) {
      _removeMark(start, end, MemoTextMark.heading);
    } else {
      _addRange(
        MemoStyleRange(
          start: start,
          end: end,
          mark: MemoTextMark.heading,
          data: '1',
        ),
      );
    }
    notifyListeners();
  }

  bool isMarkActive(MemoTextMark mark) {
    final selection = value.selection;
    if (!selection.isValid) {
      return false;
    }

    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);
    if (start == end) {
      return _activeMarks.contains(mark) ||
          _ranges.any(
            (range) =>
                range.mark == mark && range.start < start && range.end >= start,
          );
    }

    return _selectionHasFullMark(start, end, mark);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final baseStyle = style ?? const TextStyle();
    final textValue = value.text;
    if (textValue.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final effectiveRanges = <MemoStyleRange>[
      ..._ranges.where((range) => range.isValid),
      ..._buildTagRanges(textValue),
    ];

    final composing = value.composing;
    final boundaries = <int>{0, textValue.length};
    for (final range in effectiveRanges) {
      boundaries
        ..add(_clampOffset(range.start, textValue.length))
        ..add(_clampOffset(range.end, textValue.length));
    }
    if (withComposing && composing.isValid) {
      boundaries
        ..add(_clampOffset(composing.start, textValue.length))
        ..add(_clampOffset(composing.end, textValue.length));
    }

    final sorted = boundaries.toList()..sort();
    final children = <InlineSpan>[];

    for (var i = 0; i < sorted.length - 1; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (start == end) {
        continue;
      }

      var segmentStyle = baseStyle;
      for (final range in effectiveRanges) {
        if (range.start <= start && range.end >= end) {
          segmentStyle = _applyMarkStyle(context, segmentStyle, range);
        }
      }

      if (withComposing &&
          composing.isValid &&
          composing.start <= start &&
          composing.end >= end) {
        segmentStyle = segmentStyle.copyWith(
          decoration: TextDecoration.combine([
            segmentStyle.decoration ?? TextDecoration.none,
            TextDecoration.underline,
          ]),
        );
      }

      children.add(
        TextSpan(
          text: textValue.substring(start, end),
          style: segmentStyle,
        ),
      );
    }

    return TextSpan(style: baseStyle, children: children);
  }

  TextStyle _applyMarkStyle(
    BuildContext context,
    TextStyle style,
    MemoStyleRange range,
  ) {
    switch (range.mark) {
      case MemoTextMark.bold:
        return style.copyWith(fontWeight: FontWeight.w700);
      case MemoTextMark.italic:
        return style.copyWith(fontStyle: FontStyle.italic);
      case MemoTextMark.underline:
        return style.copyWith(
          decoration: TextDecoration.combine([
            style.decoration ?? TextDecoration.none,
            TextDecoration.underline,
          ]),
        );
      case MemoTextMark.strikethrough:
        return style.copyWith(
          decoration: TextDecoration.combine([
            style.decoration ?? TextDecoration.none,
            TextDecoration.lineThrough,
          ]),
        );
      case MemoTextMark.code:
        return style.copyWith(
          fontFamily: 'monospace',
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
        );
      case MemoTextMark.heading:
        return style.copyWith(
          fontSize: (style.fontSize ?? 16) + 2,
          fontWeight: FontWeight.w700,
        );
      case MemoTextMark.link:
        return style.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.combine([
            style.decoration ?? TextDecoration.none,
            TextDecoration.underline,
          ]),
        );
    }
  }

  List<MemoStyleRange> _buildTagRanges(String source) {
    final ranges = <MemoStyleRange>[];
    final tagRegex = RegExp(
      r'(^|[^\w:/#])#([^\s\[\],，、;；:：！!？?\n#]+)',
      unicode: true,
    );

    for (final match in tagRegex.allMatches(source)) {
      final prefix = match.group(1) ?? '';
      final start = match.start + prefix.length;
      final end = match.end;
      if (start < end) {
        ranges.add(
          MemoStyleRange(
            start: start,
            end: end,
            mark: MemoTextMark.link,
            data: '#${match.group(2)}',
          ),
        );
      }
    }

    return ranges;
  }

  void _transformRangesForTextChange(String oldText, String newText) {
    final diff = _TextDiff.from(oldText, newText);
    final nextRanges = <MemoStyleRange>[];

    for (final range in _ranges) {
      final transformed = _transformRange(range, diff);
      if (transformed != null && transformed.isValid) {
        nextRanges.add(transformed);
      }
    }

    final insertedLength = diff.newEnd - diff.start;
    if (insertedLength > 0 && _activeMarks.isNotEmpty) {
      for (final mark in _activeMarks) {
        nextRanges.add(
          MemoStyleRange(
            start: diff.start,
            end: diff.start + insertedLength,
            mark: mark,
          ),
        );
      }
    }

    _ranges
      ..clear()
      ..addAll(_normalizeRanges(nextRanges));
  }

  MemoStyleRange? _transformRange(MemoStyleRange range, _TextDiff diff) {
    final oldEnd = diff.oldEnd;
    final insertedLength = diff.newEnd - diff.start;
    final removedLength = oldEnd - diff.start;
    final delta = insertedLength - removedLength;

    if (range.end <= diff.start) {
      return range;
    }

    if (range.start >= oldEnd) {
      return range.copyWith(
        start: range.start + delta,
        end: range.end + delta,
      );
    }

    if (removedLength == 0) {
      if (diff.start <= range.start) {
        return range.copyWith(
          start: range.start + insertedLength,
          end: range.end + insertedLength,
        );
      }
      if (diff.start < range.end) {
        return range.copyWith(end: range.end + insertedLength);
      }
      return range;
    }

    final keepsLeft = range.start < diff.start;
    final keepsRight = range.end > oldEnd;

    if (keepsLeft && keepsRight) {
      return range.copyWith(end: range.end + delta);
    }

    if (keepsLeft) {
      return range.copyWith(end: diff.start);
    }

    if (keepsRight) {
      return range.copyWith(
        start: diff.newEnd,
        end: range.end + delta,
      );
    }

    return null;
  }

  bool _selectionHasFullMark(int start, int end, MemoTextMark mark) {
    if (start == end) {
      return false;
    }

    var coveredUntil = start;
    final matching = _ranges
        .where(
          (range) =>
              range.mark == mark && range.end > start && range.start < end,
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final range in matching) {
      if (range.start > coveredUntil) {
        return false;
      }
      coveredUntil = math.max(coveredUntil, range.end);
      if (coveredUntil >= end) {
        return true;
      }
    }

    return false;
  }

  void _addRange(MemoStyleRange range) {
    if (!range.isValid) {
      return;
    }
    _ranges.add(range);
    final normalized = _normalizeRanges(_ranges);
    _ranges
      ..clear()
      ..addAll(normalized);
  }

  void _removeMark(int start, int end, MemoTextMark mark) {
    final nextRanges = <MemoStyleRange>[];
    for (final range in _ranges) {
      if (range.mark != mark || range.end <= start || range.start >= end) {
        nextRanges.add(range);
        continue;
      }

      if (range.start < start) {
        nextRanges.add(range.copyWith(end: start));
      }
      if (range.end > end) {
        nextRanges.add(range.copyWith(start: end));
      }
    }

    _ranges
      ..clear()
      ..addAll(_normalizeRanges(nextRanges));
  }

  List<MemoStyleRange> _normalizeRanges(List<MemoStyleRange> source) {
    final sorted = source.where((range) => range.isValid).toList()
      ..sort((a, b) {
        final markCompare = a.mark.index.compareTo(b.mark.index);
        if (markCompare != 0) {
          return markCompare;
        }
        final dataCompare = (a.data ?? '').compareTo(b.data ?? '');
        if (dataCompare != 0) {
          return dataCompare;
        }
        return a.start.compareTo(b.start);
      });

    final result = <MemoStyleRange>[];
    for (final range in sorted) {
      if (result.isEmpty) {
        result.add(range);
        continue;
      }

      final last = result.last;
      if (last.mark == range.mark &&
          last.data == range.data &&
          range.start <= last.end) {
        result[result.length - 1] = last.copyWith(
          end: math.max(last.end, range.end),
        );
      } else {
        result.add(range);
      }
    }

    return result;
  }

  int _lineStartForOffset(int offset) {
    final safeOffset = _clampOffset(offset, text.length);
    final previousBreak = text.lastIndexOf('\n', safeOffset - 1);
    return previousBreak == -1 ? 0 : previousBreak + 1;
  }

  int _lineEndForOffset(int offset) {
    final safeOffset = _clampOffset(offset, text.length);
    final nextBreak = text.indexOf('\n', safeOffset);
    return nextBreak == -1 ? text.length : nextBreak;
  }

  int _clampOffset(int offset, int length) => offset.clamp(0, length);
}

class MemoMarkdownEditingCodec {
  static MemoEditingParseResult decode(String markdown) {
    final output = StringBuffer();
    final ranges = <MemoStyleRange>[];
    final lines = markdown.split('\n');
    var inFence = false;

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        output.write('\n');
      }

      final line = lines[i];
      final trimmedLeft = line.trimLeft();
      final isFence =
          trimmedLeft.startsWith('```') || trimmedLeft.startsWith('~~~');

      if (inFence || isFence) {
        output.write(line);
        if (isFence) {
          inFence = !inFence;
        }
        continue;
      }

      _decodeLine(line, output, ranges);
    }

    return MemoEditingParseResult(
      text: output.toString(),
      ranges: ranges.where((range) => range.isValid).toList(),
    );
  }

  static String encode(String text, List<MemoStyleRange> ranges) {
    final normalizedRanges = ranges.where((range) => range.isValid).toList();
    final lines = text.split('\n');
    final encoded = <String>[];
    var lineStart = 0;

    for (final line in lines) {
      final lineEnd = lineStart + line.length;
      var encodedLine = _encodeInlineLine(
        line,
        lineStart,
        normalizedRanges,
      );

      encodedLine = _encodeVisualBlockPrefix(encodedLine);
      if (_lineHasMark(
            lineStart,
            lineEnd,
            normalizedRanges,
            MemoTextMark.heading,
          ) &&
          encodedLine.trim().isNotEmpty &&
          !_startsWithMarkdownBlockPrefix(encodedLine)) {
        final level =
            _headingLevelForLine(lineStart, lineEnd, normalizedRanges);
        encodedLine = '${'#' * level} $encodedLine';
      }

      encoded.add(encodedLine);
      lineStart = lineEnd + 1;
    }

    return encoded.join('\n');
  }

  static void _decodeLine(
    String line,
    StringBuffer output,
    List<MemoStyleRange> ranges,
  ) {
    final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
    if (headingMatch != null) {
      final start = output.length;
      _decodeInline(headingMatch.group(2) ?? '', output, ranges);
      final end = output.length;
      if (end > start) {
        ranges.add(
          MemoStyleRange(
            start: start,
            end: end,
            mark: MemoTextMark.heading,
            data: headingMatch.group(1)?.length.toString() ?? '1',
          ),
        );
      }
      return;
    }

    final todoMatch =
        RegExp(r'^(\s*)[-*+]\s+\[([ xX])\]\s*(.*)$').firstMatch(line);
    if (todoMatch != null) {
      output
        ..write(todoMatch.group(1) ?? '')
        ..write((todoMatch.group(2) ?? ' ') == ' ' ? '☐ ' : '☑ ');
      _decodeInline(todoMatch.group(3) ?? '', output, ranges);
      return;
    }

    final listMatch = RegExp(r'^(\s*)[-*+]\s+(?!\[)(.*)$').firstMatch(line);
    if (listMatch != null) {
      output
        ..write(listMatch.group(1) ?? '')
        ..write('• ');
      _decodeInline(listMatch.group(2) ?? '', output, ranges);
      return;
    }

    final quoteMatch = RegExp(r'^>\s?(.*)$').firstMatch(line);
    if (quoteMatch != null) {
      output.write('│ ');
      _decodeInline(quoteMatch.group(1) ?? '', output, ranges);
      return;
    }

    _decodeInline(line, output, ranges);
  }

  static void _decodeInline(
    String source,
    StringBuffer output,
    List<MemoStyleRange> ranges,
  ) {
    var index = 0;
    while (index < source.length) {
      if (source.startsWith('<u>', index)) {
        final end = source.indexOf('</u>', index + 3);
        if (end != -1) {
          _appendMarked(
            source.substring(index + 3, end),
            output,
            ranges,
            MemoTextMark.underline,
          );
          index = end + 4;
          continue;
        }
      }

      if (source.startsWith('**', index)) {
        final end = source.indexOf('**', index + 2);
        if (end != -1) {
          _appendMarked(
            source.substring(index + 2, end),
            output,
            ranges,
            MemoTextMark.bold,
          );
          index = end + 2;
          continue;
        }
      }

      if (source.startsWith('~~', index)) {
        final end = source.indexOf('~~', index + 2);
        if (end != -1) {
          _appendMarked(
            source.substring(index + 2, end),
            output,
            ranges,
            MemoTextMark.strikethrough,
          );
          index = end + 2;
          continue;
        }
      }

      if (source.startsWith('`', index)) {
        final end = source.indexOf('`', index + 1);
        if (end != -1) {
          _appendMarked(
            source.substring(index + 1, end),
            output,
            ranges,
            MemoTextMark.code,
            trimWhitespace: false,
          );
          index = end + 1;
          continue;
        }
      }

      if (source.startsWith('[', index)) {
        final labelEnd = source.indexOf('](', index + 1);
        if (labelEnd != -1) {
          final urlEnd = source.indexOf(')', labelEnd + 2);
          if (urlEnd != -1) {
            final label = source.substring(index + 1, labelEnd);
            final url = source.substring(labelEnd + 2, urlEnd);
            final start = output.length;
            output.write(label);
            final end = output.length;
            if (end > start && url.isNotEmpty) {
              ranges.add(
                MemoStyleRange(
                  start: start,
                  end: end,
                  mark: MemoTextMark.link,
                  data: url,
                ),
              );
            }
            index = urlEnd + 1;
            continue;
          }
        }
      }

      output.write(source[index]);
      index++;
    }
  }

  static void _appendMarked(
    String raw,
    StringBuffer output,
    List<MemoStyleRange> ranges,
    MemoTextMark mark, {
    bool trimWhitespace = true,
  }) {
    if (raw.isEmpty) {
      return;
    }

    if (!trimWhitespace) {
      final start = output.length;
      output.write(raw);
      final end = output.length;
      if (end > start) {
        ranges.add(MemoStyleRange(start: start, end: end, mark: mark));
      }
      return;
    }

    final leading = RegExp(r'^\s*').firstMatch(raw)?.group(0) ?? '';
    final trailing = RegExp(r'\s*$').firstMatch(raw)?.group(0) ?? '';
    final coreEnd = raw.length - trailing.length;
    final core = raw.substring(leading.length, coreEnd);

    output.write(leading);
    final start = output.length;
    output.write(core);
    final end = output.length;
    if (end > start) {
      ranges.add(MemoStyleRange(start: start, end: end, mark: mark));
    }
    output.write(trailing);
  }

  static String _encodeInlineLine(
    String line,
    int lineStart,
    List<MemoStyleRange> ranges,
  ) {
    final startMarkers = <int, List<String>>{};
    final endMarkers = <int, List<String>>{};

    for (final range in ranges) {
      if (range.mark == MemoTextMark.heading) {
        continue;
      }
      if (range.end <= lineStart || range.start >= lineStart + line.length) {
        continue;
      }

      final localStart = math.max(0, range.start - lineStart);
      final localEnd = math.min(line.length, range.end - lineStart);
      if (localStart >= localEnd) {
        continue;
      }

      startMarkers.putIfAbsent(localStart, () => []).add(_startMarker(range));
      endMarkers.putIfAbsent(localEnd, () => []).insert(0, _endMarker(range));
    }

    final buffer = StringBuffer();
    for (var i = 0; i <= line.length; i++) {
      for (final marker in endMarkers[i] ?? const <String>[]) {
        buffer.write(marker);
      }
      for (final marker in startMarkers[i] ?? const <String>[]) {
        buffer.write(marker);
      }
      if (i < line.length) {
        buffer.write(line[i]);
      }
    }

    return buffer.toString();
  }

  static String _startMarker(MemoStyleRange range) {
    switch (range.mark) {
      case MemoTextMark.bold:
        return '**';
      case MemoTextMark.italic:
        return '_';
      case MemoTextMark.underline:
        return '<u>';
      case MemoTextMark.strikethrough:
        return '~~';
      case MemoTextMark.code:
        return '`';
      case MemoTextMark.link:
        return '[';
      case MemoTextMark.heading:
        return '';
    }
  }

  static String _endMarker(MemoStyleRange range) {
    switch (range.mark) {
      case MemoTextMark.bold:
        return '**';
      case MemoTextMark.italic:
        return '_';
      case MemoTextMark.underline:
        return '</u>';
      case MemoTextMark.strikethrough:
        return '~~';
      case MemoTextMark.code:
        return '`';
      case MemoTextMark.link:
        return '](${range.data ?? ''})';
      case MemoTextMark.heading:
        return '';
    }
  }

  static String _encodeVisualBlockPrefix(String line) {
    final indentMatch = RegExp(r'^\s*').firstMatch(line);
    final indent = indentMatch?.group(0) ?? '';
    final rest = line.substring(indent.length);

    if (rest.startsWith('☐ ')) {
      return '$indent- [ ] ${rest.substring(2)}';
    }
    if (rest.startsWith('☑ ')) {
      return '$indent- [x] ${rest.substring(2)}';
    }
    if (rest.startsWith('• ')) {
      return '$indent- ${rest.substring(2)}';
    }
    if (rest.startsWith('│ ')) {
      return '$indent> ${rest.substring(2)}';
    }

    return line;
  }

  static bool _lineHasMark(
    int start,
    int end,
    List<MemoStyleRange> ranges,
    MemoTextMark mark,
  ) =>
      ranges.any(
        (range) => range.mark == mark && range.end > start && range.start < end,
      );

  static int _headingLevelForLine(
    int start,
    int end,
    List<MemoStyleRange> ranges,
  ) {
    final headingRange = ranges.firstWhere(
      (range) =>
          range.mark == MemoTextMark.heading &&
          range.end > start &&
          range.start < end,
      orElse: () => const MemoStyleRange(
        start: 0,
        end: 1,
        mark: MemoTextMark.heading,
        data: '1',
      ),
    );
    final parsed = int.tryParse(headingRange.data ?? '1') ?? 1;
    return parsed.clamp(1, 6);
  }

  static bool _startsWithMarkdownBlockPrefix(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        trimmed.startsWith('> ') ||
        trimmed.startsWith('# ') ||
        trimmed.startsWith('- [ ] ') ||
        trimmed.startsWith('- [x] ');
  }
}

class _TextDiff {
  const _TextDiff({
    required this.start,
    required this.oldEnd,
    required this.newEnd,
  });

  final int start;
  final int oldEnd;
  final int newEnd;

  static _TextDiff from(String oldText, String newText) {
    var start = 0;
    while (start < oldText.length &&
        start < newText.length &&
        oldText[start] == newText[start]) {
      start++;
    }

    var oldEnd = oldText.length;
    var newEnd = newText.length;
    while (oldEnd > start &&
        newEnd > start &&
        oldText[oldEnd - 1] == newText[newEnd - 1]) {
      oldEnd--;
      newEnd--;
    }

    return _TextDiff(start: start, oldEnd: oldEnd, newEnd: newEnd);
  }
}
