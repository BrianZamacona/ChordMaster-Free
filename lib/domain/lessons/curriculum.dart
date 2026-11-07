import '../../core/i18n/tr.dart';
import 'lesson.dart';

/// El camino de aprendizaje: Fundamentos para todos (dos cursos: Primeros
/// pasos y Melodías) y, al terminarlo, dos caminos (rítmica y líder). Cada
/// [LessonUnit] es un nodo del mapa y [lessonUnits] da su orden.
///
/// Lo que estas lecciones afirman sobre acordes y escalas (qué cuerdas suenan,
/// qué dedos se mueven, qué notas tiene una escala) lo verifica
/// `test/domain/lessons/curriculum_test.dart` contra `chords.json` y
/// `scales_master.json`.
const List<Lesson> curriculum = [
  // ── Fundamentos ──────────────────────────────────────────────────────────
  Lesson(
    id: 'f3_em_am',
    unit: _moreOpenChords,
    title: LocalizedText(es: 'Em y Am', en: 'Em and Am'),
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
    unit: _moreOpenChords,
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
    unit: _moreOpenChords,
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

  // ── Guitarra rítmica, nivel 2 ──────────────────────────────────────────
  Lesson(
    id: 'r11_d_dm',
    unit: _openChords2,
    title: LocalizedText(es: 'D y Dm: mayor contra menor', en: 'D and Dm: major vs minor'),
    body: LocalizedText(
      es: 'Mayor y menor cambian en una sola nota, la 3ª. De D a Dm la 2ª y la 3ª cuerda no cambian: solo la 1ª pasa del traste 2 (F#) al traste 1 (F).',
      en: 'Major and minor differ by a single note, the 3rd. From D to Dm the 2nd and 3rd strings stay put: only the 1st moves from fret 2 (F#) to fret 1 (F).',
    ),
    steps: [
      LocalizedText(
        es: 'Toca D y luego Dm, escuchando el cambio de color.',
        en: 'Play D, then Dm, listening to the change in color.',
      ),
      LocalizedText(
        es: 'Mueve solo la 1ª cuerda; lo demás se queda.',
        en: 'Move only the 1st string; everything else stays.',
      ),
      LocalizedText(
        es: 'Alterna D y Dm con cuatro rasgueos cada uno.',
        en: 'Alternate D and Dm with four strums each.',
      ),
    ],
    minutes: 8,
    chords: ['D', 'Dm'],
    tool: LessonTool.metronome,
    bpm: 70,
  ),
  Lesson(
    id: 'r12_sevenths',
    unit: _openChords2,
    title: LocalizedText(es: 'Séptimas: E7, A7 y B7', en: 'Sevenths: E7, A7 and B7'),
    body: LocalizedText(
      es: 'Un acorde de séptima suma una nota que pide resolver. En E7 y A7 basta levantar un dedo: en E7 la 4ª cuerda queda al aire (D) y en A7, la 3ª (G). B7 es el acorde que lleva de vuelta a Em.',
      en: 'A seventh chord adds a note that wants to resolve. For E7 and A7 you just lift one finger: in E7 the 4th string rings open (D) and in A7, the 3rd (G). B7 is the chord that leads back to Em.',
    ),
    steps: [
      LocalizedText(
        es: 'Arma E y levanta el dedo de la 4ª cuerda: eso es E7.',
        en: 'Form E and lift the finger on the 4th string: that is E7.',
      ),
      LocalizedText(
        es: 'Arma A y levanta el dedo de la 3ª cuerda: eso es A7.',
        en: 'Form A and lift the finger on the 3rd string: that is A7.',
      ),
      LocalizedText(
        es: 'Toca Em – B7 – Em y escucha cómo B7 pide volver.',
        en: 'Play Em – B7 – Em and hear how B7 asks to return.',
      ),
    ],
    minutes: 10,
    chords: ['E7', 'A7', 'B7', 'Em'],
    tool: LessonTool.metronome,
    bpm: 70,
  ),
  Lesson(
    id: 'r13_color_chords',
    unit: _openChords2,
    title: LocalizedText(es: 'Acordes con color: Cmaj7, Am7 y Fmaj7', en: 'Color chords: Cmaj7, Am7 and Fmaj7'),
    body: LocalizedText(
      es: 'Levantar un dedo cambia el color del acorde. Cmaj7 es C sin el dedo 1: la 2ª cuerda suena al aire (B). Am7 es Am con la 3ª cuerda al aire (G). Y Fmaj7 se toca sin cejilla, solo en las cuatro cuerdas agudas.',
      en: 'Lifting one finger changes the chord’s color. Cmaj7 is C without finger 1: the 2nd string rings open (B). Am7 is Am with the 3rd string open (G). And Fmaj7 needs no barre, only the four high strings.',
    ),
    steps: [
      LocalizedText(
        es: 'Arma C y levanta el dedo 1: eso es Cmaj7.',
        en: 'Form C and lift finger 1: that is Cmaj7.',
      ),
      LocalizedText(
        es: 'Toca Cmaj7 – Am7 – Fmaj7 despacio, cuatro rasgueos cada uno.',
        en: 'Play Cmaj7 – Am7 – Fmaj7 slowly, four strums each.',
      ),
      LocalizedText(
        es: 'Arma tu propia vuelta con estos acordes en Mi progresión.',
        en: 'Build your own loop with these chords in My progression.',
      ),
    ],
    minutes: 10,
    chords: ['Cmaj7', 'Am7', 'Fmaj7'],
    tool: LessonTool.progressions,
  ),
  Lesson(
    id: 'r4_three_four',
    unit: _strumming2,
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
    id: 'r14_six_eight',
    unit: _strumming2,
    title: LocalizedText(es: 'Rasgueo en 6/8', en: '6/8 strumming'),
    body: LocalizedText(
      es: 'Seis corcheas por compás, en dos grupos de tres. El acento cae en la 1 y en la 4, y por eso suena como un vaivén.',
      en: 'Six eighth notes per bar, in two groups of three. The accent falls on 1 and 4, which is why it sways.',
    ),
    steps: [
      LocalizedText(
        es: 'Cuenta 1 2 3 4 5 6 y marca más fuerte la 1 y la 4.',
        en: 'Count 1 2 3 4 5 6 and play 1 and 4 harder.',
      ),
      LocalizedText(
        es: 'Tócalo en Em sin cambiar de acorde.',
        en: 'Play it on Em without changing chords.',
      ),
      LocalizedText(
        es: 'Pasa a G – Em – C – D, un compás cada uno.',
        en: 'Move on to G – Em – C – D, one bar each.',
      ),
    ],
    minutes: 8,
    chords: ['G', 'Em', 'C', 'D'],
    strumPattern: 'DUUDUU',
    tool: LessonTool.metronome,
    bpm: 60,
  ),
  Lesson(
    id: 'r15_backbeat',
    unit: _strumming2,
    title: LocalizedText(es: 'Acento en 2 y 4', en: 'Backbeat: accent on 2 and 4'),
    body: LocalizedText(
      es: 'En el rock y el pop la batería golpea la caja en los tiempos 2 y 4. Si rasgueas esos tiempos más fuerte, la guitarra empuja junto con la banda.',
      en: 'In rock and pop the drummer hits the snare on beats 2 and 4. If you strum those beats harder, the guitar pushes along with the band.',
    ),
    steps: [
      LocalizedText(
        es: 'Rasguea corcheas abajo y arriba sin parar.',
        en: 'Strum eighth notes down and up without stopping.',
      ),
      LocalizedText(
        es: 'Golpea más fuerte el abajo de la 2 y de la 4.',
        en: 'Hit the downstroke on 2 and 4 harder.',
      ),
      LocalizedText(
        es: 'Toca Am – Fmaj7 – C – G con ese acento.',
        en: 'Play Am – Fmaj7 – C – G with that accent.',
      ),
    ],
    minutes: 8,
    chords: ['Am', 'Fmaj7', 'C', 'G'],
    strumPattern: 'DUDUDUDU',
    tool: LessonTool.metronome,
    bpm: 80,
  ),
  Lesson(
    id: 'r16_power_riff',
    unit: _riffs,
    title: LocalizedText(es: 'Riff con power chords', en: 'Power chord riff'),
    body: LocalizedText(
      es: 'Un riff es una frase corta que se repite. Este usa E5, G5 y A5: sus tónicas son E (6ª cuerda al aire), G (6ª cuerda, traste 3) y A (5ª cuerda al aire), todas de la pentatónica menor de E.',
      en: 'A riff is a short phrase that repeats. This one uses E5, G5 and A5: their roots are E (open 6th string), G (6th string, fret 3) and A (open 5th string), all from the E minor pentatonic.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca solo las tónicas siguiendo la tablatura.',
        en: 'Play just the roots following the tab.',
      ),
      LocalizedText(
        es: 'Ahora arma cada power chord sobre su tónica.',
        en: 'Now build each power chord on its root.',
      ),
      LocalizedText(
        es: 'Apaga con la palma entre un acorde y otro.',
        en: 'Palm-mute between one chord and the next.',
      ),
    ],
    minutes: 8,
    chords: ['E5', 'G5', 'A5'],
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 4),
    tool: LessonTool.metronome,
    bpm: 80,
    tab: [TabNote(6, 0), TabNote(6, 3), TabNote(5, 0), TabNote(6, 0)],
  ),
  Lesson(
    id: 'r17_boogie',
    unit: _riffs,
    title: LocalizedText(es: 'Boogie de blues en A', en: 'Blues boogie in A'),
    body: LocalizedText(
      es: 'El boogie alterna la 5ª y la 6ª de A sobre la 5ª cuerda al aire: en la 4ª cuerda, traste 2 (E) y traste 4 (F#). Es el acompañamiento clásico del blues de 12 compases.',
      en: 'The boogie alternates the 5th and 6th of A over the open 5th string: on the 4th string, fret 2 (E) and fret 4 (F#). It is the classic backing for the 12-bar blues.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca juntas la 5ª cuerda al aire y la 4ª, como un power chord.',
        en: 'Play the open 5th string together with the 4th, like a power chord.',
      ),
      LocalizedText(
        es: 'Dos veces con el traste 2 y dos con el traste 4.',
        en: 'Twice with fret 2 and twice with fret 4.',
      ),
      LocalizedText(
        es: 'Llévalo a D (4ª al aire y 3ª cuerda) y a E (6ª al aire y 5ª cuerda) para tocar el blues completo.',
        en: 'Move it to D (open 4th and the 3rd string) and to E (open 6th and the 5th string) to play the whole blues.',
      ),
    ],
    minutes: 10,
    scale: LessonScale(scaleId: 'pentatonic_major', root: 9),
    tool: LessonTool.metronome,
    bpm: 90,
    tab: [TabNote(5, 0), TabNote(4, 2), TabNote(5, 0), TabNote(4, 2), TabNote(5, 0), TabNote(4, 4), TabNote(5, 0), TabNote(4, 4)],
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

  // ── Guitarra líder, nivel 2 ────────────────────────────────────────────
  Lesson(
    id: 'l11_bend_lick',
    unit: _licks,
    title: LocalizedText(es: 'Lick con bend', en: 'Bend lick'),
    body: LocalizedText(
      es: 'Un lick es una frase corta para usar en un solo. Este baja por la primera caja de A pentatónica menor y termina con un bend de un tono en la 3ª cuerda: del traste 7 (D) hasta que suene como E.',
      en: 'A lick is a short phrase to use in a solo. This one walks down the first box of A minor pentatonic and ends with a whole-step bend on the 3rd string: from fret 7 (D) until it sounds like E.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca las cuatro notas sin el bend.',
        en: 'Play the four notes without the bend.',
      ),
      LocalizedText(
        es: 'Agrega el bend en la última y compárala con el traste 9.',
        en: 'Add the bend on the last one and compare it with fret 9.',
      ),
      LocalizedText(
        es: 'Repite el lick sobre el blues en A.',
        en: 'Repeat the lick over the blues in A.',
      ),
    ],
    minutes: 8,
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
    tool: LessonTool.metronome,
    bpm: 70,
    tab: [TabNote(1, 5), TabNote(2, 8), TabNote(2, 5), TabNote(3, 7)],
  ),
  Lesson(
    id: 'l12_legato_lick',
    unit: _licks,
    title: LocalizedText(es: 'Lick con ligados', en: 'Legato lick'),
    body: LocalizedText(
      es: 'Ligados en la 3ª y la 4ª cuerda: martilla del traste 5 al 7 (de C a D en la 3ª, de G a A en la 4ª). La púa toca solo la primera nota de cada par.',
      en: 'Legato on the 3rd and 4th strings: hammer from fret 5 to 7 (C to D on the 3rd, G to A on the 4th). The pick plays only the first note of each pair.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca con la púa el traste 5 y martilla el 7.',
        en: 'Pick fret 5 and hammer onto fret 7.',
      ),
      LocalizedText(
        es: 'Repite en la 4ª cuerda.',
        en: 'Repeat on the 4th string.',
      ),
      LocalizedText(
        es: 'Encadena los dos pares sin parar.',
        en: 'Chain both pairs without stopping.',
      ),
    ],
    minutes: 8,
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
    tool: LessonTool.metronome,
    bpm: 70,
    tab: [TabNote(3, 5), TabNote(3, 7), TabNote(4, 5), TabNote(4, 7)],
  ),
  Lesson(
    id: 'l13_call_response',
    unit: _licks,
    title: LocalizedText(es: 'Pregunta y respuesta', en: 'Call and response'),
    body: LocalizedText(
      es: 'Una frase que termina lejos de la tónica suena a pregunta; una que termina en la tónica, a respuesta. Aquí la pregunta acaba en G y la respuesta vuelve a A.',
      en: 'A phrase that ends away from the root sounds like a question; one that ends on the root sounds like an answer. Here the question ends on G and the answer returns to A.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca las dos primeras notas: son la pregunta.',
        en: 'Play the first two notes: they are the question.',
      ),
      LocalizedText(
        es: 'Responde con las otras cuatro, que terminan en A.',
        en: 'Answer with the other four, which end on A.',
      ),
      LocalizedText(
        es: 'Inventa tu propia respuesta que acabe en A.',
        en: 'Make up your own answer that ends on A.',
      ),
    ],
    minutes: 10,
    scale: LessonScale(scaleId: 'pentatonic_minor', root: 9),
    tab: [TabNote(2, 5), TabNote(2, 8), TabNote(2, 5), TabNote(3, 7), TabNote(3, 5), TabNote(4, 7)],
  ),
  Lesson(
    id: 'l14_major_scale',
    unit: _majorMinor,
    title: LocalizedText(es: 'La escala mayor en G', en: 'The G major scale'),
    body: LocalizedText(
      es: 'Siete notas con la fórmula T T S T T T S (tono = 2 trastes, semitono = 1). En G son G A B C D E F#. Empieza en el traste 3 de la 6ª cuerda.',
      en: 'Seven notes with the formula W W H W W W H (whole step = 2 frets, half step = 1). In G they are G A B C D E F#. It starts at fret 3 on the 6th string.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca la escala subiendo y bajando, una nota por clic.',
        en: 'Play the scale up and down, one note per click.',
      ),
      LocalizedText(
        es: 'Canta cada nota mientras la tocas.',
        en: 'Sing each note as you play it.',
      ),
      LocalizedText(
        es: 'Termina siempre en G: así suena a casa.',
        en: 'Always end on G: that is what home sounds like.',
      ),
    ],
    minutes: 10,
    scale: LessonScale(scaleId: 'major', root: 7),
    tool: LessonTool.metronome,
    bpm: 60,
  ),
  Lesson(
    id: 'l15_relative_minor',
    unit: _majorMinor,
    title: LocalizedText(es: 'La menor relativa', en: 'The relative minor'),
    body: LocalizedText(
      es: 'E menor natural tiene las mismas siete notas que G mayor; solo cambia cuál es la casa. La relativa menor está 3 semitonos (3 trastes) debajo de la mayor.',
      en: 'E natural minor has the same seven notes as G major; only the home note changes. The relative minor sits 3 half steps (3 frets) below the major.',
    ),
    steps: [
      LocalizedText(
        es: 'Toca la escala de G mayor y termina en E.',
        en: 'Play the G major scale and end on E.',
      ),
      LocalizedText(
        es: 'Compara: mismas notas, distinto reposo.',
        en: 'Compare: same notes, a different resting point.',
      ),
      LocalizedText(
        es: 'Improvisa sobre Em y termina tus frases en E.',
        en: 'Improvise over Em and end your phrases on E.',
      ),
    ],
    minutes: 8,
    chords: ['Em'],
    scale: LessonScale(scaleId: 'natural_minor', root: 4),
  ),
  Lesson(
    id: 'l16_neighbor_keys',
    unit: _majorMinor,
    title: LocalizedText(es: 'Tonalidades vecinas', en: 'Neighboring keys'),
    body: LocalizedText(
      es: 'En el círculo de quintas, G está justo a la derecha de C: una quinta arriba y con un solo ♯ (F#). Dos tonalidades vecinas comparten 6 de sus 7 notas, por eso pasar de una a otra suena natural.',
      en: 'On the circle of fifths, G sits right next to C on the right: a fifth up and with a single ♯ (F#). Two neighboring keys share 6 of their 7 notes, which is why moving between them sounds natural.',
    ),
    steps: [
      LocalizedText(
        es: 'Abre el círculo y gira de C a G.',
        en: 'Open the circle and turn from C to G.',
      ),
      LocalizedText(
        es: 'Compara sus escalas: solo cambia F por F#.',
        en: 'Compare their scales: only F changes to F#.',
      ),
      LocalizedText(
        es: 'Sigue girando y busca qué nota cambia en cada paso.',
        en: 'Keep turning and find which note changes at each step.',
      ),
    ],
    minutes: 8,
    tool: LessonTool.circle,
  ),
  Lesson(
    id: 'l17_thirds',
    unit: _doubleStops,
    title: LocalizedText(es: 'Terceras en dos cuerdas', en: 'Thirds on two strings'),
    body: LocalizedText(
      es: 'Dos notas a la vez, a una tercera de distancia. En C mayor las terceras de los grados I, IV y V son mayores (4 semitonos) y las de II, III, VI y VII, menores (3).',
      en: 'Two notes at once, a third apart. In C major the thirds on degrees I, IV and V are major (4 half steps) and those on II, III, VI and VII are minor (3).',
    ),
    steps: [
      LocalizedText(
        es: 'Abre los double stops en C con terceras.',
        en: 'Open double stops in C with thirds.',
      ),
      LocalizedText(
        es: 'Toca cada pareja subiendo por el mástil en las cuerdas 1 y 2.',
        en: 'Play each pair moving up the neck on strings 1 and 2.',
      ),
      LocalizedText(
        es: 'Escucha la diferencia entre una tercera mayor y una menor.',
        en: 'Listen to the difference between a major and a minor third.',
      ),
    ],
    minutes: 10,
    tool: LessonTool.doubleStops,
  ),
  Lesson(
    id: 'l18_sixths',
    unit: _doubleStops,
    title: LocalizedText(es: 'Sextas saltando una cuerda', en: 'Sixths skipping a string'),
    body: LocalizedText(
      es: 'Las sextas se tocan con una cuerda en medio, por ejemplo la 1ª y la 3ª. En C mayor son mayores (9 semitonos) en los grados I, II, IV y V, y menores (8) en III, VI y VII.',
      en: 'Sixths are played with a string in between, for example the 1st and 3rd. In C major they are major (9 half steps) on degrees I, II, IV and V, and minor (8) on III, VI and VII.',
    ),
    steps: [
      LocalizedText(
        es: 'Abre los double stops en C con sextas.',
        en: 'Open double stops in C with sixths.',
      ),
      LocalizedText(
        es: 'Apaga la cuerda del medio con un dedo.',
        en: 'Mute the middle string with a finger.',
      ),
      LocalizedText(
        es: 'Sube por la escala tocando una sexta por grado.',
        en: 'Climb the scale playing one sixth per degree.',
      ),
    ],
    minutes: 10,
    tool: LessonTool.doubleStops,
  ),
];

