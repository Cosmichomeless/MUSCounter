# Visión y alcance del MVP

> Documento vivo. Referencia: issue de auditoría y alcance (M0). Lo marcado como **[pendiente de validar]** depende de la consulta con jugadores (ver issue de validación con jugadores).

## 1. Estado del repositorio (auditoría)

| Área | Estado |
|---|---|
| Código | No existe. El repositorio solo contenía un `README.md` mínimo. |
| Proyecto Xcode / compilación | No existe. |
| Decisiones técnicas previas | Ninguna. Las decisiones se fijan en [arquitectura](arquitectura.md). |
| Trabajo ya iniciado | Solo el backlog de lanzamiento en issues (#1–#25). |
| CI | Se añade en esta misma entrega (`.github/workflows/ci.yml`). |

**Conclusión:** se parte de cero; no hay trabajo que duplicar ni código que adaptar.

## 2. Visión del producto

Un contador de mus para iPhone que se abre y se usa en dos toques, sin cuenta ni conexión: tanteo grande y legible sobre la mesa, anotación directa por lances y un deshacer que nunca falla.

- **Público inicial:** jugadores habituales de mus en España que hoy usan piedras físicas, papel o contadores genéricos.
- **Referencia funcional:** MusMarca (tanteo visible, anotación directa por lances, deshacer). Solo se toma la *función*; la composición, el diseño y la marca son propios.

## 3. Alcance del MVP

Entra (cada punto tiene su issue en M2):

1. **Crear partida**: dos equipos con nombre editable y objetivo de tantos (30 o 40), con valores por defecto.
2. **Llevar el tanteo**: anotar Grande, Chica, Pares, Juego y Punto por equipo, con cantidad; órdago; ajuste manual ±1.
3. **Deshacer** y lista breve de acciones recientes.
4. **Final de partida**: ganador y motivo; revancha y partida nueva; guardado único en historial.
5. **Recuperar** la partida en curso al reabrir la app, e **historial** de partidas terminadas.
6. **Preferencias**: objetivo de tantos, vacas y tema (claro/oscuro/sistema).
7. Todo **offline**, **sin cuenta**, **sin analítica ni anuncios** en la primera versión.

## 4. Fuera del MVP (versiones posteriores)

- Ligas, torneos y estadísticas avanzadas.
- Nombres de jugadores individuales (el modelo los admite como opcionales; la UI no los expone en el MVP).
- Widgets, Live Activities, Apple Watch.
- Sincronización iCloud, compartir resultados, iPad optimizado.
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
