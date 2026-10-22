import 'package:chordmaster_free/features/songs/songs_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';

void main() {
  final chords = loadChordJson();
  final names = {for (final c in chords) c['displayName'] as String};

  test('cada acorde de cada canción existe en la biblioteca (en los slash, el de arriba)', () {
    // A7sus4 no es uno de los 24 tipos de chords.json: se muestra sin enlace.
    const notInLibrary = {'A7sus4'};
    for (final song in allSongs) {
      for (final symbol in song.chordProgression) {
        final base = songChordBase(symbol);
        if (notInLibrary.contains(base)) continue;
        expect(names, contains(base), reason: '${song.title}: $symbol');
      }
    }
  });

  test('notas con sostenidos: ningún bemol en los acordes', () {
    for (final song in allSongs) {
      for (final symbol in song.chordProgression) {
        expect(symbol, isNot(matches(RegExp('[A-G]b'))), reason: '${song.title}: $symbol');
      }
    }
  });

  test('songChordBase: el acorde de arriba en los slash', () {
    expect(songChordBase('Am/G#'), 'Am');
    expect(songChordBase('D/F#'), 'D');
    expect(songChordBase('Fmaj7'), 'Fmaj7');
  });
}
