#!/usr/bin/env bash
# Genera el proyecto, compila Release y ejecuta las pruebas de la app en un simulador de iPhone.
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate

# Elige el primer iPhone disponible del runtime de iOS más reciente.
UDID="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
runtimes = sorted((k for k in data if "iOS" in k), key=lambda k: [int(x) for x in k.split("iOS-")[-1].split("-")])
for rt in reversed(runtimes):
    for d in data[rt]:
        if d["name"].startswith("iPhone") and d.get("isAvailable", True):
            print(d["udid"]); sys.exit(0)
sys.exit("No hay simulador de iPhone disponible")
')"
echo "Simulador: $UDID"

echo "==> Compilando Release (sin firma)"
xcodebuild build -project MUSCounter.xcodeproj -scheme MUSCounter -configuration Release \
  -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO | tail -n 5

echo "==> Pruebas (Debug)"
xcodebuild test -project MUSCounter.xcodeproj -scheme MUSCounter -configuration Debug \
  -destination "id=$UDID" CODE_SIGNING_ALLOWED=NO | tail -n 40
