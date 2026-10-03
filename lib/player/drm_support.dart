import 'drm_support_io.dart' if (dart.library.js_interop) 'drm_support_web.dart' as impl;

/// Can this platform play SoundCloud DRM (cenc: Widevine/PlayReady)?
/// Browser: via EME, decryption happens only in the CDM. Native: not yet.
Future<bool> probeDrmPlayback() => impl.probe();
