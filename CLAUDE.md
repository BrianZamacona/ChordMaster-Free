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
- Notas siempre con sostenidos (`C C# D D# E F F# G G# A A# B`).
- Nombre de intervalos en escalas: `spellInterval` (`lib/domain/theory/intervals.dart`). En
  escalas de 7 notas cada grado tiene su número (b6 en la menor, #4 en la lidia), nunca `#5`
  por defecto.
- Dibujo de diapasón con líneas/notas: UNA función de coordenadas (`noteOffset`) y un solo
  `CustomPainter`; nada de medir widgets por separado.
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
  (`musicMono()`, notas/intervalos). Empaquetadas en `assets/google_fonts/` (OFL); los tests
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
- Berklee NO está implementado: no hay definición con trastes verificada. No inventarla.
- Progresiones: candidatos = digitaciones de `chords.json` (principal, CAGED, voicings) sin costo ergonómico infinito;
  **formas abiertas primero** (decisión del usuario): si el acorde tiene alguna forma abierta
  (`isOpenPosition`: una cuerda al aire y nada más allá del traste 4), solo entran esas; si no
  (F, B, Bm, F#m...), entran todas, cejillas incluidas. Vale en ambos modos. Después,
  camino óptimo por programación dinámica (costo ergonómico + salto de soprano + cambio de
  traste − notas retenidas). En modo Estándar el costo no penaliza cejillas; el modo
  Principiante (`ErgonomicOptions.beginner`) suma +2.0 por cejilla mini (2–3 cuerdas) y
  +8.0 por grande (≥4). No es filtro duro: un grado solo con cejillas sigue dando camino.
- Comparador de digitaciones: `analyzeFingering` incluye SIEMPRE la cejilla en el costo,
  así que puede no coincidir con Progresiones en modo Estándar; la pantalla lo advierte.
- Calidad de double stops por grado (3ª, 6ª, 7ª...) en `lib/domain/theory/double_stops.dart`,
  verificada contra resultados de referencia del sandbox TypeScript
  (`test/fixtures/golden/`).

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

## Mapa del código
- `lib/domain/theory/double_stops.dart` — double stops diatónicos y fijos.
- `lib/domain/voicing/` — `ergonomics.dart` (incl. modo principiante), `voice_leading.dart`,
  `voicing_adapter.dart`, `barre_detection.dart` (`detectBarre`: cejilla mini/grande) y
  `fingering_metrics.dart` (`analyzeFingering`, `bestIndices`).
- `lib/domain/progressions/` — datos y `ProgressionBuilder`.
- `lib/domain/fingering_systems/` — teoría de sistemas + registro.
- `lib/data/` — modelos y repositorio de escalas (resolución por raíz).
- `lib/features/` — pantallas por módulo (chords, progressions, ...).
  - `features/chords/chord_compare_screen.dart` — ruta `/learn/chords/:id/compare?sel=caged:0,voicings:2`
    (claves `sección:índice`, máx. 3; secciones `main`, `caged`, `voicings`, `triadInversions`,
    `advancedInversions`). Parseo y títulos en `fingering_selection.dart`; el explorador marca
    con checkbox "Comparar".
- `lib/ui/scales/` — escalas, detalle y `double_stops/`.
- `lib/ui/navigation.dart` — UN solo `StatefulShellRoute` con 5 pestañas (`AppScaffold`):
  Inicio `/`, Aprender `/learn/...`, Practicar `/practice/...`, Afinar `/tools/tuner|metronome`,
  Progreso `/progress/...` (incluye ajustes). Componer vive dentro de Progresiones ("Mi
  progresión", por grados) e Improvisación dentro del detalle de cada escala; sus rutas viejas
  redirigen. El detalle de escala acepta `?root=` (tónica inicial). Toda pantalla nueva cuelga de su hub para que el
  botón de atrás automático funcione; nada de `leading` manual ni barras inferiores propias.
  Las rutas viejas (`/chords`, `/tuner`…) redirigen vía `redirectLegacyRoute`. Las pestañas
  ocultas siguen montadas: lo que use micrófono/audio debe pausarse con `TickerMode`.

## Pendiente (en orden)
1. Revisión visual en el dispositivo (rediseño completo, versión bilingüe, "Mi progresión",
   tarjetas "¿Por qué?").
2. Sandbox TS: corregir la 7ª diatónica del grado VII (allí sigue como disminuida; aquí se
   corrigió a 7ª menor y se regeneraron solo esas filas del golden, 2005 → 1983).
3. Berklee, si se consigue una definición verificable.
