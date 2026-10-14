# Validación con jugadores de mus

Estado: **instrumento listo, consulta pendiente.** Este documento recoge el plan de consulta, las hipótesis de partida y el registro donde se anotarán las respuestas. Las conclusiones provisionales son decisiones por defecto del equipo; deben confirmarse o corregirse con los resultados.

## 1. Objetivo

Confirmar con jugadores reales el vocabulario, las variantes y el flujo de anotación antes de cerrar el diseño (M1) y la implementación (M2). Referencia funcional: MusMarca (tanteo visible, anotación directa por lances, deshacer).

## 2. Muestra mínima

| Requisito | Mínimo |
|---|---|
| Jugadores consultados | 8 |
| Niveles | al menos 2 principiantes/ocasionales, 3 habituales, 2 veteranos de peña/torneo |
| Grupos con reglas de casa distintas | al menos 2 (p. ej. peña que juega a 40 con vacas y grupo de amigos que juega a 30 sin vacas) |
| Dispositivos | al menos 2 personas con iPhone pequeño y 2 con pantalla grande |

## 3. Guion (20 min por persona o grupo)

1. **Contexto (3 min)**: ¿cómo apuntáis hoy? (piedras, papel, app, memoria). ¿Qué es lo que peor lleváis?
2. **Reglas de casa (5 min)**:
   - ¿A 30 o a 40? ¿Se juegan vacas? ¿Cuántas (a 2 de 3, a 3 de 5)?
   - ¿Cuándo se apuntan los tantos: lance a lance o al final de la mano?
   - ¿Cómo tratáis el órdago? ¿Se ve «el resto» o se corta la partida al instante?
   - ¿Cuántos tantos valen Pares (pareja/medias/duples) y Juego (31 / resto) y Punto?
   - ¿Se da «la mano» o hay «amarracos/piedras» en vuestra forma de contar?
3. **Vocabulario (3 min)**: ¿Qué palabras usáis para cada cosa? (tanto/punto/piedra/amarraco; vaca/juego/partida; envido/envite; «paso»…).
4. **Prueba del prototipo (7 min)**: con el prototipo de alta fidelidad cuando exista (issue de prototipo, M1), o con papel. Tareas: empezar partida, apuntar «Grande 2 al equipo B», deshacer, terminar una partida, retomar.
5. **Cierre (2 min)**: ¿qué echaríais en falta? ¿pagaríais por algo? (para la issue de modelo de ingresos).

## 4. Hipótesis y valores por defecto

| Tema | Hipótesis por defecto | Cómo se confirma |
|---|---|---|
| Objetivo de tantos | Se admiten **30 y 40**; por defecto 40 | ≥ 6/8 jugadores usan uno de los dos |
| Vacas | Opción **«Vacas para ganar»**: 1 (sin vacas), 2 (mejor de 3) o 3 (mejor de 5). Por defecto: 1 | Al menos un grupo usa vacas |
| Anotación | Lance a lance, con cantidad libre | Los jugadores no piden «sumar al final de la mano» |
| Órdago | Gana la partida/juego en curso quien lo gana | Ningún grupo usa otra regla |
| Corrección | Deshacer + ajuste manual ±1 | Nadie pide edición libre del marcador |

## 5. Registro de respuestas

Copiar una fila por persona/grupo.

| ID | Nivel | Grupo/región | Objetivo | Vacas | Variantes de casa | Confusiones | Vocabulario | Observaciones |
|---|---|---|---|---|---|---|---|---|
| J1 | | | | | | | | |
| J2 | | | | | | | | |

## 6. Conclusiones provisionales (a revisar tras la consulta)

- **30 y 40 tantos:** el primer lanzamiento permite ambos. 40 es el valor por defecto.
- **Vacas:** el MVP trata las vacas como «número de partidas ganadas necesarias» (1, 2 o 3). Una vaca ganada se muestra en el marcador; no hay reglas adicionales de vaca (p. ej. «vaca de oro»).
- **Vocabulario de la app:** *tantos* (no «puntos»), *lance*, *envite*, *órdago*, *vaca*, *revancha*.

## 7. Cómo actualizar el alcance

Tras la consulta: actualizar la tabla de §4, mover cualquier petición recurrente a [visión y alcance](vision-y-alcance.md) (dentro o fuera del MVP) y revisar la especificación de reglas.
