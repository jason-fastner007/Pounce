import 'package:material_ui/material_ui.dart';

import '../player/audio_engine.dart' show LoudMode;

import 'store.dart';

enum StreamQuality { high, saver }

/// Beat background: strength as a factor.
enum BeatLevel {
  off(0),
  light(.35),
  medium(.65),
  strong(1);

  const BeatLevel(this.intensity);
  final double intensity;
}

/// The single accent colour; `cover` follows the current artwork.
enum Accent {
  amber(Color(0xFFFF7A00)),
  cyan(Color(0xFF00F0FF)),
  cover(Color(0xFFFF7A00));

  const Accent(this.color);
  final Color color;
}

/// App settings, persisted in the [Store].
class Settings extends ChangeNotifier {
  Settings(this._store);

  final Store _store;

  /// Accent colour of the studio design.
  Accent get accent => Accent.values.asNameMap()[_store.get<String>('accent')] ?? Accent.cyan; // new installs: neon cyan (existing choice is kept)
  set accent(Accent v) => _put('accent', v.name);

  /// Loud/quiet mode (loudness normalisation).
  LoudMode get loudMode => LoudMode.values.asNameMap()[_store.get<String>('loud')] ?? LoudMode.normal;
  set loudMode(LoudMode v) => _put('loud', v.name);

  /// Master volume 0..1 (linear).
  double get volume => (_store.get<num>('volume') ?? 1).toDouble();
  set volume(double v) => _store.set('volume', v); // no rebuild – the slider keeps its own state

  /// Strength of the beat background (default: light).
  BeatLevel get beatLevel => BeatLevel.values.asNameMap()[_store.get<String>('beatLevel')] ?? BeatLevel.light;
  set beatLevel(BeatLevel v) => _put('beatLevel', v.name);

  bool get beatBackground => beatLevel != BeatLevel.off;

  /// Desktop layout: rail expanded, inspector open.
  bool get railExpanded => _store.get<bool>('railExpanded') ?? false;
  set railExpanded(bool v) => _put('railExpanded', v);

  bool get inspectorOpen => _store.get<bool>('inspectorOpen') ?? true;
  set inspectorOpen(bool v) => _put('inspectorOpen', v);

  /// null = Systemsprache.
  Locale? get locale {
    final tag = _store.get<String>('locale');
    return tag == null ? null : Locale(tag);
  }

  set locale(Locale? v) => _put('locale', v?.languageCode);

  StreamQuality get quality => StreamQuality.values.byName(_store.get<String>('quality') ?? 'high');
  set quality(StreamQuality v) => _put('quality', v.name);

  /// Keep playing similar tracks after the queue ends.
  bool get autoplay => _store.get<bool>('autoplay') ?? true;
  set autoplay(bool v) => _put('autoplay', v);

  /// Check for updates at most daily (off by default – GDPR: only after consent).
  bool get autoCheckUpdates => _store.get<bool>('autoCheckUpdates') ?? false;
  set autoCheckUpdates(bool v) => _put('autoCheckUpdates', v);

  /// Web radio as a source (radio-browser.info). Off = not a single request, no radio in UI and search.
  bool get radioEnabled => _store.get<bool>('radioEnabled') ?? true;
  set radioEnabled(bool v) => _put('radioEnabled', v);

  /// Load MP3 128 instead of HLS when a track is tapped (faster start); pre-buffered tracks keep [quality].
  bool get fastStart => _store.get<bool>('fastStart') ?? true;
  set fastStart(bool v) => _put('fastStart', v);

  /// Skip 30 s previews when advancing (tapped tracks still play).
  bool get skipPreviews => _store.get<bool>('skipPreviews') ?? false;
  set skipPreviews(bool v) => _put('skipPreviews', v);

  /// First-run setup wizard finished (or skipped).
  bool get setupDone => _store.get<bool>('setupDone') ?? false;
  set setupDone(bool v) => _put('setupDone', v);

  /// Opt-in for Echolot song recognition (not active yet; stored so the choice survives).
  bool get recognitionOptIn => _store.get<bool>('recognitionOptIn') ?? false;
  set recognitionOptIn(bool v) => _put('recognitionOptIn', v);

  /// CORS proxy for the web build (empty = off).
  String get proxy => _store.get<String>('proxy') ?? const String.fromEnvironment('SC_PROXY');
  set proxy(String v) => _put('proxy', v.trim());

  void _put(String key, Object? value) {
    _store.set(key, value);
    notifyListeners();
  }
}
