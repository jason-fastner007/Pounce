import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Key systems that cover SoundCloud's cenc streams (`ctr-encrypted-hls`).
const _keySystems = ['com.widevine.alpha', 'com.microsoft.playready.recommendation', 'com.microsoft.playready'];

/// Asks the browser for a suitable CDM for AAC in MP4 (cenc).
/// Firefox with DRM playback disabled shows its "enable DRM" bar while doing so.
Future<bool> probe() async {
  final nav = web.window.navigator;
  // Only available in secure contexts (HTTPS, localhost).
  if (!(nav as JSObject).has('requestMediaKeySystemAccess')) return false;
  final config = [
    web.MediaKeySystemConfiguration(
      initDataTypes: ['cenc'.toJS].toJS,
      audioCapabilities: [web.MediaKeySystemMediaCapability(contentType: 'audio/mp4; codecs="mp4a.40.2"')].toJS,
    ),
  ].toJS;
  for (final system in _keySystems) {
    try {
      await nav.requestMediaKeySystemAccess(system, config).toDart;
      return true;
    } catch (_) {
      // Try the next system.
    }
  }
  return false;
}