const _beyondOpen = LessonUnit(
  id: 'r_beyond_open',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Más allá de los abiertos', en: 'Beyond open chords'),
  summary: LocalizedText(
    es: 'Cejillas, power chords, apagado con la palma y el blues de 12 compases.',
    en: 'Barre chords, power chords, palm muting and the 12-bar blues.',
  ),

  art: ChordArt('F'),
);
const _fingerstyle = LessonUnit(
  id: 'r_fingerstyle',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Con los dedos', en: 'Fingerstyle'),
  summary: LocalizedText(
    es: 'Arpegios y bajo alterno con los dedos.',
    en: 'Arpeggios and alternating bass with your fingers.',
  ),

  art: ChordArt('C'),
);
const _scalesAndTechnique = LessonUnit(
  id: 'l_scales_technique',
  track: LessonTrack.lead,
  title: LocalizedText(es: 'Escalas y técnica', en: 'Scales and technique'),
  summary: LocalizedText(
    es: 'La pentatónica menor, calentamiento, ligados y bends.',
    en: 'The minor pentatonic, warm-ups, legato and bends.',
  ),

  art: ScaleArt(LessonScale(scaleId: 'pentatonic_minor', root: 9)),
);
const _expression = LessonUnit(
  id: 'l_expression',
  track: LessonTrack.lead,
  title: LocalizedText(es: 'Expresión y solos', en: 'Expression and solos'),
  summary: LocalizedText(
    es: 'Vibrato, la escala de blues, la pentatónica mayor y tu primer solo.',
    en: 'Vibrato, the blues scale, the major pentatonic and your first solo.',
  ),

  art: ScaleArt(LessonScale(scaleId: 'blues_minor', root: 9)),
);
const _theNeck = LessonUnit(
  id: 'l_the_neck',
  track: LessonTrack.lead,
  title: LocalizedText(es: 'El mástil', en: 'The neck'),
  summary: LocalizedText(
    es: 'Los nombres de las notas en las cuerdas graves y la segunda caja.',
    en: 'Note names on the low strings and the second box.',
  ),

  art: NotesArt(['E', 'F', 'G', 'A', 'B', 'C', 'D']),
);

