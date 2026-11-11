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
| Blues Guitar Jam Tracks | revisada | 2026-11-11 |
| Slow Blues Guitar Jam Tracks | revisada | 2026-11-11 |
| Rock Guitar Jam Tracks | revisada | 2026-11-11 |
| Metal Guitar Jam Tracks | revisada | 2026-11-11 |
| Country Guitar Jam Tracks | revisada | 2026-11-11 |
| Modal Guitar Jam Tracks | revisada | 2026-11-11 |

Las seis son la misma plantilla de Jonathan Bell, igual que la familia licks: cambian las
pistas y las pestañas de escalas. Se ficha completa la primera y, de las demás, solo lo que
cambia.

### Blues Guitar Jam Tracks (jam) — 2026-11-11

15 pistas de blues grabadas. Cada una tiene un nombre y dice su tempo y si va con swing o recta
(«Slow blues 57 BPM swing»). Dentro de la pista:
- **Controles**: tonalidad con − y +, tempo con − y +, ▶, parar y bucle.
- **Progresión**: los 12 compases en una cuadrícula de 3 × 4, un acorde por casilla. Al sonar se
  resalta el compás.
- **Escalas y arpegios**: pestañas con la pentatónica menor, la pentatónica mayor y la escala de
  blues de la tonalidad, y el arpegio de cada acorde (I7, IV7, V7). Se ven en el mástil del 0
  al 12 con el nombre de cada nota, y hay un botón para zurdos que espeja el mástil.
- Las flechas pasan a la pista siguiente. Nombra los acordes con bemoles (Bb7, Eb7).

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Pista de acompañamiento para improvisar (tocar encima) | nueva | módulo nuevo o Progresiones | L | Lo más valioso de la familia. Hoy Progresiones rasguea cada acorde una vez, con 1.6 s entre acordes (`ProgressionsViewModel.listen`), sin pulso ni bucle. Habría que sintetizar una pista entera: rasgueo por patrón (`strumEvents`) y, para que suene a banda, bajo y batería (no hay síntesis de ninguno de los dos). Es decisión de producto. |
| Blues de 12 compases (I7–IV7–V7) | parcial | `progression_data.dart` | S | Existe como lección de rítmica, pero no como progresión: las de Progresiones son todas de 3 o 4 grados, en mayor y sin séptimas. Faltan el blues de 12 compases y su cambio rápido al IV. |
| Tonalidad y tempo con − y + | parcial | Progresiones | S | Progresiones ya cambia de tonalidad; le falta el tempo. |
| Resaltar el compás que suena | ya está | Progresiones (`playingIndex`) | — | Ya marcamos el acorde que suena. |
| Bucle | parcial | Progresiones | S | `TabPlayer` tiene bucle; la progresión no. |
| Escalas que caben encima, en el mismo lugar | parcial | detalle de escala, Progresiones | M | El detalle de escala tiene ideas para improvisar y `scalesForChord`; faltaría, junto a la progresión, «qué escala usar encima» con un botón que la abra en esa tónica. |
| Arpegio de cada acorde de la progresión | parcial | detalle de acorde | M | Tenemos tríadas e inversiones; un arpegio del acorde en el mástil, al lado de la progresión, no. |
| Mástil para zurdos | nueva | ajustes + `FretGridGeometry` | M | Espejar el mástil y los diagramas en toda la app; es decisión de producto. |

Lo que hacemos mejor: las notas siempre con sostenidos y verificadas, la teoría «¿Por qué?» de
cada grado y el camino de digitaciones con voice leading.

Para decidir: si hacemos pistas de acompañamiento (y con qué instrumentos sintetizados), y si
hay modo zurdo.

### Slow Blues Guitar Jam Tracks (jam) — 2026-11-11

