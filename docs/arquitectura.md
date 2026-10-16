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
- Esquema actual: **v4**. Guarda la partida activa, el historial, las **preferencias** (tantos de la vaca, vacas para ganar, tema, háptica y sonido) y los **jugadores** recordados. La migración v1 → v2 añade las preferencias predeterminadas; v2 → v3 añade háptica (activada) y sonido (desactivado); v3 → v4 añade la lista de jugadores (vacía). Cada partida guarda sus asientos con el nombre tal como se jugó, así que borrar a un jugador no cambia el historial.
- Live Activity: la extensión `MUSCounterLiveActivity` (ActivityKit + WidgetKit) muestra el marcador en la pantalla de bloqueo y la Isla Dinámica. La app la inicia, actualiza y termina en local desde `AppModel` a través de `ScoreboardPublishing` (`ScoreboardActivity`); no usa notificaciones push ni red. Comparte con la app solo `Shared/MarcadorActivityAttributes.swift` (textos y números ya calculados). Bundle id de la extensión: `com.cosmichomeless.muscounter.liveactivity`.
- Mesa y mano: cuatro asientos en sentido horario (0 y 2 son un equipo, 1 y 3 el otro). La mano es una acción más del registro (`nextHand`), por lo que se deshace y se rehace como cualquier otra, y la mano actual sale de contar esas acciones. Las estadísticas (`Stats`) y la evolución del tanteo (`ScoreTimeline`) se calculan siempre desde el registro de acciones; no hay contadores duplicados que puedan descuadrarse.
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

### D7. Sin cuenta ni analítica propia; la red solo para anuncios
El marcador funciona sin red y sin cuenta. La única conexión es la de los banners de AdMob (D8), aislada del resto. Ver [anuncios](anuncios.md).

### D8. Anuncios en un módulo aislado
`Packages/MusAds` es el único que importa el SDK de Google (AdMob y UMP). `MusCore` y el marcador no lo conocen; sin red, sin consentimiento o con un fallo no se muestra nada y la app se comporta igual. `scripts/check_ads_isolation.py` lo vigila en CI.

## Convenciones

- Idioma de la interfaz y de la documentación: español.
- Identificadores de código en inglés para tipos técnicos; el vocabulario del dominio (Grande, Chica, Pares, Juego, Punto, órdago, vaca) se mantiene en español en el modelo, para coincidir con lo que dicen los jugadores.
- Una PR por issue; la CI debe pasar antes de fusionar.
