# Reglas de tanteo

Especificación del tanteo de la app. Es la fuente de verdad de `MusCore`: cada caso de la sección 7 tiene una prueba automatizada `testRNN…` con el mismo identificador (lo comprueba `scripts/check_rules_tests.py` en la CI). `VariantMatrixTests` recorre además las seis combinaciones de objetivo y vacas.

Estado: **borrador pendiente de revisión por jugadores** (ver [validación con jugadores](validacion-jugadores.md)). Los valores por defecto son los de mus «estándar» más extendidos; las diferencias de casa se cubren con las variantes de la sección 3.

## 1. Vocabulario

| Término | Significado en la app |
|---|---|
| **Tanto** | Unidad de tanteo. La app dice «tantos», nunca «puntos». |
| **Vaca** | Cada tramo de la partida hasta alcanzar el objetivo de tantos (30 o 40). |
| **Partida** | El encuentro completo: gana el primer equipo que consigue `vacas para ganar` vacas (1, 2 o 3). |
| **Lance** | Grande, Chica, Pares, Juego o Punto. |
| **Envite** | Cantidad de tantos que se juega en un lance. |
| **Órdago** | Envite por el que se juega la vaca entera. |

## 2. Qué calcula la app y qué apunta el usuario

| La app **calcula automáticamente** | El usuario **apunta manualmente** |
|---|---|
| Suma de tantos de cada equipo | Quién gana cada lance (toca el equipo) |
| Límite en el objetivo (nunca se muestra más que el objetivo) | Cuántos tantos vale la anotación (envite, bonificación de pares/juego, «paso») |
| Fin de la vaca al alcanzar el objetivo y reinicio del tanteo | Si un órdago se acepta y quién lo gana |
| Conteo de vacas y fin de la partida | Correcciones puntuales (deshacer o ajuste ±1) |
| Orden y registro de acciones, deshacer | Abandonar la partida |

La app **no** evalúa manos de cartas ni decide quién gana un lance.

## 3. Variantes admitidas en el lanzamiento

| Variante | Valores | Por defecto | Notas |
|---|---|---|---|
| Objetivo de tantos | 30 · 40 | 40 | Se fija al crear la partida; no se cambia a mitad de partida. |
| Vacas para ganar | 1 · 2 · 3 | 1 | 1 = sin vacas (una sola vaca decide la partida). 2 = mejor de 3. 3 = mejor de 5. |

No se admiten en el lanzamiento: jugar a otros objetivos, vaca de oro, reglas de «amarracos/piedras» distintas, tres o más equipos.

## 4. Anotación por lance

Una **anotación** = equipo + lance + cantidad (≥ 1). Valores rápidos que ofrece la interfaz (la cantidad siempre es editable de 1 a 40):

| Lance | Valores rápidos | Comentario |
|---|---|---|
| Grande | 1 · 2 · 3 · 4 · 5 | 1 = paso (nadie envida). 2 = envite aceptado. |
| Chica | 1 · 2 · 3 · 4 · 5 | Igual que Grande. |
| Pares | 1 · 2 · 3 · 4 · 5 | Bonificación de las jugadas: pareja 1, medias 2, duples 3; se suma al envite. |
| Juego | 2 · 3 · 4 · 5 · 6 | 31 = 3, resto de juego = 2; se suma al envite. |
| Punto | 1 · 2 · 3 · 4 · 5 | Cuando nadie tiene juego. |

La interfaz **no** valida si una cantidad es «posible» en la mano real; solo valida coherencia (cantidad ≥ 1, partida en curso).

## 5. Órdago

- La anotación de órdago lleva equipo ganador del órdago.
- El órdago **aceptado** y ganado da la vaca al equipo ganador, **independientemente del tanteo actual**: su marcador pasa a ser el objetivo.
- Si el órdago **no se acepta**, no se usa esta acción: se anota el tanto que corresponda con una anotación normal.
- El motivo de la victoria de la vaca queda registrado como «Órdago».
- Se muestra un resumen de confirmación antes de aplicarlo.

