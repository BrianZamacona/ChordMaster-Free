import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/practice/multi_day_challenges.dart';
import '../domain/practice/session_summary.dart';
import 'key_value_store.dart';

/// Las pasadas tocadas hoy con el micrófono, para el resumen de la sesión. Se
/// guardan en [StorageBoxes.userProgress] como `{día, pasadas}`; al cambiar
/// de día se empieza de cero (el resumen es solo de hoy).
final sessionLogProvider = NotifierProvider<SessionLog, List<PracticeRun>>(
  SessionLog.new,
);

class SessionLog extends Notifier<List<PracticeRun>> {
  static const keyRuns = 'session_runs';

  /// Más pasadas en un día no cambian el resumen y agrandan lo guardado.
  static const keepRuns = 200;

  /// El reloj (los tests lo cambian).
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  String _day = '';

  /// La lectura del disco: anotar espera a que termine (si no, una pasada
  /// anotada antes de leer volvía con la lectura y contaba dos veces).
  late Future<void> _ready;

  @override
  List<PracticeRun> build() {
    _day = dayKey(now());
    _ready = _load();
    return const [];
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final raw = await _storage.get<Map<dynamic, dynamic>>(
        StorageBoxes.userProgress,
        keyRuns,
      );
      if (raw == null || raw['day'] != _day) return;
      final loaded = [
        for (final r in (raw['runs'] as List?) ?? const []) ?PracticeRun.fromJson(r),
      ];
      state = loaded;
    } catch (e, st) {
      debugPrint('SessionLog._load error: $e\n$st');
    }
  }

  /// Anota una pasada de hoy.
  Future<void> record(PracticeRun run) async {
    await _ready;
    final today = dayKey(now());
    final runs = today == _day ? [...state, run] : [run];
    _day = today;
    state = runs.length > keepRuns ? runs.sublist(runs.length - keepRuns) : runs;
    try {
      await _storage.save(StorageBoxes.userProgress, keyRuns, {
        'day': _day,
        'runs': [for (final r in state) r.toJson()],
      });
    } catch (e, st) {
      debugPrint('SessionLog.record error: $e\n$st');
    }
  }

  /// El resumen de hoy (vacío si las pasadas guardadas son de otro día).
  SessionSummary get summary =>
      summarizeSession(dayKey(now()) == _day ? state : const []);
}
