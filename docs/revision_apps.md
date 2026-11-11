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
| 144 Blues Guitar Licks Pro | revisada | 2026-11-11 |
| 20 Acoustic Blues Solos | revisada | 2026-11-11 |
| 40 Guitar Licks | revisada | 2026-11-11 |
| 48 Jazz Guitar Licks | revisada | 2026-11-11 |
| 50 Easy Blues Guitar Licks | revisada | 2026-11-11 |
| 63 Advanced Blues Guitar Licks | revisada | 2026-11-11 |
| 65 Country Guitar Licks | revisada | 2026-11-11 |
| 65 Gypsy Jazz Guitar Licks | revisada | 2026-11-11 |
| 85 Metal Guitar Licks | revisada | 2026-11-11 |
| 96 Rock Guitar Licks | revisada | 2026-11-11 |

Ojo: el gypsy jazz no está entre los estilos (`LickStyle`). Agregarlo es una decisión de
producto.


### 144 Blues Guitar Licks Pro (licks) — 2026-11-11

Es de Jonathan Bell, con la misma plantilla que 20 Acoustic, 48 Jazz, 50 Easy y 63 Advanced. Tiene 144 licks
numerados en 6 pestañas por estilo (clásico, Chicago, rockabilly, Texas y dos de extras), sin
título ni nivel por lick. Cada lick muestra la tablatura con ritmo, tempo y tonalidad, ▶/■, favorito,
anterior/siguiente y un texto de dos líneas. El texto dice qué posición de la escala usa y qué papel
tiene la nota clave (por ejemplo, que el bend lleva a la b5).

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Transponer el lick a cualquier tonalidad con − / + (la tablatura se recalcula) | nueva | `Lick` + `TabPlayer` (detalle de lick) | M | La más valiosa. Se haría por regla: subir o bajar todos los trastes y, si alguno sale de 0–24, desplazar ±12 (como las escalas). Una frase con cuerdas al aire solo se transpone si todo queda dentro del mástil; si no, no se ofrece. Los textos que nombran notas tendrían que generarse, no ser fijos (la app los esconde al transponer). |
| Favoritos (estrella) | nueva | Licks y riffs | S | Hoy solo se guarda el récord (`licks_best_bpm`). Falta decidir dónde se verían (por ejemplo, un filtro «Favoritos» en la lista). |
| Anterior / siguiente sin volver a la lista | nueva | detalle de lick | S | Dentro del mismo estilo o del filtro activo. |
| El texto dice la posición de la escala y la función de la nota clave | parcial | `Lick.about` | S | Algunas de nuestras frases ya lo hacen; se podría pedir en todas, con test de lo que afirma, como siempre. |
| Marcar la nota que suena | ya está | `TabPlayer` | — | Ellos no marcan nada al sonar. Nosotros sí, y además tenemos bucle, tramo, tempo y micrófono. |

### 20 Acoustic Blues Solos (licks) — 2026-11-11

Misma plantilla. Las pestañas van por nivel (principiante, intermedio, avanzado) y los solos son largos, de
varios renglones y con repeticiones. En lugar de transponer trae afinador, porque los solos usan cuerdas
al aire. El texto explica la técnica: bajo constante con el pulgar y melodía con los dedos.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Bajo alternado y melodía a la vez (dos voces con duraciones distintas) | nueva | notación (`TabNote`) | L | `TabNote.chord` solo admite notas que empiezan y duran juntas. Dos voces piden otra estructura. Serviría para fingerstyle (la rítmica tiene la unidad «Con los dedos»). |
| Repeticiones (barras de repetición) | nueva | notación | M | Hoy, para repetir, se copian las notas. |
| Afinador a mano desde la frase | parcial | `Lesson.tool` | S | Las lecciones ya abren el afinador; el detalle de lick no. |
| Solos largos por nivel | parcial | Licks y riffs | — | Nuestras frases son cortas a propósito; un «solo» sería un tipo nuevo de frase (decisión de producto). |

### 40 Guitar Licks (licks) — 2026-11-11

De otro autor y más sencilla. Tiene cuatro categorías (rock and roll, blues, funk, hard rock) con licks
numerados. Cada lick suena **con una pista de acompañamiento**, con un volumen para el lick y otro
para el acompañamiento, y hay un botón de media velocidad.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Acompañamiento debajo de cada lick, con dos volúmenes | nueva | `TabPlayer` + audio | L | Habría que sintetizar acordes (ya tenemos rasgueo y digitaciones) y, para que suene a banda, bajo y batería. Conviene revisarlo junto con la familia jam. |
| Media velocidad con un toque | parcial | `TabPlayer` | S | Tenemos el tempo y «más lento» (−10 BPM); un botón de 50 % es más directo. |

