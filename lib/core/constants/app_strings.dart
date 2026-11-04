import '../i18n/tr.dart';

/// Textos de la interfaz en español e inglés.
///
/// Cada texto es un getter (no `const`) porque depende del idioma actual;
/// `tr` exige las dos versiones, así que falta de traducción = no compila.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────────────────────

  static const String appName = 'Learn & Strum';

  // ── Módulos ────────────────────────────────────────────────────────────────

  static String get moduleChords => tr(es: 'Acordes', en: 'Chords');
  static String get moduleScales => tr(es: 'Escalas', en: 'Scales');
  static String get moduleTuner => tr(es: 'Afinador', en: 'Tuner');
  static String get moduleMetronome => tr(es: 'Metrónomo', en: 'Metronome');
  static String get moduleProgressions =>
      tr(es: 'Progresiones', en: 'Progressions');
  static String get moduleEarTraining => tr(es: 'Oído', en: 'Ear Training');
  static String get moduleRhythmGame => tr(es: 'Ritmo', en: 'Rhythm Game');
  static String get moduleSongs => tr(es: 'Canciones', en: 'Songs');
  static String get moduleHealth =>
      tr(es: 'Salud de práctica', en: 'Practice Health');
  static String get moduleAchievements => tr(es: 'Logros', en: 'Achievements');

  // ── Acciones ───────────────────────────────────────────────────────────────

  static String get play => tr(es: 'Reproducir', en: 'Play');
  static String get stop => tr(es: 'Detener', en: 'Stop');
  static String get save => tr(es: 'Guardar', en: 'Save');
  static String get reset => tr(es: 'Reiniciar', en: 'Reset');
  static String get next => tr(es: 'Siguiente', en: 'Next');
  static String get share => tr(es: 'Compartir', en: 'Share');
  static String get grantPermission =>
      tr(es: 'Permitir micrófono', en: 'Allow microphone');
  static String get darkMode => tr(es: 'Modo oscuro', en: 'Dark mode');
  static String get darkModeSubtitle => tr(
    es: 'Apagado = sigue al sistema',
    en: 'Off = follow the system',
  );
  static String get language => tr(es: 'Idioma', en: 'Language');
  static String get supportApp =>
      tr(es: 'Apoya Learn & Strum ♥', en: 'Support Learn & Strum ♥');
  static String get start => tr(es: 'Empezar', en: 'Start');
  static String get tap => tr(es: 'Marcar', en: 'Tap');

  // ── Afinador ───────────────────────────────────────────────────────────────

  static String get inTune => tr(es: 'Afinada', en: 'In tune');
  static String get sharp => tr(es: 'Alta', en: 'Sharp');
  static String get flat => tr(es: 'Baja', en: 'Flat');
  static String get tunerIdle =>
      tr(es: 'Toca una cuerda para empezar', en: 'Play a string to begin');
  static String get cents => tr(es: 'cents', en: 'cents');

  // ── Metrónomo ──────────────────────────────────────────────────────────────

  static const String bpm = 'BPM';
  static String get timeSignature => tr(es: 'Compás', en: 'Time signature');
  static String get subdivision => tr(es: 'Subdivisión', en: 'Subdivision');

  // ── Acordes ────────────────────────────────────────────────────────────────

  static String get chordCategory => tr(es: 'Estilo', en: 'Style');
  static String get difficulty => tr(es: 'Dificultad', en: 'Difficulty');
  static String get fretPositions => tr(es: 'Trastes', en: 'Frets');
  static String get chordAliases => tr(es: 'Otros nombres', en: 'Aliases');
  static String get chordDescription =>
      tr(es: 'Sobre este acorde', en: 'About this chord');
  static String get chordFormula => tr(es: 'Fórmula', en: 'Formula');
  static String get relatedScales =>
      tr(es: 'Escalas relacionadas', en: 'Related scales');
  static String get relatedScalesNone => tr(
    es: 'Ninguna escala de la app contiene todas sus notas.',
    en: 'No scale in the app contains all of its notes.',
  );
  static String relatedChordsOf(String root) =>
      tr(es: 'Acordes relacionados con $root', en: 'Related $root chords');
  static String get styleMatches =>
      tr(es: 'Del mismo estilo', en: 'Same style');
  static String get chordExplorer => tr(es: 'Explorador', en: 'Explorer');
  static String get curatedVoicings => tr(es: 'Voicings', en: 'Voicings');
  static String get triadInversions =>
      tr(es: 'Inversiones de tríada', en: 'Triad inversions');
  static String get advancedInversions =>
      tr(es: 'Inversiones avanzadas', en: 'Advanced inversions');
  static String get chordExplorerEmpty => tr(
    es: 'Este acorde aún no tiene datos para el explorador.',
    en: 'This chord has no explorer data yet.',
  );
  static String get noDataAvailable =>
      tr(es: 'Sin datos.', en: 'No data available.');
  static String get shapeLabel => tr(es: 'Forma', en: 'Shape');
  static String positionsCount(int n) => n == 1
      ? tr(es: '1 posición', en: '1 position')
      : tr(es: '$n posiciones', en: '$n positions');
  static String allPositionsOf(String chord, int n) =>
      tr(es: 'Todas las posiciones de $chord ($n)', en: 'All $chord positions ($n)');
  static String get openDetail => tr(es: 'Ver detalle', en: 'See details');
  static String get openExplorerToCompare =>
      tr(es: 'Comparar en el explorador', en: 'Compare in the explorer');

  // ── Comparador de digitaciones ─────────────────────────────────────────────

  static String get compareTitle =>
      tr(es: 'Comparar digitaciones', en: 'Compare fingerings');
  static String get compareCheckbox => tr(es: 'Comparar', en: 'Compare');
  static String get compareButton => tr(es: 'Comparar', en: 'Compare');
  static String get compareMaxReached =>
      tr(es: 'Máximo 3 digitaciones', en: 'Up to 3 fingerings');
  static String get compareEmpty => tr(
    es: 'Elige 2–3 digitaciones en el explorador',
    en: 'Pick 2–3 fingerings in the explorer',
  );
  static String get compareBack =>
      tr(es: 'Volver al explorador', en: 'Back to the explorer');
  static String get compareBest => tr(es: 'Mejor', en: 'Best');
  static String get compareCostNote => tr(
    es: 'El costo ergonómico incluye siempre la cejilla. En Progresiones, el '
        'modo Estándar no la penaliza, así que los costos pueden diferir.',
    en: 'The ergonomic cost always includes the barre. In Progressions, '
        'Standard mode does not penalize it, so costs may differ.',
  );
  static String get compareMainSection =>
      tr(es: 'Digitación principal', en: 'Main fingering');

  static String get metricCost =>
      tr(es: 'Costo ergonómico', en: 'Ergonomic cost');
  static String get metricFingers => tr(es: 'Dedos', en: 'Fingers');
  static String get metricBarre => tr(es: 'Cejilla', en: 'Barre');
  static String get metricPosition => tr(es: 'Posición', en: 'Position');
  static String get metricSpan => tr(es: 'Extensión', en: 'Span');
  static String get metricMuted =>
      tr(es: 'Cuerdas muteadas', en: 'Muted strings');
  static String get metricBass => tr(es: 'Bajo', en: 'Bass');
  static String get metricInversion => tr(es: 'Inversión', en: 'Inversion');
  static String get metricNotes => tr(es: 'Notas', en: 'Notes');
  static String get barreNone => tr(es: 'Ninguna', en: 'None');
  static String get openPosition => tr(es: 'Al aire', en: 'Open');
  static String get fretWord => tr(es: 'traste', en: 'fret');
  static String get fretsWord => tr(es: 'trastes', en: 'frets');

  // ── Navegación ─────────────────────────────────────────────────────────────

  static String get tabHome => tr(es: 'Inicio', en: 'Home');
  static String get tabLearn => tr(es: 'Aprender', en: 'Learn');
  static String get tabPractice => tr(es: 'Practicar', en: 'Practice');

  /// Corto para que quepa en la barra inferior a 360 px.
  static String get tabTools => tr(es: 'Afinar', en: 'Tune');
  static String get toolsTitle => tr(es: 'Herramientas', en: 'Tools');
  static String get tabProgress => tr(es: 'Progreso', en: 'Progress');

  static String get learnIntro => tr(
    es: 'Lecciones paso a paso, acordes, escalas y progresiones: qué tocar y '
        'por qué suena así.',
    en: 'Step-by-step lessons, chords, scales and progressions: what to play '
        'and why it sounds that way.',
  );
  static String get practiceIntro => tr(
    es: 'Entrena el oído y el ritmo, y aplica lo aprendido en canciones.',
    en: 'Train your ear and timing, and use what you learned in real songs.',
  );
  static String get progressIntro => tr(
    es: 'Tus logros, tu tiempo de práctica y los ajustes de la app.',
    en: 'Your achievements, your practice time and the app settings.',
  );
  static String get settingsTitle => tr(es: 'Ajustes', en: 'Settings');

  static String get hubChords => tr(es: 'Acordes', en: 'Chords');
  static String get hubChordsSub => tr(
    es: 'Biblioteca de 288 acordes, formas CAGED, inversiones y comparador.',
    en: 'A library of 288 chords, CAGED shapes, inversions and a comparer.',
  );
  static String get hubScales =>
      tr(es: 'Escalas y double stops', en: 'Scales and double stops');
  static String get hubScalesSub => tr(
    es: 'Escalas y modos por sistema (CAGED, 3NPS…), cómo improvisar con '
        'ellas y parejas de notas.',
    en: 'Scales and modes by system (CAGED, 3NPS…), how to improvise with '
        'them, and note pairs.',
  );
  static String get hubProgressions =>
      tr(es: 'Progresiones', en: 'Progressions');
  static String get hubProgressionsSub => tr(
    es: 'Progresiones comunes con las digitaciones más cómodas, y las tuyas.',
    en: 'Common progressions with the most comfortable fingerings, and your own.',
  );
  static String get hubEar => tr(es: 'Oído', en: 'Ear');
  static String get hubEarSub => tr(
    es: 'Reconoce intervalos y acordes de oído.',
    en: 'Recognize intervals and chords by ear.',
  );
  static String get hubRhythm => tr(es: 'Ritmo', en: 'Rhythm');
  static String get hubRhythmSub =>
      tr(es: 'Toca a tiempo con el pulso.', en: 'Play in time with the beat.');
  static String get hubSongs => tr(es: 'Canciones', en: 'Songs');
  static String get hubSongsSub =>
      tr(es: 'Practica con canciones reales.', en: 'Practice with real songs.');
  static String get hubAchievements => tr(es: 'Logros', en: 'Achievements');
  static String get hubAchievementsSub =>
      tr(es: 'Lo que ya conseguiste.', en: 'What you have already achieved.');
  static String get hubHealth =>
      tr(es: 'Salud de práctica', en: 'Practice health');
  static String get hubHealthSub => tr(
    es: 'Tiempo de práctica, descansos y calentamiento.',
    en: 'Practice time, breaks and warm-up.',
  );
  static String get toolTuner => tr(es: 'Afinador', en: 'Tuner');
  static String get toolMetronome => tr(es: 'Metrónomo', en: 'Metronome');
  static String get hubLessons => tr(es: 'Lecciones', en: 'Lessons');
  static String get hubLessonsSub => tr(
    es: 'Un camino paso a paso: Fundamentos y después rítmica o líder.',
    en: 'A step-by-step path: Foundations, then rhythm or lead.',
  );

  // ── Lecciones ──────────────────────────────────────────────────────────────

  static String get lessonsTitle => tr(es: 'Lecciones', en: 'Lessons');
  static String get trackFoundations => tr(es: 'Fundamentos', en: 'Foundations');
  static String get trackFoundationsSub => tr(
    es: 'Lo básico que todo guitarrista necesita.',
    en: 'The basics every guitarist needs.',
  );
  static String get trackRhythm => tr(es: 'Guitarra rítmica', en: 'Rhythm guitar');
  static String get trackRhythmSub => tr(
    es: 'Acompañar canciones: rasgueos, cejillas y power chords.',
    en: 'Backing songs: strumming, barre chords and power chords.',
  );
  static String get trackLead => tr(es: 'Guitarra líder', en: 'Lead guitar');
  static String get trackLeadSub => tr(
    es: 'Escalas, técnica y expresión para tu primer solo.',
    en: 'Scales, technique and expression for your first solo.',
  );
  static String get lessonsContinue => tr(es: 'Sigue aquí', en: 'Continue here');
  static String get lessonsStart => tr(es: 'Empezar', en: 'Start');
  static String get lessonsAllDone => tr(
    es: 'Terminaste toda la ruta. Repite cualquier lección cuando quieras.',
    en: 'You finished the whole path. Repeat any lesson whenever you like.',
  );
  static String get lessonsChoosePath => tr(
    es: 'Elige tu camino. Puedes cambiarlo cuando quieras.',
    en: 'Choose your path. You can change it anytime.',
  );
  static String get lessonsChooseLater => tr(
    es: 'Al terminar Fundamentos eliges tu camino. Si ya tocas, puedes adelantarte.',
    en: 'After Foundations you choose your path. If you already play, you can skip ahead.',
  );
  static String lessonsProgress(int done, int total) =>
      tr(es: '$done de $total', en: '$done of $total');
  static String lessonMinutes(int minutes) =>
      tr(es: '$minutes min', en: '$minutes min');
  static String get lessonDone => tr(es: 'Hecha', en: 'Done');
  static String get lessonNext => tr(es: 'Siguiente', en: 'Next');
  static String get lessonSteps => tr(es: 'Pasos', en: 'Steps');
  static String get lessonChords => tr(es: 'Acordes', en: 'Chords');
  static String get lessonChordsHint =>
      tr(es: 'Toca un acorde para ver su ficha.', en: 'Tap a chord to open it.');
  static String get lessonStrum => tr(es: 'Rasgueo', en: 'Strumming');
  /// Conteo de la corchea entre pulsos: "1 y 2 y…" / "1 & 2 &…".
  static String get lessonStrumAnd => tr(es: 'y', en: '&');
  static String get lessonStrumHint => tr(
    es: '↓ abajo · ↑ arriba · — la mano pasa sin tocar',
    en: '↓ down · ↑ up · — the hand passes without touching',
  );
  static String get lessonOpenScale =>
      tr(es: 'Ver la escala en el diapasón', en: 'See the scale on the fretboard');
  static String get lessonOpenTuner => tr(es: 'Abrir el afinador', en: 'Open the tuner');
  static String lessonOpenMetronome(int? bpm) => bpm == null
      ? tr(es: 'Abrir el metrónomo', en: 'Open the metronome')
      : tr(es: 'Practicar a $bpm BPM', en: 'Practice at $bpm BPM');
  static String get lessonMarkDone =>
      tr(es: 'Marcar como completada', en: 'Mark as completed');
  static String get lessonMarkPending =>
      tr(es: 'Completada · marcar como pendiente', en: 'Completed · mark as pending');
  static String get lessonNotFound =>
      tr(es: 'No encontramos esta lección.', en: 'We could not find this lesson.');

  // ── Filtros de acordes ─────────────────────────────────────────────────────

  static String get filterRoot => tr(es: 'Raíz', en: 'Root');
  static String get filterType => tr(es: 'Tipo', en: 'Type');
  static String get filterStyle => tr(es: 'Estilo', en: 'Style');
  static String get filterRootTitle => tr(es: 'Nota raíz', en: 'Root note');
  static String get filterTypeTitle =>
      tr(es: 'Tipo de acorde', en: 'Chord type');
  static String get filterStyleTitle => tr(es: 'Estilo', en: 'Style');
  static String get filterAllRoots =>
      tr(es: 'Todas las raíces', en: 'All roots');
  static String get filterAllTypes => tr(es: 'Todos los tipos', en: 'All types');
  static String get filterAllStyles =>
      tr(es: 'Todos los estilos', en: 'All styles');
  static String get filterClear => tr(es: 'Quitar filtro', en: 'Clear filter');
  static String get filterClearAll => tr(es: 'Limpiar', en: 'Clear');
  static String chordsCount(int n) => n == 1
      ? tr(es: '1 acorde', en: '1 chord')
      : tr(es: '$n acordes', en: '$n chords');
  static String get familyTriads => tr(es: 'Tríadas', en: 'Triads');
  static String get familyTriadsHint => tr(
    es: 'Tres notas: raíz, 3ª y 5ª (o sus variantes). La base de todo.',
    en: 'Three notes: root, 3rd and 5th (or their variants). The basis of everything.',
  );
  static String get familySevenths =>
      tr(es: 'Sextas y séptimas', en: 'Sixths and sevenths');
  static String get familySeventhsHint => tr(
    es: 'Una tríada más la 6ª o la 7ª: el sonido del blues, el jazz y el soul.',
    en: 'A triad plus the 6th or 7th: the sound of blues, jazz and soul.',
  );
  static String get familyExtended =>
      tr(es: 'Novenas y extendidas', en: 'Ninths and extended');
  static String get familyExtendedHint => tr(
    es: 'Añaden 9ª, 11ª o 13ª sobre la 7ª: color y tensión suave.',
    en: 'They add a 9th, 11th or 13th on top of the 7th: color and soft tension.',
  );
  static String get familyAltered => tr(es: 'Alterados', en: 'Altered');
  static String get familyAlteredHint => tr(
    es: 'Tensiones alteradas (♭9, ♯9, ♯11) para dominantes con más tensión.',
    en: 'Altered tensions (♭9, ♯9, ♯11) for dominants with more bite.',
  );

  // ── Escalas ────────────────────────────────────────────────────────────────

  static String get scaleTonic => tr(es: 'Tónica', en: 'Tonic');
  static String get scaleSystem => tr(es: 'Sistema', en: 'System');
  static String get scaleSystemTitle =>
      tr(es: 'Sistema de digitación', en: 'Fingering system');
  static String get scaleAllSystems =>
      tr(es: 'Todos los sistemas', en: 'All systems');
  static String scaleHowItWorks(String system) =>
      tr(es: 'Cómo funciona $system', en: 'How $system works');
  static String get scaleNoPositions => tr(
    es: 'Sin posiciones para este sistema',
    en: 'No positions for this system',
  );
  static String get scaleShapeOrder => tr(es: 'Orden', en: 'Order');
  static String get cagedPositions =>
      tr(es: 'Posiciones CAGED', en: 'CAGED positions');
  static String get scaleModes => tr(es: 'Modos', en: 'Modes');
  static String get scaleNotesCount => tr(es: 'notas', en: 'notes');
  static String get dsSub => tr(
    es: 'Parejas de notas por grado y par de cuerdas',
    en: 'Note pairs by degree and string pair',
  );
  static String get scaleSteps => tr(
    es: 'Pasos entre notas: S = semitono (1 traste), T = tono (2), '
        'T+S = tono y medio (3)',
    en: 'Steps between notes: H = half step (1 fret), W = whole step (2), '
        'W+H = step and a half (3)',
  );
  static String get scaleStepsLegend => tr(
    es: 'Pasos entre notas: S = semitono (1 traste) · T = tono (2 trastes) · '
        'T+S = tono y medio (3 trastes). Solo algunas escalas tienen saltos de '
        'tono y medio.',
    en: 'Steps between notes: H = half step (1 fret) · W = whole step (2 frets) · '
        'W+H = step and a half (3 frets). Only some scales have step-and-a-half '
        'leaps.',
  );
  static String get progressionListen =>
      tr(es: 'Escuchar progresión', en: 'Listen to the progression');
  static String get progressionStop => tr(es: 'Detener', en: 'Stop');
  static String get progressionTapHint => tr(
    es: 'Toca un acorde para ver todas sus posiciones y cambiarla.',
    en: 'Tap a chord to see all of its positions and change it.',
  );
  static String progressionPositionsOf(String chord) =>
      tr(es: 'Posiciones de $chord', en: '$chord positions');
  static String get progressionChosen => tr(es: 'Elegida por ti', en: 'Your choice');
  static String get progressionResetFingering =>
      tr(es: 'Volver a la recomendada', en: 'Back to the recommended one');
  static String get slashTitle =>
      tr(es: 'Bajo (acorde slash)', en: 'Bass note (slash chord)');
  static String get slashHint => tr(
    es: 'Elige otra nota para el bajo: el acorde se mantiene arriba y esa nota '
        'suena como la más grave (C/E = C con E en el bajo).',
    en: 'Pick another bass note: the chord stays on top and that note sounds '
        'lowest (C/E = C with E in the bass).',
  );
  static String get slashNone => tr(
    es: 'No hay una digitación cómoda con ese bajo.',
    en: 'There is no comfortable fingering with that bass note.',
  );
  static String slashBassIs(String note, String interval, {required bool inChord}) => inChord
      ? tr(
          es: '$note está en el acorde ($interval sobre la raíz): es una inversión.',
          en: '$note is in the chord ($interval above the root): it is an inversion.',
        )
      : tr(
          es: '$note no está en el acorde ($interval sobre la raíz): añade color en el bajo.',
          en: '$note is not in the chord ($interval above the root): it adds color in the bass.',
        );
  static String get octavesTitle =>
      tr(es: 'Octavas de la tónica', en: 'Octaves of the tonic');
  static String get octavesHint => tr(
    es: 'La tónica en todo el diapasón y cómo saltar a su octava sin contar notas. '
        'Al llegar a la 2ª cuerda (si) la forma se corre un traste: está afinada '
        'una 3ª mayor sobre la 3ª, no una 4ª.',
    en: 'The tonic across the whole neck and how to jump to its octave without '
        'counting notes. Reaching the 2nd (B) string the shape moves one fret: it is '
        'tuned a major third above the 3rd string, not a fourth.',
  );
  static String octaveShapeLabel(int low, int high, int shift) =>
      tr(es: '$lowª→$highª', en: '${_ordinal(low)}→${_ordinal(high)}') +
      (shift == 0 ? ' =' : shift > 0 ? ' +$shift' : ' −${-shift}');
  static String octaveShapeText(int low, int high, int shift, int octaves) {
    final frets = shift.abs() == 1
        ? tr(es: '1 traste', en: '1 fret')
        : tr(es: '${shift.abs()} trastes', en: '${shift.abs()} frets');
    final where = shift == 0
        ? tr(es: 'en el mismo traste', en: 'on the same fret')
        : shift > 0
            ? tr(es: '$frets hacia el cuerpo', en: '$frets toward the body')
            : tr(es: '$frets hacia la cejuela', en: '$frets toward the nut');
    final distance = octaves == 1
        ? tr(es: 'su octava', en: 'its octave')
        : tr(es: 'la nota dos octavas más arriba', en: 'the note two octaves up');
    return tr(
      es: 'De la $lowª a la $highª cuerda: $distance está $where.',
      en: 'From the ${_ordinal(low)} to the ${_ordinal(high)} string: $distance is $where.',
    );
  }

  static String _ordinal(int n) => switch (n) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    _ => '${n}th',
  };
  static String get harmonyTitle => tr(
    es: 'Acordes que armonizan la escala',
    en: 'Chords that harmonize the scale',
  );
  static String get harmonyHint => tr(
    es: 'Cada grado forma un acorde apilando terceras con las notas de la '
        'escala: 1-3-5 (tríada) y 1-3-5-7 (cuatríada). Toca uno para verlo.',
    en: 'Each degree builds a chord by stacking thirds with the notes of the '
        'scale: 1-3-5 (triad) and 1-3-5-7 (seventh chord). Tap one to see it.',
  );
  static String get scaleImproviseTitle =>
      tr(es: 'Improvisar con esta escala', en: 'Improvise with this scale');
  static String get improvWhere => tr(es: 'Dónde suena', en: 'Where it fits');
  static String get improvIdea =>
      tr(es: 'Idea para practicar', en: 'Practice idea');
  static String get scaleChordsFit =>
      tr(es: 'Acordes que puedes acompañar', en: 'Chords it fits over');
  static String get scaleChordsFitHint => tr(
    es: 'Sobre la tónica, todas las notas del acorde están en la escala: '
        'ninguna choca.',
    en: 'On the tonic, every note of the chord is in the scale: nothing '
        'clashes.',
  );

  // ── Double stops ───────────────────────────────────────────────────────────

  static String get dsTitle =>
      tr(es: 'Double stops diatónicos', en: 'Diatonic double stops');
  static String get dsInterval => tr(es: 'Intervalo', en: 'Interval');
  static String get dsAdjacent =>
      tr(es: 'Cuerdas juntas', en: 'Adjacent strings');
  static String get dsSkipOne => tr(es: 'Saltando una', en: 'Skip one');
  static String get dsLowRange => tr(es: 'Trastes 0–12', en: 'Frets 0–12');
  static String get dsHighRange => tr(es: 'Trastes 13–24', en: 'Frets 13–24');
  static String dsGroupTitle(int a, int b, int pairs) => tr(
    es: 'Cuerdas $a y $b · $pairs parejas',
    en: 'Strings $a and $b · $pairs pairs',
  );
  static String get dsNoPairs =>
      tr(es: 'Sin parejas en este rango.', en: 'No pairs in this range.');

  /// Calidad de intervalo del dominio ("3ª mayor") en el idioma actual.
  static String intervalQualityLabel(String spanish) {
    if (CurrentLanguage.value == AppLanguage.es) return spanish;
    final m = RegExp(r'^(\d)ª (\w+)$').firstMatch(spanish);
    if (m == null) return spanish;
    const ordinals = {'2': '2nd', '3': '3rd', '4': '4th', '5': '5th', '6': '6th', '7': '7th'};
    const qualities = {
      'mayor': 'major',
      'menor': 'minor',
      'justa': 'perfect',
      'aumentada': 'augmented',
      'disminuida': 'diminished',
    };
    return '${qualities[m[2]] ?? m[2]} ${ordinals[m[1]] ?? m[1]}';
  }

  // ── Progresiones ───────────────────────────────────────────────────────────

  static String get progressionKey => tr(es: 'Tonalidad', en: 'Key');
  static String get progressionKeyTitle =>
      tr(es: 'Tonalidad (mayor)', en: 'Key (major)');
  static String get progressionLabel => tr(es: 'Progresión', en: 'Progression');
  static String get progressionPickTitle =>
      tr(es: 'Elige una progresión', en: 'Pick a progression');
  static String get transitionNoJump => tr(es: 'sin salto', en: 'no shift');
  static String get transitionJump => tr(es: 'salto', en: 'shift');
  static String get transitionCommonOne =>
      tr(es: 'nota común', en: 'common note');
  static String get transitionCommonMany =>
      tr(es: 'notas comunes', en: 'common notes');
  static String get transitionCost =>
      tr(es: 'Costo de transición', en: 'Transition cost');
  static String get progressionCustom =>
      tr(es: 'Mi progresión', en: 'My progression');
  static String get progressionCustomSub => tr(
    es: 'Ármala por grados; la app elige las digitaciones.',
    en: 'Build it by degrees; the app picks the fingerings.',
  );
  static String get progressionCustomHint => tr(
    es: 'Toca los grados para armar tu progresión. Mantén pulsado uno para '
        'ver qué función cumple.',
    en: 'Tap the degrees to build your progression. Long-press one to see '
        'its role.',
  );
  static String progressionCustomCount(int n, int max) =>
      tr(es: '$n de $max acordes', en: '$n of $max chords');
  static String get progressionLoadError => tr(
    es: 'No se pudieron cargar los acordes',
    en: 'Could not load the chords',
  );
  static String get whyTitle =>
      tr(es: '¿Por qué suena así?', en: 'Why does it sound like this?');
  static String get modeStandard => tr(es: 'Estándar', en: 'Standard');
  static String get modeBeginner => tr(es: 'Principiante', en: 'Beginner');
  static String get barreFret => tr(es: 'Cejilla traste', en: 'Barre fret');
  static String get barreLarge => tr(es: 'cejilla grande', en: 'full barre');

  // ── Diagrama ───────────────────────────────────────────────────────────────

  static String get legendRoot => tr(es: 'Raíz', en: 'Root');
  static String get legendThird => tr(es: '3ª', en: '3rd');
  static String get legendFifth => tr(es: '5ª', en: '5th');
  static String get legendSeventh => tr(es: '7ª', en: '7th');
  static String get legendTension => tr(es: 'Tensión', en: 'Tension');
  static String get showFingers => tr(es: 'Dedos', en: 'Fingers');
  static String get showIntervals => tr(es: 'Intervalos', en: 'Intervals');
  static String get showNotes => tr(es: 'Notas', en: 'Notes');

  // ── Oído ───────────────────────────────────────────────────────────────────

  static String get identifyInterval =>
      tr(es: '¿Qué intervalo escuchaste?', en: 'What interval did you hear?');
  static String get correct => tr(es: '¡Correcto!', en: 'Correct!');
  static String get incorrect => tr(es: 'Incorrecto', en: 'Incorrect');
  static String get score => tr(es: 'Puntos', en: 'Score');
  static String get streak => tr(es: 'Racha', en: 'Streak');

  // ── Salud ──────────────────────────────────────────────────────────────────

  static String get takeABreak => tr(
    es: 'Hora de un descanso corto: relaja las manos.',
    en: 'Time for a short break — rest your hands!',
  );
  static String get warmUpReminder => tr(
    es: 'Recuerda calentar antes de tocar.',
    en: 'Remember to warm up before playing.',
  );

  // ── Practicar y progreso ───────────────────────────────────────────────────

  static String get statTotal => tr(es: 'Hechos', en: 'Total done');
  static String get statAccuracy => tr(es: 'Precisión', en: 'Accuracy');
  static String get statTaps => tr(es: 'Toques', en: 'Taps');
  static String get statBest => tr(es: 'Mejor', en: 'Best');
  static String get earListen => tr(es: 'Escuchar', en: 'Listen');
  static String get earMelodic => tr(es: 'Melódico', en: 'Melodic');
  static String get earHarmonic => tr(es: 'Armónico', en: 'Harmonic');
  static String get chooseInterval =>
      tr(es: 'Elige el intervalo:', en: 'Choose the interval:');
  static String semitonesCount(int n) => n == 1
      ? tr(es: '1 semitono', en: '1 semitone')
      : tr(es: '$n semitonos', en: '$n semitones');
  static String itWas(String name, String short) =>
      tr(es: 'Era: $name ($short)', en: 'It was: $name ($short)');
  static String get earWizardUnlocked => tr(
    es: '👂 ¡Logro Oído mágico desbloqueado!',
    en: '👂 Ear Wizard achievement unlocked!',
  );
  static String rhythmMinTaps(int n) => tr(
    es: 'Toca al menos $n veces para que la sesión cuente como récord.',
    en: 'Tap at least $n times for the session to count as a record.',
  );
  static String get rhythmMasterUnlocked => tr(
    es: '🥁 ¡Logro Maestro del ritmo desbloqueado!',
    en: '🥁 Rhythm Master achievement unlocked!',
  );
  static String lastTaps(int n) =>
      tr(es: 'Últimos $n toques:', en: 'Last $n taps:');
  static String get micDeniedForever => tr(
    es: 'El permiso del micrófono está desactivado. Actívalo en los ajustes de la app para usar el afinador.',
    en: 'Microphone access is turned off. Enable it in the app settings to use the tuner.',
  );
  static String get openSettings => tr(es: 'Abrir ajustes', en: 'Open settings');
  static String get micRequired => tr(
    es: 'El afinador necesita el micrófono. Concede el permiso para usarlo.',
    en: 'Microphone access is required to use the tuner. Please grant permission.',
  );
  static String get referencePitch =>
      tr(es: 'Tono de referencia', en: 'Reference pitch');
  static String get standardTuning =>
      tr(es: 'Afinación estándar', en: 'Standard tuning reference');
  static String get subQuarter => tr(es: '♩ Negras', en: '♩ Quarter');
  static String get subEighth => tr(es: '♪ Corcheas', en: '♪ Eighth');
  static String get subSixteenth => tr(es: '♬ Semicorcheas', en: '♬ Sixteenth');
  static String get subTriplet => tr(es: '♪♪♪ Tresillos', en: '♪♪♪ Triplet');
  static String achievementsUnlocked(int n, int total) =>
      tr(es: '$n / $total desbloqueados', en: '$n / $total unlocked');
  static String unlockedOn(String date) =>
      tr(es: '✅ Desbloqueado el $date', en: '✅ Unlocked $date');
  static String get homeModules => tr(es: 'Módulos', en: 'Modules');
  static String get dailyChallenge => tr(es: 'Reto del día', en: 'Daily challenge');
  static String get songTitle => tr(es: 'Canción', en: 'Song');
  static String get songNotFound =>
      tr(es: 'Canción no encontrada.', en: 'Song not found.');
  static String get songChords =>
      tr(es: '🎸 Progresión de acordes', en: '🎸 Chord progression');
  static String get songStrumming =>
      tr(es: '🎼 Patrón de rasgueo', en: '🎼 Strumming pattern');
  static String get songNotes => tr(es: '📝 Notas de práctica', en: '📝 Practice notes');
  static List<String> get songDifficulty => [
    '',
    tr(es: 'Principiante', en: 'Beginner'),
    tr(es: 'Fácil', en: 'Easy'),
    tr(es: 'Intermedia', en: 'Intermediate'),
    tr(es: 'Avanzada', en: 'Advanced'),
    tr(es: 'Experta', en: 'Expert'),
  ];
  static String get practiceSession =>
      tr(es: '⏱️ Sesión de práctica', en: '⏱️ Practice session');
  static String get breakReminders =>
      tr(es: '🔔 Recordatorios de descanso', en: '🔔 Break reminders');
  static String get enableReminders =>
      tr(es: 'Activar recordatorios', en: 'Enable reminders');
  static String get enableRemindersSub => tr(
    es: 'Mientras la sesión de práctica está en marcha, te avisa para que descanses las manos',
    en: 'While a practice session is running, reminds you to rest your hands',
  );
  static String get breakDone => tr(es: 'Listo', en: 'Done');
  static String get pause => tr(es: 'Pausa', en: 'Pause');
  static String minutesShort(int m) => tr(es: '$m min', en: '$m min');
  static String get remindEvery => tr(es: 'Avisar cada:', en: 'Remind every:');
  static String get warmupExercises =>
      tr(es: '🤸 Ejercicios de calentamiento', en: '🤸 Warm-up exercises');
  static String get reminderTitle =>
      tr(es: 'Recordatorio de Learn & Strum', en: 'Learn & Strum reminder');
  static String get reminderChannelName =>
      tr(es: 'Recordatorios de pausa', en: 'Break reminders');
  static String get reminderChannelDesc => tr(
    es: 'Avisos periódicos para descansar y estirar las manos.',
    en: 'Periodic reminders to take a break and stretch your hands.',
  );
  static String get reminderBody => tr(
    es: '¡Hora de una pausa! Estira las manos 🎸',
    en: 'Time for a break! Stretch your hands 🎸',
  );

  // ── Búsqueda y vacíos ──────────────────────────────────────────────────────

  static String get searchHint => tr(es: 'Buscar…', en: 'Search…');
  static String get emptyChordsSearch => tr(
    es: 'Ningún acorde coincide con la búsqueda.',
    en: 'No chords match your search.',
  );
  static String get emptySongsSearch => tr(
    es: 'Ninguna canción coincide con la búsqueda.',
    en: 'No songs match your search.',
  );

  // ── Errores ────────────────────────────────────────────────────────────────

  static String get errorGeneric => tr(
    es: 'Algo salió mal. Inténtalo de nuevo.',
    en: 'Something went wrong. Please try again.',
  );
  static String get errorLoadChords => tr(
    es: 'No se pudieron cargar los acordes.',
    en: 'Failed to load chords.',
  );
  static String get errorStorage => tr(
    es: 'No se pudieron cargar los datos guardados.',
    en: 'Could not load saved data.',
  );
}
