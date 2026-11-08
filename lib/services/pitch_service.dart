import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../core/errors/failures.dart';
import '../core/utils/permission_utils.dart';
import '../domain/audio/pitch_detection.dart';

/// Una lectura del afinador.
class PitchResult {
  const PitchResult({
    required this.noteName,
    required this.frequency,
    required this.centsDeviation,
    required this.isInTune,
  });

  /// Nota más cercana con octava, p. ej. `"A4"` o `"C#3"`.
  final String noteName;

  /// Frecuencia fundamental detectada, en Hz.
  final double frequency;

  /// Desvío respecto de la nota en cents (positivo = alto).
  final double centsDeviation;

  /// A ±5 cents o menos.
  final bool isInTune;

  @override
  String toString() =>
      'PitchResult(note: $noteName, freq: ${frequency.toStringAsFixed(2)} Hz, '
      'cents: ${centsDeviation.toStringAsFixed(1)}, inTune: $isInTune)';
}

/// Escucha el micrófono y emite la afinación detectada.
///
/// El micrófono entrega PCM de 16 bits a 44.1 kHz; se baja a 22.05 kHz y,
/// cada ~46 ms, se analiza una ventana de ~93 ms con YIN
/// (`domain/audio/pitch_detection.dart`). La mediana de las últimas 5
/// lecturas estabiliza la aguja. Nada se graba ni se guarda.
class PitchService {
  factory PitchService() => instance;

  PitchService._internal();

  /// Para dobles de prueba (se inyectan con `pitchServiceProvider`).
  @visibleForTesting
  PitchService.forTesting();

  static final PitchService instance = PitchService._internal();

  static const _micRate = 44100;
  static const _rate = _micRate ~/ 2;
  static const _window = 2048; // muestras a 22.05 kHz (~93 ms)
  static const _hop = 1024; // nueva lectura cada ~46 ms
  static const _median = 5;

  /// La de referencia (440 Hz por defecto); lo cambia el afinador.
  double referenceA4 = 440;

  /// Se crea al usarlo por primera vez (abre el plugin del micrófono).
  late final AudioRecorder _recorder = AudioRecorder();
  final StreamController<PitchResult> _controller = StreamController<PitchResult>.broadcast();
  StreamSubscription<Uint8List>? _mic;

  /// Muestras a 22.05 kHz pendientes de analizar.
  final _buffer = <double>[];
  final _recent = <double>[];
  bool _isListening = false;

  Stream<PitchResult> get pitchStream => _controller.stream;

  bool get isListening => _isListening;

  /// Arranques y paradas van en fila: al volver rápido a la pestaña, un
  /// `stop()` que aún no terminaba apagaba el micrófono recién encendido.
  Future<void> _queue = Future.value();

  Future<void> _inOrder(Future<void> Function() op) {
    final done = _queue.then((_) => op());
    _queue = done.catchError((Object _) {});
    return done;
  }

  /// Pide el micrófono y empieza a emitir en [pitchStream]. Lanza
  /// [PermissionFailure] si el permiso se niega.
  Future<void> startListening() => _inOrder(_start);

  Future<void> _start() async {
    if (_isListening) return;
    final granted = await PermissionUtils.requestMicrophonePermission();
    if (!granted || !await _recorder.hasPermission()) {
      throw const PermissionFailure(
        message: 'Microphone permission denied. Please enable it in app settings.',
      );
    }
    try {
      final stream = await _recorder.startStream(
        // 44.1 kHz mono, sin procesado de voz (autoGain, echoCancel y noiseSuppress
        // quedan en su valor por defecto, desactivados): altera la guitarra.
        // Fuente de reconocimiento de voz: Android la exige sin control de
        // ganancia ni supresión de ruido, que en la fuente por defecto de
        // muchos teléfonos apagan una nota sostenida.
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceRecognition,
          ),
        ),
      );
      _carry = null;
      _odd = null;
      _buffer.clear();
      _recent.clear();
      _isListening = true;
      _mic = stream.listen(onBytes, onError: _controller.addError);
    } catch (e, st) {
      debugPrint('PitchService.startListening error: $e\n$st');
      _isListening = false;
      rethrow;
    }
  }

  Future<void> stopListening() => _inOrder(_stop);

  Future<void> _stop() async {
    if (!_isListening) return;
    _isListening = false;
    try {
      await _mic?.cancel();
      _mic = null;
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (e, st) {
      debugPrint('PitchService.stopListening error: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
    await _recorder.dispose();
  }

  /// Byte suelto del bloque anterior: un bloque puede cortar una muestra
  /// de 16 bits a la mitad, y sin él todo lo que sigue se leería corrido.
  int? _carry;

  /// Muestra a 44.1 kHz que espera su par para bajar a 22.05 kHz.
  double? _odd;

  /// Un bloque del micrófono (PCM de 16 bits a 44.1 kHz, de cualquier largo).
  @visibleForTesting
  void onBytes(Uint8List chunk) {
    var bytes = chunk;
    if (_carry case final c?) bytes = Uint8List.fromList([c, ...chunk]);
    _carry = bytes.length.isOdd ? bytes.last : null;
    var samples = pcm16ToSamples(bytes);
    if (_odd case final o?) samples = Float64List.fromList([o, ...samples]);
    _odd = samples.length.isOdd ? samples.last : null;
    _buffer.addAll(decimateByTwo(samples));
    while (_buffer.length >= _window) {
      final reading = analyze(Float64List.fromList(_buffer.sublist(0, _window)));
      _buffer.removeRange(0, _hop);
      if (reading != null && !_controller.isClosed) _controller.add(reading);
    }
  }

  /// Analiza una ventana (22.05 kHz) y devuelve la lectura estabilizada, o
  /// `null` si no hay nota (silencio, ruido): entonces se olvida el
  /// historial para que la nota siguiente no arrastre la anterior.
  @visibleForTesting
  PitchResult? analyze(Float64List window) {
    final hz = detectPitchHz(window, _rate);
    if (hz == null) {
      _recent.clear();
      return null;
    }
    _recent.add(hz);
    if (_recent.length > _median) _recent.removeAt(0);
    final sorted = [..._recent]..sort();
    return resultFor(sorted[sorted.length ~/ 2]);
  }

  /// Lectura de [hz] con el La de referencia actual.
  PitchResult resultFor(double hz) {
    final note = nearestNote(hz, a4: referenceA4);
    return PitchResult(
      noteName: note.name,
      frequency: hz,
      centsDeviation: note.cents,
      isInTune: note.cents.abs() <= 5,
    );
  }
}
