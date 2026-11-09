# ChordMaster-Free — guía del proyecto

App Flutter/Dart (Riverpod, go_router) para aprender guitarra: acordes, escalas, progresiones
y double stops. UI bilingüe (español e inglés; arranca en el idioma del teléfono si es inglés,
si no en español). Commits en español.

## Principio rector
**Una sola fuente de verdad por tema, y todo dato musical pasa por una auditoría automática.**
Nunca se escribe a mano una digitación o una posición: se generan por reglas y se auditan.

## Fuentes de verdad y cómo regenerarlas
| Qué | Archivo | Generador | Auditoría |
|---|---|---|---|
| Acordes (24 tipos × 12 raíces) | `assets/data/chords.json` | `tool/regenerate_chord_data.py` | `tool/audit_chord_music.py` + `test/features/chords/chord_music_validity_test.dart` |
| Escalas y modos | `assets/data/scales_master.json` | `tool/regenerate_scales_master.py` | `tool/audit_scales_master.py` + `test/data/scales_master_validity_test.dart` |
| Teoría de sistemas (texto) | `lib/domain/fingering_systems/` | — | tests de chips |
| Progresiones (grados, tipos) | `lib/domain/progressions/progression_data.dart` | — | `test/domain/progression_builder_test.dart` |

Reglas: los generadores son idempotentes (correrlos dos veces no cambia el archivo). Tras
tocar un JSON: correr su auditoría (debe dar 0 defectos) y el generador otra vez.
La auditoría de acordes valida que cada nota tocada pertenezca al acorde; la de escalas, que
cada nota pertenezca a la escala. No bajar la tolerancia de 0.

## Convenciones que ya causaron bugs (leer dos veces)
- `chords.json` guarda `fretPositions` de **6ª a 1ª cuerda**; `-1` = muteada.
- Los motores de `lib/domain/` (ergonomía, voice leading, double stops) usan **índice 0 =
  1ª cuerda (mi aguda)**, MIDI al aire `[64,59,55,50,45,40]`. El ÚNICO punto de conversión es
  `VoicingAdapter.fromChordJson`. La UI no invierte cuerdas.
- En `scales_master.json` las cuerdas se numeran 1 = mi aguda … 6 = mi grave, y `fret_offset`
  está dado para raíz C; la app suma el semitono de la raíz y, si pasa del traste 24 o baja de 0,
  desplaza ±12 (todo o nada, nunca recorta una posición).
- Notas siempre con sostenidos (`C C# D D# E F F# G G# A A# B`). La ÚNICA tabla es
  `lib/domain/theory/notes.dart` (`noteNames`, `noteIndex`, `pitchClassName`,
  `standardOpenStringMidi`): no copiar la lista ni la afinación en otro archivo.
