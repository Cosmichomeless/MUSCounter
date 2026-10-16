#!/usr/bin/env bash
# Exporta build/MUSCounter.xcarchive (de scripts/archive.sh) a un .ipa o lo sube a App Store Connect / TestFlight.
# Sin argumentos solo genera el .ipa en build/export; con --subir lo sube de verdad (acción de cara al exterior: confírmala antes).
# Requiere DEVELOPMENT_TEAM en Config/Secrets.xcconfig o exportado.
# No sube símbolos: los XCFramework de Google (AdMob, UMP) no traen dSYM y la subida avisaba de ello en cada build. El dSYM de la app queda en el .xcarchive (build/), conservarlo para simbolizar fallos.
set -euo pipefail
cd "$(dirname "$0")/.."

destino=export
[[ "${1:-}" == "--subir" ]] && destino=upload

[[ -d build/MUSCounter.xcarchive ]] || { echo "Falta build/MUSCounter.xcarchive: ejecuta antes scripts/archive.sh." >&2; exit 1; }

team="${DEVELOPMENT_TEAM:-$(sed -nE 's/^DEVELOPMENT_TEAM *= *([A-Z0-9]+).*/\1/p' Config/Secrets.xcconfig 2>/dev/null | head -1)}"
[[ -n "$team" ]] || { echo "Falta DEVELOPMENT_TEAM (Config/Secrets.xcconfig o variable de entorno)." >&2; exit 1; }

plist=build/ExportOptions.plist
cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>teamID</key><string>$team</string>
<key>signingStyle</key><string>automatic</string>
<key>destination</key><string>$destino</string>
<key>uploadSymbols</key><false/>
</dict></plist>
EOF

xcodebuild -exportArchive -archivePath build/MUSCounter.xcarchive \
  -exportOptionsPlist "$plist" -exportPath build/export -allowProvisioningUpdates

if [[ "$destino" == upload ]]; then
  echo "Build subida. Espera a que esté VALID en TestFlight antes de asociarla a la versión."
else
  echo "IPA generado en build/export (no se ha subido nada). Para subir: scripts/upload.sh --subir"
fi
