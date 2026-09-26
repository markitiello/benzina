#!/usr/bin/env bash
#
# Build e pubblicazione per i tester con fastlane.
#
#   scripts/release.sh android    # Play Store, traccia "test interno"
#   scripts/release.sh ios        # TestFlight (solo su Mac)
#
# Stesse opzioni di build_release.sh (--build-name, --build-number, ...).
# Configurazione di fastlane: vedi README, "Pubblicazione".
#
# Da test interno / TestFlight alla produzione si passa dalle console degli
# store (o con: cd android && fastlane promote).

set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-}"
[[ "$TARGET" =~ ^(android|ios)$ ]] || { sed -n '2,12p' "$0"; exit 1; }
command -v bundle >/dev/null || { echo "Serve Bundler: gem install bundler" >&2; exit 1; }

scripts/build_release.sh "$@"

if [[ "$TARGET" == "android" ]]; then
  (cd android && bundle install --quiet && bundle exec fastlane internal)
else
  (cd ios && bundle install --quiet && bundle exec fastlane beta)
fi