- Nombre de intervalos en escalas: `spellInterval` (`lib/domain/theory/intervals.dart`). En
  escalas de 7 notas cada grado tiene su número (b6 en la menor, #4 en la lidia), nunca `#5`
  por defecto.
- Dibujo de diapasón con líneas/notas: UNA función de coordenadas (`noteOffset`) y un solo
  `CustomPainter`; nada de medir widgets por separado. Escalas y double stops comparten
  `FretGridGeometry` (`lib/ui/widgets/fret_grid_geometry.dart`).
- La cuerda al aire NO es un traste: es una columna de afinación (`e B G D A E`, siempre visible)
  a la izquierda de la cejuela, y sus notas llevan anillo. El traste N es la celda entre los
  alambres N-1 y N. La cejuela solo se dibuja junto al traste 1; desde otro traste, alambre normal
  y el número del traste debajo.
- Las posiciones de `scales_master.json` solo suben desde su `fret_offset` en C: fuera de C casi
  nunca traen notas al aire (E menor pentatónica empieza en el traste 4, no en el 0). Las cuerdas
  al aire de otra tónica se ven en el mástil completo.
- Colores: SOLO desde `context.palette` (`lib/ui/palette.dart`, paleta Palisandro con versión
  clara y oscura) o `Theme.of(context).colorScheme`. Nada de `Colors.red`/hex sueltos ni
  colores por módulo. El color codifica intervalos (`palette.intervalColor('b3')`) y siempre
  va con etiqueta o forma (raíz = cuadrado). `test/ui/palette_test.dart` exige contraste.
- Textos: NUNCA un literal visible en una pantalla. Todo pasa por `tr(es:, en:)`
  (`lib/core/i18n/tr.dart`), normalmente vía un getter de `AppStrings`; las dos versiones son
  obligatorias. Datos con texto: `LocalizedText`. Como son getters, no van en `const` ni en
  listas globales `final` (se quedarían en el idioma viejo): usar getters. Los textos en inglés
  de `chords.json` se traducen en `lib/core/constants/chord_texts.dart` y
  `test/core/chord_texts_test.dart` exige cobertura completa; nombres de escala en
  `scale_names.dart`; intervalos en `interval_texts.dart`.
- Tipografía: Bricolage Grotesque (títulos), Atkinson Hyperlegible (texto, con Plex Mono de
  respaldo para "→"), IBM Plex Mono
  (`musicMono()`, notas/intervalos; solo trae pesos 400 y 600: otro peso falla al cargar).
  Empaquetadas en `assets/google_fonts/` (OFL); los tests
  que tocan `lightTheme`/`darkTheme` deben llamar `TestWidgetsFlutterBinding.ensureInitialized()`.

## Decisiones musicales vigentes
- Formas CAGED menores: la forma G usa la digitación de E (sustitución práctica); la UI lo
  indica ("G (usa la digitación E)").
- Escalas: CAGED = notas de la escala dentro de la ventana de cada forma (≤ 5 trastes);
  3NPS = escalera de 3 notas por cuerda (solo 7 notas); 4NPS = 3NPS + 1 nota por cuerda;
  2NPS = cajas pentatónicas (blues añade la b5 entre 4ª y 5ª). Los modos tienen sus propios
  `intervals` (rotaciones de la mayor).
- Disminuidas: el id sale de los intervalos (`diminished_hw` = empieza por semitono,
  semitono-tono; `diminished_wh` = por tono). Lo fija `regenerate_scales_master.py`.
- Formas de principiante ('Beginner Grip' en `voicings`): F xx3211, B xx4442, Bm xx4432,
  F#m xx4222, generadas por `regenerate_chord_data.py`. El modo Principiante las elige; el
  Estándar sigue usando la cejilla completa.
- Power chords (power5): R-5-R sin repetir la 5ª, con raíz en la 6ª, 5ª, 4ª y 3ª cuerda (en la
  4ª y 3ª la octava sube un traste por la afinación de la 2ª), en `voicings`. Principal: la
  abierta (E5, A5, D5) o la más baja con raíz en 6ª/5ª. Detrás, las inversiones 5-R-5 (5ª en el
  bajo, en la 6ª/5ª/4ª/3ª): en la inversión SÍ se repite la 5ª (decisión del usuario: solo la
  forma natural R-5-R no la repite). Los genera `regenerate_chord_data.py`.
- Tríadas (mayor, menor, dim, aum) en `triadInversions`: fundamental, 1ª y 2ª inversión en los
  grupos 3-2-1, 4-3-2, 5-4-3 y 6-5-4, cerradas, móviles (sin cuerdas al aire) y en la posición
  más baja. Drop 3 (maj7, 7, m7, m7b5, dim7) en `voicings`: R-7-3-5 con raíz en la 6ª y en la 5ª,
  un dedo por nota. Ambos por regla en `regenerate_chord_data.py`. Las tríadas NO entran en
  Progresiones (solo acordes completos: principal, CAGED y voicings).
- Acordes slash (bajo elegido, "Bajo (acorde slash)" en el detalle): se generan en tiempo de
  ejecución por regla (`lib/domain/voicing/slash_chords.dart`), no van en chords.json: se pone
  el bajo en la 6ª/5ª/4ª sobre las digitaciones del acorde, que deben conservar raíz y 3ª (o la
  2ª/4ª de los sus); el bajo es la nota más grave. Orden: abiertas, más cuerdas, más cómodas.
- Berklee NO está implementado: no hay definición con trastes verificada. No inventarla.
- Progresiones: candidatos = digitaciones de `chords.json` (principal, CAGED, voicings) sin costo ergonómico infinito;
  **formas abiertas primero** (decisión del usuario): si el acorde tiene alguna forma abierta
  (`isOpenPosition`: una cuerda al aire y nada más allá del traste 4), solo entran esas; si no
  (F, B, Bm, F#m...), entran todas, cejillas incluidas. Vale en ambos modos. Después,
  camino óptimo por programación dinámica (costo ergonómico + salto de soprano + cambio de
  traste − notas retenidas). En modo Estándar el costo no penaliza cejillas; el modo
  Principiante (`ErgonomicOptions.beginner`) suma +2.0 por cejilla mini (2–3 cuerdas) y
  +8.0 por grande (≥4). No es filtro duro: un grado solo con cejillas sigue dando camino.
- Progresiones, glosario: la progresión siempre se arma con el camino óptimo; tocar un acorde
  abre todas sus posiciones (principal, CAGED, voicings, tríadas, inversiones) y la elegida
  reemplaza SOLO ese acorde (`chosen` en el estado; las transiciones se recalculan). Se
  descarta al cambiar tonalidad, progresión o modo.
- Comparador de digitaciones: `analyzeFingering` incluye SIEMPRE la cejilla en el costo,
  así que puede no coincidir con Progresiones en modo Estándar; la pantalla lo advierte.
- Calidad de double stops por grado (3ª, 6ª, 7ª...) en `lib/domain/theory/double_stops.dart`,
  verificada contra resultados de referencia del sandbox TypeScript
  (`test/fixtures/golden/`).

## Audio
- No hay archivos de audio: todo se sintetiza en `lib/domain/audio/pluck_synth.dart` (cuerda
  pulsada Karplus-Strong afinada con pasa-todo, error < 1 cent; clic de metrónomo). Test de
  afinación por autocorrelación.
- `AudioService` escribe cada sonido una vez como WAV en la carpeta temporal y lo reproduce
  con `just_audio` como archivo (nada de `StreamAudioSource`: usa un proxy HTTP local que en
  Android exige tráfico sin cifrar). Se inyecta por `audioServiceProvider`; los tests usan
  `AudioService.forTesting()` para un doble que registra lo que se pidió sonar.
- Usos: rasgueo del acorde (detalle), escuchar la progresión, intervalos (oído), metrónomo y
  pulso del juego de ritmo.
- Metrónomo: NO un Timer por clic (seek+play variaba y se oía desigual). `renderMetronomeLoop`
  sintetiza compases enteros (acento, tiempos y subdivisiones a ±1 muestra, ≥ 8 s) y
  `startMetronome` los repite con `LoopMode.one`. La pantalla cuenta solo tiempos contra un
  reloj; un cambio sonando (deslizador) se aplica 200 ms después del último.
- Afinador: `PitchService` lee el micrófono con `record` (PCM 16 bits, 44.1 kHz mono, sin
  procesado de voz: fuente `voiceRecognition` en Android), baja a 22.05 kHz y detecta con YIN (`lib/domain/audio/pitch_detection.dart`,
  test con cuerdas sintetizadas: < 2 cents, sin errores de octava, silencio/ruido = sin
  lectura). Mediana de 5 lecturas; el La de referencia (440/442…) llega al cálculo. Antes era
  una simulación: no volver a eso. La pantalla se actualiza a lo sumo cada 80 ms (throttle,
  NUNCA debounce: con una nota sonando las lecturas no paran y la aguja no se movía).
  Arranques y paradas del micrófono van en fila.
- Tocar con el micrófono ("Tocar yo" en `TabPlayer`, solo donde se pasa `onPlayed`: Primeros
  pasos, Melodías y Técnica): `PitchService.windowStream` da las ventanas y
  `PlayAlongSession` (`lib/domain/practice/play_along.dart`) espera cada nota sin apuro. Ataque
  = salto del nivel de agudos (`attackLevelOf`); la nota esperada se busca con
  `periodicityAt` aunque otra cuerda siga sonando, y se rechaza si YIN oye una vecina (±2
  semitonos). Una nota sin ataque no cuenta como error. Tempo = distancia media primera→última
  (no depende del retraso del micrófono); récord = sin errores ni pausas (> 2.5× la típica),
  redondeado al paso de 5 con 2 % de margen. Una nota a la vez, nada de acordes. Límite
  conocido (test): cuerdas al aire graves acumuladas sonando al mismo nivel (3 de 39 pasos con
  las cuerdas sonando). Un solo micrófono para la app (`playAlongProvider`): se suelta al sonar
  un reproductor, al salir o al ocultar la pestaña.
- Tramo y bucle (inspirado en el "Loop"/"Slow Down" de Gibson): `TabPlayer` deja elegir un
  renglón (`tabNotesPerLine` = 8, en `tab_playback.dart`) y repetirlo en bucle, al escuchar y
  con el micrófono (vuelve a escuchar 1.5 s después y cuenta las pasadas limpias seguidas). Un
  renglón suelto nunca da récord: solo la tablatura entera llama a `onPlayed`. Tras una pasada
  entera con errores o pausa, `PlayAlongResult.lineToPractice` (el renglón de más errores; si
  empatan, el primero; sin errores, el de la pausa) propone "Repite el renglón N a X BPM":
  lo deja en bucle, baja `slowerBpm` (−10, mínimo 40) con `onBpmChanged` y empieza a sonar
  cuando llega el tempo nuevo.
- Resumen de la sesión (inspirado en el "AI Feedback" de Gibson, pero por reglas, sin IA): cada
  pasada entera con el micrófono (cursos de melodía y Técnica) se anota en `SessionLog`
  (`lib/services/session_log.dart`, `session_runs` = `{day, runs}`, solo hoy; anotar espera a
  la lectura del disco). `summarizeSession` (`lib/domain/practice/session_summary.dart`): por
  cosa tocada manda la última pasada; limpia → "Salió limpio" con el mejor tempo y el récord
  nuevo; si no → "Para repetir" con renglón, errores y 10 BPM menos. Pantalla `/session`
  (pestaña Inicio), enlazada desde Práctica de hoy; cada fila abre su paso o Técnica.

## Módulos de práctica (decisiones)
- Salud: el aviso de pausa sale SOLO durante la sesión de práctica, al cumplirse cada intervalo
  (notificación inmediata + tarjeta en pantalla). Nada de notificaciones programadas: Android
  solo repite cada minuto/hora/día/semana y avisaba toda la noche.
- Ritmo: precisión = toques a ±75 ms / máx(toques, pulsos); récord y logro desde 16 toques.
- Canciones: solo acordes (sin letras); notas con sostenidos; cada acorde enlaza a su ficha
  (slash → acorde de arriba). Test: todos existen en chords.json salvo A7sus4.
- Retos de la semana (`lib/domain/practice/multi_day_challenges.dart`, ruta `/practice/challenges`):
  se superan practicando en días distintos, sin marcar nada. `ActivityLog`
  (`lib/services/activity_log.dart`, `activity_days`, últimos 30 días) anota el día al terminar
  una lección, escuchar una rutina, guardar un tempo limpio en Técnica, responder en Oído o en
  Notas del mástil, o terminar una ronda de Ritmo con puntaje. "Semana constante" pide 7 días seguidos de cualquier
  práctica; los demás, N días de los últimos 7. Hay test de que todos se pueden superar.
- Práctica de hoy (Inicio, `lib/domain/practice/daily_plan.dart`): la siguiente lección del
  camino, una rutina (escala que rota por día entre `dailyWorkoutScales`) y un ejercicio de
  Técnica (rota por día). Cada paso se marca solo cuando `ActivityLog` anota su actividad hoy.
  Sin azar: `dayNumber` cuenta días de calendario, así que la hora no cambia el plan.
- Notas del mástil (`/practice/fretboard`, en Practicar; inspirado en el "Note Finder" de Gibson,
  por reglas): `lib/domain/theory/fretboard_quiz.dart` arma dos preguntas que se turnan, "¿qué nota
  es?" (opciones a 1 o 2 semitonos) y "¿en qué traste está su octava?" con las formas de
  `octaveShapes` (opciones: el traste de partida, el error típico, y los vecinos; la forma 6 → 1 de
  dos octavas cae en el mismo traste). Trastes 0 a 12. El generador se inyecta
  (`fretQuizRandomProvider`) para los tests; la mejor racha va en `fretboard_quiz_best_streak` y cada
  respuesta anota `PracticeActivity.fretboard`. La guía "El mástil" (Teoría) lo enlaza.
- Logros: todos deben poder conseguirse (test en `achievement_service_test.dart`). Comunidad
  se eliminó (no tenía ruta y solo guardaba en el teléfono).

## Lecciones
- Currículo en `lib/domain/lessons/curriculum.dart` (fuente única): Fundamentos (dos cursos:
  Primeros pasos y Melodías, sin lecciones sueltas) y, al terminarlo, dos caminos: rítmica
  (R1–R14, empieza por los cursos de Acordes abiertos 1, Rasgueo 1 y Acordes abiertos 2; su rasgueo de corcheas, pop y G–D–Em–C vive en el curso, no en lecciones) y líder (L1–L18), cada uno en
  dos niveles
  (`LessonUnit.level`; Fundamentos solo tiene el 1). Las lecciones se agrupan en unidades
  (`LessonUnit`, nodos del mapa, con un `summary` que la pantalla de la unidad muestra como
  vista previa). Acordes por `displayName` de `chords.json` y escalas por id de
  `scales_master.json`.
- Nivel 2 (decisión del usuario, inspirado en roadmaps tipo "Part 1/2"): rítmica = Acordes
  abiertos 2 (D/Dm, séptimas, maj7/m7), Rasgueo 2 (3/4, 6/8 y acento en 2 y 4) y Riffs (power
  chords y boogie); líder = Licks, Mayor y menor (escala mayor, relativa menor, círculo) y
  Double stops (terceras y sextas). Nada de riffs ni melodías con derechos de autor.
- Fundamentos (decisión del usuario, inspirado en "Basic Skills" y "Melodies"): conocer el
  instrumento y moverse con ganas de seguir, no acordes. Am, A y E van en el curso Acordes
  abiertos – Parte 2 (las lecciones f3–f5 y su unidad "Más acordes abiertos" se borraron al
  crearlo, decisión del usuario).
- Tablatura en `Lesson.tab` (`TabNote`: cuerda 1 = mi aguda, traste; ritmo y técnicas en
  "Notación de la tablatura"). Toda lección con tab
  declara `scale` y un test exige que cada nota pertenezca a ella; las notas que el texto nombra
  se verifican una por una. Se dibuja en `lesson_tab.dart`, en renglones de 8 notas.
- `Lesson.tool` abre afinador, metrónomo o un módulo de Aprender, siempre con `push`: atrás vuelve
  a la lección. Regla (decisión del usuario): afinador y metrónomo abiertos desde otra pantalla
  se apilan sobre ella (`/tuner` y `/metronome` en Inicio, `/learn/tuner` y `/learn/metronome`
  en Aprender, `_toolRoutes`) y atrás vuelve ahí; solo en la pestaña Afinar son raíz. El selector
  Afinador | Metrónomo, apilado, reemplaza la pantalla (`pushReplacement`) para no perder el regreso.
- Todo lo que una lección afirma sobre cuerdas, dedos o notas tiene su test en
  `test/domain/lessons/curriculum_test.dart`, verificado contra los datos. Lección nueva o
  texto nuevo con una afirmación musical = test nuevo.
- `LessonPath` decide lo siguiente (`PathNext`: una lección o un curso): Fundamentos primero,
  luego el camino elegido (nivel 1 y luego 2), después el otro, unidad por unidad; un curso
  cuenta como terminado con todos sus pasos hechos, y el avance de cada camino suma lecciones y
  pasos. Lo arma `learningPathProvider` con los pasos de cada curso; el logro
  `foundations_done` lo desbloquea un `ref.listen` en la raíz de la app. Los proveedores del
  camino y de los cursos se actualizan por `ref.listen` (Notifiers), no con cadenas de
  `Provider` derivados: una cadena así se recalcula durante el build al volver a una pestaña
  oculta (TickerMode) y Riverpod falla. Se puede adelantar cualquier lección. Progreso en `userProgress`
  (`lessons_completed`, `lessons_track`); los ids de lecciones y unidades son permanentes. Las
  etiquetas (F5, R11…) salen de la posición, así que insertar una lección las corre.
- Mapa (`lessons_screen.dart`): identidad propia, dibujado como mástil. Fundamentos es una
  cuerda que se abre en dos; cada unidad es un nodo con un dibujo generado desde los datos
  (`UnitArt`: diagrama, escala, rasgueo o notas). Nada de fotos ni imágenes de terceros.
  Los dos caminos van en columnas independientes, sin huecos (decisión del usuario: la rítmica
  puede ser más larga que la líder); ambos tienen los mismos niveles y un reto por nivel (hay
  test) y cada columna marca su nivel 2 (`lessons-level-2-<camino>`). Ningún
  camino se resalta hasta terminar Fundamentos o tocar uno (`highlightedTrack`). Al abrir, las
  cuerdas se dibujan escalonadas; con "reducir movimiento" aparecen completas.
- Retos (`challenges`): uno al cerrar cada nivel de rítmica y de líder, con el doble punto del
  traste 12; el del nivel 2 pide más (ritmo 85 → 95 %, Oído 5 → 10). Se superan solos con el
  récord de un módulo de práctica (precisión del juego de ritmo, mejor racha de Oído en
  `ear_training_best_streak`); no se marcan a mano.
- Pantalla de unidad (`lesson_unit_screen.dart`, datos de `unit_summary.dart`): encabezado con
  "camino · Unidad n de m", lecciones en una línea vertical con lo que practica cada una (acordes,
  escala, rasgueo, tablatura, herramienta), el reto si la unidad cierra su nivel, resultados
  (lecciones, minutos, acordes, notas) y la siguiente unidad (reemplaza la pantalla). Inspirada en
  cursos tipo "Level 1 · Learn to Fret", pero en vertical (decisión del usuario).
- Rutas: `/learn/lessons`, `/learn/lessons/unit/:unitId` y `/learn/lessons/:id`. Logro
  `foundations_done`.
- Cursos en el mapa (decisión del usuario: los cursos amplían el mapa, no son módulos sueltos
  en Aprender): una unidad con `course` (`LessonCourse`) no tiene lecciones; su nodo muestra los
  pasos hechos y su página (`/learn/lessons/unit/:id` o `/learn/lessons/course/<slug>`) es el
  curso con el encabezado de la unidad, el reto si cierra el nivel y la unidad que sigue. Los
  pasos van en `/learn/lessons/course/<slug>/<paso>` (atrás vuelve al curso). El orden del mapa
  es `lessonUnits` (curriculum.dart); `course_registry.dart` da de cada curso su progreso,
  niveles y rutas. Rítmica nivel 1 empieza por Acordes abiertos – Parte 1 y luego Patrones de
  rasgueo – Parte 1; Melodías va en Fundamentos. Las rutas viejas `/learn/melodies`,
  `/learn/open-chords` y `/learn/strumming` redirigen.

## Cursos de melodía: Primeros pasos y Melodías (Fundamentos)
- Primeros pasos (`lib/domain/melodies/basics_course.dart`, unidad `f_basics`): conocer la
  guitarra, afinar, sostenerla y la púa; un traste (índice), dos (1 y 3), un dedo por traste;
  la 2ª cuerda (con un consejo sobre el dolor en los dedos); el dedo medio y la 3ª cuerda;
  final. Cada nivel solo usa las cuerdas ya presentadas (hay test).
- Melodías (`melody_course.dart`, unidad `f_melodies`): una cuerda a la vez, combinar cuerdas,
  subir y bajar, el mástil (posición V), patrones (grupos de 3 y 4, los de las rutinas),
  velocidad, de memoria y final. Inspirados en cursos tipo "Basic Skills" y "Melodies", en
  vertical (decisión del usuario).
- Los dos usan `MelodyStep`: las melodías se escriben como alturas ("C4") y `tabForPitches`
  las pone dentro de la ventana de trastes y, si se dan, de las cuerdas del paso (si caben en
  dos, el traste más bajo). Un test exige que cada nota suene lo pedido, caiga en su ventana y
  sus cuerdas y pertenezca a la escala del nivel; lo que afirma cada texto tiene su test. Solo
  canciones de dominio público (tradicionales, Beethoven, Pierpont), con su origen.
- Estrellas por tempo limpio, autoinformado como en Técnica: ★ 60, ★★ 80, ★★★ 100 BPM
  (`basics_*` y `melodies_*`); la teoría se marca leída. Hacer un paso de curso cuenta como
  lección del día (Práctica de hoy y retos de la semana). El reproductor toca
  corcheas iguales: la pantalla lo aclara (el ritmo de la canción lo pone quien toca).
- La línea vertical de pasos es `StepRail` (`lesson_widgets.dart`), la misma de la unidad.

## Cursos por niveles (base común)
- `lib/domain/courses/course.dart`: `CourseStep` (teoría, ejercicio, canción), `CourseLevel`,
  estrellas por tempo (`courseStarTempos`, `starsFor`, `startTempoFor`) y `CourseProgress`.
  Pantallas comunes en `lib/features/courses/` (`CourseOverview`, `CourseStepView`,
  `CourseStars`) y progreso por curso en `courseProgressProvider(CourseId.x)`, con sus claves
  en `userProgress` (`melodies_*`, `open_chords_*`). Curso nuevo = un `CourseId` más, sin
  copiar pantallas.

## Cursos de acordes abiertos (Partes 1 y 2)
- Una parte = `OpenChordsPart` (`open_chords_course.dart`): acordes nuevos, los que ya se saben,
  cambios con canciones y final (vueltas y canciones); `buildOpenChordsPart` arma los niveles.
  `idPrefix` va delante de cada id: `oc` en la Parte 1 (sus ids no cambian) y `oc2` en la 2.
- Parte 2 (unidad `r_open_chords_part_2`, detrás de Rasgueo – Parte 1; inspirada en "Open Chords
  – Part 2"): Am, E y A, con los cambios Am–C, Am–Em, Am–G, E–Am, E–D, A–D, A–E; canciones
  Greensleeves, He's Got the Whole World y Down in the Valley; final con A–D–E–A y Am–G–C–E.
  Curso `LessonCourse.openChords2` (`/learn/lessons/course/open-chords-2/…`, progreso
  `open_chords_2_*`). Test: `open_chords_part2_test.dart`.
- `lib/domain/open_chords/`, unidad `r_open_chords_1` del mapa (primera de rítmica). Em, G, D y C
  (`openChordsCourseChords`); detrás de cada acorde nuevo, sus cambios con los anteriores
  (Em–G, D–G, D–Em, C–Em, C–G, C–D) y un final. Inspirado en cursos tipo "Open Chords – Part 1",
  en vertical (decisión del usuario).
- Las digitaciones salen de `chords.json` (`ChordShape`, armado en `openChordsCourseProvider`);
  el curso solo dice el orden. Dedo a dedo = `ChordShape.partial`: las cuerdas de los dedos que
  faltan no se tocan (X), así todo lo que suena es del acorde (hay test). Textos de "cómo se
  toca", consejos y cambios generados de la forma (`ChordChange`: dedo que se queda, que se
  desliza, que pasa a la cuerda vecina o lugar repetido con otro dedo).
- Canciones: solo acordes, un acorde por compás, de dominio público (tradicionales, Foster,
  Newton), con su origen; un test exige que solo usen acordes ya aprendidos. El reproductor
  (`StrumPlayer`, en `features/courses/`) rasguea un golpe hacia abajo por pulso; la pantalla
  lo aclara. Las canciones viven en `lib/domain/courses/course_songs.dart` (una sola lista para
  todos los cursos).

## Curso de patrones de rasgueo (Parte 1)
- `lib/domain/strumming/`, unidad `r_strumming_patterns_1` del mapa (segunda de rítmica). Cinco patrones de
  4/4 (`strummingPatterns`, una letra por corchea: `D`, `U` o espacio, y `d`/`u` = golpe
  apagado, que suena como nota muerta y se dibuja x↓/x↑; el mismo formato que
  `Lesson.strumPattern`) con Em, G, D y C. Cada patrón: aprenderlo, con uno, dos y cuatro
  acordes, consejos; luego "el patrón en canciones"; antes del 5, combinar 3 y 4; al final,
  tres partes. Inspirado en cursos tipo "Strumming Patterns – Part 1", en vertical.
- Todos los patrones siguen el péndulo (`followsPendulum`: abajo en los números, arriba en las
  "y"; hay test). Los textos de cada patrón y sus consejos se generan del patrón.
- Audio (`strumEvents` con `patterns`): abajo suenan todas las cuerdas de grave a aguda; arriba,
  las `upStrumStrings` (4) más agudas, de aguda a grave. `StrumPatternView`
  (`lesson_widgets.dart`, el mismo de las lecciones) resalta la corchea que suena.
- Digitaciones por `courseChordShapesProvider` (una lectura para todos los cursos).

## Licks y riffs (Inicio)
- Biblioteca de frases cortas y originales por estilo (decisión del usuario: un módulo como
  Acordes y Escalas, fuente única de las tablaturas de estilo; las guías no traen trastes propios y
  las de la fila "Estilos" enlazan aquí). Inspirada en las guías "In the Style Of" de Gibson, pero sin artistas: los
  estilos se nombran por lo que se toca (`LickStyle`: hard rock de estadio, clásico, heavy/doom,
  thrash, rock latino, sinfónico, psicodélico, hard rock virtuoso, atmosférico, metal progresivo,
  folk de autor) y también los géneros (`LickStyleInfo.genre`: funk, reggae, punk, country, jazz,
  grunge, metal, rock sureño, blues menor; inspirados en la fila "Genres" de Gibson). Nada de riffs
  reconocibles: se enseña la técnica del estilo. Solo afinación
  estándar por ahora (decisión del usuario; las abiertas o graves, después).
- Datos en `lib/domain/licks/licks.dart` (fuente única; se componen, no salen de una regla). Cada
  estilo (`lickStyleInfo`) declara nombre, resumen y `traits` (técnicas que lo distinguen); cada
  frase (`Lick`) su tipo (riff o lick), nivel (`GuideLevel`), escala y tónica, tempo, swing y
  tablatura con la notación de la fase 1. Una sola nota a la vez: los power chords no se pueden
  escribir todavía.
- `test/domain/licks/licks_test.dart`: cada nota y la nota a la que llega un bend son de su escala
  (lee `scales_master.json`), la tablatura está bien escrita y dura pulsos enteros, la mano no se
  estira más de 5 trastes ni sube del 15, cada estilo tiene riff y lick (el riff primero) y usa sus
  `traits`, y lo que afirma cada texto se verifica nota por nota. Frase nueva = test de lo que dice.
  El riff y el lick de un estilo declaran la misma escala y tónica (la guía lo afirma): si sus
  notas caben en dos, se declara la que contiene a las dos (jazz en D dórico, la escala del ii).
- Pantallas en `lib/features/licks/`: lista por estilo con filtros de nivel y tipo (los estilos
  vacíos se ocultan) y detalle con `TabPlayer` (▶, bucle, "Tocar yo"), el estilo y su escala en el
  diapasón. El mejor tempo limpio con el micrófono se guarda en `licks_best_bpm` (`{id: bpm}`) y
  cuenta como día de técnica (`ActivityLog`); "más lento" cambia el tempo solo en la sesión. Los
  ids son permanentes. Rutas `/licks/:id` y `/learn/licks/:id`.

## Guías y capo
- Guías (`lib/domain/guides/guides.dart`, rutas `/learn/guides` y `/learn/guides/:id`): recorridos
  por tema agrupados en filas (`GuideCategory`). No traen trastes propios: cada capítulo enlaza
  algo que ya existe (`LessonLink`, `ScaleLink`, `ChordLink`, `LickLink`, `ModuleLink`) y un test
  exige que exista. Lo que afirma un capítulo se verifica en `test/domain/guides/guides_test.dart`.
- Fila "Estilos" (`style_guides.dart`): una guía por `LickStyle`, armada desde Licks y riffs (id
  `style_<estilo>`, permanente): el riff, el lick (con el texto de cada frase) y la escala de las
  dos; nivel = el de su frase más difícil. Los géneros (`genre`) van en la fila Géneros, detrás de
  las guías escritas a mano. `guides` = las escritas a mano + `styleGuides`.
- Inspiradas en un catálogo de guías tipo "Guides", pero sin artistas reales, sin fotos y sin
  contenido de terceros: géneros genéricos (blues, rock, folk/pop) y técnica.
- Progreso (`lib/domain/guides/guide_progress.dart`): un capítulo que enlaza una lección está
  hecho si la lección está terminada (marcarlo marca la lección; una sola fuente); los demás se
  marcan a mano en `guides_chapters_done` (`guideId/índice`). Minutos por capítulo: los de la
  lección o un fijo por tipo. "Siguiente guía": la próxima sin terminar de la fila y luego del
  catálogo; reemplaza la pantalla (atrás vuelve al catálogo). Sin búsqueda, el catálogo pone
  arriba "Sigue donde ibas" con las empezadas.
- Nivel (`GuideLevel`: principiante, intermedio, avanzado; inspirado en el filtro de Gibson):
  cada guía declara el suyo y un test exige que no sea menor que el de las lecciones que
  enlaza (nivel 2 del camino = intermedio o más). El catálogo filtra por nivel (se combina con
  la búsqueda) y cada tarjeta lo dice con texto. `ScaleLink` puede llevar `position` (id de
  `scales_master.json`): el detalle de escala abre con `?position=` en ese sistema y esa
  digitación. "CAGED: acorde y escala" une cada forma de C de `chords.json` con su forma de la
  escala mayor; el test verifica digitación, traste, tramo y que las notas del acorde caigan
  dentro de la forma de escala.
- Buscador: `searchGuides` busca todas las palabras, sin tildes ni mayúsculas, en título,
  subtítulo y títulos de capítulo del idioma actual; las filas vacías se ocultan.
- Diseño vertical (decisión del usuario: nada de filas que se deslizan de lado): cada categoría es
  una sección con sus guías en lista, a todo lo ancho (dibujo, título, subtítulo, capítulos,
  minutos y avance).
- "¿Qué capo uso?" (`lib/domain/theory/capo.dart`, ruta `/learn/capo`): por regla, el traste del
  capo para cada forma abierta (C A G E D; Am Em Dm en menor), hasta el traste 7, con su
  I – IV – V. Las cinco formas mayores cubren cualquier tonalidad sin pasar del 7 (hay test).
  Cubre la parte "¿qué capo uso?" de la fase 3 del círculo. "Gira una progresión" (solo en mayor,
  las de `progression_data.dart`): `chordsInKey` y `capoTransposition` dan, por cada capo, qué arma
  la mano y cómo suena; un test lo comprueba en las 12 tonalidades y que cada forma exista.

## Rutinas de escala y tablatura con audio
- Rutinas (`lib/domain/practice/scale_workouts.dart`, ruta `/practice/workouts?scale=&root=`):
  por regla sobre una posición real de `scales_master.json`. `positionLadder` ordena las notas
  por altura sin repetir (si una nota está en dos cuerdas, queda la más grave) y `workoutNotes`
  la recorre: subir y bajar, terceras, grupos de 3 y de 4, primero subiendo y luego bajando.
  Niveles: principiante (subir y bajar, 60 BPM), intermedio (terceras y grupos de 3, 70) y
  avanzado (grupos de 4 y terceras, 90). Sistema: 3NPS en las de 7 notas, cajas en pentatónicas
  y blues, CAGED en el resto (`workoutSystemFor`). Un test exige que cada nota de cada rutina de
  cada posición pertenezca a su escala.
- Técnica (`lib/domain/practice/technique_exercises.dart`, ruta `/practice/technique`): cromático
  1-2-3-4 y araña 1-3-2-4 (6ª→1ª y de vuelta), diagonal (cada cuerda un traste más arriba) y
  salto de cuerda (6 4 5 3 4 2 3 1), un dedo por traste desde el traste 1, 5 o 9. Tempo de 5 en
  5 BPM; "Me salió limpio" guarda el récord por ejercicio en `technique_best_bpm` y propone 5 más.
- Notación de la tablatura (fase 1 de los estilos, inspirada en las guías de Gibson):
  `TabNote` lleva `length` en semicorcheas (por defecto corchea), `technique` (h, p, slide,
  bend con `bend` semitonos, release, vibrato, PM, nota muerta x) y `pick` (⊓ V);
  `TabNote.rest` es un silencio. El swing (`TabSwing`, corcheas o semicorcheas) corre el
  contratiempo a 2/3, como un tresillo, y es de la tablatura entera (`TabPlayer.swing`).
  `tabNotationProblems` (`tab_notation.dart`) dice qué está mal escrito (un ligado sigue a la
  nota anterior en su cuerda, el hammer-on sube, el pull-off baja, el release vuelve del bend…)
  y un test lo corre sobre todas las lecciones. Se dibuja en `lesson_tab.dart`: letras entre
  notas, b½/b1 y ~ en la nota, arriba la púa y PM, silencio = barrita, conteo "1 e y a" debajo
  solo si hay ritmo propio (`tabHasRhythm`), y una leyenda con solo las marcas que aparecen.
- Audio de una tablatura (`tab_playback.dart`): cada nota en su instante (duraciones y swing),
  y la pantalla marca la nota con los mismos instantes (`tabIndexAt`). `tabSounds` arma las
  cuerdas: un ligado, slide, bend o release no se vuelve a pulsar, cambia la altura de la
  cuerda que suena (Karplus-Strong con retardo variable, `_pluckMoving`; test: el bend y el
  hammer-on quedan a < 5 cents); volver a pulsar una cuerda la apaga; PM y nota muerta se
  apagan solos (`decayFor`). Se sintetiza la frase entera en un WAV (`playTab`). Claves de
  archivo largas pasan por `stableKey` (FNV-1a).
- Micrófono y notación: los silencios y las notas muertas no se esperan; un bend se espera en
  su traste (la nota empujada llega sin ataque y no es error); `NoteFollower.position` es el
  índice en la tablatura. El tempo sale de los pulsos de cada nota, no de notas iguales.
- Dedos en la tablatura (idea de Gibson, que colorea por dedo; aquí número, nunca solo color):
  `tabFingers` (`tab_playback.dart`) por la regla de un dedo por traste. Si todo lo pisado cabe
  en los trastes 1–4, el dedo es el traste; si no, el índice va en el traste más bajo; si no
  cabe en 4 trastes (la mano se mueve), no hay fila. `TabPlayer` la muestra debajo de la 6ª
  cuerda y la pista lo explica. Test: coincide con lo que dicen Primeros pasos y Melodías.
- `TabPlayer` (`features/lessons/tab_player.dart`) es el único reproductor: lecciones con tab y
  rutinas. Al empezar uno, el anterior se detiene (`tabPlaybackProvider`).
- Tests de pantallas que leen `scales_master.json`: inyectar `ScaleRepository` con un bundle de
  archivo. `rootBundle` guarda la lectura del primer test atada a su zona de tiempo falso y el
  siguiente test se queda esperando para siempre.

## Ícono y nombre
- El ícono se genera desde código: `flutter test tool/app_icon/render_app_icon_test.dart`
  (diagrama de C abierto con la paleta oscura; escribe Android clásico + capa adaptable,
  iOS sin alfa y `store/play_icon_512.png`). No editar los PNG a mano; idempotente.
- Nombre: "Learn & Strum" en todas partes (Android `android:label` y iOS `CFBundleDisplayName`
  con `&amp;`; dentro de la app `AppStrings.appName`). Id: `com.guitar.learnandstrum` (Android
  namespace/applicationId, `MainActivity` en ese paquete, iOS bundle id): permanente al publicar.
  Lo interno sigue llamándose chordmaster_free / ChordMasterApp (no se ve).
- Arranque sin destello blanco: `@color/launch_background` (claro #F3EFEA / oscuro #1C1613).

## Flujo de trabajo (obligatorio)
1. Antes de cada commit: `flutter analyze` y `flutter test` limpios. Un commit que no
   compila es peor que no commitear (pasó con el borrado de generadores).
2. Un commit por paso lógico; mensaje en español que diga qué y por qué.
3. No ejecutar `dart format` sobre archivos que no tocaste (ensucia el diff).
4. Si borras un archivo, `grep` primero quién lo importa y limpia esos imports en el mismo commit.
5. No cambies lógica de `lib/domain/` desde la UI; si falta algo, se agrega al dominio con test.
6. Datos musicales: ver "Fuentes de verdad". Cambiar un dato sin pasar por su generador está
   prohibido.
7. `git status` antes de dar por terminado; no dejar archivos sueltos (`tool/flutter`,
   `test_errors.txt`) ni cambios sin commitear.
8. Sin interrupciones: una tarea pedida se lleva hasta el PR sin preguntar. Rama desde `main`
   actualizado, commit y push con analyze y tests limpios, PR hacia `main` y Auto-fix activo.
   Preguntar solo antes de fusionar, cerrar PRs, borrar datos que no sean de prueba o decidir
   algo musical, de producto o de licencia. Lo que quede sin comprobar se dice en el PR.
9. Los PRs se fusionan rápido y por fuera de la sesión: consultar su estado antes de proponer
   cambios sobre uno. Un PR fusionado no se actualiza; va otro PR.
10. El CI en verde no prueba cómo se ve. Cambio visual = revisarlo en el emulador y dejar un test
    que mida el problema, a 360 dp y en español e inglés. En `Pixel_7_Pro`,
    `adb shell wm density 640` da 360 dp; al terminar, `adb shell wm density reset`. `adb` está en
    `%LOCALAPPDATA%\Android\Sdk\platform-tools`, y `uiautomator` no ve la app: tocar por
    coordenadas sobre una captura. El primer arranque en debug tarda: confirmar con otra captura
    que cada paso ocurrió. Si el APK debug no cabe, `flutter build apk --release --target-platform
    android-x64`. "Reducir movimiento" en Android: `settings put global transition_animation_scale 0`
    (no `animator_duration_scale`); al terminar, volver a 1.

## Dependencias y herramientas
- `pubspec.yaml` fija versiones exactas. La versión de Flutter va en `ci.yml` y `release.yml`.
- Un PR de Dependabot en rojo puede venir de una rama vieja: leer su log antes de culpar al
  paquete. Si son varios, actualizar todo junto en un PR; Dependabot cierra los suyos al fusionar.
- AGP y Gradle: la versión que Flutter declare soportada, no la última publicada. `compileSdk` va
  fijo en 37 (lo piden los plugins) y Kotlin es el integrado de AGP.
- `flutter_secure_storage` guarda la llave que cifra los datos de Hive. Antes de subirlo de versión
  mayor, instalar encima de la versión anterior sin borrar datos y comprobar que siguen ahí.
- `google_fonts`: no usar sus `...TextTheme()`, devuelven el tipo de `material_ui` y no compilan
  con `flutter/material`. Aplicar la fuente estilo por estilo, como `lib/ui/theme.dart`.

## Arquitectura y estándar de código (siempre)
Objetivo: código legible y mantenible antes que ingenioso. Capas (puertos y adaptadores):
- `lib/domain/` — Dart puro (sin Flutter ni E/S), con tests: reglas musicales, motores, síntesis.
- Puertos = interfaces que la app necesita del mundo exterior; adaptadores = la implementación
  concreta. Almacenamiento: puerto `KeyValueStore` (`lib/services/key_value_store.dart`, cajas en
  `StorageBoxes`), adaptador `HiveStore`. `main()` es la raíz de composición: abre `HiveStore` y lo
  inyecta con `keyValueStoreProvider.overrideWithValue`; el provider sin inyectar falla a
  propósito. Tests: `test/support/in_memory_store.dart` (un solo doble, separado por caja).
- Servicios con estado (logros, audio, afinación, notificaciones) se piden por su provider
  (`ref.read(achievementServiceProvider)`), nunca con `.instance` desde pantallas o view-models;
  las dependencias entran por el constructor.
- `lib/data/` — repositorios de assets (una lectura, memorizada). `lib/features/` y `lib/ui/` —
  pantallas + view-models (Riverpod `Notifier`); sin lógica de dominio ni E/S directa.
- Una sola fuente por dato o tabla (notas, afinación, cajas, textos); antes de escribir una lista o
  helper, buscar si ya existe. Nada de código muerto: lo que no se usa se borra (y su test).
- Clases y funciones pequeñas con un propósito; un archivo de pantalla grande se parte en widgets.
  Estructuras de datos según el acceso (mapas/sets para búsquedas, no `firstWhere` en bucles).
- Licencia: pendiente de decidir (MIT en evaluación); no agregar ni descartar sin preguntar.

## Teoría "¿Por qué?" (generada por reglas, con tests)
- `lib/domain/theory/harmony.dart` — función de cada grado (reposo/preparación/tensión),
  cadencias (auténtica, plagal, rota, semicadencia; también al repetir el bucle) y notas comunes.
- `lib/domain/theory/scale_insights.dart` — pasos T/S, nota característica frente a mayor o
  menor natural, simetría, acordes que caben sobre la tónica, acordes diatónicos con número
  romano, escalas para un acorde (`scalesForChord`) e ideas de improvisación (texto curado por
  escala; las disminuidas se distinguen por intervalos).
- `lib/domain/theory/octaves.dart` — formas de octava deducidas de la afinación (8: 6→4 +2,
  5→3 +2, 4→2 +3, 3→1 +3, 6→3 −3, 5→2 −2, 4→1 −2, 6→1 = a dos octavas) y posiciones de una
  nota; las usa la tarjeta "Octavas de la tónica" del detalle de escala (líneas en el mismo
  painter del diapasón, parámetro `links`).
- Todo texto nuevo de teoría: bilingüe y con test que verifique lo que afirma.

## Buscador por notas (Inicio)
- Ruta `/finder`, en la pestaña Inicio (atrás vuelve a Inicio); sus resultados abren la ficha
  en `/chords/:id` y `/scales/:scaleId`, también de Inicio. Mástil vacío (`FretboardNeck` con `onTapCell`; el
  toque se ubica con `FretGridGeometry.cellAt`, el inverso de `noteOffset`) y dos secciones,
  cada una con sus notas (`noteFinderProvider`):
  - Acordes: una nota por cuerda (tocar otra vez la apaga; el nombre de la cuerda = al aire).
    `chordsFor` (`lib/domain/theory/note_finder.dart`) busca con las fórmulas de `chords.json`
    los acordes con exactamente esas notas o sin alguna omitible (5ª, 9ª, 11ª, salvo la nota
    más alta que da el nombre); el bajo es la nota más grave y, si no es la tónica, sale
    slash (C/E). Orden: completos, tónica en el bajo, menos omitidas. Test: la digitación
    principal de cada acorde de `chords.json` se reconoce como él.
  - Escalas: notas sueltas. `scalesFor` da las escalas y modos de `scales_master.json` (12
    tónicas) que las contienen todas: primero las que menos notas agregan, luego la de
    tónica en la nota más grave. Misma tónica y mismas notas (mayor = jónica) sale una vez.
- Cada resultado abre su ficha con `push` (atrás vuelve al buscador con las notas, y de ahí a Inicio).

## Círculo de quintas
- `lib/domain/theory/circle_of_fifths.dart`: todo por regla, sin tablas. Orden sumando 7 semitonos
  desde C, armadura por posición, ventana diatónica, distancia, formas en el mástil y la matemática
  de la rueda (ángulo, acomodo, camino corto, clics). Rutas `/learn/circle` y `/learn/circle/build`.
- Notación (decisión del usuario): la app usa solo sostenidos, también aquí. Las tonalidades se
  nombran A#, D#…; la armadura se da como cantidad ("2 ♯", "3 ♭") y ninguna nota se nombra con
  bemol. F# es "6 ♯, enarmónica de 6 ♭". Su 6º sostenido cae en F, que el texto aclara como E#.
- Notas en común entre dos mayores: se calculan de las escalas. `7 − distancia` vale de 0 a 5; a
  distancia 6 son 2, no 1 (C y F# comparten B y F).
- "¿Cómo se arma?" responde por qué ese orden: cada paso busca la quinta y cambia una sola nota
  (la 4ª de la anterior sube un semitono y es la 7ª de la nueva; vale en los 12 pasos) mientras el
  círculo se llena (`circle_build_ring.dart`). Del lado de los ♭, ese mismo paso quita un ♭.
- La rueda (`circle_wheel.dart`) está fuera del scroll para que un arrastre siempre la gire. La
  rotación vive en un `AnimationController` que repinta solo su `CustomPainter`; el panel se
  reconstruye únicamente al cambiar de tonalidad, y los textos del painter van ya medidos.

## Mapa del código
- `lib/domain/theory/double_stops.dart` — double stops diatónicos y fijos.
- `lib/domain/voicing/` — `ergonomics.dart` (incl. modo principiante), `voice_leading.dart`,
  `voicing_adapter.dart`, `barre_detection.dart` (`detectBarre`: cejilla mini/grande) y
  `fingering_metrics.dart` (`analyzeFingering`, `bestIndices`).
- `lib/domain/progressions/` — datos y `ProgressionBuilder`.
- `lib/domain/fingering_systems/` — teoría de sistemas + registro.
- `lib/data/` — modelos y repositorios: `ChordRepository` (única lectura de `chords.json`,
  decodificado fuera del hilo de la UI; vistas `chords()` y `fingerings()`) y `ScaleRepository`
  (resolución por raíz). Nadie más llama a `rootBundle` para estos archivos.
- `lib/features/` — pantallas por módulo (chords, progressions, ...).
  - `features/chords/chord_compare_screen.dart` — ruta `/learn/chords/:id/compare?sel=caged:0,voicings:2`
    (claves `sección:índice`, máx. 3; secciones `main`, `caged`, `voicings`, `triadInversions`,
    `advancedInversions`). Parseo y títulos en `fingering_selection.dart`; el explorador marca
    con checkbox "Comparar".
- `lib/ui/scales/` — escalas, detalle y `double_stops/`.
  - Detalle: arriba solo la tónica (decisión del usuario: sistema y digitación se eligen viendo
    el mástil). `selectedPatternIndex == null` = sin digitación, y el diapasón fijo muestra la
    posición predeterminada: la primera declarada del primer sistema de
    `FingeringSystemsRegistry.previewOrder` (Posición 1 de 3NPS en las de 7 notas, la caja en
    pentatónicas y blues, CAGED en las simétricas). Cambiar tónica o sistema limpia la selección.
  - Vista ampliada (`detail/scale_fretboard_fullscreen.dart`): botones Sistema y Digitación
    (`widgets/pattern_selector.dart`). Se abre en el navegador raíz, sin pestañas, y comparte
    `scaleDetailProvider` con el detalle. `FretboardNeck` da la columna de aire fija y los trastes
    1–24 con scroll; las notas salen de `scaleNotesOnNeck` y una digitación se resalta en todas las
    octavas donde cabe completa (`patternAcrossNeck`), ambas en `lib/domain/theory/neck_notes.dart`.
    Solo Android e iOS piden horizontal, y al salir se devuelve con la lista vacía: la app no fija
    orientación y así respeta el bloqueo de rotación.
  - Con nombres de nota, una nota al aire reemplaza el nombre de su cuerda para no decirlo dos
    veces; con intervalos, la afinación sigue al lado.
- `lib/ui/navigation.dart` — UN solo `StatefulShellRoute` con 5 pestañas (`AppScaffold`):
  Inicio `/`, Aprender `/learn/...`, Practicar `/practice/...`, Afinar `/tools/tuner|metronome`,
  Progreso `/progress/...` (incluye ajustes). Tocar una pestaña abre siempre su inicio.
  Inicio no repite módulos de Aprender ni de Practicar (decisión del usuario, hay test): Acordes, Escalas,
  Licks y riffs, Progresiones, el Círculo de quintas y el Buscador se abren desde Inicio (`homeModules`); el hub de
  Aprender (`LearnHubScreen.entries`) tiene Lecciones, Guías y capo. Esos cinco módulos
  cuelgan de las dos pestañas (`_moduleRoutes()` en `navigation.dart`): `/chords`, `/scales`,
  `/licks`, `/progressions`, `/circle` en Inicio (atrás vuelve a Inicio) y `/learn/...` en Aprender (los
  abren lecciones y guías). Sus enlaces internos usan `context.sectionPath('chords/...')`
  (`lib/ui/section_routes.dart`) para no saltar de pestaña: nada de `'/learn/chords...'` fijo
  dentro de esas pantallas. `/chords`, `/scales` y `/progressions` dejaron de ser rutas viejas. Lo mismo con Practicar: Oído, Ritmo y Canciones se abren solo desde Practicar
  (`PracticeHubScreen.entries`), no desde Inicio. El detalle de acorde dice "Acordes" en la barra (el nombre va debajo). Componer vive dentro de Progresiones ("Mi
  progresión", por grados) e Improvisación dentro del detalle de cada escala; sus rutas viejas
  redirigen. El detalle de escala acepta `?root=` (tónica inicial). Toda pantalla nueva cuelga de su hub para que el
  botón de atrás automático funcione; nada de `leading` manual ni barras inferiores propias.
  Las rutas viejas (`/chords`, `/tuner`…) redirigen vía `redirectLegacyRoute`. Las pestañas
  ocultas siguen montadas: lo que use micrófono/audio debe pausarse con `TickerMode`.

## Pendiente (en orden)
0. Compilar en esta máquina: `android/gradle.properties` fija `org.gradle.java.home` a
   `C:/Program Files/Android/Android Studio/jbr`, que quedó roto al reinstalar Android Studio.
   Mientras tanto: `gradlew assembleRelease` con `-Dorg.gradle.java.home=` y
   `-Porg.gradle.java.installations.paths=` apuntando a `C:/Program Files/Android/openjdk/jdk-21.0.8`.
   Decidir si esa línea debe salir del repo (es una ruta de una sola máquina).
   `chords.json`: Dm marca el dedo 1 en la 3ª y en la 1ª cuerda; revisar en el generador.
1. Revisión en un dispositivo físico: rediseño completo, versión bilingüe, "Mi progresión",
   tarjetas "¿Por qué?", notificaciones, audio y afinador con una nota real. Lecciones: reto
   superado y letra grande.
2. Lecciones: el reto en inglés dice "in Ear" en vez de "Ear Training" (los números de dedo a
   64 dp y el descentrado de los diagramas ya se corrigieron: `chordDiagramMetrics`).
3. Sandbox TS: corregir la 7ª diatónica del grado VII (allí sigue como disminuida; aquí se
   corrigió a 7ª menor y se regeneraron solo esas filas del golden, 2005 → 1983).
4. Berklee, si se consigue una definición verificable.
5. iOS (al compilar por primera vez en una Mac): `permission_handler` necesita en el
   `post_install` del `ios/Podfile` que genere Flutter
   `config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'PERMISSION_MICROPHONE=1', 'PERMISSION_NOTIFICATIONS=1']`;
   sin eso el micrófono queda siempre denegado. `Info.plist` ya trae
   `NSMicrophoneUsageDescription`.
6. Círculo de quintas, fase 2:
   - Dominantes secundarias: V7 de cada diatónico (el vecino de la derecha), cadena
     III7–VI7–II7–V7–I y ii–V–I como 3 pasos contra reloj, con audio.
   - Modulación: elegir tonalidad origen y destino → distancia, notas en común y acordes pivote
     (tríadas diatónicas compartidas).
   - Intercambio modal: menor paralela (3 pasos contra reloj) y sus prestados iv, bVI y bVII,
     nombrados con sostenidos según la regla.
   - Modos ordenados por brillo (lidio → locrio) como recorrido del círculo.
7. Círculo de quintas, fase 3:
   - Juego/quiz: "¿cuál es el V de E?", "¿cuántos ♯ tiene A?", "¿qué acorde falta en la ventana?",
     con récord en `userProgress` y un logro nuevo que se pueda conseguir.
   - Unidad "Círculo de quintas" en Lecciones (según las reglas de esa sección), con un reto que
     se supere con el récord del quiz.
