# Pounce modules

Pounce is extended through **modules**, in the spirit of Kodi add-ons. There are two kinds:

| Kind | What it adds | Written as | How users get it |
|---|---|---|---|
| **Design** (`theme`) | The studio design's accent colour | JSON (data only) | Installed at runtime from the module catalog (*Settings → Modules → Catalog*) |
| **Source** (`source`) | A music source: search, home rows, streams, related tracks, DJ analysis | Dart | Compiled into an app build; switched on and off under *Settings → Modules* |

SoundCloud is the first source module (`lib/sc/soundcloud_module.dart`). Web radio and the local library are
part of the core app and always available.

## Why sources can't be downloaded at runtime

The App Store and Google Play forbid apps from downloading code that changes their features (App Review
Guideline 2.5.2). Kodi itself is not in the App Store for exactly this reason. Flutter release builds can't
load Dart code at runtime anyway.

So Pounce draws the line like this:

- **Data** (designs) can be installed from the catalog on every platform.
- **Code** (sources) ships inside the app. Developers contribute source modules as pull requests, and each
  build decides which modules it bundles.

## The catalog

The catalog is a single JSON file, [`modules/index.json`](../modules/index.json), fetched from this repository
only when the user taps *Browse modules* (one anonymous GET to `raw.githubusercontent.com`, no identifiers).
To publish a module, open a pull request that adds an entry.

Every entry has the manifest fields:

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Lower case, `a-z 0-9 . _ -`, 2–64 chars. Designs use `theme.<name>`. Never change it after release. |
| `kind` | yes | `theme` or `source` |
| `name` | yes | Up to 40 characters |
| `version` | yes | e.g. `1.0.0`. Raise it when you change the entry: users then see *Install* again |
| `author` | yes | Up to 40 characters |
| `description` | no | Up to 240 characters |
| `homepage` | no | `https://` only |
| `storeRestricted` | no | `true` if the module uses an API or content without the rights holder's permission for app distribution (see below) |

Invalid entries are skipped, so a mistake in one entry never breaks the catalog for everyone.

## Writing a design

A design is a catalog entry with a `theme` object:

```json
{
  "id": "theme.sunset",
  "kind": "theme",
  "name": "Sunset",
  "version": "1.0.0",
  "author": "Your name",
  "description": "Warm coral, like the last minutes of golden hour.",
  "theme": { "accent": "#FF5F6D" }
}
```

`accent` must be `#RRGGBB`. Pick a colour with enough contrast on near-black (`#060709`); very dark colours
disappear on the OLED background. Today a design sets the accent colour; more design tokens (surfaces, fonts)
can be added to `ThemeModule` later without breaking existing entries.

## Writing a source module

A source module is a Dart class that extends `SourceModule` (`lib/modules/source_module.dart`):

```dart
class MyServerModule extends SourceModule {
  MyServerModule(this._http);
  final http.Client _http;

  static const info = ModuleManifest(
    id: 'myserver',
    name: 'My Server',
    kind: ModuleKind.source,
    version: '1.0.0',
    author: 'You',
    description: 'Music from my self-hosted server.',
  );

  @override
  ModuleManifest get manifest => info;

  @override
  Future<List<Track>> search(String query, {int limit = 30}) async {
    final items = await _api('/search', {'q': query, 'limit': '$limit'}); // your own HTTP helper
    return [for (final j in items) _track(j)];
  }

  @override
  Future<StreamInfo> stream(Track track, {bool fast = false}) async =>
      StreamInfo('https://my.server/stream/${track.ref}', hls: false, mime: 'audio/mpeg');

  Track _track(Map<String, dynamic> j) => Track(
    id: Track.idFor(info.id, j['id'] as String), // stable numeric ID from your string ID
    ref: j['id'] as String,                       // your own ID, handed back to you in stream()
    source: info.id,                              // routes playback back to this module
    title: j['title'] as String,
    user: ScUser(id: 0, username: j['artist'] as String),
    durationMs: j['duration_ms'] as int,
    artworkUrl: j['cover'] as String?,
  );
}
```

What to implement:

| Member | Required | Used for |
|---|---|---|
| `manifest` | yes | Name, version and author in the module manager |
| `search()` | yes | The module's tab in Search, "All" results, DJ category search |
| `stream()` | yes | Playback. `fast: true` means the user tapped the track: prefer a stream that starts quickly |
| `suggestions()` | no | Search-as-you-type |
| `home()` | no | Rows on the home page (`HomeSection(title, tracks)`) |
| `related()` | no | Autoplay after the queue ends, DJ mixes |
| `analysisUrl()` | no | A progressive MP3 the DJ can read via HTTP range for beat/key analysis |
| `waveform()` | no | Seek bar waveform (values 0..1) |
| `supportsDj` | no | `true` when `related()` and `analysisUrl()` work, so DJ mixes can use your tracks |
| `activate()` / `deactivate()` | no | Called when the user switches the module on or off |
| `language` | no | UI language for localised content |

Rules:

- **Every track carries `source: <your id>`.** Player, DJ and analysis route each track back to its module
  by that field. If your IDs are strings, set `ref` and `id: Track.idFor(id, ref)`.
- **Privacy:** no analytics, no device IDs. Don't send requests until the user uses your module.
- **Errors:** throw from `stream()` when a track can't play. The player skips to the next track. Return
  empty lists from the optional methods instead of throwing.
- **Strings:** UI text goes into `tool/gen_arb.py` like everywhere else in the app.

Register the module in `lib/modules/bundled.dart`:

```dart
List<SourceModule> bundledSources(Store store, Settings settings, http.Client client, Library library) => [
  if (!storeBuild) SoundCloudModule.create(store, settings, client, library),
  MyServerModule(client),
];
```

Then add tests (see `test/modules_test.dart` for a minimal fake module) and an entry with `"kind": "source"`
to `modules/index.json`, so the catalog lists it as included.

## App store builds and `storeRestricted`

App stores reject apps that stream content without the rights holder's permission (App Review Guidelines
5.2.2/5.2.3). Modules built on unofficial APIs, like the SoundCloud module, set `storeRestricted: true` in their
manifest and are bundled behind the `storeBuild` constant:

```sh
flutter build ios --release --dart-define=POUNCE_STORE_BUILD=true
```

Because `storeBuild` is a compile-time constant, the compiler drops restricted modules completely. Their code,
endpoints and keys are not in the binary, and there is no hidden switch to turn them back on (guideline 2.3.1).
In a store build the catalog hides restricted modules, too.

A source module with an official API and permission to use it doesn't need the flag and can ship in every
build, including the App Store version.
