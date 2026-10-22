import 'dart:convert';
import 'dart:io';

/// `assets/data/chords.json` decodificado, para los tests que revisan el
/// dataset entero (la app lo lee por `ChordRepository`).
List<Map<String, dynamic>> loadChordJson() =>
    (jsonDecode(File('assets/data/chords.json').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>();
