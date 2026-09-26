#!/usr/bin/env bash
#
# Crea il keystore di upload per il Play Store e android/key.properties.
# Da eseguire una sola volta. Serve keytool (incluso nel JDK / Android Studio).
#
#   scripts/create_android_keystore.sh
#
# Conservare una copia di android/upload-keystore.jks e delle password in un
# posto sicuro (es. gestore di password): servono per ogni aggiornamento.

set -euo pipefail
cd "$(dirname "$0")/.."

KEYSTORE=android/upload-keystore.jks
PROPERTIES=android/key.properties

[[ -e "$KEYSTORE" ]] && { echo "Esiste già $KEYSTORE: non lo sovrascrivo." >&2; exit 1; }
command -v keytool >/dev/null || { echo "Serve keytool (JDK 17 o Android Studio)." >&2; exit 1; }

read -r -s -p "Password del keystore (almeno 6 caratteri): " PASSWORD; echo
read -r -s -p "Ripeti la password: " PASSWORD2; echo
[[ "$PASSWORD" == "$PASSWORD2" && ${#PASSWORD} -ge 6 ]] || { echo "Password non valide." >&2; exit 1; }
read -r -p "Nome e cognome o organizzazione (per il certificato): " OWNER

keytool -genkeypair -v -keystore "$KEYSTORE" -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -dname "CN=${OWNER:-Benzina}, O=${OWNER:-Benzina}, C=IT"

umask 077
cat > "$PROPERTIES" <<EOF
storeFile=upload-keystore.jks
storePassword=$PASSWORD
keyAlias=upload
keyPassword=$PASSWORD
EOF

echo
echo "Creati $KEYSTORE e $PROPERTIES (esclusi da git)."
echo "Per GitHub Actions: base64 -w0 $KEYSTORE  → secret ANDROID_KEYSTORE_BASE64"
