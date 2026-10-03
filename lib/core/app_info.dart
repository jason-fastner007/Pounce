/// Build-time app metadata (Flutter passes the pubspec version as `FLUTTER_BUILD_NAME`).
const appVersion = String.fromEnvironment('FLUTTER_BUILD_NAME', defaultValue: '0.0.0-dev');

/// Pre-release builds (`0.2.0-beta.1`) show a beta badge and note.
final isBeta = appVersion.contains('-');
