class FillerWord {
  const FillerWord(this.word, this.count);

  final String word;
  final int count;
}

class FillerWordDetector {
  static const List<String> _fillers = [
    'um',
    'uh',
    'uhm',
    'hmm',
    'hm',
    'er',
    'ah',
    'eh',
    'mm',
    'mmm',
    'mmhmm',
    'uhhuh',
    'like',
    'you know',
    'well',
    'actually',
    'basically',
    'i mean',
    'kind of',
    'sort of',
    'you see',
    'right',
    'okay',
    'ok',
    'so',
    'oh',
  ];

  List<FillerWord> detect(String transcript) {
    if (transcript.trim().isEmpty) {
      return const [];
    }
    final cleaned = transcript
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final counts = <String, int>{};
    for (final filler in _fillers) {
      final pattern = RegExp('(?<![a-z])${RegExp.escape(filler)}(?![a-z])');
      final n = pattern.allMatches(cleaned).length;
      if (n > 0) {
        counts[filler] = n;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => FillerWord(e.key, e.value)).toList();
  }
}
