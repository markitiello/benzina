#!/usr/bin/env bash
#
# Build di release dell'app.
#
#   scripts/build_release.sh android            # app bundle (.aab) per il Play Store
#   scripts/build_release.sh ios                # .ipa per l'App Store (solo su Mac)
#   scripts/build_release.sh all
#
# Opzioni:
#   --build-name 1.2.0    versione visibile (default: quella in pubspec.yaml)
#   --build-number 42     numero di build, sempre crescente (default: numero di commit)
#   --skip-tests          salta analisi e test
#
# La configurazione Firebase viene da config/release.json (copiare
# config/release.example.json). Il codice viene offuscato; i simboli per
# leggere i crash finiscono in build/symbols/.

set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-}"
[[ "$TARGET" =~ ^(android|ios|all)$ ]] || { sed -n '2,17p' "$0"; exit 1; }
shift
BUILD_NAME=""
BUILD_NUMBER=""
SKIP_TESTS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-name) BUILD_NAME="$2"; shift 2 ;;
    --build-number) BUILD_NUMBER="$2"; shift 2 ;;
    --skip-tests) SKIP_TESTS=1; shift ;;
    *) echo "Opzione sconosciuta: $1" >&2; exit 1 ;;
  esac
done

log() { printf '\033[1;33m▸\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

CONFIG=config/release.json
[[ -f "$CONFIG" ]] || die "Manca $CONFIG (copiare config/release.example.json e compilarlo)."
if grep -q '": ""' "$CONFIG"; then
  log "Attenzione: $CONFIG ha valori vuoti, le notifiche push non funzioneranno."
fi

BUILD_NAME="${BUILD_NAME:-$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD)}"
log "Benzina $BUILD_NAME ($BUILD_NUMBER)"

if [[ "$SKIP_TESTS" -eq 0 ]]; then
  log "Analisi e test"
  flutter analyze --no-pub >/dev/null || die "flutter analyze ha trovato problemi."
  flutter test --no-pub >/dev/null || die "Test falliti."
fi

COMMON=(
  --release
  --build-name "$BUILD_NAME"
  --build-number "$BUILD_NUMBER"
  --dart-define-from-file "$CONFIG"
  --obfuscate
  --split-debug-info "build/symbols/$BUILD_NAME-$BUILD_NUMBER"
)

if [[ "$TARGET" == "android" || "$TARGET" == "all" ]]; then
  [[ -f android/key.properties ]] || die "Manca android/key.properties: eseguire scripts/create_android_keystore.sh."
  log "Android (app bundle)"
  flutter build appbundle "${COMMON[@]}"
  printf '\033[1;32m✓\033[0m %s\n' "build/app/outputs/bundle/release/app-release.aab"
fi

if [[ "$TARGET" == "ios" || "$TARGET" == "all" ]]; then
  [[ "$(uname)" == "Darwin" ]] || die "La build iOS richiede un Mac con Xcode."
  log "iOS (ipa)"
  # La firma usa il team impostato in Xcode (Runner → Signing & Capabilities).
  flutter build ipa "${COMMON[@]}" --export-method app-store
  printf '\033[1;32m✓\033[0m %s\n' "$(ls build/ios/ipa/*.ipa)"
fi
