import 'dart:math' as math;

/// Represents the 24 keys of the Camelot wheel system for harmonic DJ mixing.
///
/// 'A' stands for minor, 'B' for major.
/// Harmonic transitions:
/// - Distance 0: exact key (identical)
/// - Distance 1: neighbour on the wheel (+1 / -1) or relative major/minor (e.g. 8A <-> 8B)
/// - Distance 2: diagonal change or 2-step energy change
/// - Distance >= 3: dissonant
enum CamelotKey {
  key1A('1A', 1, 'A', 'Abm', 'G#m', 8, true),
  key2A('2A', 2, 'A', 'Ebm', 'D#m', 3, true),
  key3A('3A', 3, 'A', 'Bbm', 'A#m', 10, true),
  key4A('4A', 4, 'A', 'Fm', 'Fm', 5, true),
  key5A('5A', 5, 'A', 'Cm', 'Cm', 0, true),
  key6A('6A', 6, 'A', 'Gm', 'Gm', 7, true),
  key7A('7A', 7, 'A', 'Dm', 'Dm', 2, true),
  key8A('8A', 8, 'A', 'Am', 'Am', 9, true),
  key9A('9A', 9, 'A', 'Em', 'Em', 4, true),
  key10A('10A', 10, 'A', 'Bm', 'Bm', 11, true),
  key11A('11A', 11, 'A', 'F#m', 'Gbm', 6, true),
  key12A('12A', 12, 'A', 'Dbm', 'C#m', 1, true),

  key1B('1B', 1, 'B', 'B', 'B', 11, false),
  key2B('2B', 2, 'B', 'F#', 'Gb', 6, false),
  key3B('3B', 3, 'B', 'Db', 'C#', 1, false),
  key4B('4B', 4, 'B', 'Ab', 'G#', 8, false),
  key5B('5B', 5, 'B', 'Eb', 'D#', 3, false),
  key6B('6B', 6, 'B', 'Bb', 'A#', 10, false),
  key7B('7B', 7, 'B', 'F', 'F', 5, false),
  key8B('8B', 8, 'B', 'C', 'C', 0, false),
  key9B('9B', 9, 'B', 'G', 'G', 7, false),
  key10B('10B', 10, 'B', 'D', 'D', 2, false),
  key11B('11B', 11, 'B', 'A', 'A', 9, false),
  key12B('12B', 12, 'B', 'E', 'E', 4, false);

  const CamelotKey(this.code, this.number, this.letter, this.standardName, this.altName, this.pitchClass, this.isMinor);

  final String code;
  final int number;
  final String letter;
  final String standardName;
  final String altName;
  final int pitchClass; // 0=C, 1=C#, 2=D, 3=D#, 4=E, 5=F, 6=F#, 7=G, 8=G#, 9=A, 10=A#, 11=B
  final bool isMinor;

  bool get isMajor => !isMinor;

  /// O(1) map lookup table for [fromCode] to avoid repeated iteration over [values].
  static final Map<String, CamelotKey> _byCode = {
    for (final k in values) k.code: k,
  };

  /// O(1) lookup tables indexed by pitch class (0..11) for [fromPitchClass].
  static final List<CamelotKey?> _minorByPitchClass = _buildPitchClassLookup(isMinor: true);
  static final List<CamelotKey?> _majorByPitchClass = _buildPitchClassLookup(isMinor: false);

  static List<CamelotKey?> _buildPitchClassLookup({required bool isMinor}) {
    final list = List<CamelotKey?>.filled(12, null);
    for (final k in values) {
      if (k.isMinor == isMinor) {
        list[k.pitchClass] = k;
      }
    }
    return list;
  }

  /// Circular difference on the 12-hour Camelot wheel (0..6).
  int wheelDiff(CamelotKey other) {
    final diff = (number - other.number).abs();
    return math.min(diff, 12 - diff);
  }

  /// Harmonic distance (0 = identical, 1 = perfectly compatible, 2 = transitional change, >=3 = dissonant).
  int distanceTo(CamelotKey other) {
    if (this == other) return 0;
    final numDiff = wheelDiff(other);
    final letterDiff = letter == other.letter ? 0 : 1;

    if (numDiff == 0 && letterDiff == 1) return 1; // Relatives Dur/Moll
    if (numDiff == 1 && letterDiff == 0) return 1; // Direct neighbour
    if (numDiff == 1 && letterDiff == 1) return 2; // Diagonal neighbour
    if (numDiff == 2 && letterDiff == 0) return 2; // 2-Schritt-Energiewechsel
    return numDiff + letterDiff;
  }

  bool isHarmonicWith(CamelotKey other) => distanceTo(other) <= 1;

  bool isExactMatch(CamelotKey other) => this == other;

  bool isRelativeMajorMinor(CamelotKey other) => number == other.number && letter != other.letter;

  bool isAdjacentOnWheel(CamelotKey other) => letter == other.letter && wheelDiff(other) == 1;

  double compatibilityScore(CamelotKey other) {
    return switch (distanceTo(other)) {
      0 => 1.0,
      1 => isRelativeMajorMinor(other) ? 0.95 : 0.90,
      2 => 0.65,
      3 => 0.30,
      _ => 0.0,
    };
  }

  /// Fast O(1) lookup by Camelot code (e.g. "8A", "11B").
  static CamelotKey? fromCode(String code) {
    return _byCode[code.trim().toUpperCase()];
  }

  /// Fast O(1) lookup by pitch class (0..11) and major/minor flag.
  static CamelotKey? fromPitchClass(int pitchClass, bool isMinor) {
    final pc = (pitchClass % 12 + 12) % 12;
    return isMinor ? _minorByPitchClass[pc] : _majorByPitchClass[pc];
  }
}
