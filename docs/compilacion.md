# Compilación y builds de prueba

## Requisitos

- macOS con Xcode 16 o superior.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
- Para builds firmadas: una cuenta de Apple Developer.

## Compilar en local

```bash
xcodegen generate              # crea MUSCounter.xcodeproj desde project.yml
open MUSCounter.xcodeproj      # Run en un simulador de iPhone (iOS 17+)
```

Ejecutar todas las pruebas, igual que la CI:

```bash
python3 scripts/check_rules_tests.py  # cada caso R-NN de la especificación tiene su prueba
(cd Packages/MusCore && swift test)   # lógica de reglas y persistencia
./scripts/test-app.sh                 # compila Release + pruebas de la app en simulador
```

## Configuración fijada

| Ajuste | Valor | Dónde |
|---|---|---|
| Bundle ID | `com.cosmichomeless.muscounter` (definitivo para la 1.0: es el que se usa al crear la app en App Store Connect) | `Config/Shared.xcconfig` |
| Bundle ID de la extensión de Live Activity | `com.cosmichomeless.muscounter.liveactivity` (hay que registrarlo en el portal de desarrolladores antes de archivar; con firma automática Xcode puede crearlo) | `project.yml` |
| iOS mínimo | 17.0 | `project.yml`, `Config/Shared.xcconfig` |
| Dispositivos | solo iPhone | `Config/Shared.xcconfig` |
| Versión / build | `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` | `Config/Shared.xcconfig` |
| Debug / Release | ajustes propios de cada configuración | `Config/Debug.xcconfig`, `Config/Release.xcconfig` |

## Secretos y certificados

**No se guardan en el repositorio.** `.gitignore` excluye `*.p12`, `*.cer`, `*.mobileprovision`, `*.p8`, `.env` y `Secrets.xcconfig`.

- Local: copia `Config/Secrets.xcconfig.example` a `Config/Secrets.xcconfig` y rellena `DEVELOPMENT_TEAM`.
- Certificados y perfiles: gestionados por Xcode («Automatically manage signing») en el llavero local.
- CI: cualquier secreto futuro (clave de App Store Connect) irá en GitHub Actions Secrets.

## Generar una build de prueba (TestFlight)

1. Sube `CURRENT_PROJECT_VERSION` en `Config/Shared.xcconfig` (cada subida necesita un número de build nuevo).
2. `DEVELOPMENT_TEAM=XXXXXXXXXX ./scripts/archive.sh` → antes de archivar comprueba la especificación y ejecuta `swift test`; crea `build/MUSCounter.xcarchive`.
3. Sube la build: `./scripts/upload.sh` solo exporta el `.ipa` a `build/export` (no sube nada) y `./scripts/upload.sh --subir` lo sube a App Store Connect; también vale Xcode → Window → Organizer → Archives → *Distribute App* → *App Store Connect* → *Upload*. La app debe existir ya en App Store Connect.
4. En App Store Connect → TestFlight, añade la build al grupo de pruebas internas.

## CI

`.github/workflows/ci.yml` ejecuta en cada PR: comprobación de enlaces de documentación, coincidencia entre especificación y pruebas, `swift test` de `MusCore` y `scripts/test-app.sh` (Release + pruebas en simulador).
