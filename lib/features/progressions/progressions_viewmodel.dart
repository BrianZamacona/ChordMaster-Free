import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/chord_metadata.dart';
import '../../core/i18n/tr.dart';
import '../../data/repository/chord_repository.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../../domain/progressions/custom_progression.dart';
import '../../domain/progressions/progression_builder.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/progressions/progression_playback.dart';
import '../../domain/progressions/saved_progressions.dart';
import '../../domain/progressions/song.dart';
import '../../domain/strumming/strumming_course.dart';
import '../../domain/theory/notes.dart';
import '../../domain/voicing/voice_leading.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart';
import '../../services/key_value_store.dart';

/// Immutable state for [ProgressionsViewModel].
class ProgressionsState {
  const ProgressionsState({
    this.tonic = 0,
    this.progressionId = 'v1-2',
    this.progressionsGenerated = 0,
    this.beginner = false,
    this.sections = const [[]],
    this.section = 0,
    this.order = const [0],
    this.playingPart,
    this.listenSong = false,
    this.saved = const [],
    this.clipboard,
    this.chosen = const {},
    this.playingIndex,
    this.bpm = progressionDefaultBpm,
    this.loop = false,
    this.pattern = 0,
    this.customMode = customDefaultMode,
    this.customSevenths = false,
    this.customSource = ChordSource.scale,
  });

  /// De qué fuente ofrece acordes "Mi progresión" (la escala de base, los
  /// prestados, las dominantes secundarias…).
  final ChordSource customSource;

  /// Escala de base de "Mi progresión" (rotación de la mayor; 0 = mayor,
  /// 5 = menor): qué acordes ofrece. Los ya puestos no cambian.
  final int customMode;

  /// "Mi progresión" ofrece los grados con su 7ª.
  final bool customSevenths;

  /// Patrón de rasgueo al escuchar (índice en `strummingPatterns`; el 0 es un
  /// golpe por pulso). El 12/8 no lo usa.
  final int pattern;

  /// Tempo al escuchar la progresión (un compás por acorde).
  final int bpm;

  /// Repetir la progresión sin parar al escucharla.
  final bool loop;

  /// Acorde que está sonando al escuchar la progresión (`null` = en silencio).
  final int? playingIndex;

  /// Pitch class de la tónica (C = 0).
  final int tonic;
  final String progressionId;
  final int progressionsGenerated;

  /// Modo principiante: penaliza las cejillas al elegir digitaciones.
  final bool beginner;

  /// Las secciones de "Mi progresión" (A, B…, hasta `songMaxSections`), cada
  /// una con sus acordes. La que se edita es [section].
  final List<List<CustomChord>> sections;

  /// La sección que se edita: la que dibujan los diagramas y explica la teoría.
  final int section;

  /// En qué orden se tocan las secciones en la canción (hasta `songMaxParts`).
  final List<int> order;

  /// Al escuchar la canción entera, la parte del orden que suena (`null` al
  /// escuchar solo la sección).
  final int? playingPart;

  /// El botón de escuchar toca la canción entera, no solo la sección.
  final bool listenSong;

  /// Grados de la sección que se edita de "Mi progresión".
  List<String> get custom => [for (final c in sections[section]) c.numeral];

  /// Pulsos de cada acorde de [custom] (los de `customChordBeats`).
  List<int> get customBeats => [for (final c in sections[section]) c.beats];

  /// La canción tiene más de una parte o de una sección: se puede escuchar entera.
  bool get hasSong => sections.length > 1 || order.length > 1;

  /// "Mis progresiones": las guardadas con nombre, la última primero.
  final List<SavedProgression> saved;

  /// El acorde copiado de "Mi progresión", listo para pegar.
  final CustomChord? clipboard;

  /// Digitaciones elegidas a mano en el glosario, por índice de acorde
  /// (orden de chords.json). El resto sigue el camino óptimo.
  final Map<int, FingeringChoice> chosen;

  bool get isCustom => progressionId == customProgressionId;

