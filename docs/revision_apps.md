# Revisión de apps de guitarra (Enlace Móvil)

Catálogo y resultados del workflow `/revisar-app` (`.claude/skills/revisar-app/SKILL.md`). Se
revisan apps del teléfono a través de Enlace Móvil para tomar **ideas** (módulos, formas de
practicar, organización), nunca contenido: licks, tablaturas, audio, textos, imágenes y nombres
de artistas de esas apps no se copian.

Estados: `pendiente`, `revisada`, `no instalada`, `de pago` (casi todo detrás de un pago).

## Orden de revisión

Se revisa por familias: dentro de una familia las apps se parecen, así que la primera se recorre
a fondo y las demás solo por lo que cambia. Orden de las familias, de más a menos valor para lo
que ya tiene el proyecto:

1. **licks**: amplía Licks y riffs (`lib/domain/licks/`).
2. **jam**: pistas de acompañamiento; hoy no existen (sería un módulo nuevo, con audio
   sintetizado).
3. **caged**: compara con CAGED en escalas, acordes y la guía "CAGED: acorde y escala".
4. **mastil**: compara con Notas del mástil, el detalle de escala y el Buscador.
5. **tecnica**: tapping (la notación de la tablatura todavía no lo tiene).
6. **componer**: compara con "Mi progresión" (Progresiones).

## 1. Familia licks: bibliotecas de licks

Qué mirar: cómo se organiza por estilo y nivel, cómo se practica cada lick (tempo, bucle, tramo,
lento), qué notación usa (y qué técnicas dibuja que nosotros no), si hay acompañamiento, si mide
el progreso. Compara con Licks y riffs, `TabPlayer` y las guías de Estilos.

| App | Estado | Fecha |
|---|---|---|
| 144 Blues Guitar Licks Pro | pendiente | |
| 20 Acoustic Blues Solos | pendiente | |
| 40 Guitar Licks | pendiente | |
| 48 Jazz Guitar Licks | pendiente | |
| 50 Easy Blues Guitar Licks | pendiente | |
| 63 Advanced Blues Guitar Licks | pendiente | |
| 65 Country Guitar Licks | pendiente | |
| 65 Gypsy Jazz Guitar Licks | pendiente | |
| 85 Metal Guitar Licks | pendiente | |
| 96 Rock Guitar Licks | pendiente | |

Ojo: el gypsy jazz no está entre los estilos (`LickStyle`). Agregarlo es una decisión de
producto.

## 2. Familia jam: pistas de acompañamiento

Qué mirar: qué controla el usuario (tonalidad, tempo, progresión, instrumentos), cómo muestra
qué escala usar encima, si marca el compás o el acorde que suena, si se puede repetir un tramo.
Compara con la progresión que suena en Progresiones, el metrónomo, los ▶ del círculo y las ideas
de improvisación del detalle de escala. Todo audio nuestro es sintetizado
(`lib/domain/audio/pluck_synth.dart`): anotar qué haría falta sintetizar (bajo, batería, otros
instrumentos).

| App | Estado | Fecha |
|---|---|---|
| Blues Guitar Jam Tracks | pendiente | |
| Slow Blues Guitar Jam Tracks | pendiente | |
| Rock Guitar Jam Tracks | pendiente | |
| Metal Guitar Jam Tracks | pendiente | |
| Country Guitar Jam Tracks | pendiente | |
| Modal Guitar Jam Tracks | pendiente | |

## 3. Familia caged: sistema CAGED

Qué mirar: cómo enseña las cinco formas y cómo pasa de una a otra, cómo une acorde, arpegio y
escala, y si tiene ejercicios o quiz. Compara con los sistemas de escala
(`lib/domain/fingering_systems/`), las `cagedPositions` de `chords.json` y la guía "CAGED: acorde
y escala".

| App | Estado | Fecha |
|---|---|---|
| CAGED Companion | pendiente | |
| CAGEDapp | pendiente | |

## 4. Familia mastil: mástil y escalas

Qué mirar: tipos de pregunta y de juego, cómo muestra las escalas (sistemas, digitaciones,
intervalos) y qué filtros tiene. Compara con Notas del mástil (`fretboard_quiz.dart`), el detalle
de escala, la vista ampliada y el Buscador.

| App | Estado | Fecha |
|---|---|---|
| Fretmaster | pendiente | |
| Guitar Scales and Patterns | pendiente | |
| Guitar Fretboard | pendiente | |

## 5. Familia tecnica: tapping

Qué mirar: cómo dibuja el tapping en la tablatura y qué ejercicios tiene, en qué orden.
Compara con Técnica (`technique_exercises.dart`) y con la notación (`TabTechnique`): el tapping
sería una técnica nueva, con su regla en `tabNotationProblems` y su sonido en `tabSounds`.

| App | Estado | Fecha |
|---|---|---|
| Learn Tapping for Guitar | pendiente | |

## 6. Familia componer

Qué mirar: cómo se arma una progresión o una canción (grados, compases, secciones), qué
sugiere y cómo se escucha y se guarda. Compara con "Mi progresión", el `ProgressionBuilder` y la
teoría "¿Por qué?" (`harmony.dart`).

| App | Estado | Fecha |
|---|---|---|
| Pocket Composer | pendiente | |

## Plantilla de ficha

```markdown
### <App> (<familia>) — <fecha>

<Resumen: qué es y qué hace bien, en 2–3 líneas.>

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| <qué hace> | ya está / parcial / nueva | <archivo o pantalla> | S / M / L | <por qué vale o qué falta> |

Para decidir: <decisiones de producto, musicales o de licencia, si hay>.
Sin ver: <lo que estaba detrás de un pago o un registro>.
```
