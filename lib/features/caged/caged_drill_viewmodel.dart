import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/scale_repository.dart';
import '../../domain/practice/caged_drill.dart';

/// El azar de la práctica; los tests lo inyectan con una semilla.
final cagedDrillRandomProvider = Provider<Random>((ref) => Random());

class CagedDrillState {
  const CagedDrillState({required this.draw, this.phase = CagedDrillPhase.scale});

  final CagedDraw draw;
  final CagedDrillPhase phase;

  bool get isLastPhase => phase == CagedDrillPhase.values.last;
}

class CagedDrillViewModel extends Notifier<CagedDrillState> {
  Random get _rng => ref.read(cagedDrillRandomProvider);

  @override
  CagedDrillState build() => CagedDrillState(draw: drawCaged(_rng));

  /// La fase siguiente (en la última no hace nada).
  void nextPhase() {
    if (state.isLastPhase) return;
    state = CagedDrillState(draw: state.draw, phase: CagedDrillPhase.values[state.phase.index + 1]);
  }

  /// Otra tónica y otra forma, desde la primera fase.
  void reroll() => state = CagedDrillState(draw: drawCaged(_rng, previous: state.draw));
}

final cagedDrillProvider = NotifierProvider<CagedDrillViewModel, CagedDrillState>(CagedDrillViewModel.new);

/// La escala mayor de la tónica sorteada, en la posición CAGED de su forma.
final cagedDrillPositionProvider = FutureProvider.family<ResolvedPattern?, CagedDraw>((ref, draw) async {
  final positions = await ref
      .read(scaleRepositoryProvider)
      .getPositions(scaleId: 'major', rootSemitone: draw.root, systemFilter: 'caged');
  return positions.where((p) => p.positionId == cagedPositionId(draw.shape)).firstOrNull;
});
