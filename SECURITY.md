# Security policy

## Supported versions

Only the latest release (including beta pre-releases) receives fixes.

## Reporting a vulnerability

Please **do not** open a public issue. Use GitHub's
[private vulnerability reporting](../../security/advisories/new) instead.
You'll get an answer within a week. Please include steps to reproduce and the affected version.

## Update integrity

APKs published on GitHub Releases are signed with the project's upload key, and every release
ships a `SHA256SUMS` file. The in-app updater (github flavor) checks the SHA-256 checksum before it
hands an APK to the Android installer and discards the file on a mismatch.
