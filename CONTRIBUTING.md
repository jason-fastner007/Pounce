# Contributing to Pounce

Thanks for helping! Pounce is in **beta**, so bug reports from real devices are the most valuable
contribution right now.

## Reporting bugs

Use the [bug report template](../../issues/new/choose). Include the app version (Settings → About),
your device and the steps that lead to the problem. Logs help a lot – please strip personal data.

## Development setup

```sh
flutter pub get
flutter run --flavor github            # Android
flutter run -d linux                   # needs libmpv (pacman -S mpv / apt install libmpv2)
```

See [docs/BUILDING.md](docs/BUILDING.md) for web, desktop, signing and the Rust engine.

## Before you open a pull request

```sh
flutter analyze        # must be clean
flutter test           # must pass
```

- **Code style:** follow the surrounding code. Comments and identifiers are in English.
- **Strings:** never hard-code UI text. Add it to `tool/gen_arb.py` (all 7 languages), then run
  `python3 tool/gen_arb.py && flutter gen-l10n`. If you can't translate a language, copy the
  English text and mention it in the PR.
- **UI widgets:** import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`.
- **Privacy:** no analytics, no device IDs, no new network requests without an opt-in toggle.
  Explain any new request in the PR.
- **Dependencies:** keep them few. Discuss larger additions in an issue first.
- One topic per pull request; small PRs get merged faster.

## Commit messages

Short imperative subject (`Fix crossfade stutter on skip`), optional body explaining *why*.
Release notes are generated from merged PR titles.

## License

By contributing you agree that your contributions are licensed under the
[GPL-3.0](LICENSE), like the rest of the project.
