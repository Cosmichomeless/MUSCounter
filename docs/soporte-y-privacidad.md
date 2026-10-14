# Soporte, solicitudes de privacidad y ficha de App Store

Cierra el alcance de #19. Lo marcado como **[a cargo del titular]** no se puede completar desde el repositorio.

## 1. Enlaces en la app

| Clave (`Config/*.xcconfig`) | Info.plist | Uso |
|---|---|---|
| `PRIVACY_POLICY_URL` | `MusPrivacyPolicyURL` | Botón «Política de privacidad completa» |
| `SUPPORT_EMAIL` | `MusSupportEmail` | Botón «Contactar con soporte» (`mailto:`) |

- Vacías por defecto (Debug/CI): la app **oculta** los botones en vez de enseñar un enlace roto (`SupportInfo`, con pruebas).
- `scripts/archive.sh` **no archiva** sin ambas en `Config/Secrets.xcconfig`. En xcconfig `//` es un comentario: escribe la URL como `https:/$()/dominio/privacidad`.
- El resumen de privacidad va empaquetado en la app y funciona sin conexión. La URL de la ficha de App Store debe apuntar a la política pública ([borrador](privacidad.md)). **[a cargo del titular]** alojarla y fijar el contacto.

## 2. Canal de soporte

- Correo único `SUPPORT_EMAIL`, accesible desde Ajustes y desde la ficha (URL de soporte).
- Respuesta objetivo: 5 días laborables.
- Registro mínimo de incidencias en issues de GitHub sin datos personales; el correo no se copia a los issues.

## 3. Procedimiento de solicitudes de privacidad

1. Recepción por el correo de soporte (asunto «Privacidad»).
2. Verificar que quien escribe es el remitente de la solicitud; no se pide documentación adicional salvo duda razonable.
3. Responder en **un mes** (RGPD art. 12), prorrogable justificadamente.
4. Contenido de la respuesta: no existen datos personales en servidores propios; las partidas residen en el dispositivo (se borran al desinstalar). Para datos de publicidad, indicar a Google (<https://myaccount.google.com/data-and-privacy>).
5. Conservar solo la fecha y el tipo de solicitud como constancia.

## 4. Respuestas de privacidad de App Store Connect

> **Recomendado, a verificar por el titular en App Store Connect** (no se ha modificado nada allí). Se basa en la guía de Google sobre divulgación de datos del SDK de AdMob; revísala al actualizar el SDK. La app ya **no** puede declararse «Datos no recopilados».

**¿Recopilan datos?** Sí (a través del SDK de terceros de Google).

| Tipo de dato (Apple) | Vinculado al usuario | Seguimiento | Propósito |
|---|---|---|---|
| Identificadores → ID de dispositivo | Sí | No | Publicidad de terceros, analítica |
| Datos de uso → Datos de publicidad | Sí | No | Publicidad de terceros |
| Datos de uso → Otras interacciones | Sí | No | Publicidad de terceros, analítica |
| Diagnósticos → Datos de rendimiento y de fallos | No | No | Analítica |
| Ubicación aproximada (dirección IP) | Sí | No | Publicidad de terceros |

- **Seguimiento («Tracking») = No**: no se solicita ATT ni se accede al IDFA (decisión en [anuncios](anuncios.md)). Si esto cambia, hay que declarar seguimiento, añadir `NSUserTrackingUsageDescription` y los dominios en el manifiesto.
- **Datos propios:** ninguno (sin cuenta, sin servidor, sin analítica propia).
- `App/PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, sin dominios, sin tipos recopilados por la app ni APIs de «razón requerida» propias. El SDK (13.x) y UMP traen su propio manifiesto.
- Cuestionario de clasificación por edad y «Contiene anuncios»: indicar que sí hay publicidad.

## 5. Antes del lanzamiento

- [ ] **[a cargo del titular]** Cuenta e IDs reales de AdMob; mensaje de consentimiento UMP publicado en AdMob (EEE/Reino Unido/Suiza).
- [ ] **[a cargo del titular]** Política pública alojada, `PRIVACY_POLICY_URL` y `SUPPORT_EMAIL` en `Secrets.xcconfig`.
- [ ] **[a cargo del titular]** Revisión legal del [borrador](privacidad.md) y cumplimentar la ficha de privacidad según §4.
- [ ] Probar en un dispositivo con región EEE: aparece el formulario UMP y «Revisar consentimiento» funciona.
- [ ] Revisar `PrivacyInfo.xcprivacy` y la ficha al actualizar GoogleMobileAds.
