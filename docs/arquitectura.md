# Arquitectura y decisiones técnicas

## Resumen

```
MUSCounter/
├── Packages/MusCore/   Lógica pura en Swift (reglas, modelo, persistencia). Sin UI.
├── App/                Aplicación SwiftUI (iOS 17+).
├── project.yml         Definición del proyecto para XcodeGen (el .xcodeproj no se versiona).
├── scripts/            Utilidades de CI y desarrollo.
└── docs/               Producto, reglas, diseño y decisiones.
```

## Decisiones

### D1. SwiftUI nativo
Aplicación pequeña, solo iPhone, sin dependencias de terceros. SwiftUI da accesibilidad, Dynamic Type y modo oscuro casi gratis.

### D2. Lógica en un paquete Swift independiente (`MusCore`)
Las reglas de tanteo son lo más delicado del producto y deben poder comprobarse. Un paquete sin dependencias de UIKit/SwiftUI se prueba con `swift test` de forma rápida y en CI.

### D3. iOS 17 como mínimo
Permite `@Observable`, `ContentUnavailableView` y las APIs modernas de SwiftUI. Cubre la inmensa mayoría de iPhone activos y reduce código de compatibilidad.

### D4. Persistencia en JSON versionado (sin SwiftData/CoreData)
- Los datos son pocos y simples (una partida activa + historial).
- Cada fichero lleva `schemaVersion`; un migrador explícito convierte versiones anteriores.
- Esquema actual: **v3**. Guarda la partida activa, el historial y las **preferencias** (tantos de la vaca, vacas para ganar, tema, háptica y sonido). La migración v1 → v2 añade las preferencias predeterminadas; v2 → v3 añade háptica (activada) y sonido (desactivado).
- Las preferencias solo se usan al crear partidas nuevas: las partidas en curso o guardadas conservan sus reglas.
- «Nueva partida» y «Opciones de la partida» parten de las preferencias; la revancha y «Nueva partida» desde el resultado conservan la configuración de la partida terminada.
- Es trivial de probar en `MusCore` (sin framework de persistencia) y de borrar por completo.
- Escritura atómica (`.atomic`) para no perder la partida si la app se cierra a medias.

### D5. Proyecto generado con XcodeGen
El `.xcodeproj` produce conflictos de fusión constantes. `project.yml` es legible, revisable y reproducible. Cualquier persona (o CI) ejecuta `xcodegen generate`.

### D6. Distribución: TestFlight
- Build de prueba interna: archivo `.ipa` subido a TestFlight (grupo interno).
- Beta cerrada (M3): grupo externo.
- Firma: certificados y perfiles **nunca** en el repositorio; se gestionan en el llavero local o en secretos de CI.

### D7. Sin red, sin cuenta, sin analítica en la v1
Simplifica la privacidad (ficha "Datos no recopilados") y elimina clases enteras de fallos.

## Convenciones

- Idioma de la interfaz y de la documentación: español.
- Identificadores de código en inglés para tipos técnicos; el vocabulario del dominio (Grande, Chica, Pares, Juego, Punto, órdago, vaca) se mantiene en español en el modelo, para coincidir con lo que dicen los jugadores.
- Una PR por issue; la CI debe pasar antes de fusionar.
