import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _notes = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];
const _flats = {'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#'};

// Estándar E A D G B e (6ª → 1ª).
const _openPitch = [4, 9, 2, 7, 11, 4];

const _listFields = [
  'cagedPositions',
  'voicings',
  'triadInversions',
  'advancedInversions',
];

void main() {
  test('chords.json: digitaciones suenan solo notas del acorde', () {
    final data =
        jsonDecode(File('assets/data/chords.json').readAsStringSync())
            as List<dynamic>;

    final defects = <String, List<String>>{};
    final totals = <String, int>{};

    void check(
      String field,
      String label,
      List<dynamic> frets,
      Set<int> allowed,
    ) {
      totals[field] = (totals[field] ?? 0) + 1;
      final played = <int>{
        for (var i = 0; i < frets.length && i < 6; i++)
          if ((frets[i] as int) >= 0) (_openPitch[i] + (frets[i] as int)) % 12,
      };
      final foreign = played.difference(allowed);
      if (frets.length != 6 || foreign.isNotEmpty) {
        final names = (foreign.toList()..sort()).map((p) => _notes[p]);
        defects.putIfAbsent(field, () => []).add(
          '$label $frets -> ajenas: ${names.join(', ')}'
          '${frets.length != 6 ? ' (longitud ${frets.length})' : ''}',
        );
      }
    }

    for (final raw in data) {
      final chord = raw as Map<String, dynamic>;
      final root = chord['root'] as String;
      final rootPc = _notes.indexOf(_flats[root] ?? root);
      expect(rootPc, isNot(-1), reason: 'root desconocida: $root');
      final allowed = {
        for (final i in (chord['intervals'] as List<dynamic>))
          (rootPc + (i as int)) % 12,
      };
      final name = chord['name'] as String;

      check(
        'fretPositions',
        name,
        chord['fretPositions'] as List<dynamic>,
        allowed,
      );
      for (final field in _listFields) {
        for (final item in (chord[field] as List<dynamic>? ?? const [])) {
          final map = item as Map<String, dynamic>;
          check(
            field,
            '$name / ${map['title']}',
            map['fretPositions'] as List<dynamic>,
            allowed,
          );
        }
      }
    }

    for (final field in ['fretPositions', ..._listFields]) {
      final found = defects[field] ?? const <String>[];
      expect(
        found,
        isEmpty,
        reason:
            '$field: ${found.length} defectos de ${totals[field]}.\n'
            '${found.join('\n')}',
      );
    }
  });
}
