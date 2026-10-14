# Propuesta de valor, nombre e ingresos

Estado: **propuesta del equipo, pendiente de confirmación del responsable de producto.** La disponibilidad del nombre en App Store y la valoración con jugadores no se pueden comprobar desde el repositorio y se listan como acciones pendientes.

## 1. Propuesta de valor (una frase)

> Apunta tu partida de mus en dos toques: tanteo grande y claro sobre la mesa, anotación directa por lances y un deshacer que nunca falla — sin cuenta, sin conexión obligatoria y con anuncios que nunca tapan el marcador.

**Público inicial:** jugadores habituales de mus en España (peñas, bares, grupos de amigos y familia) que hoy usan piedras, papel o contadores genéricos.

## 2. Diferenciación frente a los contadores gratuitos

| Punto de dolor habitual | Respuesta del producto |
|---|---|
| Anuncios que tapan el marcador | Anuncios discretos y nunca sobre el tanteo (ver §4); sin cuentas; el marcador funciona sin red |
| Contadores genéricos (no saben de lances) | Anotación por Grande, Chica, Pares, Juego y Punto con registro |
| Errores al sumar | Deshacer exacto y lista de acciones recientes |
| Poca legibilidad en la mesa | Tanteo muy grande, dos lados diferenciados por color **y** forma, tema oscuro |
| Se pierde la partida al cerrar | La partida en curso se recupera siempre |

## 3. Nombre e identidad

**Nombre elegido: Tanteo Mus** (decisión del responsable de producto). *MUSCounter* sigue siendo solo el nombre del repositorio y del proyecto de Xcode. La disponibilidad en App Store, dominio y marca sigue pendiente de comprobar (§6).

Candidatos considerados:

| Candidato | Idea | Comprobaciones pendientes |
|---|---|---|
| **Tanteo Mus** | Descriptivo, bueno para ASO en español | Disponibilidad en App Store, dominio, marca registrada (OEPM) |
| **Órdago: marcador de mus** | Memorable y propio del juego | Ídem; riesgo de confusión con apps de cartas homónimas |
| **Piedras** | Referencia a las piedras con las que se cuenta | Ídem; nombre muy genérico |

**Decisión:** Tanteo Mus como nombre y «Marcador de mus rápido y sin cuenta» como subtítulo, sujeto a la comprobación de disponibilidad. Si el nombre no estuviera libre, el siguiente candidato es «Órdago: marcador de mus».

**Identidad visual propia (dirección):** fieltro verde oscuro de mesa de juego, acentos «oro» de la baraja española, tipografía de sistema redondeada con cifras tabulares. Equipos diferenciados por color **y** forma/etiqueta (nunca solo color). Se desarrolla en la issue del sistema visual (M1). Prohibido copiar iconografía, composición o textos de MusMarca.

## 4. Modelo de ingresos del MVP

**Decisión:** el MVP es **gratuito, con anuncios y sin compras integradas**.

- El marcador esencial (crear partida, tanteo, deshacer, recuperar, historial) nunca se bloquea tras un pago.
- **Anuncios (política inicial, a confirmar en la issue de privacidad):**
  - Solo banner discreto en Inicio, Historial y pantalla de victoria. **Nunca** en la pantalla del marcador, ni intersticiales ni vídeos que interrumpan una partida.
  - Sin conexión no se muestra ningún anuncio y el marcador funciona igual.
  - Sin cuenta y sin analítica propia. Se usará un SDK publicitario de terceros, por lo que la ficha de privacidad **ya no podrá decir «Datos no recopilados»**: hay que declarar los datos del SDK (identificadores, datos de uso) y valorar el aviso de transparencia de seguimiento (ATT) y el consentimiento (UMP/RGPD) en España.
- **Proveedor elegido: Google AdMob** (SDK `GoogleMobileAds` por Swift Package Manager). Motivos: es el estándar en iOS con mejor relleno en España, es gratuito sin cuota fija, incluye el formulario de consentimiento (Google UMP) compatible con el RGPD y el marco de transparencia de la IAB (TCF), y permite banners adaptativos que se ajustan al ancho sin tapar contenido. Alternativas descartadas: AppLovin MAX y mediación múltiple (complejidad innecesaria para un MVP), Meta Audience Network (menor relleno y peor encaje con la política de privacidad).
- Integración (trabajo de código pendiente, no incluido en esta entrega): módulo de anuncios aislado de `MusCore`; en desarrollo y CI se usan los identificadores de prueba de Google; los identificadores reales no se guardan en el repositorio sino en configuración de build. Hasta que se integre, la app no muestra anuncios.
- Opción futura para quitar anuncios: compra única «Quitar anuncios». Se valorará tras M5.
- Para valorar tras M5: compra opcional única «Apoyar el proyecto» o paquete de temas/sonidos. Se decidirá con evidencia de uso, no antes.

## 5. Dónde se refleja la decisión

- [Visión y alcance](vision-y-alcance.md): el MVP incluye anuncios discretos (nunca en el marcador) y no incluye compras integradas.
- Textos de tienda (issue de ficha, M4): la descripción menciona «sin cuenta» y «el marcador funciona sin conexión» y declara la existencia de anuncios.
- Privacidad (issue de cumplimiento, M3): declarar los datos del SDK publicitario, consentimiento y ATT.

## 6. Acciones pendientes de una persona

1. Comprobar disponibilidad del nombre elegido en App Store Connect, dominio y registro de marca.
2. Crear la cuenta de AdMob, dar de alta la app y obtener los identificadores de bloque de anuncios.
3. Contrastar la propuesta de valor con la consulta a jugadores.
