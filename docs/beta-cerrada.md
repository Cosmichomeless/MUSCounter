# Beta cerrada (TestFlight)

Cubre #20. **Este documento prepara la beta; no la sustituye.** Hace falta distribuir una build a jugadores reales, y eso depende del titular (**[a cargo del titular]**). El issue no se puede cerrar hasta que la beta se haya ejecutado y se cumplan los criterios de §6.

## 1. Dispositivos y versión compatibles

- iPhone con iOS 17 o superior ([arquitectura](arquitectura.md)); solo iPhone, vertical y horizontal.
- Cobertura mínima: un iPhone pequeño (pantalla ≤ 5,5″ o SE), uno estándar y uno grande (Max/Plus), más un dispositivo en iOS 17.x y otro en la última versión.
- Distribución: TestFlight interno (equipo) → externo (jugadores, requiere revisión de beta de Apple). Los anuncios en TestFlight usan los IDs reales: no pulsar los anuncios propios.

## 2. Flujos que debe cubrir cada tester

| # | Flujo | Qué se comprueba |
|---|---|---|
| 1 | Crear partida (30/40, vacas, nombres) | Valores por defecto y edición |
| 2 | Anotar Grande, Chica, Pares, Juego y Punto con cantidad | El marcador suma lo que el jugador espera |
| 3 | Órdago | Termina la partida/juego como se juega en su grupo |
| 4 | Ajuste manual ±1 y deshacer varias veces | Nada se pierde ni se descuadra |
| 5 | Terminar partida, revancha, partida nueva | Ganador y motivo correctos |
| 6 | Cerrar la app a mitad de partida y reabrir | La partida se recupera |
| 7 | Historial | Las partidas terminadas aparecen una sola vez |
| 8 | Ajustes: tema, vibración, sonido, privacidad | Se aplican y persisten |
| 9 | Horizontal, texto grande, VoiceOver ([accesibilidad](accesibilidad.md) §4) | Legible y operable |
| 10 | Banners y consentimiento (EEE) | No tapan el marcador; el formulario aparece donde corresponde |

## 3. Qué incidencias se recogen

| Categoría | Ejemplos | Gravedad por defecto |
|---|---|---|
| **Error de tanteo** | Suma incorrecta, ganador equivocado, vaca mal contada, órdago mal resuelto | Bloqueante |
| **Pérdida de partida** | Se pierde la partida al cerrar, el historial duplica o pierde partidas, deshacer rompe el estado | Bloqueante |
| **Confusión de controles** | El tester no sabe cómo anotar, deshacer o terminar; toca el equipo equivocado | Alta si lo sufren ≥ 2 testers |
| Visual / accesibilidad | Texto cortado, contraste, VoiceOver sin etiqueta | Media |
| Anuncios | Banner que tapa controles, formulario que no aparece | Alta |
| Sugerencia | Funciones que echan en falta | Baja |

Cada incidencia lleva: dispositivo y versión de iOS, versión/build, pasos, resultado esperado y obtenido. En TestFlight se puede enviar captura y comentario desde la propia app; también el canal de §4. **Bloqueante** = impide completar una partida o pierde datos: se corrige antes del lanzamiento.

## 4. Canal de feedback

- Formulario de TestFlight (captura + comentario) y el correo de soporte ([soporte y privacidad](soporte-y-privacidad.md)).
- El equipo vuelca las incidencias en issues de GitHub (etiqueta `beta`), sin datos personales del tester.
- Revisión de incidencias al cierre de cada ronda; objetivo: dos rondas de una semana con 8 o más jugadores ([validación con jugadores](validacion-jugadores.md) §2).

## 5. Notas de versión (plantilla para TestFlight)

> **Tanteo Mus — beta N (build X)**
>
> **Qué probar:** crea una partida, anota unas manos con Grande, Chica, Pares, Juego y Punto, prueba el deshacer, termina la partida y vuelve a abrirla a mitad de otra para ver si se recupera.
>
> **Novedades:** `[lista de cambios desde la beta anterior]`
>
> **Problemas conocidos:** `[lista]`
>
> **Anuncios:** la app es gratuita y muestra banners fuera del marcador. No pulses los anuncios.
>
> **Cómo enviar feedback:** captura de pantalla desde TestFlight o escribe a `[correo de soporte]`. Cuéntanos sobre todo si el tanteo no sale como esperabas, si algo no se entiende o si pierdes una partida.

## 6. Criterios de salida (de #20)

- [ ] La beta ha cubierto los flujos de §2 en los dispositivos de §1.
- [ ] Incidencias de tanteo, controles y pérdida de partida recogidas (§3).
- [ ] Sin defectos bloqueantes ni pérdida de datos conocida.
- [x] Notas de versión y canal de feedback preparados (§4 y §5).

## 7. Registro de rondas

| Ronda | Fechas | Build | Testers | Dispositivos | Bloqueantes abiertos | Notas |
|---|---|---|---|---|---|---|
| 1 | | | | | | |
