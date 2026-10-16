# Visión y alcance del MVP

> Documento vivo. Referencia: issue de auditoría y alcance (M0). Lo marcado como **[pendiente de validar]** depende de la consulta con jugadores (ver issue de validación con jugadores).

## 1. Estado del repositorio (auditoría)

| Área | Estado |
|---|---|
| Código | Auditoría inicial: no existía; el repositorio solo contenía un `README.md` mínimo. Desde entonces M1 y M2 están implementados (`MusCore` + app SwiftUI). |
| Proyecto Xcode / compilación | Auditoría inicial: no existía. Ahora se genera con `project.yml` (ver [compilación](compilacion.md)). |
| Decisiones técnicas previas | Ninguna. Las decisiones se fijan en [arquitectura](arquitectura.md). |
| Trabajo ya iniciado | Solo el backlog de lanzamiento en issues (#1–#25). |
| CI | Se añade en esta misma entrega (`.github/workflows/ci.yml`). |

**Conclusión:** se parte de cero; no hay trabajo que duplicar ni código que adaptar.

## 2. Visión del producto

Un contador de mus para iPhone que se abre y se usa en dos toques, sin cuenta ni conexión: tanteo grande y legible sobre la mesa, anotación directa por lances y un deshacer que nunca falla.

- **Público inicial:** jugadores habituales de mus en España que hoy usan piedras físicas, papel o contadores genéricos.
- **Base funcional:** tanteo visible, anotación directa por lances y deshacer. Tanto la composición como el diseño y la marca son propios; se parte de cómo se apunta una partida real en la mesa (ver [validación con jugadores](validacion-jugadores.md)).

## 3. Alcance del MVP

Entra (cada punto tiene su issue en M2):

1. **Crear partida**: dos equipos con nombre editable y objetivo de tantos (30 o 40), con valores por defecto.
2. **Llevar el tanteo**: anotar Grande, Chica, Pares, Juego y Punto por equipo, con cantidad; órdago; ajuste manual ±1.
3. **Deshacer** y lista breve de acciones recientes.
4. **Final de partida**: ganador y motivo; revancha y partida nueva; guardado único en historial.
5. **Recuperar** la partida en curso al reabrir la app, e **historial** de partidas terminadas.
6. **Preferencias**: objetivo de tantos, vacas y tema (claro/oscuro/sistema).
7. Marcador **offline** (los anuncios son lo único que usa red), **sin cuenta**, **sin analítica propia**; con **anuncios discretos** que nunca aparecen en la pantalla del marcador (ver [propuesta de valor](propuesta-de-valor.md)).

## 3 bis. Versión 1.1: la mesa y los jugadores

El contador deja de ser solo un marcador de tantos y pasa a seguir la partida tal como se juega en la mesa:

1. **Jugadores y mesa** (opcional): al crear la partida se escriben los cuatro nombres en el orden en que se sientan; los asientos pares son un equipo y los impares el otro. Los nombres se recuerdan en el iPhone y se sugieren al crear la siguiente partida.
2. **Mano**: se indica quién es mano y un botón «Siguiente mano» la pasa al jugador siguiente, en sentido horario. Queda en el registro de acciones y se puede deshacer. La revancha continúa la rotación.
3. **Estadísticas**: en Historial → «Jugadores», partidas, victorias y porcentaje, vacas ganadas, órdagos ganados y perdidos, lance en el que más tantos suma su equipo y rendimiento de cada pareja. Cuentan solo las partidas terminadas con los cuatro jugadores; las abandonadas no.
4. **Evolución y resultado compartible**: gráfica del tanteo anotación a anotación (con marcas en los cambios de mano y la meta), tantos por lance y una imagen del resultado para enviar por mensajería, sin anuncios y solo si la persona lo pide.
5. **Piedras**: ajuste visual que dibuja el tanteo en grupos de cinco. No cambia ninguna regla.
6. **Marcador en la pantalla de bloqueo**: mientras hay una partida en curso, el tanteo, las vacas y la mano se ven en la pantalla de bloqueo y en la Isla Dinámica (Live Activity local). Se puede desactivar en Ajustes y desaparece al terminar o abandonar la partida.

Todo es opcional: sin nombres, la partida funciona igual que en 1.0.

## 4. Fuera del MVP (versiones posteriores)

- Ligas y torneos.
- Widgets, Apple Watch.
- Sincronización iCloud, iPad optimizado.
- Más idiomas (euskera, catalán, gallego, inglés). El MVP sale en español.
- Variantes de reglas exóticas más allá de las listadas en reglas de tanteo (issue de reglas, M0).

## 5. Decisiones confirmadas

| Decisión | Valor | Detalle |
|---|---|---|
| Arquitectura | SwiftUI + paquete Swift `MusCore` (lógica pura) | [arquitectura](arquitectura.md) |
| iOS mínimo | iOS 17 | [arquitectura](arquitectura.md) |
| Persistencia | JSON versionado en el sandbox de la app | [arquitectura](arquitectura.md) |
| Distribución de builds | TestFlight (interna → externa) | [arquitectura](arquitectura.md) |
| CI | GitHub Actions en macOS | `.github/workflows/ci.yml` |
