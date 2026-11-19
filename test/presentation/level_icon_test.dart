import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/presentation/exercise/painters/signal_shapes.dart';
import 'package:haidonggumdo/presentation/selection/level_icon.dart';

/// Ícono de nivel con una o varias señales (Spec 006, FR-013; research R6;
/// contrato selection-ui §2; tasks T022).

const _side = 64;
const _size = Size(64, 64);

/// Copia de las fórmulas del ícono anterior a la Spec 006 (un solo glifo en
/// la caja útil), para comparar la geometría.
void _referenceGlyph(Canvas canvas, Rect box, ResponseType type) {
  final white = Paint()..color = const Color(0xFFFFFFFF);
  switch (type) {
    case ResponseType.evasion:
      final l = box.width / 1.45;
      final arrowHeight = SignalShapes.arrowHeadHeight * l;
      final arrow = Rect.fromLTWH(
        box.right - l,
        box.center.dy - arrowHeight / 2,
        l,
        arrowHeight,
      );
      canvas.drawPath(SignalShapes.evasionArrow(arrow), white);
      final line = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 0.09 * l
        ..strokeCap = StrokeCap.round;
      final gap = 0.04 * l;
      for (final (dy, start) in const [
        (-0.18, 0.10),
        (0.0, 0.0),
        (0.18, 0.10),
      ]) {
        final y = box.center.dy + dy * l;
        canvas.drawLine(
          Offset(box.left + start * l + line.strokeWidth / 2, y),
          Offset(arrow.left - gap - line.strokeWidth / 2, y),
          line,
        );
      }
    case ResponseType.defense:
      final saber = SignalShapes.defenseSaber(
        SignalShapes.fitDefense(box, box.height),
      );
      canvas
        ..drawPath(saber.grip, white)
        ..drawPath(saber.guard, white)
        ..drawPath(saber.blade, white);
  }
}

/// Píxeles RGBA sin premultiplicar de lo que pinta [paint] en 64 × 64.
Future<Uint8List> _pixels(
  WidgetTester tester,
  void Function(Canvas canvas) paint,
) async => (await tester.runAsync(() async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_side, _side);
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  return data!.buffer.asUint8List();
}))!;

/// Caja que contiene todos los píxeles pintados con x en [fromX, toX).
Rect? _bounds(Uint8List px, {int fromX = 0, int toX = _side}) {
  var (left, top, right, bottom) = (_side, _side, -1, -1);
  for (var y = 0; y < _side; y++) {
    for (var x = fromX; x < toX; x++) {
      if (px[(y * _side + x) * 4 + 3] > 0) {
        left = math.min(left, x);
        top = math.min(top, y);
        right = math.max(right, x);
        bottom = math.max(bottom, y);
      }
    }
  }
  return right < 0
      ? null
      : Rect.fromLTRB(
          left.toDouble(),
          top.toDouble(),
          right + 1.0,
          bottom + 1.0,
        );
}

void _expectClose(Rect? actual, Rect? expected, String reason) {
  expect(actual, isNotNull, reason: reason);
  expect(expected, isNotNull, reason: reason);
  for (final (a, e) in [
    (actual!.left, expected!.left),
    (actual.top, expected.top),
    (actual.right, expected.right),
    (actual.bottom, expected.bottom),
  ]) {
    expect((a - e).abs(), lessThanOrEqualTo(1), reason: '$reason: $actual');
  }
}

void main() {
  // La caja útil: el ícono menos un margen del 10 % del lado.
  final box = (Offset.zero & _size).deflate(0.10 * _size.shortestSide);

  for (final type in ResponseType.values) {
    testWidgets('un tipo ($type): la misma geometría que antes (FR-013)', (
      tester,
    ) async {
      final actual = await _pixels(
        tester,
        (c) => LevelIconPainter([type]).paint(c, _size),
      );
      final expected = await _pixels(
        tester,
        (c) => _referenceGlyph(c, box, type),
      );
      _expectClose(_bounds(actual), _bounds(expected), '$type');
    });
  }

  testWidgets('dos tipos: el sable a la izquierda y la flecha a la derecha, '
      'solo en blanco (FR-013, regla de color)', (tester) async {
    final px = await _pixels(
      tester,
      (c) =>
          const LevelIconPainter([ResponseType.defense, ResponseType.evasion])
              .paint(c, _size),
    );

    // Solo blanco (con su antialiasing) o transparente: nada de rojo, azul
    // ni amarillo.
    for (var i = 0; i < px.length; i += 4) {
      if (px[i + 3] == 0) continue;
      expect(
        [px[i], px[i + 1], px[i + 2]],
        everyElement(greaterThanOrEqualTo(250)),
        reason: 'píxel ${i ~/ 4}',
      );
    }

    // Celdas: 2 de ancho (caja − separación del 8 %) / 2; cada glifo en el
    // cuadrado más grande que cabe, centrado.
    final gap = 0.08 * box.width;
    final cellWidth = (box.width - gap) / 2;
    Rect glyphBox(int i) => Rect.fromCenter(
      center: Offset(
        box.left + i * (cellWidth + gap) + cellWidth / 2,
        box.center.dy,
      ),
      width: cellWidth,
      height: cellWidth,
    );
    final defense = await _pixels(
      tester,
      (c) => _referenceGlyph(c, glyphBox(0), ResponseType.defense),
    );
    final evasion = await _pixels(
      tester,
      (c) => _referenceGlyph(c, glyphBox(1), ResponseType.evasion),
    );
    const middle = _side ~/ 2;
    _expectClose(
      _bounds(px, toX: middle),
      _bounds(defense),
      'mitad izquierda: sable',
    );
    _expectClose(
      _bounds(px, fromX: middle),
      _bounds(evasion),
      'mitad derecha: flecha',
    );
  });

  test('shouldRepaint compara las listas de tipos', () {
    const a = LevelIconPainter([ResponseType.defense, ResponseType.evasion]);
    expect(
      a.shouldRepaint(
        const LevelIconPainter([ResponseType.defense, ResponseType.evasion]),
      ),
      isFalse,
    );
    expect(
      a.shouldRepaint(const LevelIconPainter([ResponseType.defense])),
      isTrue,
    );
  });
}