  /// Progresión elegida: una de [progressions] o la propia del usuario.
  Progression get progression => isCustom
      ? Progression(
          customProgressionId,
          custom.join(' - '),
          custom,
          // Todos de un compás = como las de siempre.
          beats: customBeats.every((b) => b == progressionBeatsPerChord) ? null : customBeats,
        )
      : progressions.firstWhere(
          (p) => p.id == progressionId,
          orElse: () => progressions.first,
        );

  ProgressionsState copyWith({
    int? tonic,
    String? progressionId,
    int? progressionsGenerated,
    bool? beginner,
    List<List<CustomChord>>? sections,
    int? section,
    List<int>? order,
    Object? playingPart = _keep,
    bool? listenSong,
    List<SavedProgression>? saved,
    Object? clipboard = _keep,
    Map<int, FingeringChoice>? chosen,
    Object? playingIndex = _keep,
    int? bpm,
    bool? loop,
    int? pattern,
    int? customMode,
    bool? customSevenths,
    ChordSource? customSource,
  }) => ProgressionsState(
    tonic: tonic ?? this.tonic,
    progressionId: progressionId ?? this.progressionId,
    progressionsGenerated: progressionsGenerated ?? this.progressionsGenerated,
    beginner: beginner ?? this.beginner,
    sections: sections ?? this.sections,
    section: section ?? this.section,
    order: order ?? this.order,
    playingPart: identical(playingPart, _keep) ? this.playingPart : playingPart as int?,
    listenSong: listenSong ?? this.listenSong,
    saved: saved ?? this.saved,
    clipboard: identical(clipboard, _keep) ? this.clipboard : clipboard as CustomChord?,
    chosen: chosen ?? this.chosen,
    playingIndex: identical(playingIndex, _keep) ? this.playingIndex : playingIndex as int?,
    bpm: bpm ?? this.bpm,
    loop: loop ?? this.loop,
    pattern: pattern ?? this.pattern,
    customMode: customMode ?? this.customMode,
    customSevenths: customSevenths ?? this.customSevenths,
    customSource: customSource ?? this.customSource,
  );

  static const Object _keep = Object();
}

/// Digitación elegida para un acorde (orden de chords.json, 6ª → 1ª).
typedef FingeringChoice = ({List<int> frets, List<int> fingers});

/// Id de la progresión armada por el usuario.
const customProgressionId = 'custom';


/// Transición entre dos acordes consecutivos de un camino.
class ProgressionTransition {
  const ProgressionTransition({
    required this.fretShift,
    required this.commonNotes,
    required this.cost,
  });

  final int fretShift;
  final int commonNotes;
  final double cost;
}

class ProgressionStep {
  const ProgressionStep({
    required this.numeral,
    required this.voicing,
    this.transition,
    this.chosen = false,
  });

  final String numeral;
  final ProgressionVoicing voicing;

  /// `true` si el usuario la eligió en el glosario (no es la del camino).
  final bool chosen;

  /// `null` en el primer acorde.
  final ProgressionTransition? transition;
}

class ProgressionPlan {
  const ProgressionPlan({
    required this.progression,
    required this.tonic,
    this.steps = const [],
    this.problem,
  });

  final Progression progression;
  final int tonic;
  final List<ProgressionStep> steps;

  /// Mensaje legible cuando no se pudo armar el camino.
  final String? problem;
}

String _degreeLabel(ProgressionDegree degree, int tonic) {
  final root = pitchClassName(tonic + degree.semitones);
  return '${degree.numeral} (${chordDisplayName(root: root, type: degree.type)})';
}

