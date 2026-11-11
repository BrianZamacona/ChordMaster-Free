import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick_backing.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const am = ChordShape(name: 'Am', frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0]);
  const e = ChordShape(name: 'E', frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0]);
  // Am en los pulsos 1 y 2, E en el 3 y el 4.
  final strokes = <BackingStroke>[
    for (var b = 0; b < 4; b++) (shape: b < 2 ? am : e, position: b * tabQuarter),
  ];

  test('el acompañamiento suena más bajo que la frase', () {
    final sounds = lickBacking(strokes, from: 0, to: 4 * tabQuarter, bpm: 60);
    // Am en 5 cuerdas y E en 6, dos golpes cada uno.
    expect(sounds, hasLength(2 * 5 + 2 * 6));
    expect(sounds.every((s) => s.gain == lickBackingGain), isTrue);
    expect(lickBackingGain, lessThan(1));
    expect({for (final s in sounds) s.at.floor()}, {0, 1, 2, 3});
  });

  test('en un renglón suelto, solo sus golpes y contados desde su principio', () {
    final sounds = lickBacking(strokes, from: 2 * tabQuarter, to: 4 * tabQuarter, bpm: 60);
    expect(sounds, hasLength(2 * 6));
    expect(sounds.first.at, closeTo(0, 1e-9));
    expect({for (final s in sounds) s.at.floor()}, {0, 1});
  });

  test('con swing, un golpe en la «y» cae a 2/3 del pulso, como la frase', () {
    final offbeat = <BackingStroke>[(shape: am, position: tabEighth)];
    final straight = lickBacking(offbeat, from: 0, to: tabQuarter, bpm: 60);
    final swung = lickBacking(offbeat, from: 0, to: tabQuarter, bpm: 60, swing: TabSwing.eighths);
    expect(straight.first.at, closeTo(0.5, 1e-9));
    expect(swung.first.at, closeTo(2 / 3, 1e-9));
  });

  test('una cuerda con volumen 0 no cambia la mezcla', () {
    const a = StringSound(midi: 45, at: 0, seconds: 0.3);
    const b = StringSound(midi: 52, at: 0.1, seconds: 0.3);
    expect(renderStrings([a, b.withGain(0)], seconds: 0.5), renderStrings([a], seconds: 0.5));
    expect(b.withGain(0.4).toString(), endsWith('*0.40'));
    expect(b.toString(), isNot(contains('*')));
  });
}