La misma plantilla con 12 pistas lentas (47 a 74 BPM). Una va en tresillos («47 BPM triplet»,
o sea 12/8). Algunas son blues menores (Dm–Gm–A7#5), pero las pestañas de arpegio siguen
diciendo D7, G7 y A7: la plantilla no se ajusta a la pista.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Blues lento en 12/8 (tresillos) | parcial | pista / `TabSwing` | M | Tenemos tresillos en la tablatura y el 6/8 en Rasgueo 2; una pista en 12/8 lo pediría en el acompañamiento. |
| Blues menor de 12 compases (i–iv–V) | nueva | `progression_data.dart` | S | Va con el blues mayor: grados con su calidad (m7, 7). Nosotros generaríamos las escalas y arpegios desde los grados, así no pasa lo de los arpegios equivocados. |

### Rock Guitar Jam Tracks (jam) — 2026-11-11

La misma plantilla con 15 pistas de rock. Cada una dice su tempo y si es mayor o menor. Las
progresiones tienen otros largos (una de 10 compases) y solo traen las dos pentatónicas. Aquí
nombra los acordes con sostenidos (C#, G#).

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Marcar mayor o menor en cada pista | parcial | Progresiones | S | Nuestras progresiones son todas en mayor; agregar las de modo menor (i–♭VII–♭VI…) daría la etiqueta. |

### Metal Guitar Jam Tracks (jam) — 2026-11-11

La misma plantilla con 10 pistas de 85 a 190 BPM, sin pestaña de progresión: son riffs, no
acordes. Trae las escalas que caben encima: pentatónica menor, blues, eólico, frigio, frigio
dominante y el arpegio disminuido.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Pista de riff (sin acordes) con sus escalas | parcial | Licks y riffs | M | Nuestros riffs ya suenan y dicen su escala; un acompañamiento de riff en bucle para tocar encima sería parte de la decisión de pistas. |
| Escalas de metal juntas (frigio dominante, disminuida) | ya está | `scales_master.json` | — | Están todas; falta solo agruparlas por estilo, como la guía de metal. |

### Country Guitar Jam Tracks (jam) — 2026-11-11

La misma plantilla con 15 pistas (80 a 200 BPM; vals y shuffle incluidos). Además de las
pentatónicas y la escala mayor, trae pestañas de **terceras y sextas mayores**: los double stops
de la escala dibujados en el mástil, en las cuerdas 1 y 2.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Double stops de la tonalidad junto a la pista | ya está | Double stops (`double_stops.dart`) | — | Tenemos terceras y sextas diatónicas verificadas; faltaría solo enlazarlas desde la progresión. |
| Vals en 3/4 como pista | parcial | Rasgueo 2 | S | El 3/4 ya está en Rasgueo 2; entraría en las pistas. |

### Modal Guitar Jam Tracks (jam) — 2026-11-11

La misma plantilla con dos pistas por modo, de jónico a locrio. Cada una es un vamp que hace oír
el modo (lidio = I–II mayor, F–G, con la #4 en el acorde de G) y trae el modo y una «pentatónica
del modo».

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Vamp que hace sonar cada modo | parcial | círculo («modos por brillo»), detalle de escala | M | Ya explicamos qué nota cambia cada modo (`modesByBrightness`). Un vamp de dos acordes por modo, generado por regla desde su nota característica, lo haría oír. Un test verificaría que el vamp contiene la nota característica. |
| Pentatónica de cada modo | nueva | `scales_master.json` | M | Es la pentatónica que conserva la nota característica. Habría que definirla por regla con su generador y su auditoría. Es decisión musical (no es una escala estándar). |

## Resumen de la familia jam

Lo que más se repite, ordenado por valor:
1. **Pistas para tocar encima** (las seis apps): bucle, tempo, tonalidad y el compás que suena.
   Es lo que más falta; hoy solo rasgueamos cada acorde una vez. Pediría sintetizar bajo y
   batería además de la guitarra.
2. **Progresiones nuevas**: blues de 12 compases (mayor, menor, cambio rápido, 12/8), progresiones
   en menor y vamps modales. Son pocas líneas en `progression_data.dart` y se verifican con
   tests.
3. **«Qué tocar encima», junto a la progresión**: las escalas que caben y el arpegio de cada
   acorde, abriendo lo que ya tenemos (detalle de escala, double stops), en la tónica de la
   progresión.
4. **Tempo y bucle en Progresiones**: pequeño, y sirve aunque no haya pistas.
5. **Modo zurdo** (todas lo traen): espejar el mástil en toda la app.

Lo que hacemos mejor: notas siempre con sostenidos, escalas y arpegios generados desde los
grados (en estas apps el arpegio no cambia con la pista), la teoría de cada grado, el camino de
digitaciones y el micrófono.

Para decidir:
- ¿Pistas de acompañamiento? Si sí: ¿solo guitarra rasgueada, o también bajo y batería
  sintetizados? Esto también decide el «acompañamiento debajo del lick» que quedó pendiente de
  la familia licks.
- ¿Agregamos los blues de 12 compases, las progresiones en menor y los vamps modales?
- ¿Modo zurdo?
- ¿«Pentatónica del modo» como escala nueva?

Decidido por el usuario (2026-11-11):
- **Pistas de acompañamiento**: sí, primero solo guitarra rasgueada con su patrón, bucle, tempo y
  el compás resaltado, con el motor que ya tenemos. Bajo y batería, después si se quiere. Vale
  también para el acompañamiento debajo del lick.
- **Progresiones nuevas**: blues de 12 compases (mayor con cambio rápido, menor y en 12/8),
  progresiones en menor y vamps modales, todas por grados y con tests.
- **Tempo y bucle** en Progresiones.
- **Aprobado**: «qué tocar encima» junto a la progresión (escalas que caben y arpegio de cada
  acorde), modo zurdo y la pentatónica de cada modo (por regla, con su generador y su auditoría).

Orden de trabajo (un PR por punto): tempo y bucle → progresiones nuevas → pista de guitarra (y
debajo del lick) → qué tocar encima → pentatónica del modo → modo zurdo.

## 3. Familia caged: sistema CAGED

Qué mirar: cómo enseña las cinco formas y cómo pasa de una a otra, cómo une acorde, arpegio y
escala, y si tiene ejercicios o quiz. Compara con los sistemas de escala
(`lib/domain/fingering_systems/`), las `cagedPositions` de `chords.json` y la guía "CAGED: acorde
y escala".

| App | Estado | Fecha |
|---|---|---|
| CAGED Companion | revisada | 2026-11-11 |
| CAGEDapp | revisada | 2026-11-11 |

### CAGED Companion (caged) — 2026-11-11

Es una caja de herramientas del sistema CAGED, con muchas pestañas: escalas, arpegios,
«verticales», acordes, tríadas, navegar, práctica, octavas, teoría y notas. Arriba hay siempre un
metrónomo, un temporizador de práctica y un ajuste de mano. Todo gira alrededor del
**ancla**: la raíz en la 6ª o la 5ª cuerda, desde la que se arma cada forma. Algunas funciones
llevan el sello PRO.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Escala por forma (C A G E D), con filtro de forma y mástil completo | ya está | detalle de escala (sistema CAGED, vista ampliada) | — | Nuestro mástil completo resalta la forma en cada octava (`patternAcrossNeck`). |
| Arpegio de una forma sobre su escala, con «ocultar escala» | nueva | detalle de escala / acorde | M | Las notas del acorde de la forma, resaltadas dentro de la forma de escala. «CAGED: acorde y escala» ya une forma de acorde y de escala en C; esto lo haría en cualquier tónica y en la pantalla. |
| «Autopistas» (verticales): la escala o el arpegio a lo largo del mástil desde un ancla | nueva | detalle de escala | M | Recorrer las cinco formas seguidas, por la misma cuerda raíz. |
| Navegar paso a paso: encontrar el ancla y armar la forma desde ella (5 pasos) | parcial | guía «CAGED: acorde y escala», Notas del mástil | M | Tenemos las formas de octava y el quiz del mástil; falta un recorrido guiado «ancla → forma». |
| Rutina de práctica: tonalidad y forma al azar, por fases (escala, arpegio…) | nueva | Practicar | M | Parecida a Práctica de hoy, pero sorteando tónica y forma CAGED. |
| Tríadas por forma CAGED, en una tabla con sus juegos de cuerdas e inversiones | parcial | `triadInversions` de chords.json | M | Las tenemos por grupo de cuerdas; faltaría agruparlas por la forma CAGED en la que caen. |
| Cambios de acorde cerca de un ancla (I–vi–IV–V con formas E y A en la misma zona) | parcial | Progresiones | S | El camino óptimo ya minimiza el movimiento; faltaría poder fijar la zona del mástil. |
| Entrenador de octavas | ya está | Notas del mástil, tarjeta «Octavas de la tónica» | — | |
| Ajuste de mano (zurdo) | ya está | modo zurdo (#142) | — | |
| Metrónomo y temporizador siempre arriba | parcial | Afinar → Metrónomo, Salud | S | Lo tenemos, en otras pantallas. |

Lo que hacemos mejor: cada forma y cada nota salen de un generador auditado, solo sostenidos, la
teoría verificada y el audio de cada diagrama.

Sin ver: lo marcado como PRO.

### CAGEDapp (caged) — 2026-11-11

«CAGED Unchained», en italiano, inglés y español. Enseña cinco **cajas** que valen a la vez para
la mayor y para su relativa menor («C Major / A minor»).
- Cada caja resalta su tríada.
- Una pantalla une cada caja con su forma de acorde. Tiene «partes comunes», que colorea lo que
  comparten dos cajas vecinas, y «unir», que las junta en un solo mástil encimando esas partes.
- Otra muestra cada caja como escala completa, pentatónica o con la blue note, y marca que todo se
  repite a los 12 trastes.
- «Tonalidad» elige tónica (con bemol y sostenido: «Bb A#») y modo mayor o menor.

| Idea | Estado | Dónde encaja | Esfuerzo | Notas |
|---|---|---|---|---|
| Partes comunes entre formas vecinas y «unir / expandir» | nueva | vista ampliada del mástil | M | Colorear las notas que comparten dos formas seguidas y verlas encimadas. Explica por qué las cinco formas cubren el mástil. Se calcula de las posiciones de `scales_master.json`. |
| Una caja, dos escalas: la mayor y su relativa menor | parcial | lección de la relativa menor, detalle de escala | S | La lección lo enseña; en el detalle de escala no se dice que la forma es la misma. |
| Tríada dentro de la caja | parcial | ver «arpegio de una forma» en la ficha anterior | — | Es la misma idea. |
| Escala completa, pentatónica y blue note sobre la misma caja | parcial | detalle de escala | S | Cambiar de escala sin perder la forma; hoy cambiar de escala limpia la digitación. |
| Se repite a los 12 trastes | ya está | mástil completo (todas las octavas) | — | |

Lo que hacemos mejor: solo sostenidos (ellos escriben «Bb A#»), digitaciones auditadas y más
escalas y sistemas.

## Resumen de la familia caged

Lo que se repite, ordenado por valor:
1. **El arpegio o la tríada dentro de su forma de escala**, en cualquier tónica (las dos apps): ver
   qué notas de la forma son del acorde. Une Acordes y Escalas.
2. **Partes comunes y «unir»** (CAGEDapp): por qué las cinco formas encajan y cubren el mástil.
3. **Recorrido guiado desde el ancla** (CAGED Companion): encontrar la raíz y armar la forma.
4. **Práctica sorteada** (tónica y forma al azar), y las tríadas agrupadas por forma CAGED.
5. Cosas pequeñas: decir en el detalle que la forma vale para la relativa menor, y cambiar de
   escala sin perder la forma.

Para decidir:
- ¿Arpegio y tríada dentro de la forma, en el detalle de escala (o en el de acorde)?
- ¿Partes comunes y «unir» en la vista ampliada?
- ¿Recorrido guiado del ancla y práctica sorteada de tónica y forma?
- ¿Tríadas agrupadas por forma CAGED en el detalle de acorde?

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