/// Calcula el camino óptimo y las transiciones; sin efectos secundarios.
ProgressionPlan buildProgressionPlan(
  ProgressionBuilder builder,
  Progression progression,
  int tonic, {
  bool beginner = false,
  Map<int, FingeringChoice> chosen = const {},
}) {
  final layers = builder.layersFor(progression, tonic, beginner: beginner);
  final missing = [
    for (var i = 0; i < layers.length; i++)
      if (layers[i].isEmpty) _degreeLabel(progression.degrees[i], tonic),
  ];
  if (missing.isNotEmpty) {
    return ProgressionPlan(
      progression: progression,
      tonic: tonic,
      problem: tr(
        es: 'No hay digitaciones válidas para: ${missing.join(', ')}.',
        en: 'No valid fingerings for: ${missing.join(', ')}.',
      ),
    );
  }

  final optimal = findOptimalProgressionPath(layers);
  // Las elegidas a mano reemplazan solo su acorde; los demás quedan como en
  // el camino óptimo (la progresión por defecto no cambia).
  final path = [
    for (var i = 0; i < optimal.length; i++)
      if (chosen[i] case final c?)
        builder.voicingFor(
              optimal[i].chord.root,
              optimal[i].chord.type,
              c.frets,
              c.fingers,
            ) ??
            optimal[i]
      else
        optimal[i],
  ];
  if (path.isEmpty) {
    return ProgressionPlan(
      progression: progression,
      tonic: tonic,
      problem: tr(
        es: 'No se encontró un camino de digitaciones para esta progresión.',
        en: 'No fingering path was found for this progression.',
      ),
    );
  }

  return ProgressionPlan(
    progression: progression,
    tonic: tonic,
    steps: [
      for (var i = 0; i < path.length; i++)
        ProgressionStep(
          numeral: progression.degrees[i].numeral,
          voicing: path[i],
          chosen: chosen.containsKey(i),
          transition: i == 0
              ? null
              : ProgressionTransition(
                  fretShift: (path[i].anchorFret - path[i - 1].anchorFret).abs(),
                  commonNotes: retainedPositionCount(path[i - 1], path[i]),
                  cost: calculateVoiceLeadingCost(path[i - 1], path[i]),
                ),
        ),
    ],
  );
}

final progressionBuilderProvider = FutureProvider<ProgressionBuilder>(
  (ref) async =>
      ProgressionBuilder(await ref.read(chordRepositoryProvider).fingerings()),
);

/// Provider for [ProgressionsViewModel].
final progressionsViewModelProvider =
    NotifierProvider<ProgressionsViewModel, ProgressionsState>(
        ProgressionsViewModel.new);

final progressionPlanProvider = Provider<AsyncValue<ProgressionPlan>>((ref) {
  final s = ref.watch(progressionsViewModelProvider);
  final progression = s.progression;
  if (progression.degrees.isEmpty) {
    return AsyncValue.data(ProgressionPlan(progression: progression, tonic: s.tonic));
  }
  return ref
      .watch(progressionBuilderProvider)
      .whenData(
        (b) => buildProgressionPlan(
          b,
          progression,
          s.tonic,
          beginner: s.beginner,
          chosen: s.chosen,
        ),
      );
});

/// Manages progression selection state and the usage counter.
///
/// El contador (logro "composer") sube una vez por progresión distinta
/// (id + tónica), no en cada cambio de selección.
class ProgressionsViewModel extends Notifier<ProgressionsState> {
  static const _keyCount = 'progressions_generated';
  static const _keySeen = 'progressions_seen';
  static const _keyCustom = 'progressions_custom';
  static const _keyCustomMode = 'progressions_custom_mode';
  static const _keyCustomSevenths = 'progressions_custom_sevenths';
  static const _keySaved = 'progressions_saved';
  static const _keySong = 'progressions_song';

  @override
  ProgressionsState build() {
    ref.onDispose(() => _listenTimer?.cancel());
    _seen.clear();
    _loaded = _loadCount();
    return const ProgressionsState();
  }

  /// Progresiones ya contadas, como `id@tónica`.
  final _seen = <String>{};

  /// Los conteos esperan a la carga: si no, un cambio hecho antes de que
  /// termine se pisaría con el valor guardado (o lo pisaría a él).
  late Future<void> _loaded;

  @visibleForTesting
  Future<void> get loaded => _loaded;

