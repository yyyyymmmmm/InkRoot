abstract final class TextAnalysisUtils {
  static List<String> extractTerms(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), ' ')
        .replaceAll(RegExp('<[^>]+>'), ' ')
        .replaceAll(RegExp(r'[-*_`#~>\[\](){}.,，。!?！？:：;；、|/\\]+'), ' ');

    final terms = <String>[];
    for (final raw in cleaned.split(RegExp(r'\s+'))) {
      final token = raw.trim();
      if (token.isEmpty) {
        continue;
      }
      if (_isMostlyChinese(token)) {
        terms.addAll(_chineseNgrams(token));
      } else if (token.length > 1 && !_isStopWord(token)) {
        terms.add(token);
      }
    }
    return terms;
  }

  static Set<String> extractKeywords(String text) => extractTerms(text).toSet();

  static double jaccardSimilarity(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) {
      return 0;
    }
    final intersection = left.intersection(right).length;
    final union = left.union(right).length;
    return union == 0 ? 0 : intersection / union;
  }

  static bool _isMostlyChinese(String token) {
    final chineseCount = RegExp(r'[\u4e00-\u9fa5]').allMatches(token).length;
    return chineseCount >= 2 && chineseCount >= token.length * 0.6;
  }

  static List<String> _chineseNgrams(String token) {
    final chars = RegExp(r'[\u4e00-\u9fa5]')
        .allMatches(token)
        .map((match) => match.group(0)!)
        .toList();
    if (chars.length <= 1) {
      return const [];
    }

    final terms = <String>{};
    for (var n = 2; n <= 3; n++) {
      if (chars.length < n) {
        continue;
      }
      for (var i = 0; i <= chars.length - n; i++) {
        final term = chars.sublist(i, i + n).join();
        if (!_isStopWord(term)) {
          terms.add(term);
        }
      }
    }
    return terms.toList();
  }

  static bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'is',
      'at',
      'which',
      'on',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'with',
      'to',
      'for',
      'of',
      'as',
      'by',
      'this',
      'that',
      '的',
      '了',
      '和',
      '是',
      '在',
      '我',
      '有',
      '个',
      '就',
      '不',
      '一个',
      '这个',
      '那个',
      '可以',
      '如果',
      '但是',
    };
    return stopWords.contains(word);
  }
}
