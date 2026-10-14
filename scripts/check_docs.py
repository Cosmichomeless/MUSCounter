#!/usr/bin/env python3
"""Comprueba que los enlaces relativos de los .md del repositorio apuntan a ficheros que existen."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
errors = []

for md in sorted(ROOT.rglob("*.md")):
    if ".git" in md.parts:
        continue
    for target in LINK.findall(md.read_text(encoding="utf-8")):
        if re.match(r"^(https?:|mailto:|#)", target) or target.startswith(("../../issues", "../../pulls")):
            continue
        path = target.split("#", 1)[0]
        if path and not (md.parent / path).exists():
            errors.append(f"{md.relative_to(ROOT)}: enlace roto -> {target}")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("Enlaces de documentación correctos.")