  Future<void> _loadCount() async {
    try {
      final storage = ref.read(keyValueStoreProvider);
      final count =
          await storage.get<int>(StorageBoxes.userProgress, _keyCount) ?? 0;
      final seen = await storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            _keySeen,
          ) ??
          const [];
      _seen.addAll(seen.whereType<String>());
      final custom = await storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            _keyCustom,
          ) ??
          const [];
      final mode = await storage.get<int>(StorageBoxes.userProgress, _keyCustomMode);
      final sevenths = await storage.get<bool>(StorageBoxes.userProgress, _keyCustomSevenths);
      final named = await storage.get<List<dynamic>>(StorageBoxes.userProgress, _keySaved) ?? const [];
      final rawSong = await storage.get<Map<dynamic, dynamic>>(StorageBoxes.userProgress, _keySong);
      // La canción; la de antes era una sola sección en `progressions_custom`.
      final song = rawSong == null
          ? (sections: [[for (final t in custom.whereType<String>()) ?parseCustomToken(t)]], order: const [0])
          : parseSong(rawSong['sections'], rawSong['order'], allowEmpty: true);
      // Si el usuario ya empezó a armar una antes de terminar la carga, gana lo suyo.
      final started = state.sections.any((x) => x.isNotEmpty);
      state = state.copyWith(
        // Una guardada que ya no se puede leer se descarta.
        saved: [for (final j in named) ?SavedProgression.fromJson(j)],
        progressionsGenerated: count,
        customMode: customBaseModes.contains(mode) ? mode : null,
        customSevenths: sevenths,
        sections: started || song == null ? null : song.sections,
        order: started || song == null ? null : song.order,
      );
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._loadCount error: $e\n$st');
    }
  }

  /// Cada cuánto se mira qué acorde suena.
  static const listenFrame = Duration(milliseconds: 30);

  /// Sube en cada escucha o cambio: una escucha vieja deja de marcar.
  int _listenToken = 0;
  Timer? _listenTimer;

  /// Lo que suena, para volver a empezarlo al cambiar el tempo.
  Future<void> Function()? _listening;

  /// Rasguea [plan] entera (un compás por acorde, al tempo y, con bucle, sin
  /// parar), marcando cuál suena. Llamarla otra vez mientras suena la detiene.
  Future<void> listen(ProgressionPlan plan) async {
    if (state.playingIndex != null) {
      _stopListening();
      return;
    }
    await _startPlan(plan);
  }

  Future<void> _startPlan(ProgressionPlan plan) {
    _listening = () => _startPlan(plan);
    return _play(
      [for (final s in plan.steps) _shapeOf(s)],
      plan.progression.beats,
      feel: plan.progression.feel,
      mark: (i) => (part: null, chord: i),
    );
  }

  /// Rasguea la canción entera de "Mi progresión": cada parte del orden con
  /// el camino de digitaciones de su sección (la que se edita, con las
  /// elegidas a mano). Llamarla otra vez mientras suena la detiene.
  Future<void> listenWholeSong() async {
    if (state.playingIndex != null) {
      _stopListening();
      return;
    }
    await _startSong();
  }

  Future<void> _startSong() async {
    _listening = _startSong;
    final builder = await ref.read(progressionBuilderProvider.future);
    final s = state;
    final plans = [
      for (final (i, section) in s.sections.indexed)
        if (section.isEmpty)
          null
        else
          buildProgressionPlan(
            builder,
            Progression(customProgressionId, '', [for (final c in section) c.numeral]),
            s.tonic,
            beginner: s.beginner,
            chosen: i == s.section ? s.chosen : const {},
          ),
    ];
    final playable = [
      for (final p in plans)
        if (p != null && p.problem == null) p.steps.length else 0,
    ];
    final timeline = songTimeline(playable, s.order);
    if (timeline.isEmpty) return;
    await _play(
      [for (final t in timeline) _shapeOf(plans[t.section]!.steps[t.chord])],
      [for (final t in timeline) s.sections[t.section][t.chord].beats],
      mark: (k) => (part: timeline[k].part, chord: timeline[k].chord),
    );
  }

  static ChordShape _shapeOf(ProgressionStep s) =>
      ChordShape(name: '', frets: s.voicing.jsonFrets, fingers: List.filled(6, 0));

  /// Rasguea [shapes] (de [beats] pulsos cada una, o un compás) marcando qué
  /// suena: [mark] da, del acorde k, la parte del orden y el acorde en su sección.
  Future<void> _play(
    List<ChordShape> shapes,
    List<int>? beats, {
    ProgressionFeel feel = ProgressionFeel.straight,
    required ({int? part, int chord}) Function(int) mark,
  }) async {
    final token = ++_listenToken;
    _listenTimer?.cancel();
    final bpm = state.bpm;
    final loop = state.loop;
    final count = shapes.length;
    final sounds = progressionStrum(
      shapes,
      bpm: bpm,
      feel: feel,
      pattern: strummingPatterns[state.pattern],
      beats: beats,
    );
    final seconds = progressionAudioSeconds(count, bpm: bpm, loop: loop, beats: beats);
    final audio = ref.read(audioServiceProvider);
    final first = mark(0);
    state = state.copyWith(playingIndex: first.chord, playingPart: first.part);
    var current = 0;
    // El temporizador cuenta sus vueltas (`tick` salta si una se atrasa):
    // así la marca sigue al audio, y en los tests avanza con el reloj falso.
    _listenTimer = Timer.periodic(listenFrame, (timer) {
      if (token != _listenToken) return timer.cancel();
      final elapsed = timer.tick * listenFrame.inMicroseconds / 1e6;
      final i = progressionChordAt(elapsed, count, bpm: bpm, loop: loop, beats: beats);
      if (i == null) {
        _stopListening(silence: false);
      } else if (i != current) {
        current = i;
        final m = mark(i);
        state = state.copyWith(playingIndex: m.chord, playingPart: m.part);
      }
    });
    await (loop ? audio.loopTab(sounds, seconds: seconds) : audio.playTab(sounds, seconds: seconds));
  }

  void _stopListening({bool silence = true}) {
    _listenToken++;
    _listenTimer?.cancel();
    _listenTimer = null;
    final wasPlaying = state.playingIndex != null;
    if (wasPlaying) state = state.copyWith(playingIndex: null, playingPart: null);
    if (wasPlaying && silence) ref.read(audioServiceProvider).stopAll();
  }

  /// Tempo de la escucha (de 5 en 5, 40–200). Si suena, vuelve a empezar.
  void setBpm(int bpm) {
    final next = progressionTempo(bpm);
    if (next == state.bpm) return;
    state = state.copyWith(bpm: next);
    _restartIfPlaying();
  }

  /// Repetir la vuelta sin parar. Si suena, vuelve a empezar.
  void setLoop({required bool loop}) {
    if (loop == state.loop) return;
    state = state.copyWith(loop: loop);
    _restartIfPlaying();
  }

  /// Patrón de rasgueo ([strummingPatterns]). Si suena, vuelve a empezar.
  void setPattern(int pattern) {
    if (pattern == state.pattern || pattern < 0 || pattern >= strummingPatterns.length) return;
    state = state.copyWith(pattern: pattern);
    _restartIfPlaying();
  }

  void _restartIfPlaying() {
    final again = _listening;
    if (state.playingIndex == null || again == null) return;
    unawaited(again());
  }

  /// Usa [choice] para el acorde [index] de la progresión (glosario).
  void chooseFingering(int index, FingeringChoice choice) =>
      state = state.copyWith(chosen: {...state.chosen, index: choice});

  /// Vuelve a la digitación del camino óptimo en el acorde [index].
  void resetFingering(int index) =>
      state = state.copyWith(chosen: {...state.chosen}..remove(index));

  // Las elegidas a mano se descartan al cambiar tonalidad, progresión o modo:
  // los acordes ya no son los mismos.
  void setTonic(int tonic) {
    _stopListening();
    state = state.copyWith(tonic: tonic, chosen: const {});
    if (!state.isCustom) {
      _countGeneration('${state.progressionId}@$tonic');
    } else if (state.custom.length >= 3) {
      _countGeneration('$customProgressionId:${state.custom.join('-')}@$tonic');
    }
  }

  void setBeginner({required bool beginner}) {
    _stopListening();
    state = state.copyWith(beginner: beginner, chosen: const {});
  }

  void setProgression(String id) {
    _stopListening();
    state = state.copyWith(progressionId: id, chosen: const {});
    if (id != customProgressionId) _countGeneration('$id@${state.tonic}');
  }

  /// Escala de base de "Mi progresión" (ver [ProgressionsState.customMode]).
  void setCustomMode(int mode) {
    if (!customBaseModes.contains(mode) || mode == state.customMode) return;
    state = state.copyWith(customMode: mode);
    _saveSetting(_keyCustomMode, mode);
  }

  /// De qué fuente ofrece acordes "Mi progresión".
  void setCustomSource(ChordSource source) => state = state.copyWith(customSource: source);

  /// "Mi progresión" ofrece los grados con su 7ª, o en tríada.
  void setCustomSevenths({required bool sevenths}) {
    if (sevenths == state.customSevenths) return;
    state = state.copyWith(customSevenths: sevenths);
    _saveSetting(_keyCustomSevenths, sevenths);
  }

  Future<void> _saveSetting(String key, Object value) async {
    await _loaded;
    try {
      await ref.read(keyValueStoreProvider).save(StorageBoxes.userProgress, key, value);
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._saveSetting error: $e\n$st');
    }
  }

  /// Añade un grado a "Mi progresión" (máximo [customProgressionMax]): un
  /// número romano que `parseDegreeNumeral` sabe leer.
  void addCustomDegree(String numeral) {
    if (!isCustomNumeral(numeral) ||
        state.custom.length >= customProgressionMax) {
      return;
    }
    _setCustom([...state.custom, numeral], [...state.customBeats, progressionBeatsPerChord]);
  }

  void removeCustomDegree(int index) {
    if (index < 0 || index >= state.custom.length) return;
    _setCustom([...state.custom]..removeAt(index), [...state.customBeats]..removeAt(index));
  }

  /// Cuántos pulsos dura el acorde [index] de "Mi progresión" (uno de
  /// `customChordBeats`).
  void setCustomBeats(int index, int beats) {
    if (index < 0 || index >= state.custom.length || !customChordBeats.contains(beats)) return;
    if (state.customBeats[index] == beats) return;
    _setCustom(state.custom, [...state.customBeats]..[index] = beats);
  }

  void clearCustom() => _setCustom(const [], const []);

  /// Edita la sección [index] (las digitaciones elegidas a mano se descartan:
  /// son de la otra).
  void selectSection(int index) {
    if (index < 0 || index >= state.sections.length || index == state.section) return;
    _stopListening();
    state = state.copyWith(section: index, chosen: const {});
  }

  /// Agrega una sección vacía (hasta `songMaxSections`), la deja para editar
  /// y la suma al final del orden (si cabe).
  void addSection() {
    if (state.sections.length >= songMaxSections) return;
    final index = state.sections.length;
    _setSong(
      [...state.sections, const []],
      state.order.length < songMaxParts ? [...state.order, index] : state.order,
      section: index,
    );
  }

  /// Quita la sección [index] y sus partes del orden (siempre queda una).
  void removeSection(int index) {
    if (state.sections.length <= 1 || index < 0 || index >= state.sections.length) return;
    final section = state.section > index || state.section == state.sections.length - 1
        ? state.section - 1
        : state.section;
    _setSong(
      [...state.sections]..removeAt(index),
      orderWithoutSection(state.order, index),
      section: section < 0 ? 0 : section,
    );
  }

  /// Agrega al final del orden una parte de la sección [index].
  void addPart(int index) {
    if (index < 0 || index >= state.sections.length || state.order.length >= songMaxParts) return;
    _setSong(state.sections, [...state.order, index]);
  }

  /// Quita la parte [part] del orden (siempre queda una).
  void removePart(int part) {
    if (state.order.length <= 1 || part < 0 || part >= state.order.length) return;
    _setSong(state.sections, [...state.order]..removeAt(part));
  }

  /// El botón de escuchar toca la canción entera o solo la sección.
  void setListenSong({required bool song}) {
    if (song == state.listenSong) return;
    _stopListening();
    state = state.copyWith(listenSong: song);
  }

  void _setSong(List<List<CustomChord>> sections, List<int> order, {int? section}) {
    _stopListening();
    final next = section ?? state.section;
    state = state.copyWith(
      sections: sections,
      order: order,
      section: next,
      progressionId: customProgressionId,
      chosen: next == state.section ? state.chosen : const {},
    );
    _saveSong();
  }

  /// Pone una copia del acorde [index] justo detrás de él.
  void duplicateCustom(int index) {
    if (index < 0 || index >= state.custom.length) return;
    _insertCustom(index + 1, (numeral: state.custom[index], beats: state.customBeats[index]));
  }

  /// Copia el acorde [index] para pegarlo después.
  void copyCustom(int index) {
    if (index < 0 || index >= state.custom.length) return;
    state = state.copyWith(clipboard: (numeral: state.custom[index], beats: state.customBeats[index]));
  }

  /// Pega el acorde copiado detrás del [after] (al final si es `null`).
  void pasteCustom({int? after}) {
    final chord = state.clipboard;
    if (chord == null) return;
    _insertCustom(after == null ? state.custom.length : after + 1, chord);
  }

  void _insertCustom(int at, CustomChord chord) {
    if (state.custom.length >= customProgressionMax || at < 0 || at > state.custom.length) return;
    _setCustom(
      [...state.custom]..insert(at, chord.numeral),
      [...state.customBeats]..insert(at, chord.beats),
    );
  }

  /// Guarda "Mi progresión" en "Mis progresiones" con [name] (si ya hay una
  /// con ese nombre, la reemplaza). `false` si no se guardó: sin acordes, sin
  /// nombre o sin lugar.
  bool saveCustomAs(String name) {
    // Se guarda la canción entera, sin las secciones que quedaron vacías.
    final song = withoutEmptySections(state.sections, state.order);
    if (song.sections.isEmpty || name.trim().isEmpty) return false;
    final item = SavedProgression(
      name: name.trim(),
      mode: state.customMode,
      sections: song.sections,
      order: song.order,
    );
    final next = upsertSaved(state.saved, item);
    if (next == null) return false;
    _setSaved(next);
    return true;
  }

  /// Abre la guardada [index] en "Mi progresión", con su escala de base.
  void openSaved(int index) {
    if (index < 0 || index >= state.saved.length) return;
    final item = state.saved[index];
    setCustomMode(item.mode);
    _setSong(item.sections, item.order, section: 0);
    state = state.copyWith(chosen: const {});
  }

  /// Quita la guardada [index] de "Mis progresiones".
  void deleteSaved(int index) {
    if (index < 0 || index >= state.saved.length) return;
    _setSaved([...state.saved]..removeAt(index));
  }

  void _setSaved(List<SavedProgression> saved) {
    state = state.copyWith(saved: saved);
    _saveSetting(_keySaved, [for (final s in saved) s.toJson()]);
  }

  void _setCustom(List<String> custom, List<int> beats) {
    _stopListening();
    state = state.copyWith(
      sections: [...state.sections]
        ..[state.section] = [for (final (i, n) in custom.indexed) (numeral: n, beats: beats[i])],
      progressionId: customProgressionId,
      chosen: const {},
    );
    _saveSong();
    // Cuenta como progresión generada a partir de 3 acordes.
    if (custom.length >= 3) {
      _countGeneration('$customProgressionId:${custom.join('-')}@${state.tonic}');
    }
  }

  /// Guarda la canción de "Mi progresión" (secciones y orden).
  void _saveSong() => _saveSetting(_keySong, {
    'sections': [
      for (final section in state.sections) [for (final c in section) customToken(c.numeral, c.beats)],
    ],
    'order': state.order,
  });

  /// Cuenta [key] una sola vez. La clave se arma al llamar (no tras el
  /// `await`) para contar lo que el usuario eligió aunque ya haya cambiado.
  Future<void> _countGeneration(String key) async {
    await _loaded;
    if (!_seen.add(key)) return;
    final newCount = state.progressionsGenerated + 1;
    state = state.copyWith(progressionsGenerated: newCount);
    try {
      final storage = ref.read(keyValueStoreProvider);
      await storage.save(StorageBoxes.userProgress, _keyCount, newCount);
      await storage.save(
        StorageBoxes.userProgress,
        _keySeen,
        _seen.toList(growable: false),
      );
      if (newCount >= 5) {
        await ref.read(achievementServiceProvider).unlock('composer');
      }
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._countGeneration error: $e\n$st');
    }
  }
}
