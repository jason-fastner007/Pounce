# Building Pounce

Requirements: Flutter 3.47 (stable), Java 17 for Android, Python 3 for the code generators.

```sh
flutter pub get
flutter analyze && flutter test
```

## Android

```sh
flutter run --flavor github                                   # debug on a device
flutter build apk --release --flavor github --target-platform android-arm64 --split-per-abi
flutter build appbundle --release --flavor play --target-platform android-arm64
```

- `github` flavor: in-app updater for GitHub Releases. Pass
  `--dart-define=POUNCE_GITHUB_REPO=<owner>/<repo>` to enable it (the release workflow does this).
  Without it the updater is hidden.
- `play` flavor: no install permission, updates through Google Play.
- Release builds use R8 (`android/app/proguard-rules.pro`) and 16 KB page-aligned native libraries.

### Signing

Create an upload keystore once and keep it **outside** the repository (it's git-ignored anyway):

```sh
keytool -genkeypair -v -keystore ~/pounce-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

Local builds read `android/key.properties`:

```properties
storeFile=/home/you/pounce-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

CI reads the same values from the environment (`POUNCE_KEYSTORE`, `POUNCE_KEYSTORE_PASSWORD`,
`POUNCE_KEY_ALIAS`, `POUNCE_KEY_PASSWORD`). Without a keystore, release builds fall back to the
debug key – fine for testing, not for publishing.

For GitHub Actions add these repository secrets:

| Secret | Value |
|---|---|
| `POUNCE_KEYSTORE_BASE64` | `base64 -w0 ~/pounce-upload.jks` |
| `POUNCE_KEYSTORE_PASSWORD` | keystore password |
| `POUNCE_KEY_ALIAS` | `upload` |
| `POUNCE_KEY_PASSWORD` | key password |

### Releasing

1. Bump `version:` in `pubspec.yaml` (e.g. `0.2.0-beta.2+9`).
2. Commit, then tag and push: `git tag v0.2.0-beta.2 && git push --tags`.
3. `.github/workflows/release.yml` builds the signed APK and AAB, writes `SHA256SUMS` and publishes the
   release (tags containing `-` become pre-releases).

## Rust engine (deckengine)

Beat, key, loudness, cue/drop analysis and audio fingerprints come from
[deckengine](https://github.com/jason-fastner007/deckengine) (Rust, AGPL-3.0-or-later). Prebuilt libraries are checked in:

- Android: `packages/native_player/android/src/main/jniLibs/arm64-v8a/libdeckengine.so`
- Linux: `linux/deckengine/libdeckengine.so`
- Web: `web/deckengine.wasm`

To rebuild them from source (needs Rust and the Android NDK):

```sh
DECKENGINE=~/src/deckengine tool/build_deckengine.sh
```

If the library can't be loaded, Pounce keeps working – only DJ analysis is unavailable.

## Desktop

- **Linux:** needs libmpv (`pacman -S mpv`, `apt install libmpv2`). `flutter run -d linux`.
- **Windows:** put `libmpv-2.dll` (e.g. from
  [mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake/releases)) next to the `.exe`.
- **macOS / iOS:** AVPlayer, no extra dependencies.

## App Store build (iOS)

App store builds leave out modules marked `storeRestricted` (SoundCloud uses an unofficial API):

```sh
flutter build ipa --release --dart-define=POUNCE_STORE_BUILD=true
```

That version is a web radio player with the local library, designs from the module catalog and every source
module that is cleared for app distribution. Before submitting, also check:

- Signing: set your team in Xcode (`ios/Runner.xcworkspace` → Runner → Signing & Capabilities).
- `ios/Runner/PrivacyInfo.xcprivacy` still matches what the app does (no tracking, no collected data).
- App Store Connect: privacy policy URL, age rating, screenshots, and "Data Not Collected" in the privacy labels.
- The license: Pounce is GPL-3.0, which the FSF considers incompatible with the App Store terms. Publishing there
  needs the consent of all copyright holders (or an additional permission in the license).

See [MODULES.md](MODULES.md) for how restricted modules are compiled out.

## Web

SoundCloud's API only allows browser requests from soundcloud.com (CORS), so the web build needs a proxy:

- Local: `dart run tool/proxy/dev_proxy.dart`, then build with
  `--dart-define=SC_PROXY=http://localhost:8787/?url=`
- Hosted: deploy `tool/proxy/worker.js` as a Cloudflare Worker (only SoundCloud hosts are allowed).
- The proxy can also be set in the app settings.

```sh
flutter build web --wasm --dart-define=SC_PROXY=https://<proxy>/?url=
```

Performance notes:

- Serve with the headers from `web/_headers` (COOP `same-origin` + COEP `credentialless`) so Skwasm can
  render multi-threaded (measured 60 instead of ~22 FPS during playback).
- Fonts in `assets/fonts` are subsets (originals in `tool/fonts_src`); regenerate with
  `tool/subset_fonts.sh` (`pip install fonttools`).
- `web/flutter_bootstrap.js` enables the Wasm renderer for Firefox as well. Don't use
  `cacheWidth`/`ResizeImage` on the web – Skwasm shows downscaled images zoomed in Firefox.
- DRM-protected tracks play via EME (Widevine/PlayReady) in Chrome, Edge and Firefox. Native apps and
  Safari skip them.

## Translations

All strings live in `tool/gen_arb.py` (one table, 7 languages):

```sh
python3 tool/gen_arb.py && flutter gen-l10n
```

## Icons

App icons, splash and web icons are generated from the source artwork:

```sh
tool/gen_icons.sh <logo-without-text.png> <logo-with-text.png>
```

## Tests

```sh
flutter test                                   # unit tests
flutter test --run-skipped --tags live         # against the real SoundCloud / lyrics APIs
flutter test integration_test -d linux         # end-to-end incl. real (muted) playback
```

README screenshots are rendered from the real app in a phone layout:

```sh
flutter test integration_test/screenshots_test.dart -d linux --dart-define=SHOTS=$PWD/docs/screenshots
```
