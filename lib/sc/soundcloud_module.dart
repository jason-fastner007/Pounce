import 'package:http/http.dart' as http;

import '../core/login_launcher.dart';
import '../core/settings.dart';
import '../core/store.dart';
import '../library/account.dart';
import '../library/library.dart';
import '../modules/source_module.dart';
import 'auth.dart';
import 'soundcloud.dart';

/// SoundCloud as a source module: guest mode or signed in, home feed, search, DJ mixes.
///
/// Uses SoundCloud's unofficial api-v2 – marked [ModuleManifest.storeRestricted], so app store
/// builds leave it out.
class SoundCloudModule extends SourceModule {
  SoundCloudModule(this.sc, this.account);

  factory SoundCloudModule.create(Store store, Settings settings, http.Client client, Library library) {
    final sc = SoundCloud(store, settings, client: client);
    return SoundCloudModule(sc, Account(ScAuth(store, client, sc.wrap), sc, library, LoginLauncher.create()));
  }

  static const info = ModuleManifest(
    id: Track.soundcloud,
    name: 'SoundCloud',
    kind: ModuleKind.source,
    version: '1.0.0',
    author: 'Pounce',
    description: 'Search, home feed, likes and playlists from SoundCloud – with or without an account.',
    homepage: 'https://soundcloud.com',
    storeRestricted: true,
  );

  final SoundCloud sc;
  final Account account;

  @override
  ModuleManifest get manifest => info;

  @override
  void activate() => account.attach();

  @override
  void deactivate() => account.detach();

  @override
  void dispose() => account.dispose();

  @override
  set language(String code) => sc.language = code;

  @override
  bool get supportsDj => true;

  @override
  Future<List<Track>> search(String query, {int limit = 30}) async => (await sc.searchTracks(query)).items;

  @override
  Future<List<String>> suggestions(String query) => sc.suggestions(query);

  @override
  Future<List<Track>> related(Track seed, {int limit = 20}) => sc.related(seed.id, limit: limit);

  @override
  Future<StreamInfo> stream(Track track, {bool fast = false}) => sc.stream(track, fast: fast);

  @override
  void prefetchStream(Track track, {bool fast = false}) => sc.prefetchStream(track, fast: fast);

  @override
  Future<String?> analysisUrl(Track track) => sc.progressiveMp3(track);

  @override
  Future<List<double>> waveform(Track track) => sc.waveform(track);

  /// soundcloud.com and on.soundcloud.com links (opened from the search field).
  static bool isLink(String text) => RegExp(r'(soundcloud\.com|on\.soundcloud\.com)/').hasMatch(text);
}
