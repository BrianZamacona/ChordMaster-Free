import '../../core/i18n/tr.dart';
import 'lesson.dart';

/// El camino de aprendizaje: Fundamentos para todos y, al terminarlo, dos
/// caminos (rítmica y líder). Cada [LessonUnit] es un nodo del mapa y el
/// orden de la lista es el orden de estudio.
///
/// Lo que estas lecciones afirman sobre acordes y escalas (qué cuerdas suenan,
/// qué dedos se mueven, qué notas tiene una escala) lo verifica
/// `test/domain/lessons/curriculum_test.dart` contra `chords.json` y
/// `scales_master.json`.
const List<Lesson> curriculum = [
  // ── Fundamentos ──────────────────────────────────────────────────────────
  Lesson(
    id: 'f1_meet_guitar',
    unit: _firstSteps,
    title: LocalizedText(es: 'Conoce tu guitarra', en: 'Meet your guitar'),
    body: LocalizedText(
      es: 'Las cuerdas se numeran de la más delgada (1ª, mi agudo) a la más '
          'gruesa (6ª, mi grave). Al aire, de la 6ª a la 1ª, suenan E A D G B E.',
      en: 'Strings are numbered from the thinnest (1st, high E) to the '
          'thickest (6th, low E). Open, from the 6th to the 1st, they sound '
          'E A D G B E.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca cada cuerda al aire de la 6ª a la 1ª y di su nombre.',
        en: 'Play each open string from the 6th to the 1st and say its name.',
      ),
      LocalizedText(
        es: 'Pisa justo detrás del traste, no encima de él.',
        en: 'Press right behind the fret, not on top of it.',
      ),
      LocalizedText(
        es: 'Usa la punta del dedo y mantén cortas las uñas de la mano que pisa.',
        en: 'Use your fingertip and keep the nails of your fretting hand short.',
      ),
    ],
    minutes: 5,
    tool: LessonTool.tuner,
  ),
  Lesson(
    id: 'f2_tune',
    unit: _firstSteps,
    title: LocalizedText(es: 'Afina tu guitarra', en: 'Tune your guitar'),
    body: LocalizedText(
      es: 'El afinador escucha cada cuerda por el micrófono y te dice si está '
          'grave o aguda. Afina siempre antes de practicar: una guitarra '
          'desafinada hace que los acordes bien puestos suenen mal.',
      en: 'The tuner listens to each string through the microphone and tells '
          'you if it is flat or sharp. Always tune before practicing: an '
          'out-of-tune guitar makes well-placed chords sound wrong.',
    ),
    steps: [
      LocalizedText(es: 'Empieza por la 6ª cuerda.', en: 'Start with the 6th string.'),
      LocalizedText(
        es: 'Si está grave, aprieta la clavija; si está aguda, aflójala.',
        en: 'If it is flat, tighten the tuning peg; if it is sharp, loosen it.',
      ),
      LocalizedText(
        es: 'Gira poco a poco y vuelve a tocar la cuerda.',
        en: 'Turn a little at a time and play the string again.',
      ),
    ],
    minutes: 5,
    tool: LessonTool.tuner,
  ),
  Lesson(
    id: 'f3_em_am',
    unit: _firstSteps,
    title: LocalizedText(
      es: 'Tus primeros acordes: Em y Am',
      en: 'Your first chords: Em and Am',
    ),
    body: LocalizedText(
      es: 'Em usa dos dedos y suenan las seis cuerdas. Am empieza en la 5ª '
          'cuerda: la 6ª no se toca.',
      en: 'Em uses two fingers and all six strings ring. Am starts on the 5th '
          'string: the 6th is not played.',
    ),
    steps: [
      LocalizedText(
        es: 'Arma Em y rasguea despacio: cada cuerda debe sonar limpia.',
        en: 'Fret Em and strum slowly: every string should ring clearly.',
      ),
      LocalizedText(
        es: 'Arma Am y revisa que el dedo 1 no apague la 1ª cuerda.',
        en: 'Fret Am and check that finger 1 does not mute the 1st string.',
      ),
      LocalizedText(
        es: 'Toca cada acorde cuatro veces seguidas.',
        en: 'Play each chord four times in a row.',
      ),
    ],
    minutes: 8,
    chords: ['Em', 'Am'],
  ),
  Lesson(
    id: 'f4_em_am_change',
    unit: _firstSteps,
    title: LocalizedText(es: 'Cambio Em ↔ Am', en: 'Em ↔ Am change'),
    body: LocalizedText(
      es: 'Para pasar de Em a Am, los dedos 2 y 3 bajan juntos una cuerda (de '
          'la 5ª y 4ª a la 4ª y 3ª) y el dedo 1 entra en la 2ª cuerda.',
      en: 'To go from Em to Am, fingers 2 and 3 move down one string together '
          '(from the 5th and 4th to the 4th and 3rd) and finger 1 goes on the '
          '2nd string.',
    ),
    steps: [
      LocalizedText(
        es: 'Cambia sin rasguear, solo con la mano que pisa.',
        en: 'Change without strumming, using only your fretting hand.',
      ),
      LocalizedText(
        es: 'Mueve los dedos 2 y 3 como un bloque.',
        en: 'Move fingers 2 and 3 as one block.',
      ),
      LocalizedText(
        es: 'Cuando salga solo, rasguea una vez cada acorde.',
        en: 'Once it comes easily, strum each chord once.',
      ),
    ],
    minutes: 5,
    chords: ['Em', 'Am'],
  ),
  Lesson(
    id: 'f5_d_a_e',
    unit: _openChords,
    title: LocalizedText(es: 'D, A y E', en: 'D, A and E'),
    body: LocalizedText(
      es: 'Tres acordes mayores de miles de canciones. D se toca desde la 4ª '
          'cuerda, A desde la 5ª y E con las seis.',
      en: 'Three major chords found in thousands of songs. D is played from '
          'the 4th string, A from the 5th and E on all six.',
    ),
    steps: [
      LocalizedText(
        es: 'En D, los dedos 1, 3 y 2 forman un triángulo.',
        en: 'In D, fingers 1, 3 and 2 form a triangle.',
      ),
      LocalizedText(
        es: 'En A, los tres dedos caben juntos en el traste 2.',
        en: 'In A, all three fingers fit together on fret 2.',
      ),
      LocalizedText(
        es: 'E tiene la forma de Am, una cuerda más arriba.',
        en: 'E has the shape of Am, one string higher.',
      ),
    ],
    minutes: 10,
    chords: ['D', 'A', 'E'],
  ),
  Lesson(
    id: 'f6_g_c',
    unit: _openChords,
    title: LocalizedText(es: 'G y C', en: 'G and C'),
    body: LocalizedText(
      es: 'G y C piden abrir más la mano. Es normal que al principio una '
          'cuerda suene apagada.',
      en: 'G and C ask you to stretch your hand more. It is normal for a '
          'string to sound muted at first.',
    ),
    steps: [
      LocalizedText(
        es: 'En G, el meñique (dedo 4) va en la 1ª cuerda, traste 3.',
        en: 'In G, your pinky (finger 4) goes on the 1st string, fret 3.',
      ),
      LocalizedText(
        es: 'En C, arquea los dedos para no apagar la 1ª cuerda.',
        en: 'In C, arch your fingers so you do not mute the 1st string.',
      ),
      LocalizedText(
        es: 'Alterna G y C, cuatro rasgueos cada uno.',
        en: 'Alternate G and C, four strums each.',
      ),
    ],
    minutes: 10,
    chords: ['G', 'C'],
  ),
  Lesson(
    id: 'f7_quarter_strum',
    unit: _openChords,
    title: LocalizedText(es: 'Rasgueo en negras', en: 'Quarter-note strumming'),
    body: LocalizedText(
      es: 'Un rasgueo hacia abajo en cada pulso. Si el pulso es estable, todo '
          'lo demás se acomoda.',
      en: 'One downstrum on every beat. If the beat is steady, everything '
          'else falls into place.',
    ),
    steps: [
      LocalizedText(es: 'Pon el metrónomo a 70 BPM.', en: 'Set the metronome to 70 BPM.'),
      LocalizedText(
        es: 'Rasguea G hacia abajo en cada clic.',
        en: 'Strum G downward on every click.',
      ),
      LocalizedText(
        es: 'Cuenta en voz alta: 1, 2, 3, 4.',
        en: 'Count out loud: 1, 2, 3, 4.',
      ),
    ],
    minutes: 6,
    chords: ['G'],
    strumPattern: 'D D D D ',
    tool: LessonTool.metronome,
    bpm: 70,
  ),
  Lesson(
    id: 'f8_g_c_d',
    unit: _openChords,
    title: LocalizedText(es: 'Progresión G – C – D', en: 'G – C – D progression'),
    body: LocalizedText(
      es: 'Tu primera progresión completa: cuatro rasgueos por acorde y '
          'vuelta a empezar. Al terminarla eliges tu camino.',
      en: 'Your first full progression: four strums per chord, then start '
          'over. After this lesson you choose your path.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca G, C y D con cuatro rasgueos cada uno.',
        en: 'Play G, C and D with four strums each.',
      ),
      LocalizedText(
        es: 'Prepara el siguiente acorde durante el último rasgueo.',
        en: 'Get ready for the next chord during the last strum.',
      ),
      LocalizedText(
        es: 'Vuelve a G y repite sin detenerte.',
        en: 'Go back to G and repeat without stopping.',
      ),
    ],
    minutes: 8,
    chords: ['G', 'C', 'D'],
    tool: LessonTool.metronome,
    bpm: 70,
  ),

  // ── Guitarra rítmica ─────────────────────────────────────────────────────
  Lesson(
    id: 'r1_eighths',
    unit: _strumming,
    title: LocalizedText(es: 'Corcheas: abajo y arriba', en: 'Eighth notes: down and up'),
    body: LocalizedText(
      es: 'La mano que rasguea nunca se detiene: abajo en cada número y arriba '
          'en cada "y". Así el ritmo queda parejo.',
      en: 'Your strumming hand never stops: down on every number and up on '
          'every "and". That keeps the rhythm even.',
    ),
    steps: [
      LocalizedText(es: 'Cuenta "1 y 2 y 3 y 4 y".', en: 'Count "1 and 2 and 3 and 4 and".'),
      LocalizedText(
        es: 'Abajo en los números, arriba en las "y".',
        en: 'Down on the numbers, up on the "ands".',
      ),
      LocalizedText(
        es: 'Empieza a 70 BPM y sube de 5 en 5.',
        en: 'Start at 70 BPM and go up 5 at a time.',
      ),
    ],
    minutes: 6,
    chords: ['Em'],
    strumPattern: 'DUDUDUDU',
    tool: LessonTool.metronome,
    bpm: 70,
  ),
  Lesson(
    id: 'r2_pop_strum',
    unit: _strumming,
    title: LocalizedText(es: 'El rasgueo pop', en: 'The pop strum'),
    body: LocalizedText(
      es: 'Abajo, abajo-arriba, arriba-abajo-arriba. En los huecos la mano '
          'sigue moviéndose, solo que sin tocar las cuerdas.',
      en: 'Down, down-up, up-down-up. In the gaps your hand keeps moving, it '
          'just does not touch the strings.',
    ),
    steps: [
      LocalizedText(
        es: 'Tócalo en C sin cambiar de acorde.',
        en: 'Play it on C without changing chords.',
      ),
      LocalizedText(
        es: 'Cuenta en voz alta para no perder el lugar de los huecos.',
        en: 'Count out loud so you do not lose track of the gaps.',
      ),
      LocalizedText(
        es: 'Cuando salga solo, súbele al metrónomo.',
        en: 'Once it comes easily, speed up the metronome.',
      ),
    ],
    minutes: 8,
    chords: ['C'],
    strumPattern: 'D DU UDU',
    tool: LessonTool.metronome,
    bpm: 80,
  ),
  Lesson(
    id: 'r3_g_d_em_c',
    unit: _strumming,
    title: LocalizedText(es: 'G – D – Em – C', en: 'G – D – Em – C'),
    body: LocalizedText(
      es: 'Una de las progresiones más usadas en el pop. Toca un compás del '
          'rasgueo pop por acorde.',
      en: 'One of the most used progressions in pop. Play one bar of the pop '
          'strum per chord.',
    ),
    steps: [
      LocalizedText(
        es: 'Practica primero el cambio D → Em, que es el más difícil.',
        en: 'Practice the D → Em change first; it is the hardest one.',
      ),
      LocalizedText(
        es: 'Toca la progresión rasgueando solo hacia abajo.',
        en: 'Play the progression with downstrums only.',
      ),
      LocalizedText(es: 'Agrega el rasgueo pop.', en: 'Add the pop strum.'),
    ],
    minutes: 10,
    chords: ['G', 'D', 'Em', 'C'],
    strumPattern: 'D DU UDU',
    tool: LessonTool.metronome,
    bpm: 80,
  ),
  Lesson(
    id: 'r4_three_four',
    unit: _strumming,
    title: LocalizedText(es: 'Ritmo en 3/4', en: 'Playing in 3/4'),
    body: LocalizedText(
      es: 'Tres pulsos por compás en lugar de cuatro: el compás del vals y de '
          'muchas baladas.',
      en: 'Three beats per bar instead of four: the time signature of the '
          'waltz and of many ballads.',
    ),
    steps: [
      LocalizedText(
        es: 'Pon el metrónomo en 3/4: el acento marca el inicio de cada compás.',
        en: 'Set the metronome to 3/4: the accent marks the start of each bar.',
      ),
      LocalizedText(
        es: 'Rasguea el 1 con más fuerza que el 2 y el 3.',
        en: 'Strum beat 1 harder than beats 2 and 3.',
      ),
      LocalizedText(
        es: 'Toca C, G y Am, un compás cada uno.',
        en: 'Play C, G and Am, one bar each.',
      ),
    ],
    minutes: 8,
    chords: ['C', 'G', 'Am'],
    strumPattern: 'D DUDU',
    tool: LessonTool.metronome,
    bpm: 90,
  ),
  Lesson(
    id: 'r5_barre',
    unit: _beyondOpen,
    title: LocalizedText(es: 'Tu primera cejilla: F y Bm', en: 'Your first barre: F and Bm'),
    body: LocalizedText(
      es: 'En la cejilla el dedo 1 pisa varias cuerdas a la vez. En F cubre '
          'las seis cuerdas en el traste 1; en Bm, de la 5ª a la 1ª en el traste 2.',
      en: 'In a barre chord, finger 1 presses several strings at once. In F '
          'it covers all six strings at fret 1; in Bm, the 5th to the 1st at '
          'fret 2.',
    ),
    steps: [
      LocalizedText(
        es: 'Apoya el costado del dedo 1, no la yema, y acerca el codo al cuerpo.',
        en: 'Use the side of finger 1, not the pad, and bring your elbow in.',
      ),
      LocalizedText(
        es: 'Pisa solo la cejilla y toca cuerda por cuerda hasta que todas suenen.',
        en: 'Press only the barre and play string by string until they all ring.',
      ),
      LocalizedText(
        es: 'Agrega los demás dedos y alterna C y F.',
        en: 'Add the other fingers and alternate C and F.',
      ),
    ],
    minutes: 12,
    chords: ['F', 'Bm'],
  ),
  Lesson(
    id: 'r6_power_chords',
    unit: _beyondOpen,
    title: LocalizedText(es: 'Power chords', en: 'Power chords'),
    body: LocalizedText(
      es: 'Un power chord tiene solo la tónica y la quinta. Como no tiene '
          'tercera, no es mayor ni menor y encaja en casi cualquier canción de '
          'rock.',
      en: 'A power chord has only the root and the fifth. With no third it is '
          'neither major nor minor, so it fits almost any rock song.',
    ),
    steps: [
      LocalizedText(
        es: 'Apaga las cuerdas que no se tocan apoyando los dedos suavemente.',
        en: 'Mute the strings you do not play by resting your fingers on them.',
      ),
      LocalizedText(
        es: 'Mueve la forma de G5 por el mástil: la tónica queda en la 6ª cuerda.',
        en: 'Slide the G5 shape along the neck: the root stays on the 6th string.',
      ),
      LocalizedText(
        es: 'Rasguea solo hacia abajo, con golpes cortos.',
        en: 'Strum down only, with short strokes.',
      ),
    ],
    minutes: 8,
    chords: ['E5', 'A5', 'G5'],
  ),
  Lesson(
    id: 'r7_palm_mute',
    unit: _beyondOpen,
    title: LocalizedText(es: 'Apagado con la palma', en: 'Palm muting'),
    body: LocalizedText(
      es: 'Apoya el borde de la mano que rasguea sobre las cuerdas, justo '
          'donde salen del puente. El sonido se vuelve corto y percusivo.',
      en: 'Rest the edge of your strumming hand on the strings, right where '
          'they leave the bridge. The sound becomes short and percussive.',
    ),
    steps: [
      LocalizedText(
        es: 'Si suena totalmente apagado, mueve la palma hacia el puente.',
        en: 'If it sounds fully muted, move your palm toward the bridge.',
      ),
      LocalizedText(
        es: 'Toca E5 en corcheas, todas hacia abajo.',
        en: 'Play E5 in eighth notes, all downstrokes.',
      ),
      LocalizedText(
        es: 'Alterna un compás apagado y uno abierto.',
        en: 'Alternate one muted bar and one open bar.',
      ),
    ],
    minutes: 6,
    chords: ['E5'],
    strumPattern: 'DDDDDDDD',
    tool: LessonTool.metronome,
    bpm: 90,
  ),
  Lesson(
    id: 'r8_twelve_bar',
    unit: _beyondOpen,
    title: LocalizedText(es: 'Blues de 12 compases', en: '12-bar blues'),
    body: LocalizedText(
      es: 'Doce compases con tres acordes: cuatro de A7, dos de D7, dos de A7, '
          'y luego E7, D7, A7 y E7, uno cada uno.',
      en: 'Twelve bars with three chords: four of A7, two of D7, two of A7, '
          'then E7, D7, A7 and E7, one each.',
    ),
    steps: [
      LocalizedText(
        es: 'Cuenta los compases en voz alta mientras tocas.',
        en: 'Count the bars out loud as you play.',
      ),
      LocalizedText(es: 'Cuatro rasgueos por compás.', en: 'Four strums per bar.'),
      LocalizedText(
        es: 'Repite la vuelta hasta que ya no tengas que contar.',
        en: 'Repeat the form until you no longer need to count.',
      ),
    ],
    minutes: 10,
    chords: ['A7', 'D7', 'E7'],
    tool: LessonTool.metronome,
    bpm: 90,
  ),

  Lesson(
    id: 'r9_arpeggio',
    unit: _fingerstyle,
    title: LocalizedText(es: 'Arpegio con los dedos', en: 'Fingerpicked arpeggio'),
    body: LocalizedText(
      es: 'El pulgar (p) toca el bajo y los dedos índice (i), medio (m) y '
          'anular (a) tocan la 3ª, la 2ª y la 1ª cuerda. En Am y en C el bajo '
          'está en la 5ª cuerda.',
      en: 'Your thumb (p) plays the bass and your index (i), middle (m) and '
          'ring (a) fingers play the 3rd, 2nd and 1st strings. In Am and C the '
          'bass is on the 5th string.',
    ),
    steps: [
      LocalizedText(
        es: 'Apoya i, m y a en la 3ª, 2ª y 1ª cuerda.',
        en: 'Rest i, m and a on the 3rd, 2nd and 1st strings.',
      ),
      LocalizedText(
        es: 'Toca en orden: p, i, m, a, una nota por clic.',
        en: 'Play in order: p, i, m, a, one note per click.',
      ),
      LocalizedText(
        es: 'Repite en Am y en C sin cambiar el orden.',
        en: 'Repeat on Am and C without changing the order.',
      ),
    ],
    minutes: 8,
    chords: ['Am', 'C'],
    tool: LessonTool.metronome,
    bpm: 60,
  ),
  Lesson(
    id: 'r10_alternating_bass',
    unit: _fingerstyle,
    title: LocalizedText(es: 'Bajo alterno', en: 'Alternating bass'),
    body: LocalizedText(
      es: 'El pulgar alterna dos bajos mientras los dedos tocan arriba. En C '
          'alterna la 5ª cuerda (C) y la 4ª (E); en G, la 6ª (G) y la 4ª (D).',
      en: 'Your thumb alternates two bass notes while your fingers play on '
          'top. In C it alternates the 5th string (C) and the 4th (E); in G, '
          'the 6th (G) and the 4th (D).',
    ),
    steps: [
      LocalizedText(
        es: 'Practica solo el pulgar: 5ª, 4ª, 5ª, 4ª en C.',
        en: 'Practice the thumb alone: 5th, 4th, 5th, 4th on C.',
      ),
      LocalizedText(
        es: 'Agrega i y m juntos entre cada bajo.',
        en: 'Add i and m together between each bass note.',
      ),
      LocalizedText(
        es: 'Pasa a G: el pulgar alterna 6ª y 4ª.',
        en: 'Move to G: the thumb alternates the 6th and 4th.',
      ),
    ],
    minutes: 10,
    chords: ['C', 'G'],
    tool: LessonTool.metronome,
    bpm: 60,
  ),

  // ── Guitarra líder ───────────────────────────────────────────────────────
  Lesson(
    id: 'l1_minor_pentatonic',
    unit: _scalesAndTechnique,
    title: LocalizedText(es: 'Pentatónica menor en A', en: 'A minor pentatonic'),
    body: LocalizedText(
      es: 'Cinco notas (A C D E G) para improvisar en rock, blues y pop. La '
          'primera caja empieza en el traste 5 de la 6ª cuerda.',
      en: 'Five notes (A C D E G) for improvising in rock, blues and pop. The '
          'first box starts at fret 5 on the 6th string.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca la escala subiendo y bajando, una nota por clic a 60 BPM.',
        en: 'Play the scale up and down, one note per click at 60 BPM.',
      ),
      LocalizedText(
        es: 'Un dedo por traste: índice en el 5, anular en el 7, meñique en el 8.',
        en: 'One finger per fret: index on 5, ring on 7, pinky on 8.',
      ),
      LocalizedText(
        es: 'Improvisa usando solo tres notas antes de usar las cinco.',
        en: 'Improvise with only three notes before using all five.',
      ),
    ],
    minutes: 10,
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
    tool: LessonTool.metronome,
    bpm: 60,
  ),
  Lesson(
    id: 'l2_chromatic',
    unit: _scalesAndTechnique,
    title: LocalizedText(es: 'Calentamiento cromático', en: 'Chromatic warm-up'),
    body: LocalizedText(
      es: 'Trastes 5, 6, 7 y 8 en cada cuerda, un dedo por traste. Fortalece '
          'los dedos y sincroniza las dos manos.',
      en: 'Frets 5, 6, 7 and 8 on every string, one finger per fret. It '
          'strengthens your fingers and syncs both hands.',
    ),
    steps: [
      LocalizedText(
        es: 'Usa púa alternada: abajo, arriba, abajo, arriba.',
        en: 'Use alternate picking: down, up, down, up.',
      ),
      LocalizedText(
        es: 'Deja cada dedo pisado hasta que lo necesites.',
        en: 'Keep each finger down until you need it.',
      ),
      LocalizedText(
        es: 'Empieza a 60 BPM, una nota por clic, y sube de 5 en 5.',
        en: 'Start at 60 BPM, one note per click, and go up 5 at a time.',
      ),
    ],
    minutes: 6,
    tool: LessonTool.metronome,
    bpm: 60,
  ),
  Lesson(
    id: 'l3_legato',
    unit: _scalesAndTechnique,
    title: LocalizedText(es: 'Hammer-on y pull-off', en: 'Hammer-ons and pull-offs'),
    body: LocalizedText(
      es: 'Ligados: tocas una nota con la púa y la siguiente solo con la mano '
          'que pisa. En el hammer-on golpeas la cuerda con un dedo; en el '
          'pull-off lo jalas para que la cuerda suene.',
      en: 'Legato: you pick one note and sound the next with your fretting '
          'hand only. A hammer-on strikes the string with a finger; a '
          'pull-off plucks it as the finger lifts.',
    ),
    steps: [
      LocalizedText(
        es: 'En la 3ª cuerda: toca el traste 5 y martilla el 7.',
        en: 'On the 3rd string: pick fret 5 and hammer on to fret 7.',
      ),
      LocalizedText(
        es: 'Ahora toca el 7 y jala el dedo para que suene el 5.',
        en: 'Now pick fret 7 and pull off so fret 5 sounds.',
      ),
      LocalizedText(
        es: 'La nota ligada debe sonar casi tan fuerte como la tocada con púa.',
        en: 'The slurred note should sound almost as loud as the picked one.',
      ),
    ],
    minutes: 8,
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
  ),
  Lesson(
    id: 'l4_bends',
    unit: _scalesAndTechnique,
    title: LocalizedText(es: 'Bends', en: 'Bends'),
    body: LocalizedText(
      es: 'Empujar la cuerda sube la nota. En un bend de un tono, el traste 7 '
          'de la 3ª cuerda debe llegar a sonar como el traste 9.',
      en: 'Pushing the string raises the pitch. In a whole-step bend, fret 7 '
          'on the 3rd string should end up sounding like fret 9.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca primero el traste 9 para tener la nota en el oído.',
        en: 'Play fret 9 first to get the target note in your ear.',
      ),
      LocalizedText(
        es: 'Empuja con tres dedos juntos, no con uno solo.',
        en: 'Push with three fingers together, not just one.',
      ),
      LocalizedText(
        es: 'Detente cuando la nota coincida con la del traste 9.',
        en: 'Stop when the pitch matches fret 9.',
      ),
    ],
    minutes: 8,
    tool: LessonTool.tuner,
  ),
  Lesson(
    id: 'l5_vibrato',
    unit: _expression,
    title: LocalizedText(es: 'Vibrato', en: 'Vibrato'),
    body: LocalizedText(
      es: 'Mover la nota ligeramente arriba y abajo de forma constante. Es lo '
          'que hace que una nota larga suene viva.',
      en: 'Moving the pitch slightly up and down at a steady rate. It is what '
          'makes a long note sound alive.',
    ),
    steps: [
      LocalizedText(
        es: 'Mueve la muñeca, no solo el dedo.',
        en: 'Move from the wrist, not just the finger.',
      ),
      LocalizedText(
        es: 'Busca un movimiento parejo, como el pulso del metrónomo.',
        en: 'Aim for an even motion, like the metronome pulse.',
      ),
      LocalizedText(
        es: 'Prueba vibratos lentos y rápidos sobre la misma nota.',
        en: 'Try slow and fast vibrato on the same note.',
      ),
    ],
    minutes: 6,
    tool: LessonTool.metronome,
    bpm: 60,
  ),
  Lesson(
    id: 'l6_blues_scale',
    unit: _expression,
    title: LocalizedText(es: 'Escala de blues en A', en: 'A blues scale'),
    body: LocalizedText(
      es: 'La escala de blues es la pentatónica menor más una nota de paso, '
          'la b5. En A esa nota es D#.',
      en: 'The blues scale is the minor pentatonic plus one passing note, the '
          'b5. In A that note is D#.',
    ),
    steps: [
      LocalizedText(
        es: 'Busca la b5 en el diapasón: está entre la 4 y la 5.',
        en: 'Find the b5 on the fretboard: it sits between the 4 and the 5.',
      ),
      LocalizedText(
        es: 'Toca la escala subiendo y bajando.',
        en: 'Play the scale up and down.',
      ),
      LocalizedText(
        es: 'Usa la b5 de paso, sin quedarte en ella.',
        en: 'Use the b5 in passing, without resting on it.',
      ),
    ],
    minutes: 8,
    chords: ['A7', 'D7', 'E7'],
    scale: LessonScale(scaleId: 'blues_minor', root: 9),
  ),
  Lesson(
    id: 'l7_major_pentatonic',
    unit: _expression,
    title: LocalizedText(es: 'Pentatónica mayor', en: 'Major pentatonic'),
    body: LocalizedText(
      es: 'C pentatónica mayor tiene las mismas notas que A pentatónica menor. '
          'Lo que cambia es la tónica: termina tus frases en C y suena más '
          'alegre, ideal para country y pop.',
      en: 'C major pentatonic has the same notes as A minor pentatonic. What '
          'changes is the root: end your phrases on C and it sounds brighter, '
          'great for country and pop.',
    ),
    steps: [
      LocalizedText(
        es: 'Compara las dos escalas en el diapasón.',
        en: 'Compare both scales on the fretboard.',
      ),
      LocalizedText(
        es: 'Toca la escala empezando y terminando en C.',
        en: 'Play the scale starting and ending on C.',
      ),
      LocalizedText(
        es: 'Improvisa sobre C y G, terminando cada frase en C.',
        en: 'Improvise over C and G, ending each phrase on C.',
      ),
    ],
    minutes: 8,
    chords: ['C', 'G'],
    scale: LessonScale(scaleId: 'pentatonic_major', root: 0),
  ),
  Lesson(
    id: 'l8_first_solo',
    unit: _expression,
    title: LocalizedText(es: 'Tu primer solo', en: 'Your first solo'),
    body: LocalizedText(
      es: 'Junta todo sobre un blues en A: pentatónica, ligados, bends y '
          'vibrato. Piensa en frases cortas con silencios entre ellas.',
      en: 'Put it all together over a blues in A: pentatonic, legato, bends '
          'and vibrato. Think in short phrases with space between them.',
    ),
    steps: [
      LocalizedText(
        es: 'Inventa una frase de cuatro notas y repítela.',
        en: 'Make up a four-note phrase and repeat it.',
      ),
      LocalizedText(
        es: 'Termina la frase con un bend o con vibrato.',
        en: 'End the phrase with a bend or with vibrato.',
      ),
      LocalizedText(
        es: 'Cambia una nota a la vez hasta que la frase sea tuya.',
        en: 'Change one note at a time until the phrase is your own.',
      ),
    ],
    minutes: 12,
    chords: ['A7', 'D7', 'E7'],
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
    tool: LessonTool.metronome,
    bpm: 80,
  ),
  Lesson(
    id: 'l9_low_string_notes',
    unit: _theNeck,
    title: LocalizedText(es: 'Notas en la 6ª y la 5ª cuerda', en: 'Notes on the 6th and 5th strings'),
    body: LocalizedText(
      es: 'En la 6ª cuerda: E al aire, F en el traste 1, G en el 3, A en el '
          '5, B en el 7, C en el 8 y D en el 10. En la 5ª: A al aire, B en el '
          '2, C en el 3, D en el 5, E en el 7, F en el 8 y G en el 10. En el '
          'traste 12 se repiten las cuerdas al aire, una octava arriba.',
      en: 'On the 6th string: E open, F at fret 1, G at 3, A at 5, B at 7, C '
          'at 8 and D at 10. On the 5th: A open, B at fret 2, C at 3, D at 5, '
          'E at 7, F at 8 and G at 10. At fret 12 the open strings repeat, one '
          'octave higher.',
    ),
    steps: [
      LocalizedText(
        es: 'Di el nombre de cada nota mientras la tocas.',
        en: 'Say the name of each note as you play it.',
      ),
      LocalizedText(
        es: 'Busca la misma nota en las dos cuerdas (por ejemplo C).',
        en: 'Find the same note on both strings (for example C).',
      ),
      LocalizedText(
        es: 'Usa estas notas para encontrar la tónica de un acorde con cejilla.',
        en: 'Use these notes to find the root of a barre chord.',
      ),
    ],
    minutes: 8,
  ),
  Lesson(
    id: 'l10_second_box',
    unit: _theNeck,
    title: LocalizedText(es: 'Segunda caja de la pentatónica', en: 'Second pentatonic box'),
    body: LocalizedText(
      es: 'La segunda caja de A pentatónica menor empieza en el traste 8 de la '
          '6ª cuerda, sobre C. Con dos cajas ya puedes moverte por el mástil.',
      en: 'The second box of A minor pentatonic starts at fret 8 on the 6th '
          'string, on C. With two boxes you can already move along the neck.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca la primera caja y sigue subiendo hasta la segunda.',
        en: 'Play the first box and keep climbing into the second.',
      ),
      LocalizedText(
        es: 'Busca las notas A en las dos cajas: son la tónica.',
        en: 'Find the A notes in both boxes: they are the root.',
      ),
      LocalizedText(
        es: 'Improvisa pasando de una caja a la otra.',
        en: 'Improvise moving from one box to the other.',
      ),
    ],
    minutes: 10,
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
  ),
];