const _openChords2 = LessonUnit(
  id: 'r_open_chords_2',
  track: LessonTrack.rhythm,
  level: 2,
  title: LocalizedText(es: 'Acordes abiertos 2', en: 'Open chords 2'),
  summary: LocalizedText(
    es: 'Menores, séptimas y maj7: más color con las formas que ya conoces.',
    en: 'Minors, sevenths and maj7: more color from shapes you already know.',
  ),
  art: ChordArt('Dm'),
);
const _strumming2 = LessonUnit(
  id: 'r_strumming_2',
  track: LessonTrack.rhythm,
  level: 2,
  title: LocalizedText(es: 'Rasgueo 2', en: 'Strumming 2'),
  summary: LocalizedText(
    es: 'Los compases de 3/4 y 6/8 y el acento que hace sonar la guitarra con la banda.',
    en: '3/4 and 6/8 time and the accent that locks the guitar in with the band.',
  ),
  art: StrumArt('DUUDUU'),
);
const _riffs = LessonUnit(
  id: 'r_riffs',
  track: LessonTrack.rhythm,
  level: 2,
  title: LocalizedText(es: 'Riffs', en: 'Riffs'),
  summary: LocalizedText(
    es: 'Frases cortas que se repiten: power chords y el boogie del blues.',
    en: 'Short repeating phrases: power chords and the blues boogie.',
  ),
  art: ChordArt('E5'),
);
const _licks = LessonUnit(
  id: 'l_licks',
  track: LessonTrack.lead,
  level: 2,
  title: LocalizedText(es: 'Licks', en: 'Licks'),
  summary: LocalizedText(
    es: 'Frases cortas para tus solos: bends, ligados y frases que dialogan.',
    en: 'Short phrases for your solos: bends, legato and phrases that talk back.',
  ),
  art: NotesArt(['A', 'G', 'E', 'D']),
);
const _majorMinor = LessonUnit(
  id: 'l_major_minor',
  track: LessonTrack.lead,
  level: 2,
  title: LocalizedText(es: 'Mayor y menor', en: 'Major and minor'),
  summary: LocalizedText(
    es: 'La escala mayor, su relativa menor y cómo se ordenan las tonalidades.',
    en: 'The major scale, its relative minor and how keys are ordered.',
  ),
  art: ScaleArt(LessonScale(scaleId: 'major', root: 7)),
);
const _doubleStops = LessonUnit(
  id: 'l_double_stops',
  track: LessonTrack.lead,
  level: 2,
  title: LocalizedText(es: 'Double stops', en: 'Double stops'),
  summary: LocalizedText(
    es: 'Dos notas a la vez: terceras y sextas por la escala.',
    en: 'Two notes at once: thirds and sixths through the scale.',
  ),
  art: NotesArt(['C', 'E']),
);

