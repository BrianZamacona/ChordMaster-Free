# Ficha de Google Play — Learn & Strum

Textos listos para copiar en Play Console. Límites de Play: título 30 caracteres,
descripción breve 80, descripción completa 4000 (verificados con
`python -I store/check_listing.py`).

Ícono 512 × 512: `store/play_icon_512.png` (lo genera `tool/app_icon/render_app_icon_test.dart`).
Política de privacidad: `docs/privacy-policy.md` (publicar con GitHub Pages y pegar la URL).

---

## Español (es-419 / es-ES)

### Título
Learn & Strum: Guitarra

### Descripción breve
Acordes, escalas, progresiones, afinador y oído. Sin anuncios y sin conexión.

### Descripción completa
Learn & Strum es una app para aprender guitarra que explica el porqué de cada acorde, escala y progresión. Es gratis, no tiene anuncios ni cuentas y funciona sin conexión.

ACORDES
• 288 acordes: 24 tipos en las 12 tonalidades, de mayores y menores a 7#9, 13 y maj7#11.
• Más de 1800 digitaciones: formas CAGED, tríadas e inversiones en todos los grupos de cuerdas, Drop 2 y Drop 3, power chords y formas para principiantes.
• Acordes slash: elige cualquier nota para el bajo (C/E, D/F#, Am/G) y la app te da las digitaciones.
• Escucha cada acorde y compara digitaciones lado a lado.

ESCALAS
• 12 escalas y los 7 modos: mayor, menores, pentatónicas, blues, disminuidas, tonos enteros y exóticas.
• Posiciones CAGED, 3 y 4 notas por cuerda y cajas pentatónicas, en cualquier tónica.
• "¿Por qué?": los pasos de la escala, qué nota la distingue y qué acordes la armonizan.
• Octavas de la tónica en todo el diapasón e ideas para improvisar.

PROGRESIONES
• Progresiones clásicas en cualquier tonalidad o arma la tuya por grados.
• La app elige las digitaciones con menos saltos (formas abiertas primero) y puedes cambiar cualquiera.
• Escucha la progresión completa y entiende su función: reposo, tensión y cadencias.

PRÁCTICA
• Afinador cromático con La de referencia ajustable.
• Metrónomo.
• Entrenamiento auditivo de intervalos, melódicos o armónicos.
• Juego de ritmo para tocar a tiempo.
• Double stops y canciones conocidas con sus acordes.
• Calentamiento y avisos de pausa para cuidar tus manos.
• Racha diaria y logros.

Disponible en español e inglés, con tema claro y oscuro. Tus datos se quedan en tu teléfono: el micrófono solo se usa para el afinador y no graba nada.

---

## English (en-US)

### Title
Learn & Strum: Guitar

### Short description
Chords, scales, progressions, tuner and ear training. No ads, works offline.

### Full description
Learn & Strum is a guitar-learning app that explains the why behind every chord, scale and progression. It is free, with no ads and no accounts, and it works offline.

CHORDS
• 288 chords: 24 types in all 12 keys, from major and minor to 7#9, 13 and maj7#11.
• Over 1800 fingerings: CAGED shapes, triads and inversions on every string set, Drop 2 and Drop 3, power chords and beginner shapes.
• Slash chords: pick any bass note (C/E, D/F#, Am/G) and get the fingerings.
• Listen to every chord and compare fingerings side by side.

SCALES
• 12 scales and all 7 modes: major, minors, pentatonics, blues, diminished, whole tone and exotic scales.
• CAGED, 3- and 4-notes-per-string and pentatonic box positions, in any key.
• "Why?": the scale's steps, the note that makes it unique and the chords that harmonize it.
• Octaves of the tonic across the neck and improvisation ideas.

PROGRESSIONS
• Classic progressions in any key, or build your own by scale degree.
• The app picks the fingerings with the smallest jumps (open shapes first), and you can swap any of them.
• Listen to the whole progression and learn what each chord does: rest, tension and cadences.

PRACTICE
• Chromatic tuner with adjustable A reference.
• Metronome.
• Interval ear training, melodic or harmonic.
• Rhythm game to play in time.
• Double stops and well-known songs with their chords.
• Warm-ups and break reminders to look after your hands.
• Daily streak and achievements.

Available in Spanish and English, with light and dark themes. Your data stays on your phone: the microphone is only used by the tuner and nothing is recorded.

---

## Datos para Play Console

**Categoría:** Educación (alternativa: Música y audio). **Etiquetas:** guitarra, acordes, música.
**Contiene anuncios:** No. **Compras en la app:** No (la donación abre Ko-fi en el navegador).

**Seguridad de los datos** (verificado en el código):
- ¿Recopila o comparte datos? **No.** La app no tiene permiso de internet ni SDK de analítica, anuncios o errores; el progreso y los ajustes se guardan cifrados solo en el teléfono.
- Audio: el micrófono se procesa al momento en el teléfono para el afinador y no se guarda ni se envía. Según la definición de Google, el procesamiento que no sale del dispositivo no cuenta como "recopilado".
- Permisos que verá Google: `RECORD_AUDIO` (afinador), `POST_NOTIFICATIONS` (avisos de pausa), `VIBRATE` (notificaciones).

**Clasificación de contenido:** sin violencia, lenguaje, contenido sexual, apuestas ni interacción entre usuarios (Comunidad se eliminó); no comparte ubicación ni datos personales.

**Público objetivo:** mayores de 13 años recomendado. Incluir menores de 13 activa los requisitos de la política de Familias; la app no recopila datos, pero la declaración es más larga.
