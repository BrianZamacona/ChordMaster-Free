/// Notas que empiezan, a partir de los cuadros que analiza el micrófono:
/// cuándo se pulsa una cuerda y qué nota suena. Sirve para seguir una
/// melodía nota por nota (una a la vez, no acordes).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'pitch_detection.dart';
import 'pluck_synth.dart';

/// Un cuadro de análisis: instante (segundos, por el reloj de muestras),
/// nivel y nivel de agudos ([attackLevelOf]) de lo último que entró, altura
/// detectada (`null` = sin nota clara) y, si se esperaba una nota, qué tan
/// presente está ([periodicityAt]: cerca de 0 = suena).
typedef PitchFrame = ({
  double at,
  double rms,
  double attack,
  double? hz,
  double? fit,
});

/// Una nota que empieza: MIDI, instante y si hubo ataque (se pulsó) o solo
/// cambió la altura (un ligado, o la mezcla de cuerdas que siguen sonando).
typedef HeardNote = ({int midi, double at, bool plucked});

/// Analiza una ventana del micrófono: los niveles salen de las últimas [hop]
/// muestras (lo que acaba de entrar, así el ataque se ubica bien), la altura
/// de la ventana entera con YIN y, con [expectedMidi], cuánto suena esa nota.
/// En un acorde, la nota esperada (la más grave) se busca con el periodo del
/// acorde entero: [periodDivisor] veces el suyo.
///
/// [sounding] = las últimas notas oídas, que pueden seguir sonando y tapar
/// la esperada (una nota apagada con la palma se apaga enseguida bajo una
/// cuerda que sigue abierta). La esperada también se busca sin ellas
/// ([withoutPeriod]) y vale la mejor de las dos medidas. No se quita una
/// nota cuyo periodo cabe entero en el de la esperada: lo que quedara de
/// ella lo cumpliría.
PitchFrame analyzeFrame(
  Float64List window,
  int sampleRate, {
  required double at,
  required int hop,
  int? expectedMidi,
  int periodDivisor = 1,
  List<int> sounding = const [],
  double a4 = 440,
}) {
  double? fit;
  if (expectedMidi != null) {
    final hz = midiToHz(expectedMidi) * a4 / 440 / periodDivisor;
    fit = _fitOf(window, sampleRate, hz);
    var rest = window;
    for (final midi in sounding) {
      final other = midiToHz(midi) * a4 / 440;
      final ratio = other / hz;
      if ((ratio - ratio.round()).abs() > 0.03 * ratio) {
        rest = withoutPeriod(rest, sampleRate, other);
      }
    }
    if (!identical(rest, window)) fit = math.min(fit, _fitOf(rest, sampleRate, hz));
  }
  return (
    at: at,
    rms: rmsOf(window, from: window.length - hop),
    attack: attackLevelOf(window, from: window.length - hop),
    hz: detectPitchHz(window, sampleRate),
    fit: fit,
  );
}

double _fitOf(Float64List window, int sampleRate, double hz) =>
    periodicityAt(window, sampleRate, hz, minHz: math.min(60, hz * 0.95));

/// Convierte cuadros en notas que empiezan.
///
/// - Un **ataque** es un salto del nivel de agudos ([onsetRatio] veces el
///   menor de los últimos cuadros) con sonido por encima de [minRms]. La púa
///   suena sobre todo aguda, así que se nota aunque otras cuerdas sigan
///   sonando. Los cuadros del ataque no se usan para la altura de YIN: su
///   ventana mezcla lo de antes con lo nuevo. En su cola (el ataque ya baja)
///   sí cuenta el periodo de la nota esperada: una nota apagada con la palma
///   se apaga antes de que el ataque termine.
/// - **La nota esperada** se da por oída tras un ataque cuando está presente
///   (`fit` bajo [fitThreshold], y YIN no oye clara una nota vecina) en
///   [confirmFrames] cuadros seguidos, aunque otra cuerda siga sonando.
/// - **Cualquier otra nota** necesita que YIN dé la misma altura en
///   [confirmFrames] cuadros seguidos y, o bien un ataque (la misma nota
///   pulsada otra vez), o bien que la altura cambie (sin ataque: un ligado o
///   la mezcla de cuerdas que suenan, que no cuenta como error).
/// - El instante es el del ataque o, sin ataque, el del primer cuadro con la
///   altura nueva.
class NoteOnsetDetector {
  NoteOnsetDetector({
    this.a4 = 440,
    this.onsetRatio = 2,
    this.minRms = 0.01,
    this.confirmFrames = 2,
    this.fitThreshold = 0.5,
  });

  final double a4;
  final double onsetRatio;
  final double minRms;
  final int confirmFrames;
  final double fitThreshold;

