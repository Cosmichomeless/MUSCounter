#!/usr/bin/env bash
# Genera un .xcarchive de Release para subir a TestFlight.
# Requiere Secrets.xcconfig (DEVELOPMENT_TEAM) o variable DEVELOPMENT_TEAM exportada, y un certificado de distribución en el llavero.
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate
mkdir -p build
xcodebuild archive -project MUSCounter.xcodeproj -scheme MUSCounter -configuration Release \
  -destination "generic/platform=iOS" -archivePath build/MUSCounter.xcarchive \
  ${DEVELOPMENT_TEAM:+DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"} -allowProvisioningUpdates
echo "Archivo generado en build/MUSCounter.xcarchive"
