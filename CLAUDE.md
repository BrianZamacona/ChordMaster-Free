# ChordMaster-Free — guía del proyecto

App Flutter/Dart (Riverpod, go_router) para aprender guitarra: acordes, escalas, progresiones
y double stops. Idioma de la UI y de los commits: español.

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
- Dibujo de diapasón con líneas/notas: UNA función de coordenadas (`noteOffset`) y un solo
  `CustomPainter`; nada de medir widgets por separado.

## Decisiones musicales vigentes
- Formas CAGED menores: la forma G usa la digitación de E (sustitución práctica); la UI lo
  indica ("G (usa la digitación E)").
- Escalas: CAGED = notas de la escala dentro de la ventana de cada forma (≤ 5 trastes);
  3NPS = escalera de 3 notas por cuerda (solo 7 notas); 4NPS = 3NPS + 1 nota por cuerda;
  2NPS = cajas pentatónicas (blues añade la b5 entre 4ª y 5ª). Los modos tienen sus propios
  `intervals` (rotaciones de la mayor).
- Berklee NO está implementado: no hay definición con trastes verificada. No inventarla.
- Progresiones: candidatos = digitaciones de `chords.json` sin costo ergonómico infinito;
  camino óptimo por programación dinámica (costo ergonómico + salto de soprano + cambio de
  traste − notas retenidas). El costo ergonómico no penaliza cejillas completas.
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

## Mapa del código
- `lib/domain/theory/double_stops.dart` — double stops diatónicos y fijos.
- `lib/domain/voicing/` — `ergonomics.dart`, `voice_leading.dart`, `voicing_adapter.dart`.
- `lib/domain/progressions/` — datos y `ProgressionBuilder`.
- `lib/domain/fingering_systems/` — teoría de sistemas + registro.
- `lib/data/` — modelos y repositorio de escalas (resolución por raíz).
- `lib/features/` — pantallas por módulo (chords, progressions, ...).
- `lib/ui/scales/` — escalas, detalle y `double_stops/`.

## Pendiente (en orden)
1. Revisión visual en el dispositivo de Progresiones y Double stops (colores de nota cuando
   una nota es raíz en una pareja e intervalo en otra; contador del logro "composer").
2. Pantalla para comparar varias digitaciones de un mismo acorde.
3. Berklee, si se consigue una definición verificable.
4. Penalizar cejillas completas en progresiones "para principiantes" (pasar `barre`/dedos).
