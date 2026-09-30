#!/usr/bin/env bash
#
# Versione dell'app: MAJOR.MINOR da pubspec.yaml, poi il numero di commit.
#
#   scripts/version.sh          # stampa: 1.0.412 412 a1b2c3d
#
# - nome versione (quello che vede l'utente): MAJOR.MINOR.COMMIT
# - numero di build (Play Store / App Store, sempre crescente): COMMIT
# - short commit, con "-dirty" se ci sono modifiche non committate
#
# MAJOR.MINOR si cambiano a mano in pubspec.yaml (riga "version:").
# Serve la storia completa di git (in CI: fetch-depth: 0).

set -euo pipefail
cd "$(dirname "$0")/.."

MAJOR_MINOR="$(sed -n 's/^version: *\([0-9]*\.[0-9]*\).*/\1/p' pubspec.yaml)"
[[ -n "$MAJOR_MINOR" ]] || { echo "version: MAJOR.MINOR non trovata in pubspec.yaml" >&2; exit 1; }
if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
  echo "Clone parziale: il numero di commit sarebbe sbagliato (git fetch --unshallow)." >&2
  exit 1
fi
COMMITS="$(git rev-list --count HEAD)"
SHA="$(git rev-parse --short=7 HEAD)"
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  SHA="$SHA-dirty"
fi
echo "$MAJOR_MINOR.$COMMITS $COMMITS $SHA"
