# Anuncios (Google AdMob)

Política: [propuesta de valor](propuesta-de-valor.md) §4. El MVP es gratuito con **banners discretos**; sin compras integradas, sin intersticiales y sin vídeo. El marcador no depende de la red ni de los anuncios.

## 1. Dónde aparecen

| Pantalla | Banner |
|---|---|
| Inicio | Sí, al pie |
| Historial | Sí, al pie |
| Victoria (resultado) | Sí, al pie |
| **Marcador** | **Nunca** |
| Preparar partida y Ajustes | No |

`AdPlacement` (`App/Ads/AdSlot.swift`) lista las únicas pantallas con banner y `AdsTests` comprueba que `game`, `setup` y `settings` no lo tienen. `scripts/check_ads_isolation.py` (CI) impide que `GameView`, `TeamPanel`, el flujo de partida o `MusCore` mencionen el SDK.

## 2. Arquitectura

- Paquete local `Packages/MusAds`: único sitio que importa `GoogleMobileAds` y `UserMessagingPlatform` (SPM, versiones fijas). `MusCore` no lo conoce.
- `AdsController`: recoge el consentimiento (Google UMP, RGPD/TCF) y arranca el SDK solo si `canRequestAds`. Sin configuración, sin consentimiento o ante cualquier fallo → `canShowAds == false` y la app sigue igual.
- `AdBanner`: banner adaptativo anclado que ocupa **cero** altura hasta recibir un anuncio. Sin red o con error no hay hueco ni cambio de layout.
- Las pruebas (`XCTest`) y el argumento de lanzamiento `-MusAdsDisabled` desactivan los anuncios.

## 3. Identificadores

| Entorno | App ID / bloque de banner |
|---|---|
| Debug | Siempre los **de prueba de Google** |
| CI / Release sin `Secrets.xcconfig` | De prueba de Google (por defecto en `Config/Shared.xcconfig`) |
| Release / TestFlight / App Store | Reales, en `Config/Secrets.xcconfig` (ignorado por git; plantilla en `Secrets.xcconfig.example`) |

`scripts/archive.sh` se niega a archivar si faltan los reales o son los de prueba. **Tarea de una persona:** crear la cuenta de AdMob, dar de alta la app y un bloque de tipo banner y copiar los dos identificadores a `Secrets.xcconfig`. Cuando se publique, enlazar la app en AdMob con su ficha de App Store.

## 4. Consentimiento (UMP)

- Al abrir la app, antes de pedir ningún anuncio, se actualiza el estado de consentimiento y se muestra el formulario si procede (EEE/Reino Unido).
- Ajustes → «Anuncios» → «Revisar consentimiento de anuncios» aparece cuando UMP indica que hay opciones de privacidad que ofrecer.
- Para probar el formulario hay que configurar en AdMob → Privacidad y mensajes un mensaje de consentimiento (lo hace la persona que gestiona la cuenta) y, en un dispositivo de prueba, `DebugSettings` de UMP (no incluido en el repositorio).

## 5. ATT (App Tracking Transparency)

**Decisión: no se solicita ATT en esta versión.** La app no accede al IDFA ni enlaza datos con otras apps o webs, por lo que no necesita el aviso; el SDK sirve anuncios sin IDFA (menos personalizados). No se declara `NSUserTrackingUsageDescription`. Si en el futuro se quisiera mejorar la monetización con IDFA, habría que añadir la clave, el aviso previo a UMP y actualizar la política de privacidad y la ficha de App Store. `SKAdNetworkItems` (lista oficial de Google, 50 identificadores) se mantiene en `project.yml`.

## 6. Privacidad y tienda

- La ficha de privacidad de App Store Connect **ya no puede ser «Datos no recopilados»**: el SDK de AdMob recopila datos de dispositivo y de uso para publicidad. Se concreta en #19.
- Los textos de tienda (#21) deben mencionar los anuncios y no decir «sin anuncios».
- La política de privacidad (#19) debe citar a Google como tercero y el modo de revisar el consentimiento.

## 7. Pendiente de comprobar con identificadores reales

- Que el banner se rellena (con identificadores reales, el relleno depende de la cuenta).
- Que el formulario de consentimiento se muestra en el EEE.
- Que no hay hueco en pantalla con el iPhone sin conexión.
