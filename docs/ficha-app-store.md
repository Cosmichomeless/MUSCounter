# Ficha de App Store

Estado: **textos y capturas listos para subir a App Store Connect.** Cubre #21. Nada de esto se ha subido a App Store Connect: hacerlo es una acción del titular (o, con su confirmación expresa, de una herramienta).

Los textos están en español (idioma principal). Entre paréntesis, la longitud actual y el límite de Apple.

## 1. Textos

| Campo | Texto | Límite |
|---|---|---|
| Nombre | `Tanteo Mus` (10) | 30 |
| Subtítulo | `Marcador de mus para la mesa` (28) | 30 |
| Texto promocional | `Apunta Grande, Chica, Pares, Juego y Punto en dos toques. Tanteo grande, deshacer ilimitado y sin cuenta. Tu partida de mus, siempre clara sobre la mesa.` (153) | 170 |
| Palabras clave | `marcador,contador,puntos,cartas,baraja,vacas,órdago,envite,grande,chica,pares,juego,peña,piedras` (96) | 100 |
| Categoría principal | Utilidades | — |
| Categoría secundaria | Juegos › Cartas | — |
| URL de soporte | <https://cosmichomeless.github.io/MUSCounter/support/> | — |
| URL de privacidad | <https://cosmichomeless.github.io/MUSCounter/privacy/> | — |
| URL de marketing (opcional) | <https://cosmichomeless.github.io/MUSCounter/> | — |
| Copyright | `2026 <titular>` (lo rellena el titular; no se inventa aquí) | — |

Notas de ASO:

- Apple ya indexa el nombre y el subtítulo, así que «tanteo», «mus» y «marcador» no hace falta repetirlos en las palabras clave (se mantiene «marcador» porque el límite lo permite; quítalo si se necesita sitio).
- No se usan marcas ni nombres de otras apps en ningún campo.
- «Sin anuncios» **no** puede aparecer en la ficha: la app es gratuita y muestra banners (ver [anuncios](anuncios.md)). El diferencial que se comunica es «sin cuenta», «funciona sin conexión» (los anuncios sí necesitan red) y que el marcador nunca lleva anuncios encima.

## 2. Descripción

```
Tanteo Mus es el marcador para tus partidas de mus. Ábrela, empieza y apunta: sin cuenta ni registro, y funciona sin conexión.

TANTEO GRANDE Y CLARO
Los tantos de cada equipo se ven de un vistazo desde el otro lado de la mesa. Los equipos se distinguen por color y por forma, y hay tema claro, oscuro o el del sistema.

ANOTA POR LANCES
Grande, Chica, Pares, Juego y Punto, con la cantidad que toque. Órdago incluido, y un ajuste de ±1 para corregir un tanto suelto.

UN DESHACER QUE NO FALLA
Te has equivocado de equipo o de cantidad: toca Deshacer tantas veces como necesites. Verás además las últimas jugadas.

A 30 O A 40, CON O SIN VACAS
Elige a cuántos tantos se juega y cuántas partidas hay que ganar. Cada equipo tiene el nombre que quieras.

LA MESA ENTERA, CON SUS JUGADORES (OPCIONAL)
Escribe los cuatro nombres en el orden en que os sentáis y la app sabe quién es mano. Pasa la mano con un toque y la rotación sigue en la revancha. En Historial verás las victorias, las vacas y los órdagos de cada jugador y de cada pareja. Todo se guarda solo en tu iPhone.

MARCADOR EN LA PANTALLA DE BLOQUEO
Mientras juegas, el tanteo y la mano se ven en la pantalla de bloqueo y en la Isla Dinámica. Lo desactivas en Ajustes.

CÓMO FUE LA PARTIDA
Una gráfica del tanteo anotación a anotación, los tantos de cada equipo por lance y una imagen del resultado, sin anuncios, para enviar al grupo.

TU PARTIDA, A SALVO
Si cierras la app a mitad de partida, la recuperas tal cual al volver. Las partidas terminadas quedan en el historial. Revancha en un toque.

PENSADA PARA LA MESA
- Botones grandes y fáciles de pulsar.
- Marcador en vertical y en horizontal.
- Compatible con VoiceOver y con texto grande.
- Háptica y sonido opcionales al apuntar.
- Piedras opcionales: el tanteo dibujado en grupos de cinco.

PRIVACIDAD
No necesitas cuenta y tus partidas se guardan solo en tu iPhone. La app es gratuita y muestra anuncios de Google AdMob en las pantallas de inicio, historial y victoria, nunca durante el marcador. En la Unión Europea, el Reino Unido y Suiza te pedimos tu consentimiento antes de mostrar anuncios, y puedes cambiarlo en Ajustes.

¿Dudas o sugerencias? Abre una incidencia en la página de soporte.
```

Antes de publicar, contrastar cada afirmación con la versión enviada (p. ej. «Marcador en horizontal», háptica y sonido, «últimas jugadas»); si algo no está en la build, se quita.

## 3. Notas de la versión (1.0)

```
Primera versión de Tanteo Mus: marcador de mus con anotación por lances, deshacer, partida recuperable, historial y tema claro/oscuro.
```

## 3 bis. Notas de la versión (1.1)

