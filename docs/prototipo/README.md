# Prototipo de alta fidelidad

Prototipo interactivo en HTML de un solo fichero: abre [`index.html`](index.html) en un navegador (mejor en móvil o con el inspector a 390 × 844). No es código de producto; sirve para validar el flujo y fijar el diseño que se implementa en SwiftUI.

## Flujo cubierto

| Pantalla / estado | Cómo verlo |
|---|---|
| Inicio con «Partida en curso» | Empieza una partida, vuelve atrás con ☰ → Abandonar, o recarga la página con una partida a medias |
| Configuración | Inicio → «Opciones de la partida» (nombres, 30/40 tantos, vacas) |
| Marcador | «Nueva partida». Elige lance abajo y toca 1–5 en el lado del equipo que gana el lance |
| Cantidad libre con resumen | Botón «Más» del equipo → paso a paso con resumen «1 → 7» antes de apuntar |
| Deshacer | Botón «↶ Deshacer», o desde el aviso tras cada anotación |
| Acciones recientes | Botón ⏱ (arriba a la derecha) |
| Órdago con resumen | «¡Órdago!» → elige equipo → confirmar |
| Victoria | Alcanza el objetivo o gana un órdago: motivo, tanteo, revancha, nueva partida, inicio, deshacer última anotación |
| Confirmación de reinicio | ☰ → «Reiniciar partida» |
| Error corregible | ☰ → «Ajuste −1» con el marcador en 0 muestra «El tanteo no puede bajar de 0» |
| Historial | Inicio → «Historial» (las abandonadas se marcan como tales) |
| Tema claro/oscuro | ☰ → «Cambiar tema» |

Las reglas del prototipo siguen la [especificación de tanteo](../reglas-de-tanteo.md).

## Decisiones de diseño

- **Una mano, sobre la mesa:** el tanteo ocupa la mitad central; lo que se toca (cantidades, lances, deshacer, órdago) está en el tercio inferior, al alcance del pulgar. Objetivos táctiles ≥ 52 pt.
- **Dos lados inequívocos:** cada equipo tiene color **y** forma (círculo / rombo) más su nombre. El equipo que va por delante lleva un anillo dorado.
- **Anotación en un toque:** lance seleccionado + cantidad en el lado del equipo. Sin pasar por más pantallas; «Más» abre un resumen solo para cantidades fuera de 1–5.
- **Errores con salida:** cada anotación muestra un aviso con «Deshacer»; los errores se explican en lenguaje claro.
- **Confirmaciones solo donde cuesta:** órdago, reinicio y abandono.
- **Identidad:** fieltro verde de mesa, oro de la baraja, tipografía de sistema redondeada con cifras tabulares.

## Comprobación

- Revisado en 390 × 844 (iPhone estándar) con todos los estados anteriores, sin errores de consola.
- **Pendiente de una persona:** prueba con jugadores (ver [validación con jugadores](../validacion-jugadores.md)) y resolución de los bloqueos que aparezcan. Hasta entonces no se marcan como cumplidos los criterios de «controles cómodos con una mano» y «jugadores prueban el prototipo».
