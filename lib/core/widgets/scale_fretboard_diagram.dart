import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/scale.dart';

/// Visual fretboard renderer for [ScaleFingering] position strings.
class ScaleFretboardDiagram extends StatelessWidget {
  const ScaleFretboardDiagram({
    super.key,
    required this.pattern,
    required this.accentColor,
  });

  final ScaleFingering pattern;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final parsed = _ParsedScalePattern.from(pattern);
    if (!parsed.hasDrawableStrings) return const SizedBox.shrink();

    return SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(
        painter: _ScaleFretboardPainter(
          pattern: parsed,
          accentColor: accentColor,
          colorScheme: Theme.of(context).colorScheme,
        ),
      ),
    );
  }
}

class _ParsedScalePattern {
  const _ParsedScalePattern({
    required this.positionsByString,
    required this.minFret,
    required this.maxFret,
  });

  factory _ParsedScalePattern.from(ScaleFingering pattern) {
    if (pattern.notes.isNotEmpty) {
      final strings = <int, List<int>>{};
      var minFret = 99;
      var maxFret = 0;
      for (final note in pattern.notes) {
        final stringIndex = 6 - note.stringNumber;
        final notes = strings[stringIndex] ??= <int>[];
        notes.add(note.fret);
        if (note.fret > 0) {
          minFret = math.min(minFret, note.fret);
          maxFret = math.max(maxFret, note.fret);
        }
      }
      if (minFret == 99) minFret = 1;
      if (maxFret == 0) maxFret = 5;
      return _ParsedScalePattern(
        positionsByString: strings,
        minFret: minFret,
        maxFret: maxFret,
      );
    }

    final strings = <int, List<int>>{};
    var minFret = 99;
    var maxFret = 0;

    final regex = RegExp(r'^(\d)(?:st|nd|rd|th)\s+string:\s*([\d-]+)$');
    for (final line in pattern.positions) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;

      final stringNumber = int.tryParse(match.group(1)!);
      final fingerings = match.group(2)!;
      if (stringNumber == null || stringNumber < 1 || stringNumber > 6) {
        continue;
      }

      final stringIndex = 6 - stringNumber;
      final frets = fingerings
          .split('-')
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: false);
      if (frets.isEmpty) continue;

      strings[stringIndex] = frets;
      for (final fret in frets) {
        if (fret > 0) {
          minFret = math.min(minFret, fret);
          maxFret = math.max(maxFret, fret);
        }
      }
    }

    if (minFret == 99) minFret = 1;
    if (maxFret == 0) maxFret = 5;

    return _ParsedScalePattern(
      positionsByString: strings,
      minFret: minFret,
      maxFret: maxFret,
    );
  }

  final Map<int, List<int>> positionsByString;
  final int minFret;
  final int maxFret;

  bool get hasDrawableStrings => positionsByString.isNotEmpty;
}

class _ScaleFretboardPainter extends CustomPainter {
  const _ScaleFretboardPainter({
    required this.pattern,
    required this.accentColor,
    required this.colorScheme,
  });

  final _ParsedScalePattern pattern;
  final Color accentColor;
  final ColorScheme colorScheme;

  static const _stringCount = 6;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 16.0;
    final right = size.width - 12;
    const top = 20.0;
    final bottom = size.height - 14;
    final width = right - left;
    final height = bottom - top;

    final baseFret = pattern.minFret > 1 ? pattern.minFret : 1;
    final fretSpan = math.max(4, (pattern.maxFret - baseFret) + 2);

    final stringSpacing = width / (_stringCount - 1);
    final fretSpacing = height / fretSpan;

    final fretPaint = Paint()
      ..color = colorScheme.outline.withAlpha(220)
      ..strokeWidth = 1;

    final nutPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = baseFret == 1 ? 3 : 1.5;

    for (var fret = 0; fret <= fretSpan; fret++) {
      final y = top + fret * fretSpacing;
      final paint = fret == 0 ? nutPaint : fretPaint;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }

    final stringPaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(190)
      ..strokeWidth = 1.2;
    for (var stringIndex = 0; stringIndex < _stringCount; stringIndex++) {
      final x = left + stringIndex * stringSpacing;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), stringPaint);
    }

    if (baseFret > 1) {
      _drawText(
        canvas,
        '$baseFret fr',
        Offset(right + 4, top + fretSpacing * 0.2),
        colorScheme.onSurfaceVariant,
      );
    }

    final markerPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (var stringIndex = 0; stringIndex < _stringCount; stringIndex++) {
      final stringFrets = pattern.positionsByString[stringIndex];
      if (stringFrets == null) continue;

      final x = left + stringIndex * stringSpacing;
      for (final fret in stringFrets) {
        if (fret <= 0) continue;
        final normalized = fret - baseFret + 0.5;
        if (normalized < 0 || normalized > fretSpan) continue;
        final y = top + normalized * fretSpacing;
        canvas.drawCircle(
          Offset(x, y),
          math.min(stringSpacing, fretSpacing) * 0.24,
          markerPaint,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ScaleFretboardPainter oldDelegate) =>
      oldDelegate.pattern != pattern ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.colorScheme != colorScheme;
}
