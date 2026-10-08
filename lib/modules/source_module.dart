import 'dart:typed_data';

import '../player/stream_info.dart';
import '../sc/models.dart';
import 'module.dart';

export '../player/stream_info.dart';
export '../sc/models.dart' show Track, ScUser;
export 'module.dart';

/// A titled row of tracks on the home page.
class HomeSection {
  const HomeSection(this.title, this.tracks);
  final String title;
  final List<Track> tracks;
}

/// A music source (SoundCloud, a self-hosted server, …), compiled into the app.
///
/// Tracks a module returns must carry `source: id` – the player routes playback, related tracks
/// and DJ analysis back to the module by that field. Modules with string IDs set [Track.ref] and
/// `id: Track.idFor(id, ref)`. See docs/MODULES.md.
abstract class SourceModule extends PounceModule {
  Future<List<Track>> search(String query, {int limit = 30});

  /// Search-as-you-type suggestions.
  Future<List<String>> suggestions(String query) async => const [];

  /// Rows for the home page.
  Future<List<HomeSection>> home() async => const [];

  /// Similar tracks for autoplay and DJ mixes.
  Future<List<Track>> related(Track seed, {int limit = 20}) async => const [];

  /// A directly playable URL for [track]. [fast]: the user tapped the track – prefer a stream
  /// that starts quickly over the best quality.
  Future<StreamInfo> stream(Track track, {bool fast = false});

  /// Resolve the stream ahead of time (finger on a row, next track in the queue).
  void prefetchStream(Track track, {bool fast = false}) => stream(track, fast: fast).ignore();

  /// Progressive MP3 for the DJ's beat/key analysis (fetched via HTTP range), null = no analysis.
  Future<String?> analysisUrl(Track track) async => null;

  /// Loudness envelope (0..1) for the seek bar, empty = none.
  Future<List<double>> waveform(Track track) async => const [];

  /// Can tracks of this module be beat-matched in DJ mixes (needs [analysisUrl] and [related])?
  bool get supportsDj => false;

  /// UI language for localised content.
  set language(String code) {}
}

/// What player, DJ and analysis need from wherever a track comes from – implemented by
/// `ModuleRegistry`, which routes each call to the track's module.
abstract interface class TrackSource {
  Future<StreamInfo> stream(Track track, {bool fast = false});
  void prefetchStream(Track track, {bool fast = false});
  Future<List<Track>> related(Track seed, {int limit = 20});

  /// Tracks from all active sources that support DJ mixes.
  Future<List<Track>> search(String query, {int limit = 30});
  Future<String?> analysisUrl(Track track);
  Future<List<double>> waveform(Track track);

  /// Bytes [start]..[end] (inclusive) of a file.
  Future<Uint8List> range(String url, int start, int end);
}

/// The track's module isn't part of this build or was switched off.
class ModuleUnavailable implements Exception {
  ModuleUnavailable(this.source);
  final String source;
  @override
  String toString() => 'ModuleUnavailable($source)';
}
