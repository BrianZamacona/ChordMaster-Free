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
  static String get hubCircleSub => tr(
    es: 'Gira la rueda: armaduras, acordes de cada tonalidad y su cadencia.',
    en: 'Spin the wheel: key signatures, the chords of each key and its cadence.',
  );
  static String get circleTitle =>
      tr(es: 'Círculo de quintas', en: 'Circle of fifths');
  static String get circleWheelHint => tr(
    es: 'Gira con el dedo o usa los botones para cambiar de tonalidad.',
    en: 'Spin with your finger or use the buttons to change key.',
  );
  static String get circleStepLeft =>
      tr(es: 'Una quinta abajo', en: 'One fifth down');
  static String get circleStepRight =>
      tr(es: 'Una quinta arriba', en: 'One fifth up');
  static String get circleTickOn =>
      tr(es: 'Activar el tic de la rueda', en: 'Turn on the wheel tick');
  static String get circleTickOff =>
      tr(es: 'Apagar el tic de la rueda', en: 'Turn off the wheel tick');
  static String circleKeySemantics(String name, String signature) => tr(
    es: '$name mayor, $signature',
    en: '$name major, $signature',
  );
  static String circleKeyTitle(String name, String relative) => tr(
    es: '$name mayor · relativa ${relative}m',
    en: '$name major · relative ${relative}m',
  );
  static String circleListenCadence(String cadence) => tr(
    es: 'Escuchar cadencia $cadence',
    en: 'Hear the cadence $cadence',
  );
  static String circlePlayingCadence(String numeral, int step, int total) => tr(
    es: 'Suena $numeral ($step de $total). Detener',
    en: 'Playing $numeral ($step of $total). Stop',
  );
  static String circleCadenceNote(String cadence) => 'V → I: $cadence.';
  static String circleToProgressions(String name) => tr(
    es: 'Usar $name en Progresiones',
    en: 'Use $name in Progressions',
  );
  static String circleOpenChord(String name) =>
      tr(es: 'Abrir la ficha de $name', en: 'Open the $name chord page');
  static String get circleBuildTitle =>
      tr(es: '¿Cómo se arma?', en: 'How is it built?');
  static String circleBuildProgress(int step, int total) =>
      tr(es: 'Paso $step de $total', en: 'Step $step of $total');
  static String circleBuildNeck(String from, String to) => tr(
    es: 'En la guitarra: de $from a $to',
    en: 'On the guitar: from $from to $to',
  );
  static String circleBuildNeckStart(String name) =>
      tr(es: 'En la guitarra: $name', en: 'On the guitar: $name');
  static String circleBuildFindFifth(String name) => tr(
    es: '1. Busca la quinta de $name',
    en: '1. Find the fifth of $name',
  );
  static String get circleBuildChangeOne =>
      tr(es: '2. Cambia una sola nota', en: '2. Change a single note');
  static String circleBuildNotesOf(String name) =>
      tr(es: 'Las notas de $name', en: 'The notes of $name');
  static String get circleBuildClosingTitle =>
      tr(es: 'Para qué sirve', en: 'What it is for');
  static String get circleBuildToWheel =>
      tr(es: 'Ir a la rueda', en: 'Go to the wheel');
  static String circleBuildRingLabel(int reached, String key, String signature) =>
      tr(
        es: 'Círculo con $reached de 12 tonalidades. Actual: $key, armadura $signature.',
        en: 'Circle with $reached of 12 keys. Current: $key, key signature $signature.',
      );
  static String get circleBuildPrevious => tr(es: 'Anterior', en: 'Previous');
  static String get circleBuildNext => tr(es: 'Siguiente', en: 'Next');
  static String get hubGuides => tr(es: 'Guías', en: 'Guides');
  static String get hubGuidesSub => tr(
    es: 'Recorridos por tema: géneros, técnica, escalas y teoría.',
    en: 'Topic tours: genres, technique, scales and theory.',
  );
  static String get hubCapo => tr(es: '¿Qué capo uso?', en: 'Which capo?');
  static String get hubCapoSub => tr(
    es: 'El traste y la forma abierta para cualquier tonalidad.',
    en: 'The fret and open shape for any key.',
  );
  static String get guidesTitle => tr(es: 'Guías', en: 'Guides');
  static String get guidesIntro => tr(
    es: 'Cada guía junta lecciones, escalas y módulos sobre un tema. Toca una '
        'para ver sus capítulos.',
    en: 'Each guide brings together lessons, scales and modules on one topic. '
        'Tap one to see its chapters.',
  );
  static String get guidesSearch =>
      tr(es: 'Buscar guías…', en: 'Search guides…');
  static String get guidesNoResults => tr(
    es: 'Ninguna guía coincide con tu búsqueda.',
    en: 'No guide matches your search.',
  );
  static String get guideNotFound =>
      tr(es: 'No encontramos esta guía.', en: 'We could not find this guide.');
  static String guideChapters(int count) => tr(
    es: count == 1 ? '1 capítulo' : '$count capítulos',
    en: count == 1 ? '1 chapter' : '$count chapters',
  );
  static String guideMinutes(int minutes) =>
      tr(es: 'unos $minutes min', en: 'about $minutes min');
  static String guideDoneCount(int done, int total) =>
      tr(es: '$done de $total hechos', en: '$done of $total done');
  static String get guideMarkDone =>
      tr(es: 'Marcar como hecho', en: 'Mark as done');
  static String get guideMarkPending =>
      tr(es: 'Marcar como pendiente', en: 'Mark as not done');
  static String get guideContinueHere =>
      tr(es: 'Sigue aquí', en: 'Continue here');
  static String get guideFinished =>
      tr(es: '¡Guía terminada!', en: 'Guide finished!');
  static String get guideNext => tr(es: 'Siguiente guía', en: 'Next guide');
  static String get guidesInProgress =>
      tr(es: 'Sigue donde ibas', en: 'Pick up where you left off');
  static String guideOpenLesson(String title) =>
      tr(es: 'Lección: $title', en: 'Lesson: $title');
  static String guideOpenChord(String chord) =>
      tr(es: 'Ver el acorde $chord', en: 'See the $chord chord');
  static String get guideOpenCapo =>
      tr(es: 'Calcular el capo', en: 'Find the capo fret');
  static String guideOpenModuleNamed(String name) =>
      tr(es: 'Abrir $name', en: 'Open $name');
  static String get capoTitle => tr(es: '¿Qué capo uso?', en: 'Which capo?');
  static String get capoIntro => tr(
    es: 'Elige la tonalidad que quieres que suene. Cada forma abierta te dice '
        'en qué traste va el capo y qué tocas con la mano.',
    en: 'Pick the key you want to hear. Each open shape tells you which fret '
        'the capo goes on and what your hand plays.',
  );
  static String get capoKey => tr(es: 'Tonalidad', en: 'Key');
  static String get capoMajor => tr(es: 'Mayor', en: 'Major');
  static String get capoMinor => tr(es: 'Menor', en: 'Minor');
  static String capoResults(String key) =>
      tr(es: 'Para que suene en $key', en: 'To sound in $key');
  static String capoNone(String shape) =>
      tr(es: 'Sin capo · forma de $shape', en: 'No capo · $shape shape');
  static String capoAt(int fret, String shape) => tr(
    es: 'Capo en el traste $fret · forma de $shape',
    en: 'Capo on fret $fret · $shape shape',
  );
  static String capoSounds(String chord) =>
      tr(es: 'suena $chord', en: 'sounds $chord');
  static String get capoTurnTitle =>
      tr(es: 'Gira una progresión', en: 'Turn a progression');
  static String capoTurnIntro(String key) => tr(
    es: 'Elige una progresión: así la tocas en $key con cada capo.',
    en: 'Pick a progression: this is how you play it in $key with each capo.',
  );
  static String get capoProgression =>
      tr(es: 'Progresión', en: 'Progression');
  static String capoTurnInKey(String key, String chords) =>
      tr(es: 'En $key: $chords', en: 'In $key: $chords');
  static String get capoRule => tr(
    es: 'El capo sube cada cuerda un semitono por traste. Solo se muestran '
        'capos hasta el traste 7: más arriba los trastes quedan muy juntos.',
    en: 'A capo raises every string a half step per fret. Only capos up to fret '
        '7 are shown: higher up the frets get too close together.',
  );
  static String get hubWorkouts =>
      tr(es: 'Rutinas de escala', en: 'Scale workouts');
  static String get hubWorkoutsSub => tr(
    es: 'Ejercicios por nivel en cualquier escala y tónica, para escuchar y tocar.',
    en: 'Exercises by level in any scale and key, to hear and play.',
  );
  static String get workoutsTitle =>
      tr(es: 'Rutinas de escala', en: 'Scale workouts');
  static String get workoutsIntro => tr(
    es: 'Cada rutina sale de una posición real de la escala. Escúchala, sigue la '
        'nota marcada y luego tócala tú al mismo tempo.',
    en: 'Each workout comes from a real scale position. Listen to it, follow the '
        'highlighted note, then play it yourself at the same tempo.',
  );
  static String get workoutsScale => tr(es: 'Escala', en: 'Scale');
  static String get workoutsPrevious =>
      tr(es: 'Posición anterior', en: 'Previous position');
  static String get workoutsNext =>
      tr(es: 'Posición siguiente', en: 'Next position');
  static String workoutsPosition(
    String position,
    String system,
    int start,
    int end,
  ) => tr(
    es: '$position · $system · trastes $start–$end',
    en: '$position · $system · frets $start–$end',
  );
  static String workoutsPositionCount(int index, int total) =>
      tr(es: '$index de $total, de grave a aguda', en: '$index of $total, low to high');
  static String get workoutsAddDown =>
      tr(es: 'Agregar la bajada', en: 'Add the way down');
  static String get workoutsOnlyUp =>
      tr(es: 'Solo la subida', en: 'Only the way up');
  static String get todayPlanTitle =>
      tr(es: 'Práctica de hoy', en: "Today's practice");
  static String get todayPlanDone =>
      tr(es: '¡Listo por hoy!', en: 'Done for today!');
  static String get todayLessonsAllDone =>
      tr(es: 'Terminaste el camino', en: 'You finished the path');
  static String todayWorkout(String scale) =>
      tr(es: 'Rutina: $scale', en: 'Workout: $scale');
  static String get todayWorkoutHint =>
      tr(es: 'Escúchala y tócala al tempo', en: 'Listen, then play it in time');
  static String todayTechnique(String exercise) =>
      tr(es: 'Técnica: $exercise', en: 'Technique: $exercise');
  static String get todayTechniqueHint => tr(
    es: 'Guarda un tempo limpio',
    en: 'Save a clean tempo',
  );
  static String get hubMelodies => tr(es: 'Melodías', en: 'Melodies');
  static String get hubMelodiesSub => tr(
    es: 'Curso por niveles: de las cuerdas agudas a tocar canciones de memoria.',
    en: 'A course by levels: from the high strings to playing songs by heart.',
  );
  static String get melodiesIntro => tr(
    es: 'Aprende a tocar melodías en las cuerdas agudas y luego más arriba del '
        'mástil. Cada ejercicio y canción da hasta tres estrellas según el '
        'tempo al que te sale limpio.',
    en: 'Learn to play melodies on the high strings and then higher up the '
        'neck. Each exercise and song gives up to three stars by the tempo '
        'you can play it cleanly.',
  );
  static String courseLevel(int level) =>
      tr(es: 'Nivel $level', en: 'Level $level');
  static String get courseTheory => tr(es: 'Teoría', en: 'Theory');
  static String get courseExercise => tr(es: 'Ejercicio', en: 'Exercise');
  static String get courseSong => tr(es: 'Canción', en: 'Song');
  static String get courseResults =>
      tr(es: 'Resultados del curso', en: 'Course results');
  static String get courseStarsLabel => tr(es: 'estrellas', en: 'stars');
  static String get courseSongsLabel => tr(es: 'canciones', en: 'songs');
  static String get courseStarRule => tr(
    es: '★ a 60 BPM · ★★ a 80 · ★★★ a 100',
    en: '★ at 60 BPM · ★★ at 80 · ★★★ at 100',
  );
  static String get courseRead => tr(es: 'Entendido', en: 'Got it');
  static String get courseUnread =>
      tr(es: 'Marcar como pendiente', en: 'Mark as not done');
  static String get courseNext => tr(es: 'Siguiente paso', en: 'Next step');
  static String get melodiesEvenRhythm => tr(
    es: 'Suena con todas las notas iguales (corcheas): sirve para aprender '
        'las notas; el ritmo de la canción lo pones tú.',
    en: 'It plays every note the same length (eighth notes): it is for '
        "learning the notes; you add the song's rhythm.",
  );
  static String get hubMultiDay =>
      tr(es: 'Retos de la semana', en: 'Weekly challenges');
  static String get hubMultiDaySub => tr(
    es: 'Practica varios días: racha, Técnica, rutinas, lecciones, Oído y Ritmo.',
    en: 'Practice on several days: streak, Technique, workouts, lessons, Ear and Rhythm.',
  );
  static String get multiDayIntro => tr(
    es: 'Se superan solos: cada día que practicas un módulo cuenta. Los '
        'círculos son los últimos 7 días, el de la derecha es hoy.',
    en: 'They complete themselves: every day you practice a module counts. '
        'The circles are the last 7 days; the one on the right is today.',
  );
  static String multiDayPassed(int passed, int total) => tr(
    es: '$passed de $total superados',
    en: '$passed of $total completed',
  );
  static String get hubTechnique =>
      tr(es: 'Técnica', en: 'Technique');
  static String get hubTechniqueSub => tr(
    es: 'Cromático, araña, diagonal y salto de cuerda, con tu récord de tempo.',
    en: 'Chromatic, spider, diagonal and string skipping, with your tempo record.',
  );
  static String get techniqueIntro => tr(
    es: 'Un dedo por traste en una ventana de cuatro trastes. Escucha, tócalo '
        'al tempo y, cuando salga limpio, guarda el récord y sube 5 BPM.',
    en: 'One finger per fret in a four-fret window. Listen, play it at the '
        'tempo and, when it comes out clean, save the record and go up 5 BPM.',
  );
  static String get techniqueStartFret =>
      tr(es: 'Empieza en el traste', en: 'Start at fret');
  static String get techniqueTempo => tr(es: 'Tempo', en: 'Tempo');
  static String get techniqueSlower => tr(es: 'Más lento', en: 'Slower');
  static String get techniqueFaster => tr(es: 'Más rápido', en: 'Faster');
  static String techniqueBpm(int bpm) => '$bpm BPM';
  static String techniqueRecord(int bpm) =>
      tr(es: 'Récord: $bpm BPM', en: 'Record: $bpm BPM');
  static String get techniqueNoRecord =>
      tr(es: 'Sin récord todavía', en: 'No record yet');
  static String techniqueTryNext(int bpm) =>
      tr(es: 'Prueba a $bpm BPM', en: 'Try $bpm BPM');
  static String techniqueSaveClean(int bpm) =>
      tr(es: 'Me salió limpio a $bpm BPM', en: 'Clean at $bpm BPM');
  static String workoutsNoteCount(int count) =>
      tr(es: '$count notas', en: '$count notes');
  static String get tabListen => tr(es: 'Escuchar', en: 'Listen');
  static String get tabStop => tr(es: 'Detener', en: 'Stop');
  static String tabAtBpm(int bpm) =>
      tr(es: 'a $bpm BPM, en corcheas', en: 'at $bpm BPM, in eighth notes');
  static String guideOpenWorkout(String scale) =>
      tr(es: 'Rutinas de $scale', en: '$scale workouts');
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
  static String get unitNotFound =>
      tr(es: 'No encontramos esta unidad.', en: 'We could not find this unit.');
  static String get lessonsTapTrack => tr(
    es: 'Toca un camino para elegirlo.',
    en: 'Tap a path to choose it.',
  );
  static String get challengePassed => tr(es: 'Superado', en: 'Passed');
  static String challengeRhythmBest(int best, int goal) => tr(
    es: 'Récord: $best %\nMeta: $goal %',
    en: 'Best: $best%\nGoal: $goal%',
  );
  static String challengeEarBest(int best, int goal) => tr(
    es: 'Mejor racha: $best\nMeta: $goal',
    en: 'Best streak: $best\nGoal: $goal',
  );
  static String lessonsLevel(int level) =>
      tr(es: 'Nivel $level', en: 'Level $level');
  static String get lessonsLevelHint => tr(
    es: 'Para cuando termines el nivel anterior',
    en: 'For when you finish the level before',
  );
  static String trackLevel(String track, int level) =>
      '$track · ${lessonsLevel(level)}';
  static String get lessonsResume => tr(es: 'Continuar', en: 'Continue');
  static String get lessonsReview => tr(es: 'Repasar', en: 'Review');
  static String unitPosition(int index, int total) =>
      tr(es: 'Unidad $index de $total', en: 'Unit $index of $total');
  static String get unitLessons => tr(es: 'Lecciones', en: 'Lessons');
  static String get unitChallenge =>
      tr(es: 'Reto del nivel', en: 'Level challenge');
  static String get unitResults =>
      tr(es: 'Resultados de la unidad', en: 'Unit results');
  static String get unitResultLessons => tr(es: 'lecciones', en: 'lessons');
  static String get unitResultMinutes =>
      tr(es: 'min practicados', en: 'min practiced');
  static String get unitResultChords => tr(es: 'acordes', en: 'chords');
  static String get unitResultNotes =>
      tr(es: 'notas en tablatura', en: 'tab notes');
  static String get unitNext => tr(es: 'Siguiente unidad', en: 'Next unit');
  static String get unitEndOfPath => tr(
    es: 'Es la última unidad de este camino.',
    en: 'This is the last unit on this path.',
  );
  static String lessonChordList(String chords) =>
      tr(es: 'Acordes: $chords', en: 'Chords: $chords');
  static String lessonTabNotes(int notes) =>
      tr(es: 'Tablatura · $notes notas', en: 'Tab · $notes notes');
  static String lessonsUnitCount(int lessons, int minutes) => tr(
    es: '$lessons lecciones · unos $minutes min',
    en: '$lessons lessons · about $minutes min',
  );
  static String get lessonTab => tr(es: 'Tablatura', en: 'Tablature');
  static String get lessonTabHint => tr(
    es: 'Arriba la 1ª cuerda (mi aguda). El número es el traste; 0 = al aire.',
    en: 'The 1st string (high E) is on top. The number is the fret; 0 = open.',
  );
  static String lessonTabLabel(String notes) =>
      tr(es: 'Tablatura: $notes', en: 'Tablature: $notes');
  static String lessonTabNote(int string, int fret) => tr(
    es: 'cuerda $string, traste $fret',
    en: 'string $string, fret $fret',
  );
  static String get lessonOpenProgressions =>
      tr(es: 'Abrir Progresiones', en: 'Open Progressions');
  static String get lessonOpenDoubleStops =>
      tr(es: 'Abrir los double stops', en: 'Open double stops');
  static String get lessonOpenCircle =>
      tr(es: 'Abrir el círculo de quintas', en: 'Open the circle of fifths');
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
  static String get scaleFingering => tr(es: 'Digitación', en: 'Fingering');
  static String get scaleFingeringTitle =>
      tr(es: 'Elige una digitación', en: 'Choose a fingering');
  static String get scaleWholeNeck =>
      tr(es: 'Todo el mástil', en: 'Whole neck');
  static String scaleFretRange(int start, int end) =>
      tr(es: 'trastes $start–$end', en: 'frets $start–$end');
  static String scalePatternContext(
    String position,
    String system,
    int start,
    int end,
  ) => '$position · $system · ${scaleFretRange(start, end)}';
  static String scalePreviewHint(String position, String system) => tr(
    es: 'Vista previa: $position · $system. Amplía para ver todo el mástil y '
        'elegir sistema o digitación.',
    en: 'Preview: $position · $system. Expand to see the whole neck and choose '
        'a system or fingering.',
  );
  static String get scaleExpandBoard =>
      tr(es: 'Ampliar diapasón', en: 'Expand fretboard');
  static String get neckIntervals => tr(es: 'Intervalos', en: 'Intervals');
  static String get neckNotes => tr(es: 'Notas', en: 'Notes');
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
