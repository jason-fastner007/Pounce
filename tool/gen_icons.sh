#!/bin/sh
# Generates all app icons, splash and web/README images from the two source logos.
# Usage: tool/gen_icons.sh <logo-without-text.jpg> <logo-with-text.jpg>
set -e
cd "$(dirname "$0")/.."
MARK_SRC="$1"; TEXT_SRC="$2"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# Crop to the artwork, centre it on a square and binarise (the sources are 1-bit art saved as JPEG).
square() { # src out
  magick "$1" -colorspace gray -threshold 50% -trim +repage \
    -gravity center -background black -extent "%[fx:max(w,h)]x%[fx:max(w,h)]" "$2"
}
square "$MARK_SRC" "$T/mark.png"
square "$TEXT_SRC" "$T/text.png"
# White artwork on transparent (for adaptive/monochrome icons and in-app use).
magick "$T/mark.png" -alpha copy -fill white -colorize 100 "$T/mark_alpha.png"

# icon <src> <size> <artwork fraction> <out> [bg]
icon() {
  inner=$(( $2 * $3 / 100 ))
  magick "$1" -filter Lanczos -resize ${inner}x${inner} -gravity center -background "${5:-black}" -extent $2x$2 "$4"
}

R=android/app/src/main/res
for d in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  n=${d%%:*}; rest=${d#*:}; s=${rest%%:*}; fg=${rest#*:}
  mkdir -p $R/mipmap-$n $R/drawable-$n
  icon "$T/mark.png" $s 82 $R/mipmap-$n/ic_launcher.png
  # Adaptive foreground: 108dp canvas, artwork inside the 66dp safe zone.
  icon "$T/mark_alpha.png" $fg 58 $R/drawable-$n/ic_launcher_foreground.png none
done
mkdir -p $R/mipmap-anydpi-v26 $R/drawable-nodpi
cat > $R/mipmap-anydpi-v26/ic_launcher.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
XML
icon "$T/mark_alpha.png" 288 100 $R/drawable-nodpi/splash_logo.png none

W=web
icon "$T/mark.png" 32 90 $W/favicon.png
icon "$T/mark.png" 180 80 $W/icons/apple-touch-icon.png
icon "$T/mark.png" 192 86 $W/icons/Icon-192.png
icon "$T/mark.png" 512 86 $W/icons/Icon-512.png
icon "$T/mark.png" 192 62 $W/icons/Icon-maskable-192.png
icon "$T/mark.png" 512 62 $W/icons/Icon-maskable-512.png

mkdir -p assets/brand docs/assets
icon "$T/mark_alpha.png" 512 100 assets/brand/pounce_mark.png none
icon "$T/text.png" 640 100 docs/assets/logo.png
icon "$T/mark.png" 1024 100 docs/assets/icon.png

# Desktop
if [ -d windows/runner/resources ]; then
  for s in 16 32 48 256; do icon "$T/mark.png" $s 88 "$T/w$s.png"; done
  magick "$T/w16.png" "$T/w32.png" "$T/w48.png" "$T/w256.png" windows/runner/resources/app_icon.ico
fi
M=macos/Runner/Assets.xcassets/AppIcon.appiconset
if [ -d $M ]; then
  for s in 16 32 64 128 256 512 1024; do icon "$T/mark.png" $s 82 $M/app_icon_$s.png; done
fi
I=ios/Runner/Assets.xcassets/AppIcon.appiconset
if [ -d $I ]; then
  for f in $I/Icon-App-*.png; do
    b=${f##*Icon-App-}; b=${b%.png}; pt=${b%%x*}; k=${b##*@}; k=${k%x}
    s=$(python3 -c "print(round($pt*$k))")
    icon "$T/mark.png" $s 80 "$f"; magick "$f" -alpha off "$f"
  done
fi
echo done
