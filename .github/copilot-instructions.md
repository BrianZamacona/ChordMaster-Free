# Learn & Strum — instrucciones para asistentes de código

La guía completa y obligatoria es [`CLAUDE.md`](../CLAUDE.md): fuentes de verdad, convenciones,
decisiones musicales y flujo de trabajo. Este archivo resume lo indispensable.

## Comandos
- Dependencias: `flutter pub get`
- Análisis y tests (obligatorios antes de cada commit): `flutter analyze` y `flutter test`
- Auditorías de datos (0 defectos): `python tool/audit_chord_music.py assets/data/chords.json`
  y `python tool/audit_scales_master.py`

## Reglas que más fallan
- Los datos musicales (`assets/data/*.json`) **no se editan a mano**: se cambian en
  `tool/regenerate_*.py`, se audita y se confirma que el generador es idempotente.
- `chords.json` va de la 6ª a la 1ª cuerda (`-1` = muteada); `lib/domain/` usa índice 0 = 1ª
  cuerda. Solo `VoicingAdapter` convierte.
- Notas siempre con sostenidos.
- Ningún texto visible literal: todo pasa por `tr(es:, en:)`, normalmente vía `AppStrings`.
- Colores solo desde `context.palette`.
- La lógica va en `lib/domain/` con tests; la UI no cambia lógica de dominio.
- Sin archivos de audio: el sonido se sintetiza (`lib/domain/audio/`); el afinador usa YIN.

## Estructura
`lib/domain` (Dart puro), `lib/data`, `lib/models`, `lib/features/<módulo>` (pantalla +
view-model con Riverpod), `lib/ui` (navegación de 5 pestañas, tema, escalas), `lib/core`,
`lib/services`. Tests en `test/` con la misma división (`domain`, `features`, `widget`…).
