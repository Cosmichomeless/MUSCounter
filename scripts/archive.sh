#!/usr/bin/env bash
# Genera un .xcarchive de Release para subir a TestFlight.
# Requiere Secrets.xcconfig (DEVELOPMENT_TEAM) o variable DEVELOPMENT_TEAM exportada, y un certificado de distribución en el llavero.
set -euo pipefail
cd "$(dirname "$0")/.."

# Antes de preparar una versión: la especificación y las pruebas deben coincidir y pasar.
python3 scripts/check_rules_tests.py
python3 scripts/check_ads_isolation.py
(cd Packages/MusCore && swift test)

# Nunca se archiva con los anuncios de prueba de Google: ni TestFlight ni App Store deben llevarlos.
if ! grep -qE '^ADMOB_APP_ID *= *ca-app-pub-[0-9]{16}~[0-9]{10}' Config/Secrets.xcconfig 2>/dev/null \
   || grep -q '3940256099942544' Config/Secrets.xcconfig; then
  echo "Faltan los identificadores reales de AdMob en Config/Secrets.xcconfig (ver Secrets.xcconfig.example)." >&2
  exit 1
fi

# La política de privacidad y el contacto de soporte son obligatorios para la ficha de App Store.
for key in PRIVACY_POLICY_URL SUPPORT_EMAIL; do
  if ! grep -qE "^$key *= *[^ ]+" Config/Secrets.xcconfig 2>/dev/null; then
    echo "Falta $key en Config/Secrets.xcconfig (ver Secrets.xcconfig.example)." >&2
    exit 1
  fi
done

xcodegen generate
mkdir -p build
xcodebuild archive -project MUSCounter.xcodeproj -scheme MUSCounter -configuration Release \
  -destination "generic/platform=iOS" -archivePath build/MUSCounter.xcarchive \
  ${DEVELOPMENT_TEAM:+DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"} -allowProvisioningUpdates
echo "Archivo generado en build/MUSCounter.xcarchive"
