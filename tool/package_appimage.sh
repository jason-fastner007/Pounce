#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="${1:-build/linux/x64/release/bundle}"
OUTPUT="${2:-dist/pounce-linux-x86_64.AppImage}"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Bundle dir $BUNDLE_DIR does not exist."
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"
APPDIR=$(mktemp -d -t appdir-XXXXXX)
trap 'rm -rf "$APPDIR"' EXIT

mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/bin/"
cp docs/assets/icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/pounce.png"
cp docs/assets/icon.png "$APPDIR/pounce.png"

cat << 'EOF' > "$APPDIR/pounce.desktop"
[Desktop Entry]
Name=Pounce
Exec=pounce
Icon=pounce
Type=Application
Categories=AudioVideo;Audio;Player;
Terminal=false
StartupWMClass=dev.kittyfork.kittyfork
EOF
cp "$APPDIR/pounce.desktop" "$APPDIR/usr/share/applications/"

cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${HERE}/usr/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr/bin"
exec "${HERE}/usr/bin/pounce" "$@"
EOF
chmod +x "$APPDIR/AppRun"

if [ ! -f "appimagetool" ]; then
  curl -L -o appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool
fi

ARCH=x86_64 ./appimagetool --appimage-extract-and-run "$APPDIR" "$OUTPUT"
