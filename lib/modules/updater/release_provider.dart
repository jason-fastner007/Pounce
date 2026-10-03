import 'models/update_info.dart';

/// Contract for update sources. The GitHub and Play builds each implement it – the rest of the
/// app only sees this interface.
abstract class ReleaseProvider {
  /// A release newer than [currentVersion], otherwise null. Network errors yield null (no crash,
  /// no retry loop).
  Future<UpdateInfo?> checkForUpdate({required String currentVersion});

  /// Starts installing [info]. GitHub: download (only after consent), SHA-256 check,
  /// hand-off to the system installer. Play: Google's update dialog. [onProgress]: 0..1.
  Future<InstallResult> install(UpdateInfo info, {void Function(double progress)? onProgress});
}

/// Outcome of an install attempt.
enum InstallResult {
  /// Handed to the installer or Play – the user confirms there.
  started,

  /// Checksum mismatch: file discarded.
  checksumMismatch,

  /// Installing from this app isn't allowed (yet) – the setting was opened.
  needsPermission,

  /// Network or other error.
  failed,
}

/// Compares semantic versions: "1.2.10" > "1.2.9", "0.2.0" > "0.2.0-beta.3" ("+7" build metadata is ignored).
bool isNewer(String candidate, String current) {
  // Semver without build metadata: "1.2.3-beta.2+7" → core [1,2,3], pre-release ["beta", 2].
  (List<int>, List<String>) parse(String v) {
    final s = v.replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
    final dash = s.indexOf('-');
    final core = dash < 0 ? s : s.substring(0, dash);
    final pre = dash < 0 ? const <String>[] : s.substring(dash + 1).split('.');
    return ([for (final p in core.split('.')) int.tryParse(p) ?? 0], pre);
  }

  final (a, ap) = parse(candidate);
  final (b, bp) = parse(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  // Same core: a release beats any pre-release of it, pre-releases compare field by field.
  if (ap.isEmpty || bp.isEmpty) return ap.isEmpty && bp.isNotEmpty;
  for (var i = 0; i < ap.length && i < bp.length; i++) {
    final x = int.tryParse(ap[i]), y = int.tryParse(bp[i]);
    final c = x != null && y != null ? x.compareTo(y) : ap[i].compareTo(bp[i]);
    if (c != 0) return c > 0;
  }
  return ap.length > bp.length;
}
