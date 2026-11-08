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

/// Un micrófono que tarda en arrancar.
class _SlowPitch extends PitchService {
  _SlowPitch() : super.forTesting();

  final started = Completer<void>();
  bool listening = false;

  @override
  Stream<PitchResult> get pitchStream => const Stream.empty();

  @override
  Future<void> startListening() async {
    await started.future;
    listening = true;
  }

  @override
  Future<void> stopListening() async => listening = false;
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

    test('bloques del micrófono de largo impar: igual lee la cuerda', () async {
      final service = PitchService.forTesting();
      final readings = <PitchResult>[];
      final sub = service.pitchStream.listen(readings.add);
      final wave = pluck(midiToHz(45), 0.6);
      final bytes = ByteData(wave.length * 2);
      for (var i = 0; i < wave.length; i++) {
        bytes.setInt16(i * 2, (wave[i] * 32767).round(), Endian.little);
      }
      final all = bytes.buffer.asUint8List();
      // 1001 bytes: cada bloque corta una muestra de 16 bits a la mitad.
      for (var i = 0; i < all.length; i += 1001) {
        service.onBytes(Uint8List.sublistView(all, i, (i + 1001).clamp(0, all.length)));
      }
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(readings, isNotEmpty);
      expect(readings.every((r) => r.noteName == 'A2'), isTrue);
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

    test('con la cuerda sonando la aguja se mueve, sin esperar al silencio', () async {
      final pitch = _FakePitch();
      addTearDown(pitch.controller.close);
      final container = ProviderContainer(
        overrides: [pitchServiceProvider.overrideWithValue(pitch)],
      );
      addTearDown(container.dispose);
      final vm = container.read(tunerViewModelProvider.notifier);
      await vm.startListening();
      final service = PitchService.forTesting();
      // Lecturas cada 40 ms, como llegan con una nota sostenida.
      pitch.controller.add(service.resultFor(110));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(tunerViewModelProvider).note, 'A2');
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        pitch.controller.add(service.resultFor(82.41));
      }
      // Todavía llegan lecturas y la pantalla ya muestra la nota nueva.
      expect(container.read(tunerViewModelProvider).note, 'E2');
      await vm.stopListening();
    });

    test('si la pantalla se oculta mientras arranca, el micrófono se apaga', () async {
      final pitch = _SlowPitch();
      final container = ProviderContainer(
        overrides: [pitchServiceProvider.overrideWithValue(pitch)],
      );
      addTearDown(container.dispose);
      final vm = container.read(tunerViewModelProvider.notifier);
      final starting = vm.startListening();
      await vm.stopListening();
      pitch.started.complete();
      await starting;
      expect(pitch.listening, isFalse);
      expect(container.read(tunerViewModelProvider).isListening, isFalse);
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