  /// Cuadros que puede esperar un ataque a que la altura se aclare.
  static const _onsetPatience = 4;

  /// Cuadros que abarca un ataque.
  static const _attackFrames = 3;

  /// Nivel de agudos de los últimos cuadros: un ataque se mide contra el
  /// menor (puede repartirse en dos cuadros).
  final _recentAttack = <double>[];
  double? _onsetAt;
  int _onsetAge = 0;
  int? _sounding;
  int? _candidate;
  int _count = 0;
  double _candidateAt = 0;
  int _fitCount = 0;

  /// Olvida todo (al volver a empezar).
  void reset() {
    _recentAttack.clear();
    _onsetAt = null;
    _onsetAge = 0;
    _sounding = null;
    _candidate = null;
    _count = 0;
    _fitCount = 0;
  }

  /// Un cuadro más ([expected]: la nota que se espera, la misma con la que
  /// se calculó `fit`); devuelve la nota que acaba de empezar, si hay una.
  /// Con [chord], lo esperado es un acorde con esa nota en el bajo: su
  /// periodo también lo cumplen la quinta o la octava solas, así que si YIN
  /// oye clara una sola nota, tiene que ser la del bajo (en cualquier octava).
  HeardNote? feed(PitchFrame f, {int? expected, bool chord = false}) {
    final floor = _recentAttack.isEmpty ? 0.0 : _recentAttack.reduce(math.min);
    final previous = _recentAttack.isEmpty ? 0.0 : _recentAttack.last;
    final attack = f.rms >= minRms && f.attack > floor * onsetRatio;
    _recentAttack.add(f.attack);
    if (_recentAttack.length > _attackFrames) _recentAttack.removeAt(0);
    final present = _isPresent(f, expected, chord: chord);
    if (attack) {
      // Un ataque que sigue en el cuadro siguiente es el mismo.
      final ongoing = _onsetAt != null && _onsetAge < _attackFrames;
      // Si ya baja, es su cola: la nota nueva domina la ventana y su periodo
      // cuenta. Una nota corta (apagada con la palma) se apaga antes de que
      // termine el ataque, sobre todo tras un silencio, cuando el piso es 0.
      final fading = ongoing && f.attack < previous;
      if (!ongoing) _onsetAt = f.at;
      _onsetAge = 0;
      _candidate = null;
      _count = 0;
      _fitCount = fading && present ? _fitCount + 1 : 0;
      if (_fitCount >= confirmFrames) return _emit(expected!, _onsetAt!, plucked: true);
      return null;
    }
    if (_onsetAt != null && ++_onsetAge > _onsetPatience) _onsetAt = null;

    // La nota esperada, tras un ataque.
    _fitCount = present ? _fitCount + 1 : 0;
    if (_onsetAt case final at? when present && _fitCount >= confirmFrames) {
      return _emit(expected!, at, plucked: true);
    }

    final hz = f.hz;
    if (hz == null) {
      _candidate = null;
      _count = 0;
      if (f.rms < minRms) _sounding = null;
      return null;
    }
    final midi = nearestNote(hz, a4: a4).midi;
    if (midi == _candidate) {
      _count++;
    } else {
      _candidate = midi;
      _count = 1;
      _candidateAt = f.at;
    }
    if (_count < confirmFrames) return null;
    if (midi == _sounding && _onsetAt == null) return null;
    return _emit(midi, _onsetAt ?? _candidateAt, plucked: _onsetAt != null);
  }

  /// La nota esperada suena en este cuadro: su periodo está (`fit` bajo
  /// [fitThreshold]) y YIN no oye clara una vecina (a uno o dos semitonos:
  /// el valle de la diferencia es ancho y una vecina también lo deja bajo;
  /// una nota lejana puede ser otra cuerda que sigue sonando). En un acorde,
  /// lo que YIN oiga claro tiene que ser el bajo, en cualquier octava.
  bool _isPresent(PitchFrame f, int? expected, {required bool chord}) {
    final fit = f.fit;
    final hz = f.hz;
    if (expected == null || fit == null || fit >= fitThreshold || f.rms < minRms) return false;
    if (hz == null) return true;
    final heard = nearestNote(hz, a4: a4).midi;
    final neighbour = heard != expected && (heard - expected).abs() <= 2;
    final notTheBass = chord && (heard - expected) % 12 != 0;
    return !neighbour && !notTheBass;
  }

  HeardNote _emit(int midi, double at, {required bool plucked}) {
    _onsetAt = null;
    _sounding = midi;
    _candidate = midi;
    _count = confirmFrames;
    return (midi: midi, at: at, plucked: plucked);
  }
}