### 48 Jazz Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada **por progresión**: una pestaña por progresión (rhythm
changes y ii–V–I mayor). Los acordes van escritos encima de la tablatura, compás por compás, y
hay ▶ al 50 %, 75 % y 100 %. Un botón cambia la vista a la **parte rítmica** del mismo tramo:
los acordes con su diagrama y su tablatura de acompañamiento.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Acordes encima de la tablatura (qué suena debajo del lick) | nueva | `Lick` + `lesson_tab.dart` | M | Sería un campo con el acorde de cada compás. Un test exigiría que el acorde exista en `chords.json` y que las notas largas del lick sean del acorde o de la escala. Ayuda a entender por qué funciona la frase. |
| Ver la parte rítmica del lick (acordes con diagrama) | nueva | detalle de lick | M | Saldría de los acordes del punto anterior y de las digitaciones de `chords.json`. El ▶ rasguearía como en el círculo (`playCircleChords`). |
| Licks agrupados por progresión | parcial | Licks y riffs / Progresiones | M | El círculo ya tiene el ii–V–I (`twoFiveOne`). Un filtro o una sección «sobre esta progresión» uniría Licks y Progresiones. |
| ▶ al 50 / 75 / 100 % | parcial | `TabPlayer` | S | Igual que en 40 Guitar Licks. |

### 50 Easy Blues Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada **por escala** (pentatónica menor, pentatónica mayor, blues, híbrida).
Una pestaña enseña primero cada escala, corta y después completa, y dice qué licks salen de ella.
Otra trae solos y una pista de blues de 12 compases con los acordes y sus diagramas, también
transponible.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Recorrido escala → licks de esa escala → improvisar sobre una pista | parcial | Guías / Licks y riffs | M | Ya enseñamos la escala de cada frase, y las guías de estilo siguen el orden riff → lick → escala. Faltaría el paso de improvisar (familia jam). |
| Filtrar licks por escala | nueva | lista de Licks y riffs | S | Cada `Lick` ya declara su escala; sería un filtro más. |
| La escala corta (pocas cuerdas) antes de la completa | parcial | detalle de escala / rutinas | S | Tenemos las posiciones completas; no existe una versión de 2–3 cuerdas para empezar. |
| 12 compases con acordes y diagramas para tocar encima | parcial | lecciones de rítmica | M | El blues de 12 compases existe como lección; como pista para improvisar, entra en la familia jam. |

### 63 Advanced Blues Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada por técnica: rápidos, de acordes, jazz y disminuidos. Los «licks de
acordes» son double stops que se deslizan juntos, en tresillos y con swing, pensados también
como relleno en la parte rítmica.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Deslizar o ligar un double stop (las dos notas a la vez) | nueva | notación (`TabNote.chord`) | M | Hoy un acorde no se liga ni se desliza (`tabNotationProblems`). Habría que permitir el slide cuando todas sus notas se mueven igual, con su sonido y su test. |
| Frases de relleno para la parte rítmica | nueva | Licks y riffs / rítmica | M | Sería un tipo de frase «relleno», además de riff y lick; es decisión de producto. |
| Licks sobre el acorde disminuido | nueva | Licks y riffs | M | Ya tenemos la escala disminuida y su teoría. |

### 65 Country Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada **por tonalidad** (A, C, E y G mayor). No transpone, porque los licks usan
cuerdas al aire. El texto da consejos de práctica: empezar despacio y no apurar los hammer-ons.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Agrupar por tonalidad | parcial | lista de Licks y riffs | S | Cada `Lick` declara su tónica; sería un filtro por tónica, junto al filtro por escala (50 Easy Blues). |
| Consejo de práctica en el texto | ya está | `Lick.about` | — | Nuestros textos ya dicen qué cuidar al tocar. |

