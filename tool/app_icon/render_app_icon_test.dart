// Genera el ícono de la app (Android, iOS y tienda) desde código.
//
//   flutter test tool/app_icon/render_app_icon_test.dart
//
// Dibuja un diagrama del acorde de C abierto (x32010) con los colores de la
// paleta Palisandro oscura: raíz = cuadrado latón, 3ª = círculo verde, como
// en la app. Escribe los PNG directamente (codificador propio, sin paquetes):
// iOS sin canal alfa (App Store lo exige) y Android con transparencia.
// Idempotente: correrlo dos veces deja los mismos archivos.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chordmaster_free/ui/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _p = AppPalette.dark;

/// Dibuja el ícono en un lienzo de [size] px.
///
/// - [background]: fondo palisandro (si no, transparente: capa frontal del
///   ícono adaptable de Android).
/// - [corner]: radio de las esquinas relativo al tamaño (0 = cuadrado; iOS
///   y el ícono adaptable redondean solos).
/// - [art]: fracción del lado que ocupa el diagrama.
void paintIcon(Canvas c, double size, {bool background = true, double corner = 0, double art = 0.62}) {
  final full = Offset.zero & Size(size, size);
  if (background) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size * 0.5, size * 0.32),
        size * 0.85,
        [_p.surfaceHigh, _p.background],
      );
    c.drawRRect(RRect.fromRectAndRadius(full, Radius.circular(size * corner)), paint);
  }

  // Diagrama: 6 cuerdas, cejuela y 3 trastes, centrado.
  final w = size * art * 0.86;
  final h = size * art;
  final left = (size - w) / 2;
  final top = (size - h) / 2 + size * 0.02;
  final gap = w / 5;
  final fret = h / 3.15;
  final stroke = size * 0.018;

  final wire = Paint()
    ..color = _p.fretWire
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;
  for (var f = 1; f <= 3; f++) {
    final y = top + f * fret;
    c.drawLine(Offset(left, y), Offset(left + w, y), wire);
  }
  final string = Paint()
    ..color = _p.fretString
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;
  for (var s = 0; s < 6; s++) {
    final x = left + s * gap;
    c.drawLine(Offset(x, top), Offset(x, top + 3 * fret + stroke), string);
  }
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left - stroke, top - stroke * 2.2, w + 2 * stroke, stroke * 3.2),
      Radius.circular(stroke),
    ),
    Paint()..color = _p.nut,
  );

  // C abierto: raíz en la 5ª (traste 3), 3ª en la 4ª (traste 2), raíz en la 2ª (traste 1).
  final r = gap * 0.4;
  Offset at(int stringFromLow, int f) => Offset(left + stringFromLow * gap, top + (f - 0.5) * fret);
  void root(Offset o) => c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCircle(center: o, radius: r), Radius.circular(r * 0.3)),
        Paint()..color = _p.intervalRoot,
      );
  root(at(1, 3));
  c.drawCircle(at(2, 2), r, Paint()..color = _p.intervalThird);
  root(at(4, 1));
}

Future<Uint8List> _render(int px, {required bool alpha, bool background = true, double corner = 0, double art = 0.62}) async {
  final recorder = ui.PictureRecorder();
  paintIcon(Canvas(recorder), px.toDouble(), background: background, corner: corner, art: art);
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  return encodePng(data!.buffer.asUint8List(), px, px, alpha: alpha);
}

/// PNG de 8 bits por canal (RGBA o RGB) a partir de RGBA sin premultiplicar.
Uint8List encodePng(Uint8List rgba, int width, int height, {required bool alpha}) {
  final channels = alpha ? 4 : 3;
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filtro "ninguno"
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.add(rgba.sublist(i, i + channels));
    }
  }
  final out = BytesBuilder()..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> body) {
    final typed = [...type.codeUnits, ...body];
    out
      ..add(_u32(body.length))
      ..add(typed)
      ..add(_u32(_crc32(typed)));
  }

  // Tipo de color: 6 = RGBA, 2 = RGB.
  final colorType = alpha ? 6 : 2;
  chunk('IHDR', [..._u32(width), ..._u32(height), 8, colorType, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes()));
  chunk('IEND', const []);
  return out.takeBytes();
}

List<int> _u32(int v) => [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255];

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera los íconos', () async {
    final files = <String, Uint8List>{};
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      // Android: ícono clásico (esquinas redondeadas) y capa frontal del
      // adaptable (108 dp; con art 0.46 las esquinas del diagrama quedan a
      // 32.8 dp del centro, dentro del círculo seguro de 33 dp).
      const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
      for (final MapEntry(key: d, value: k) in densities.entries) {
        final dir = 'android/app/src/main/res/mipmap-$d';
        files['$dir/ic_launcher.png'] = await _render((48 * k).round(), alpha: true, corner: 0.22);
        files['$dir/ic_launcher_foreground.png'] =
            await _render((108 * k).round(), alpha: true, background: false, art: 0.46);
      }
      // iOS: sin alfa ni esquinas (el sistema las recorta).
      const ios = {
        'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40, 'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29, 'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80, 'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120, 'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76, 'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167, 'Icon-App-1024x1024@1x.png': 1024,
      };
      for (final MapEntry(key: name, value: px) in ios.entries) {
        files['ios/Runner/Assets.xcassets/AppIcon.appiconset/$name'] = await _render(px, alpha: false);
      }
      // Google Play: 512 × 512 (Play redondea las esquinas).
      files['store/play_icon_512.png'] = await _render(512, alpha: true);
    });
    for (final MapEntry(key: path, value: bytes) in files.entries) {
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    }
    expect(files, hasLength(10 + 15 + 1));
  });
}
