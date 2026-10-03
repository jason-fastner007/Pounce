import '../lib/dj/camelot_key.dart';

void main() {
  print('Running CamelotKey tests...');

  // Test fromCode
  assert(CamelotKey.fromCode('8A') == CamelotKey.key8A, '8A failed');
  assert(CamelotKey.fromCode(' 8a ') == CamelotKey.key8A, 'case/space 8a failed');
  assert(CamelotKey.fromCode('11B') == CamelotKey.key11B, '11B failed');
  assert(CamelotKey.fromCode('invalid') == null, 'invalid code failed');

  // Test fromPitchClass
  assert(CamelotKey.fromPitchClass(0, true) == CamelotKey.key5A, '0 minor failed');
  assert(CamelotKey.fromPitchClass(0, false) == CamelotKey.key8B, '0 major failed');
  assert(CamelotKey.fromPitchClass(9, true) == CamelotKey.key8A, '9 minor failed');
  assert(CamelotKey.fromPitchClass(11, false) == CamelotKey.key1B, '11 major failed');
  assert(CamelotKey.fromPitchClass(-12, true) == CamelotKey.key5A, 'negative pitch class failed');
  assert(CamelotKey.fromPitchClass(12, false) == CamelotKey.key8B, 'out-of-bounds pitch class failed');

  // Test harmonic distance & compatibility
  assert(CamelotKey.key8A.distanceTo(CamelotKey.key8A) == 0, 'distanceTo self failed');
  assert(CamelotKey.key8A.distanceTo(CamelotKey.key8B) == 1, 'distanceTo relative failed');
  assert(CamelotKey.key8A.distanceTo(CamelotKey.key7A) == 1, 'distanceTo neighbor failed');
  assert(CamelotKey.key8A.isHarmonicWith(CamelotKey.key8B), 'isHarmonicWith failed');

  print('All CamelotKey tests passed successfully!');
}