/// Retos al final de cada nivel de cada camino; se superan con el récord de
/// un módulo de práctica.
const _basicsCourse = LessonUnit(
  id: 'f_basics',
  track: LessonTrack.foundations,
  title: LocalizedText(es: 'Primeros pasos', en: 'First steps'),
  summary: LocalizedText(
    es: 'Conoce la guitarra, afínala y pisa tus primeros trastes: uno, dos, '
        'otra cuerda y otro dedo.',
    en: 'Meet the guitar, tune it and fret your first notes: one fret, two, '
        'another string and another finger.',
  ),
  art: NotesArt(['E', 'A', 'D', 'G', 'B']),
  course: LessonCourse.basics,
);
const _moreOpenChords = LessonUnit(
  id: 'r_more_open_chords',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Más acordes abiertos', en: 'More open chords'),
  summary: LocalizedText(
    es: 'Am, A y E: los abiertos que faltan, y el cambio Em ↔ Am.',
    en: 'Am, A and E: the remaining open chords, and the Em ↔ Am change.',
  ),
  art: ChordArt('Am'),
);
const _melodiesCourse = LessonUnit(
  id: 'f_melodies',
  track: LessonTrack.foundations,
  title: LocalizedText(es: 'Melodías', en: 'Melodies'),
  summary: LocalizedText(
    es: 'Curso por niveles: de las cuerdas agudas a tocar canciones de memoria.',
    en: 'A course by levels: from the high strings to playing songs by heart.',
  ),
  art: NotesArt(['G', 'A', 'B', 'C']),
  course: LessonCourse.melodies,
);
const _openChordsCourse = LessonUnit(
  id: 'r_open_chords_1',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Acordes abiertos – Parte 1', en: 'Open chords – Part 1'),
  summary: LocalizedText(
    es: 'Em, G, D y C dedo a dedo, los cambios entre ellos y canciones con solo esos acordes.',
    en: 'Em, G, D and C finger by finger, the changes between them and songs with only those chords.',
  ),
  art: ChordArt('Em'),
  course: LessonCourse.openChords,
);
const _strummingCourse = LessonUnit(
  id: 'r_strumming_patterns_1',
  track: LessonTrack.rhythm,
  title: LocalizedText(es: 'Patrones de rasgueo – Parte 1', en: 'Strumming patterns – Part 1'),
  summary: LocalizedText(
    es: 'Cinco rasgueos con Em, G, D y C: tempo, conteo, péndulo y canciones.',
    en: 'Five strums with Em, G, D and C: tempo, counting, pendulum and songs.',
  ),
  art: StrumArt('D DUD DU'),
  course: LessonCourse.strumming,
);