const _firstSteps = LessonUnit(
  id: 'f_first_steps',
  track: LessonTrack.foundations,
  title: LocalizedText(es: 'Primeros pasos', en: 'First steps'),
  art: ChordArt('Em'),
);
const _openChords = LessonUnit(
  id: 'f_open_chords',
  track: LessonTrack.foundations,
  title: LocalizedText(es: 'Acordes abiertos', en: 'Open chords'),
  art: ChordArt('G'),
);
const _strumming = LessonUnit(
  id: 'r_strumming',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Rasgueo', en: 'Strumming'),
  art: StrumArt('D DU UDU'),
);
const _beyondOpen = LessonUnit(
  id: 'r_beyond_open',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Más allá de los abiertos', en: 'Beyond open chords'),
  art: ChordArt('F'),
);
const _fingerstyle = LessonUnit(
  id: 'r_fingerstyle',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Con los dedos', en: 'Fingerstyle'),
  art: ChordArt('C'),
);
const _scalesAndTechnique = LessonUnit(
  id: 'l_scales_technique',
  track: LessonTrack.lead,
  title: LocalizedText(es: 'Escalas y técnica', en: 'Scales and technique'),
  art: ScaleArt(LessonScale(scaleId: 'pentatonic_minor', root: 9)),
);
const _expression = LessonUnit(
  id: 'l_expression',
  track: LessonTrack.lead,
  title: LocalizedText(es: 'Expresión y solos', en: 'Expression and solos'),
  art: ScaleArt(LessonScale(scaleId: 'blues_minor', root: 9)),
);
const _theNeck = LessonUnit(
  id: 'l_the_neck',
  track: LessonTrack.lead,
  title: LocalizedText(es: 'El mástil', en: 'The neck'),
  art: NotesArt(['E', 'F', 'G', 'A', 'B', 'C', 'D']),
);

