# Publicación de Tanteo Mus 1.0

Lista de comprobación propia de esta app, basada en la guía general de publicación (`Apps/GUIA_PUBLICACION_APP_STORE.md`, fuera de este repositorio). Los textos de la ficha están en [ficha de App Store](ficha-app-store.md); la compilación y la subida de builds, en [compilación](compilacion.md). Nada de esto se ha hecho en App Store Connect: cada acción allí la confirma el titular.

## 1. Antes de archivar

- [ ] Subir `MARKETING_VERSION` de `0.1.0` a `1.0` en `Config/Shared.xcconfig`; `CURRENT_PROJECT_VERSION` sube en cada subida.
- [ ] Confirmar el **Bundle ID** definitivo (`com.cosmichomeless.muscounter` figura como provisional en [compilación](compilacion.md)). Debe estar registrado y es el de la app creada en App Store Connect.
- [ ] `Config/Secrets.xcconfig` presente en el Mac que archiva (`DEVELOPMENT_TEAM` e identificadores reales de AdMob); la Release debe llevar IDs reales, no los de prueba.
- [ ] `ITSAppUsesNonExemptEncryption = NO`: ya está en `project.yml`.
- [ ] `App/PrivacyInfo.xcprivacy` presente (sin rastreo, sin datos propios recopilados); AdMob y UMP aportan su manifiesto. Comprobar el informe de privacidad del archivo (*Product › Archive › Generate Privacy Report*) frente a la declaración de §3.
- [ ] Xcode con el SDK que Apple exija en ese momento (el mínimo para compilar, Xcode 16, no basta para subir si Apple pide uno más nuevo).
- [ ] Pruebas verdes: `python3 scripts/check_docs.py`, `check_rules_tests.py`, `swift test` en `Packages/MusCore` y `./scripts/test-app.sh`.

## 2. Build y pruebas en dispositivo

- [ ] `DEVELOPMENT_TEAM=… ./scripts/archive.sh`, subir con Organizer y esperar a que la build esté `VALID` en TestFlight.
- [ ] Instalar la Release desde TestFlight en un **iPhone físico** y comprobar: arranque sin cuenta ni conexión, partida completa, háptica, rotación, VoiceOver, ajuste «Revisar consentimiento» y que los anuncios salen con los IDs reales (sin pulsarlos).
- [ ] Beta con jugadores reales según [beta cerrada](beta-cerrada.md).

## 3. App Store Connect (cada paso lo confirma el titular)

| Paso | Valor para Tanteo Mus |
|---|---|
| Acuerdos | Aceptado el de apps gratuitas (el titular debe aceptar los pendientes); no se cobra en la app |
| Nombre / subtítulo / textos | [ficha](ficha-app-store.md) §1–§3; «Novedades» no existe en la 1.0 |
| Capturas | `docs/capturas/` (6,9″, 1320 × 2868); revisar que siguen siendo fieles a la build |
| Precio / disponibilidad | Gratis; territorios a decidir por el titular |
| Categorías | Utilidades; secundaria Juegos › Cartas |
| Clasificación por edad | Cuestionario: sin contenido sensible, sin apuestas ni juegos de azar simulados, **contiene anuncios** → esperada 4+ |
| Derechos de contenido | No usa contenido de terceros |
| Copyright | `2026 <titular>` (lo pone el titular) |
| Privacidad de la app | **No** «Datos no recopilados»: declarar los datos de publicidad de Google AdMob con finalidad «Publicidad o marketing de terceros», sin rastreo; ver [soporte y privacidad](soporte-y-privacidad.md) §4 |
| DSA (comerciante) | Lo indica el titular según su situación |
| Dispositivo médico regulado | No |
| Cifrado | Exención estándar (`ITSAppUsesNonExemptEncryption = NO`) |
| URLs | Soporte, privacidad y marketing de [ficha](ficha-app-store.md) §1 (comprobar que devuelven 200) |
| Publicación | `AFTER_APPROVAL` o manual, a decidir por el titular |

## 4. Notas para Apple (borrador)

```
Tanteo Mus es un marcador para el juego de cartas mus. No requiere cuenta ni inicio de sesión y no pide ningún permiso.
Para probarla: abrir la app, pulsar «Nueva partida», pulsar un lance (Grande, Chica, Pares, Juego o Punto) y una cantidad para apuntar tantos a un equipo; «Deshacer» revierte la última jugada.
La app es gratuita y muestra banners de Google AdMob en Inicio, Historial y la pantalla de victoria, nunca durante el marcador. En el EEE, Reino Unido y Suiza se muestra el formulario de consentimiento de Google (UMP) antes de pedir anuncios. No se usa App Tracking Transparency.
No hay compras integradas ni funciones que dependan de la conexión.
```

Contacto del revisor (nombre, correo, teléfono): lo rellena el titular en App Store Connect; no se guarda en el repositorio.

## 5. Enviar y comprobar

- [ ] Asociar la build `VALID`, repasar todos los campos de §3 y enviar a revisión (estado esperado: `WAITING_FOR_REVIEW`).
- [ ] Tras publicarse: ficha visible en los territorios elegidos; instalación limpia sin cuenta ni conexión que inicia y termina una partida; enlaces de soporte y privacidad correctos; anuncios con IDs reales; registrar versión, fecha e incidencias.
- [ ] Opcional: `app-ads.txt` en la raíz de la web y enlazar la app de AdMob con su ficha de App Store.
- [ ] Bajar de permisos o revocar la clave de la API de App Store Connect si se usó.