/// Todas las unidades, en el orden del mapa (cada camino de arriba abajo).
/// Las de curso no tienen lecciones; las demás, las suyas en [curriculum].
const List<LessonUnit> lessonUnits = [
  _basicsCourse,
  _melodiesCourse,
  _openChordsCourse,
  _strummingCourse,
  _moreOpenChords,
  _beyondOpen,
  _fingerstyle,
  _openChords2,
  _strumming2,
  _riffs,
  _scalesAndTechnique,
  _expression,
  _theNeck,
  _licks,
  _majorMinor,
  _doubleStops,
];

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
  LessonChallenge(
    id: 'rc2_groove',
    track: LessonTrack.rhythm,
    level: 2,
    title: LocalizedText(es: 'Reto: groove fino', en: 'Challenge: tight groove'),
    body: LocalizedText(
      es: 'Logra 95 % o más de precisión en el juego de ritmo.',
      en: 'Reach 95% accuracy or more in the rhythm game.',
    ),
    kind: ChallengeKind.rhythmAccuracy,
    goal: 95,
  ),
  LessonChallenge(
    id: 'lc2_ear',
    track: LessonTrack.lead,
    level: 2,
    title: LocalizedText(es: 'Reto: oído de solista', en: 'Challenge: soloist ear'),
    body: LocalizedText(
      es: 'Reconoce 10 intervalos seguidos sin fallar en Oído.',
      en: 'Recognize 10 intervals in a row without a miss in Ear.',
    ),
    kind: ChallengeKind.earStreak,
    goal: 10,
  ),
];

