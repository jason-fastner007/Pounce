#!/usr/bin/env bash
# Subsets the fonts from tool/fonts_src into assets/fonts (the web build loads them before the first frame).
#   - only scripts in use: Latin (incl. Vietnamese), Greek, Cyrillic, punctuation, arrows, maths
#     (everything else, e.g. Arabic/CJK, still comes from the fallback fonts)
#   - weight axis limited to 400–800 (the UI uses nothing else), opsz stays variable
#   - no hinting (Flutter renders unhinted)
# Requires fonttools:  pip install fonttools
set -euo pipefail
KF=$(cd "$(dirname "$0")/.." && pwd)
SRC="$KF/tool/fonts_src"
OUT="$KF/assets/fonts"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

UNICODES="U+0000-024F,U+0259,U+02B0-036F,U+0370-03FF,U+0400-052F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,\
U+2100-218F,U+2190-21FF,U+2200-22FF,U+2300-23FF,U+25A0-25FF,U+2713,U+2715,U+FEFF,U+FFFD"

for f in Inter JetBrainsMono; do
  pyftsubset "$SRC/$f.ttf" --unicodes="$UNICODES" \
    --layout-features+=tnum,case,zero,sups,subs,ordn \
    --no-hinting --desubroutinize --name-IDs='*' \
    --output-file="$TMP/$f.ttf"
  fonttools varLib.instancer "$TMP/$f.ttf" wght=400:800 -q -o "$OUT/$f.ttf"
  printf '%-16s %7d -> %7d Bytes\n' "$f" "$(stat -c%s "$SRC/$f.ttf")" "$(stat -c%s "$OUT/$f.ttf")"
done
