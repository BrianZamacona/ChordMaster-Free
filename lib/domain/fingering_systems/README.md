# domain/fingering_systems

Fuente única de teoría + algoritmo para cada sistema de digitación.
`features/chords` y la pantalla de escalas (`ui/scales/`) deben leer de
aquí en vez de cada quien reimplementar su propio pedazo de teoría.

## Estado actual — las 5 estrategias migradas

Las 5 estrategias que vivían huérfanas en
`lib/features/scales/domain/strategies/` (nada fuera de esa carpeta las
importaba) ya están migradas aquí, cada una con su teoría + generador:

| Sistema                | Carpeta                   | id de registro         |
|-------------------------|----------------------------|-------------------------|
| CAGED                   | `caged/`                   | `caged`                 |
| 3 Notes Per String       | `three_nps/`                | `three_nps`             |
| Pentatonic Box (2NPS)    | `pentatonic_two_notes/`     | `pentatonic_two_notes`  |
| Linear (4NPS)            | `linear_four_notes/`        | `linear_four_notes`     |
| Berklee (4NPS)           | `berklee/`                  | `berklee`               |

Todas se resuelven a través de `FingeringSystemsRegistry` (teoría +
generador + orden de despliegue) — no importar los archivos individuales
directamente desde fuera de esta carpeta.

## Lo que ESTO no resuelve todavía (integración pendiente)

Migrar el algoritmo no significa que ya esté conectado a la app. Falta:

1. **Poblar `assets/data/scales_master.json` con los 3 sistemas nuevos.**
   Hoy el JSON solo trae datos para `CAGED` y `3NPS` (12 escalas + 7
   modos). `pentatonic_two_notes`, `linear_four_notes` y `berklee` no
   tienen ninguna escala con patrones generados todavía — el algoritmo
   existe pero no hay datos que lo usen. Esto requiere un script/tarea
   aparte que recorra cada escala, corra el generador correspondiente
   con las notas de la escala, y escriba las posiciones resultantes al
   JSON (no es algo que se resuelva en tiempo de ejecución dentro de la
   app — los patrones deben quedar precalculados en el JSON, igual que
   CAGED y 3NPS hoy).
2. **`_SystemFilterRow`** (en `ui/scales/detail/scale_detail_screen.dart`)
   sigue leyendo `scale.systems` directo del JSON — una vez el JSON
   tenga los 5 sistemas, los chips van a aparecer solos, sin cambios de
   código ahí. Pero si quieres un orden fijo de chips (en vez del orden
   en que vengan en el JSON), usa `FingeringSystemsRegistry.displayOrder`.
3. **`chord_explorer_screen.dart`** sigue con el texto de CAGED
   hardcodeado (`AppStrings.cagedPositions`) — cámbialo para leer
   `FingeringSystemsRegistry.theoryFor('caged')!.name` en vez del string
   suelto.
4. Una vez lo anterior esté funcionando, borra
   `lib/features/scales/` completo (viewmodel, screen y las 5
   estrategias viejas) — ya no queda nada ahí que no esté migrado aquí.