### 65 Gypsy Jazz Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada **por cadencia** (licks mayores, menores, V7–I mayor y V7–I menor), con los
acordes encima de la tablatura y ▶ al 50 y al 100 %, como 48 Jazz.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Licks sobre una cadencia (V7–I) con los acordes encima | nueva | `Lick` + `lesson_tab.dart` | M | Es la misma idea que «acordes encima de la tablatura» (48 Jazz). El dominante y su resolución ya existen en el círculo (`dominantOf`). |
| Nota ligada a través de la barra de compás (el número entre paréntesis) | nueva | notación (`TabNote`) | S | Hoy una nota larga dura lo que diga `length`, pero no se dibuja dividida entre dos compases; haría falta para frases que cruzan el compás. |
| El gypsy jazz como estilo | nueva | `LickStyle` | M | Es decisión de producto. |

### 85 Metal Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada **por técnica**: púa alterna, sweep picking, legato y tapping, y clásicos. Cada
lick lleva su tonalidad y su tempo, y ▶ al 50, 75 y 100 %. El sweep son arpegios en seisillos con la
dirección de la púa en cada nota; el legato, tresillos con hammer-ons y pull-offs encadenados.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Filtrar licks por técnica | parcial | lista de Licks y riffs | S | Cada lick ya muestra sus técnicas (`Lick.techniques`); faltaría el filtro. |
| Sweep picking (arpegios con la púa en cada nota) | parcial | Licks y riffs / Técnica | M | La notación ya tiene la púa y el seisillo (`tabTripletSixteenth`). Faltan frases y un ejercicio de Técnica. |
| Tapping | nueva | notación + Técnica | M | Es lo que mira la familia técnica (Learn Tapping). |
| Tempos de más de 120 BPM | parcial | `licks_test.dart` | S | Nuestro test limita el tempo de presentación a 50–120; con el 50 % bastaría para empezar despacio. |

### 96 Rock Guitar Licks (licks) — 2026-11-11

Plantilla de Jonathan Bell, organizada **por tonalidad** (A, D, E y G menor). Los licks suben hasta el traste 20 y
encadenan bend, release y pull-off. No trae texto por lick.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Frases en la parte alta del mástil (hasta el traste 20) | parcial | `licks_test.dart` | S | Nuestro test no deja pasar del traste 15. Con la transposición, una frase podría subir una octava. |
| Bend → release → pull-off encadenados | ya está | notación | — | Ya se escribe y suena. |

### Resumen de la familia licks (10 de 10)

Lo que más se repite y más valdría, en orden:
1. **Transponer** cualquier frase a otra tonalidad. Lo traen casi todas las de Jonathan Bell; las de
   cuerdas al aire (country, acústico) se agrupan por tonalidad en lugar de transponer.
2. **Acordes encima de la tablatura** y la vista de la parte rítmica. Explica por qué suena bien
   la frase y conecta Licks con Acordes y Progresiones.
3. **Acompañamiento debajo del lick**, con dos volúmenes. Se decide junto con la familia jam.
4. **Ir más lento con un toque** (50 / 75 %), **favoritos**, **anterior / siguiente** y **filtros**
   por escala, tónica y técnica. Son pequeños y baratos.
5. En la notación: **slides y ligados en double stops**, **notas ligadas entre compases** y, más
   adelante, **dos voces** (bajo y melodía) y **repeticiones**. El **tapping** se ve con la familia
   técnica.

Lo que ya hacemos mejor:
- marcar la nota que suena;
- el bucle por renglón y el tempo libre;
- «Tocar yo» con el micrófono, con su récord;
- los dedos debajo de la tablatura;
- que cada texto se verifica contra las notas.

Decidido por el usuario (2026-11-11):
- **Transponer**: sí, solo las frases movibles (las que, al moverlas, quedan enteras dentro del
  mástil sin depender de una cuerda al aire). Los textos que nombran notas se generan por regla.
- **Favoritos**: sí, con una estrella en el detalle y un filtro «Favoritos» en la lista.
- **Tipos nuevos de frase**: «solo» largo (varios renglones, por nivel) y «relleno» rítmico,
  además de riff y lick.
- **Aprobado**: acordes encima de la tablatura con la vista de la parte rítmica; ▶ al 50 / 75 %,
  anterior / siguiente y filtros por escala, tónica y técnica; el gypsy jazz como estilo; y
  subir los límites del test (tempo de presentación hasta 160 BPM y traste hasta 20).
- **Acompañamiento** debajo del lick: se decide con la familia jam.

Orden de trabajo (un PR por punto): mejoras pequeñas y límites del test → favoritos →
transponer → acordes sobre la tablatura → tipos nuevos → gypsy jazz.

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