/// Lecciones de [track], en orden.
List<Lesson> lessonsOf(LessonTrack track) =>
    [for (final l in curriculum) if (l.track == track) l];

/// Unidades de [track] en el orden del camino; con [level], solo las de ese
/// nivel.
List<LessonUnit> unitsOf(LessonTrack track, {int? level}) => [
  for (final u in lessonUnits)
    if (u.track == track && (level == null || u.level == level)) u,
];

/// Niveles de [track], de menor a mayor.
List<int> levelsOf(LessonTrack track) =>
    {for (final u in unitsOf(track)) u.level}.toList()..sort();

/// Lecciones de [unit], en orden.
List<Lesson> lessonsOfUnit(LessonUnit unit) =>
    [for (final l in curriculum) if (l.unit == unit) l];

/// Retos de [track]; con [level], solo el que cierra ese nivel en el mapa.
List<LessonChallenge> challengesOf(LessonTrack track, {int? level}) => [
  for (final c in challenges)
    if (c.track == track && (level == null || c.level == level)) c,
];

/// Lecciones por id.
final Map<String, Lesson> lessonsById = {for (final l in curriculum) l.id: l};

/// Unidades por id.
final Map<String, LessonUnit> unitsById = {for (final u in lessonUnits) u.id: u};

/// La unidad del mapa que abre [course].
LessonUnit unitOfCourse(LessonCourse course) =>
    lessonUnits.firstWhere((u) => u.course == course);
