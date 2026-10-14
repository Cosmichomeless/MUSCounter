# Accesibilidad

Referencia: issue #17 (M3). Qué hace la app, qué comprueban las pruebas automáticas y qué hay que revisar a mano.

## 1. Qué cubre la app

| Criterio | Cómo se cumple |
|---|---|
| **VoiceOver describe equipos, tanteo y acciones** | Cada panel de equipo es un elemento con el nombre como etiqueta y un valor como «12 tantos de 40, vacas 1 de 3, va por delante» (`AccessibilityText.teamValue`). Los botones dicen «Apuntar 3 de Grande a Equipo 1». El selector de lance se llama «Lance» y marca la opción elegida. |
| **Cambios anunciados** | Tras cada anotación se anuncia la acción y el marcador completo («Grande: +2 para Equipo 1. Equipo 1 7, Equipo 2 3») y al terminar la partida se anuncia la victoria. |
| **El color nunca es la única señal** | Los equipos se distinguen por forma (círculo / rombo) y nombre; «va por delante» y «ganador» llevan icono además del anillo dorado; las vacas son ● / ○; los errores llevan icono y texto. |
| **Texto dinámico** | Con tamaños de accesibilidad los paneles se apilan, el selector de lance pasa a vertical con hasta dos líneas, la cabecera se reparte en dos filas, la cuadrícula de cantidades pasa a dos columnas y el diseño apaisado cede al vertical con desplazamiento. Ningún control se oculta. |
| **Contraste** | Texto ≥ 4,5:1 y elementos gráficos ≥ 3:1 en tema claro y oscuro, incluido el texto sobre el color de equipo del botón pulsado (`DesignTokensTests`). |
| **Áreas táctiles** | Botones de 52 pt y opciones de selector de 48 pt, ambos por encima de los 44 pt de Apple. |
| **Reducir movimiento** | Con el ajuste del sistema activado desaparecen la escala del botón y el desplazamiento del aviso; queda solo un fundido. |

## 2. Pruebas automáticas

- `AccessibilityTextTests` (MusCore): textos de VoiceOver, plurales y anuncios.
- `DesignTokensTests` (MusCore): contraste de la paleta y tamaños mínimos.
- `AccessibilityLayoutTests` (app): el marcador se monta con todos los tamaños de texto, en vertical y horizontal.

## 3. Háptica y sonido

- **Qué hace:** al apuntar tantos suena un toque suave y vibra levemente; al ganar la partida, una vibración de éxito y un sonido distinto. Ajustes → «Respuesta al apuntar» permite desactivar cada canal. Por defecto: vibración activada, sonido desactivado (en una mesa de mus el sonido molesta).
- **El marcador no depende de ellos:** el tanteo, el aviso de «Deshacer» y la victoria se ven y se anuncian por VoiceOver igual con ambos canales desactivados.
- **Modo silencioso:** el sonido usa sonidos de sistema, que respetan el interruptor de silencio del iPhone.
- **No bloquea la anotación:** la respuesta se dispara sin esperar; el siguiente toque se atiende siempre.
- **Sin respuesta:** los ajustes manuales ±1, los rechazos y el deshacer no vibran ni suenan.
- **Código:** `App/State/Feedback.swift` (protocolo `FeedbackPlayer`); `FeedbackTests` lo comprueba con un espía.
- **Pendiente:** probar la sensación real en un iPhone físico (el simulador no vibra).

## 4. Revisión manual antes de cada versión (no automatizable)

Hecha en un iPhone real o en el simulador. **Pendiente de realizar y anotar con la versión candidata:**

1. VoiceOver: recorrer Inicio → Preparar partida → marcador → victoria → historial sin ver la pantalla.
2. Ajustes → Accesibilidad → Pantalla y tamaño de texto → Texto más grande → máximo: revisar marcador (vertical y horizontal), preparar partida y ajustes.
3. Activar «Diferenciar sin color» y «Aumentar contraste»: ninguna información debe perderse.
4. Activar «Reducir movimiento».
5. Control por voz y teclado externo: todos los botones tienen un nombre pronunciable y orden de foco lógico.

Los hallazgos se registran como issues con la etiqueta `M3`.
