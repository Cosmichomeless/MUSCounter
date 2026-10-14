#!/usr/bin/env python3
"""Comprueba que los casos R-NN de docs/reglas-de-tanteo.md y las pruebas `testRNN…` coinciden."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
spec = (ROOT / "docs" / "reglas-de-tanteo.md").read_text(encoding="utf-8")
documented = set(re.findall(r"^\| (R-\d{2}) \|", spec, flags=re.MULTILINE))

tests_dir = ROOT / "Packages" / "MusCore" / "Tests"
tested = set()
for swift in tests_dir.rglob("*.swift"):
    for number in re.findall(r"func testR(\d{2})", swift.read_text(encoding="utf-8")):
        tested.add(f"R-{number}")

errors = []
errors += [f"{case}: está en la especificación pero no tiene prueba" for case in sorted(documented - tested)]
errors += [f"{case}: tiene prueba pero no está en la especificación" for case in sorted(tested - documented)]
if not documented:
    errors.append("No se encontró ningún caso R-NN en docs/reglas-de-tanteo.md")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"Especificación y pruebas coinciden ({len(documented)} casos).")