/// Retos al final de cada camino; se superan con el récord de un módulo de
/// práctica.
const List<LessonChallenge> challenges = [
  LessonChallenge(
    id: 'rc1_steady_beat',
    track: LessonTrack.rhythm,
    title: LocalizedText(es: 'Reto: pulso firme', en: 'Challenge: steady beat'),
    body: LocalizedText(
      es: 'Logra 85 % o más de precisión en el juego de ritmo.',
      en: 'Reach 85% accuracy or more in the rhythm game.',
    ),
    kind: ChallengeKind.rhythmAccuracy,
    goal: 85,
  ),
  LessonChallenge(
    id: 'lc1_ear',
    track: LessonTrack.lead,
    title: LocalizedText(es: 'Reto: oído afinado', en: 'Challenge: sharp ear'),
    body: LocalizedText(
      es: 'Reconoce 5 intervalos seguidos sin fallar en Oído.',
      en: 'Recognize 5 intervals in a row without a miss in Ear.',
    ),
    kind: ChallengeKind.earStreak,
    goal: 5,
  ),
];

/// Lecciones de [track], en orden.
List<Lesson> lessonsOf(LessonTrack track) =>
    [for (final l in curriculum) if (l.track == track) l];

/// Unidades de [track] en el orden del camino.
List<LessonUnit> unitsOf(LessonTrack track) {
  final units = <LessonUnit>[];
  for (final l in lessonsOf(track)) {
    if (!units.contains(l.unit)) units.add(l.unit);
  }
  return units;
}

/// Lecciones de [unit], en orden.
List<Lesson> lessonsOfUnit(LessonUnit unit) =>
    [for (final l in curriculum) if (l.unit == unit) l];

/// Retos de [track] (los muestra el mapa al final del camino).
List<LessonChallenge> challengesOf(LessonTrack track) =>
    [for (final c in challenges) if (c.track == track) c];

/// Lecciones por id.
final Map<String, Lesson> lessonsById = {for (final l in curriculum) l.id: l};

/// Unidades por id.
final Map<String, LessonUnit> unitsById = {
  for (final l in curriculum) l.unit.id: l.unit,
};
