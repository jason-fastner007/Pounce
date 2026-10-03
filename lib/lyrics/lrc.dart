/// One line of synced lyrics.
class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration time;
  final String text;
}

class Lyrics {
  const Lyrics({required this.lines, required this.synced, required this.source});

  final List<LyricLine> lines;
  final bool synced;
  final String source;

  /// Index of the active line (binary search).
  int indexAt(Duration pos) {
    var lo = 0, hi = lines.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= pos) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }

  static final _tag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');

  /// Parses LRC; without timestamps -> unsynchronised.
  static Lyrics? parse(String raw, String source) {
    final lines = <LyricLine>[];
    for (final row in raw.split(RegExp(r'\r?\n'))) {
      final tags = _tag.allMatches(row).toList();
      if (tags.isEmpty) continue;
      final text = row.substring(tags.last.end).trim();
      for (final m in tags) {
        final frac = m.group(3) ?? '0';
        final ms = int.parse(frac.padRight(3, '0').substring(0, 3));
        lines.add(
          LyricLine(Duration(minutes: int.parse(m.group(1)!), seconds: int.parse(m.group(2)!), milliseconds: ms), text),
        );
      }
    }
    if (lines.isNotEmpty) {
      lines.sort((a, b) => a.time.compareTo(b.time));
      return Lyrics(lines: lines, synced: true, source: source);
    }
    final plain = raw.trim();
    if (plain.isEmpty) return null;
    return Lyrics(
      lines: [for (final l in plain.split('\n')) LyricLine(Duration.zero, l.trim())],
      synced: false,
      source: source,
    );
  }
}
