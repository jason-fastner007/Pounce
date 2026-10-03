#!/bin/sh
# Replaces the jason-fastner007/Pounce placeholder in docs and GitHub config with the real repository.
# Usage: tool/set_repo.sh your-name/pounce
set -e
[ -n "$1" ] || { echo "usage: $0 <owner>/<repo>"; exit 1; }
cd "$(dirname "$0")/.."
owner=${1%%/*}
grep -rlI --exclude-dir=build --exclude-dir=.dart_tool --exclude-dir=.git -e 'OWNER/' . \
  | while read -r f; do sed -i "s#jason-fastner007/Pounce#$1#g; s#jason-fastner007/deckengine#$owner/deckengine#g" "$f"; echo "updated $f"; done
