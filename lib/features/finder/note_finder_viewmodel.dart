import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/theory/note_finder.dart';

/// Qué busca el buscador: un acorde (una nota por cuerda) o una escala
/// (notas sueltas en cualquier cuerda).
enum FinderMode { chords, scales }

/// Lo marcado en el buscador. Cada sección guarda sus notas: al cambiar de
/// pestaña no se pierde lo de la otra.
class NoteFinderState {
  const NoteFinderState({
    this.mode = FinderMode.chords,
    this.chordFrets = const {},
    this.scaleNotes = const {},
  });

  final FinderMode mode;

  /// Acordes: traste de cada cuerda marcada (1 = mi aguda); las demás no suenan.
  final Map<int, int> chordFrets;

  /// Escalas: las notas marcadas.
  final Set<FretNote> scaleNotes;

  /// Las notas de la sección a la vista.
  List<FretNote> get notes => mode == FinderMode.chords
      ? [for (final e in chordFrets.entries) (string: e.key, fret: e.value)]
      : scaleNotes.toList();

  NoteFinderState copyWith({
    FinderMode? mode,
    Map<int, int>? chordFrets,
    Set<FretNote>? scaleNotes,
  }) =>
      NoteFinderState(
        mode: mode ?? this.mode,
        chordFrets: chordFrets ?? this.chordFrets,
        scaleNotes: scaleNotes ?? this.scaleNotes,
      );
}

class NoteFinderViewModel extends Notifier<NoteFinderState> {
  @override
  NoteFinderState build() => const NoteFinderState();

  void setMode(FinderMode mode) => state = state.copyWith(mode: mode);

  /// Tocar el mástil. Acordes: marca esa cuerda en ese traste (otra vez en el
  /// mismo lugar la apaga). Escalas: marca o desmarca la nota.
  void tap(int string, int fret) {
    if (state.mode == FinderMode.chords) {
      final frets = {...state.chordFrets};
      if (frets[string] == fret) {
        frets.remove(string);
      } else {
        frets[string] = fret;
      }
      state = state.copyWith(chordFrets: frets);
    } else {
      final note = (string: string, fret: fret);
      final notes = {...state.scaleNotes};
      if (!notes.remove(note)) notes.add(note);
      state = state.copyWith(scaleNotes: notes);
    }
  }

  /// Borra lo marcado en la sección a la vista.
  void clear() => state = state.mode == FinderMode.chords
      ? state.copyWith(chordFrets: const {})
      : state.copyWith(scaleNotes: const {});
}

final noteFinderProvider =
    NotifierProvider<NoteFinderViewModel, NoteFinderState>(NoteFinderViewModel.new);
