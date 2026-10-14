#!/usr/bin/env python3
"""Comprueba que los anuncios siguen aislados.

Reglas (issue #41): el marcador y la lógica no pueden depender del SDK de anuncios.
- Solo `Packages/MusAds`, `App/Ads/` y los puntos de montaje conocidos importan `MusAds` / `GoogleMobileAds`.
- `MusCore`, `GameView` y `TeamPanel` no mencionan anuncios.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ALLOWED_IMPORTERS = {
    "App/Ads/AdSlot.swift",
    "App/MUSCounterApp.swift",
    "App/Screens/SettingsView.swift",
}
FORBIDDEN_TOKENS = re.compile(r"AdSlot|AdBanner|AdsController|MusAds|GoogleMobileAds|UserMessagingPlatform|AdPlacement")
NEVER = ["App/Screens/GameView.swift", "App/Screens/TeamPanel.swift", "App/Screens/GameMenus.swift",
         "App/Screens/GameSheets.swift", "App/Screens/SetupView.swift", "App/State/AppModel.swift"]

errors = []
for path in (ROOT / "App").rglob("*.swift"):
    rel = path.relative_to(ROOT).as_posix()
    if re.search(r"^\s*import\s+(MusAds|GoogleMobileAds|UserMessagingPlatform)\b", path.read_text(), re.M) \
            and rel not in ALLOWED_IMPORTERS:
        errors.append(f"{rel}: importa el módulo de anuncios y no está permitido")

for rel in NEVER:
    if FORBIDDEN_TOKENS.search((ROOT / rel).read_text()):
        errors.append(f"{rel}: no puede mencionar anuncios (marcador y flujo de partida)")

for path in (ROOT / "Packages" / "MusCore").rglob("*.swift"):
    if ".build" in path.parts:
        continue
    if FORBIDDEN_TOKENS.search(path.read_text()):
        errors.append(f"{path.relative_to(ROOT)}: MusCore no puede conocer los anuncios")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("Anuncios aislados: marcador y MusCore no dependen del SDK.")
