import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/features/songs/songs_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List<dynamic>)
      .cast<Map<String, dynamic>>();
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
