import 'dart:async';
import 'dart:typed_data';

import 'package:chordmaster_free/core/errors/failures.dart';
import 'package:chordmaster_free/domain/audio/pitch_detection.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/features/tuner/tuner_viewmodel.dart';
import 'package:chordmaster_free/services/pitch_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ventana de 2048 muestras a 22.05 kHz de una cuerda sintetizada.
Float64List _window(int midi, {double from = 0.15}) {
  final half = decimateByTwo(pluck(midiToHz(midi), 0.6));
  final start = (from * synthSampleRate / 2).round();
  return Float64List.sublistView(half, start, start + 2048);
}

class _FakePitch extends PitchService {
  _FakePitch({this.deny = false}) : super.forTesting();

  final bool deny;
  // Lo cierra cada test con addTearDown.
  // ignore: close_sinks
  final controller = StreamController<PitchResult>.broadcast();

  @override
  Stream<PitchResult> get pitchStream => controller.stream;

  @override
  Future<void> startListening() async {
    if (deny) throw const PermissionFailure(message: 'denied');
  }

  @override
  Future<void> stopListening() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PitchService.analyze (lo que se hace con cada ventana del micrófono)', () {
    test('lee la cuerda que suena: A2 afinada', () {
      final service = PitchService.forTesting();
      final r = service.analyze(_window(45))!;
      expect(r.noteName, 'A2');
      expect(r.centsDeviation.abs(), lessThan(2));
      expect(r.isInTune, isTrue);
    });

    test('silencio: sin lectura y se olvida la nota anterior', () {
      final service = PitchService.forTesting();
      for (var i = 0; i < 4; i++) {
        service.analyze(_window(40, from: 0.1 + i * 0.05));
      }
      expect(service.analyze(Float64List(2048)), isNull);
      // La siguiente nota no arrastra la mediana de E2.
      expect(service.analyze(_window(64))!.noteName, 'E4');
    });

    test('el La de referencia cambia los cents', () {
      final service = PitchService.forTesting();
      expect(service.resultFor(440).centsDeviation, closeTo(0, 1e-9));
      service.referenceA4 = 442;
      expect(service.resultFor(440).centsDeviation, closeTo(-7.85, 0.05));
      expect(service.resultFor(440).isInTune, isFalse);
    });
  });

  group('TunerViewModel', () {
    test('elegir 442 Hz llega al servicio de afinación', () {
      final pitch = _FakePitch();
      addTearDown(pitch.controller.close);
      final container = ProviderContainer(
        overrides: [pitchServiceProvider.overrideWithValue(pitch)],
      );
      addTearDown(container.dispose);
      container.read(tunerViewModelProvider.notifier).setReference(442);
      expect(pitch.referenceA4, 442);
      expect(container.read(tunerViewModelProvider).referenceHz, 442);
    });

    test('permiso negado: deja de escuchar y lo indica', () async {
      final pitch = _FakePitch(deny: true);
      addTearDown(pitch.controller.close);
      final container = ProviderContainer(
        overrides: [pitchServiceProvider.overrideWithValue(pitch)],
      );
      addTearDown(container.dispose);
      await container.read(tunerViewModelProvider.notifier).startListening();
      final s = container.read(tunerViewModelProvider);
      expect(s.hasPermission, isFalse);
      expect(s.isListening, isFalse);
    });
  });
}
