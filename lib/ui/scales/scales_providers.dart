import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/scale_repository.dart';

final patternsProvider = FutureProvider.family<List<ResolvedPattern>, ScaleQuery>(
  (ref, query) async {
    final repo = ref.read(scaleRepositoryProvider);
    return repo.getVisiblePatterns(
      scaleId: query.scaleId,
      rootSemitone: query.rootSemitone,
      startFret: query.startFret,
      endFret: query.endFret,
      stringCount: query.stringCount,
      systemFilter: query.systemId,
    );
  },
);

class ScaleQuery {
  const ScaleQuery({
    required this.scaleId,
    required this.rootSemitone,
    required this.startFret,
    required this.endFret,
    required this.stringCount,
    this.systemId,
  });

  final String scaleId;
  final int rootSemitone;
  final int startFret;
  final int endFret;
  final int stringCount;
  final String? systemId;

  @override
  bool operator ==(Object other) =>
      other is ScaleQuery &&
      other.scaleId == scaleId &&
      other.rootSemitone == rootSemitone &&
      other.startFret == startFret &&
      other.endFret == endFret &&
      other.stringCount == stringCount &&
      other.systemId == systemId;

  @override
  int get hashCode => Object.hash(
      scaleId, rootSemitone, startFret, endFret, stringCount, systemId);
}
