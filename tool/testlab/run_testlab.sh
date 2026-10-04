#!/usr/bin/env bash
# Firebase Test Lab: Robo-Tests von Pounce auf Android und iOS.
#
# Ablauf pro Geraet (TIMEOUT, Standard 20 min):
#   1. Robo-Skript (~10 min): Einrichtung als Gast (ohne SoundCloud-Login), Suche, DJ-Mix starten,
#      Musik laeuft ~9 min – auf Android wird jede Minute per "dumpsys media_session" geprueft,
#      dass wirklich abgespielt wird (DJ blendet dabei per Crossfade ueber).
#   2. Danach erkundet Robo selbststaendig den Rest der App bis zum Timeout.
#
# Spark-Tarif (kostenlos): 10 Laeufe/Tag auf virtuellen, 5 auf physischen Geraeten.
# Standard hier: 5 Android-Emulatoren (ARM) + 2 echte iPhones.
#
# Voraussetzungen (einmalig):
#   gcloud auth login
#   gcloud config set project <FIREBASE-PROJEKT>
#
# Aufruf:  bash tool/testlab/run_testlab.sh [android|ios|all]
# Optional: APK=… IPA=… TIMEOUT=20m ANDROID_DEVICES="MediumPhone.arm:36 …" IOS_DEVICES="iphone16pro:18.3 …"
# Geraete:  gcloud firebase test android models list   /   gcloud firebase test ios models list
set -euo pipefail
cd "$(dirname "$0")/../.."

WHAT="${1:-all}"
TIMEOUT="${TIMEOUT:-20m}"
# Die Rust-Engine gibt es nur fuer arm64 -> ARM-Emulatoren.
ANDROID_DEVICES="${ANDROID_DEVICES:-MediumPhone.arm:36 MediumPhone.arm:34 SmallPhone.arm:33 MediumTablet.arm:35 Pixel2.arm:30}"
IOS_DEVICES="${IOS_DEVICES:-iphone16pro:18.3 iphonese3:18.4}"

if [[ "$WHAT" == all || "$WHAT" == android ]]; then
  if [ -z "${APK:-}" ]; then
    flutter build apk --release --flavor github --target-platform android-arm64
    APK=build/app/outputs/flutter-apk/app-github-release.apk
  fi
  args=()
  for d in $ANDROID_DEVICES; do
    args+=(--device "model=${d%%:*},version=${d##*:},locale=en,orientation=portrait")
  done
  gcloud firebase test android run --async \
    --type robo \
    --app "$APK" \
    --robo-script tool/testlab/robo_script.json \
    --timeout "$TIMEOUT" \
    --results-history-name "Pounce Android Robo" \
    "${args[@]}"
fi

if [[ "$WHAT" == all || "$WHAT" == ios ]]; then
  : "${IPA:?IPA=pfad/zur/pounce-…-ios-untested.ipa setzen (aus dem GitHub-Release)}"
  args=()
  for d in $IOS_DEVICES; do
    args+=(--device "model=${d%%:*},version=${d##*:},locale=en,orientation=portrait")
  done
  gcloud beta firebase test ios run --async \
    --type robo \
    --app "$IPA" \
    --robo-script tool/testlab/robo_script_ios.json \
    --timeout "$TIMEOUT" \
    --results-history-name "Pounce iOS Robo" \
    "${args[@]}"
fi