```
Novedades de Tanteo Mus:
• Jugadores y mesa: escribe los cuatro nombres, indica quién es mano y pásala con un toque.
• Estadísticas por jugador y por pareja: victorias, vacas, órdagos y lance fuerte.
• Gráfica de la evolución de cada partida y resultado para compartir como imagen.
• Marcador en la pantalla de bloqueo y en la Isla Dinámica mientras juegas.
• Piedras opcionales: el tanteo en grupos de cinco (Ajustes).
```

## 4. Clasificación por edad y cuestionarios

- Contenido sin violencia, apuestas con dinero, contenido sexual ni acceso web libre: la clasificación esperada es **4+**. «Contiene anuncios»: **sí**.
- «Juegos de azar simulados»: **no** (la app solo cuenta tantos; no hay dinero ni apuestas).
- Cifrado: la app solo usa HTTPS estándar del sistema y del SDK → exención estándar (se confirma en el cuestionario de exportación).
- Ficha de privacidad: respuestas en [soporte y privacidad](soporte-y-privacidad.md) §4.

## 5. Capturas

Tamaño obligatorio hoy para iPhone: **6,9″ (1320 × 2868)** y, si Apple lo pide, 6,5″. La app es solo iPhone.

Orden propuesto (contar el flujo de una partida real):

| # | Pantalla | Mensaje en la captura |
|---|---|---|
| 1 | Marcador a mitad de partida | «Tanteo grande, visible desde toda la mesa» |
| 2 | Anotar un lance (cantidad) | «Anota Grande, Chica, Pares, Juego y Punto» |
| 3 | Deshacer y últimas jugadas | «Un deshacer que no falla» |
| 4 | Nueva partida (30/40, vacas, nombres) | «A 30 o a 40, con o sin vacas» |
| 5 | Victoria | «Revancha en un toque» |
| 6 | Marcador en tema claro | «Claro u oscuro» |
| 7 | Nueva partida con jugadores y mano (1.1) | «Cuatro jugadores, una mano que rota» |
| 8 | Estadísticas de jugadores y parejas (1.1) | «Quién gana más y en qué lance puntúa» |
| 9 | Gráfica y resultado para compartir (1.1) | «Cómo fue la partida» |

Capturas hechas, en [`docs/capturas/`](capturas/) (1320 × 2868, iPhone 17 Pro Max, barra de estado a las 9:41, sin marco ni titular):

| # | Fichero |
|---|---|
| 1 | `01-marcador.png` |
| 2 | `02-cantidad.png` |
| 3 | `03-jugadas.png` |
| 4 | `04-nueva-partida.png` |
| 5 | `05-victoria.png` |
| 6 | `06-claro.png` |
| 7 | `07-jugadores.png` |
| 8 | `08-estadisticas.png` |
| 9 | `09-grafica.png` |

Se generaron con la app (build de la versión actual, sin banners de prueba) sobre partidas de ejemplo con nombres «Nosotros» / «Ellos» (las 7-9, con los jugadores ficticios Ana, Luis, Marta y Pedro y tres partidas jugadas de verdad en la app). Las versiones con titular, las que se suben a la ficha, se generan con `python3 scripts/make-capturas.py` y quedan en [`docs/capturas/titulares/`](capturas/titulares/) (mismo tamaño, fondo de fieltro y un titular corto con verbo y beneficio por captura; el texto está en `TITULARES` del script). Las originales, sin titular, se conservan para regenerarlas. Si la versión enviada cambia el aspecto de alguna pantalla, hay que repetirlas.

Reglas: capturas de la **versión enviada**, sin banner de prueba («Test Ad») visible, sin datos personales, con nombres de equipo neutros («Nosotros» / «Ellos»), solo la interfaz de la app y sin marcas ajenas. Los titulares sobre la captura van en español, que es el único idioma de la ficha.

## 6. Icono

El icono (`App/Assets.xcassets/AppIcon.appiconset`) se genera con `scripts/make-icon.py`: cuatro piedras de tanteo (dos por equipo, en los colores de los equipos) cruzadas por una barra dorada sobre el fieltro verde. Se comprueba la legibilidad a 60 y 29 pt antes de enviar.

## 7. Lista de comprobación (#21)

- [x] Nombre, subtítulo, descripción, palabras clave y categoría redactados (esta página).
- [x] Enlaces de soporte y privacidad públicos y respondiendo (200); se muestran también dentro de la app.
- [x] Icono con identidad propia (claro, oscuro y tintado).
- [x] Capturas de la versión actual (§5, `docs/capturas/`) y sus versiones con titular (`docs/capturas/titulares/`); repetirlas solo si cambia la interfaz antes de enviar.
- [x] Afirmaciones de la descripción contrastadas con el código el 2026-10-19: horizontal, vibración y sonido opcionales, piedras, últimas jugadas, VoiceOver, marcador en pantalla de bloqueo con su ajuste, deshacer sin límite.
- [x] Copyright («2026 David Rodríguez») puesto en la versión 1.1 y nombre «Tanteo Mus» confirmado como disponible por el titular (2026-10-20); ficha dada de alta en App Store Connect.
- [x] Revisión legal de la política de privacidad hecha y conforme (confirmada por el titular el 2026-10-21).
- [x] Ficha de privacidad de la app en App Store Connect revisada y ajustada por el titular el 2026-10-21 (§4 de [soporte y privacidad](soporte-y-privacidad.md)).
