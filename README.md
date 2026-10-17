# domain/fingering_systems

Fuente única de la **teoría** de cada sistema de digitación (nombre, explicación,
orden de formas, cómo se conectan). La UI (`ui/scales/`, `features/chords/`) lee de
`FingeringSystemsRegistry` en vez de duplicar texto.

Las **posiciones** (qué trastes tocar) NO se calculan aquí ni en tiempo de ejecución:
salen de `assets/data/scales_master.json`, generado por reglas con
`tool/regenerate_scales_master.py` y validado con `tool/audit_scales_master.py` y
`test/data/scales_master_validity_test.dart`.

| Sistema                | Carpeta                | id                     | Escalas con datos                                  |
|------------------------|------------------------|------------------------|-----------------------------------------------------|
| CAGED                  | `caged/`               | `caged`                | las 12 escalas (cajas por ventana de forma CAGED)   |
| 3 notas por cuerda     | `three_nps/`           | `three_nps`            | escalas de 7 notas + 7 modos                        |
| Pentatonic Box (2NPS)  | `pentatonic_two_notes/`| `pentatonic_two_notes` | pentatónicas mayor/menor y blues                    |
| Linear (4NPS)          | `linear_four_notes/`   | `linear_four_notes`    | escalas de 7 notas + 7 modos                        |

Berklee no está: no hay definición con trastes verificable (ver CLAUDE.md). Para añadirlo,
primero definir sus 7 posiciones con una fuente, luego una regla en el generador de
Python, luego su teoría aquí y su id en `displayOrder`.

Para añadir un sistema: (1) regla en `tool/regenerate_scales_master.py`, (2) correr el
generador y el auditor, (3) archivo `*_theory.dart` y alta en el registro, (4) test de chips.
