#!/usr/bin/env bash
# Firebase Test Lab: Robo-Test von Pounce auf echten Geraeten.
# Das Robo-Skript (robo_script.json) richtet die App als Gast ein (ohne SoundCloud-Login),
# startet einen DJ-Mix und prueft per "dumpsys media_session", dass wirklich Musik laeuft.
# Danach erkundet Robo selbststaendig den Rest der App, bis --timeout erreicht ist.
#
# Voraussetzungen (einmalig):
#   gcloud auth login
#   gcloud config set project <DEIN-FIREBASE-PROJEKT>
#   gcloud services enable testing.googleapis.com toolresults.googleapis.com
#
# Aufruf:  bash tool/testlab/run_testlab.sh
# Optional: APK=pfad.apk DEVICES="oriole:33 husky:34" TIMEOUT=15m bash tool/testlab/run_testlab.sh
# Geraete-Liste: gcloud firebase test android models list --filter=form=PHYSICAL
set -euo pipefail
cd "$(dirname "$0")/../.."

# Die Rust-Engine gibt es nur fuer arm64 -> nur echte ARM-Geraete (keine x86-Emulatoren).
DEVICES="${DEVICES:-oriole:33 husky:34}"
TIMEOUT="${TIMEOUT:-10m}"
APK="${APK:-}"

if [ -z "$APK" ]; then
  flutter build apk --release --flavor github --target-platform android-arm64
  APK=build/app/outputs/flutter-apk/app-github-release.apk
fi

args=()
for d in $DEVICES; do
  args+=(--device "model=${d%%:*},version=${d##*:},locale=en,orientation=portrait")
done

gcloud firebase test android run \
  --type robo \
  --app "$APK" \
  --robo-script tool/testlab/robo_script.json \
  --timeout "$TIMEOUT" \
  --results-history-name "Pounce Robo" \
  "${args[@]}"