## 6. Cierre de vaca y partida

1. Tras cada anotación, si el equipo que suma alcanza o supera el objetivo, **gana la vaca** en ese instante; el exceso se descarta (el marcador muestra el objetivo).
2. Al ganar una vaca el tanteo vuelve a 0-0 y suma una vaca al equipo.
3. Si ese equipo llega a `vacas para ganar`, **gana la partida** y no se aceptan más anotaciones.
4. **Deshacer** revierte exactamente la última acción, incluso si fue la que cerró una vaca o la partida (restaura tanteo, vacas y estado en curso).
5. **Ajuste manual** ±1 para corregir un error sin deshacer: se registra como acción de lance «Ajuste»; no puede dejar el marcador por debajo de 0 y, si alcanza el objetivo, cierra la vaca como cualquier otra anotación.
6. **Partida abandonada**: el usuario puede abandonar. Se guarda en el historial con estado «Abandonada», sin ganador, y no admite más acciones. Una partida en curso sin tocar se conserva indefinidamente hasta que el usuario la retome, la abandone o la borre.

### Mesa y mano (versión 1.1, informativo)

La mesa tiene cuatro asientos en sentido horario; los equipos se sientan alternados (asientos 0 y 2 contra 1 y 3). La **mano** es el jugador que abre cada lance y pasa al siguiente asiento en sentido horario tras cada mano. La app no deduce cuándo termina una mano: la persona que apunta pulsa «Siguiente mano», que queda en el registro y se puede deshacer. La mano no cambia ningún tanteo; solo se usa para el registro, la gráfica y las estadísticas. Las estadísticas cuentan únicamente partidas terminadas con los cuatro jugadores nombrados.

## 7. Casos de prueba de referencia

Objetivo 40 y 1 vaca para ganar salvo que se indique otra cosa.

| ID | Situación | Resultado esperado |
|---|---|---|
| R-01 | Partida nueva | 0-0, vacas 0-0, en curso |
| R-02 | Grande 2 al equipo A | A 2 – B 0 |
| R-03 | Varias anotaciones de ambos equipos | Cada equipo suma solo lo suyo |
| R-04 | Anotar cantidad 0 | Rechazada |
| R-05 | A con 38, Chica 1 | A 39, en curso |
| R-06 | A con 38, Pares 3 | A gana la vaca y la partida (1 vaca); marcador A = 40 (sin exceso) |
| R-07 | A con 40 alcanzado, intentar nueva anotación | Rechazada (partida terminada) |
| R-08 | Objetivo 30: A con 29, Punto 1 | A gana |
| R-09 | A 10 – B 25, órdago ganado por A | A gana por órdago; marcador A = 40 |
| R-10 | Deshacer tras R-09 | Vuelve a A 10 – B 25, en curso |
| R-11 | Deshacer sin acciones | Rechazado (no hay nada que deshacer) |
| R-12 | Ajuste −1 con marcador 0 | Rechazado (no baja de 0) |
| R-13 | Ajuste +1 con 39 | Gana la vaca |
| R-14 | 2 vacas para ganar: A gana 1.ª vaca | Tanteo 0-0, vacas A 1 – B 0, en curso |
| R-15 | 2 vacas: A gana 2 vacas | A gana la partida |
| R-16 | 2 vacas: A 1 – B 1, A gana 3.ª | A gana la partida (mejor de 3) |
| R-17 | Deshacer la anotación que cerró la 1.ª vaca | Vuelve el tanteo previo y vacas 0-0 |
| R-18 | Abandonar partida en curso | Estado «Abandonada», sin ganador, sin más acciones |
| R-19 | Registro de acciones | Cada acción conserva equipo, lance y cantidad en orden |
| R-20 | Ajuste manual cuando la partida ya terminó | Rechazado |
