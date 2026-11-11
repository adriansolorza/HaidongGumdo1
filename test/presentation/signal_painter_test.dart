import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart' show CustomPainter;
import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/opponent_motion.dart';
import 'package:haidonggumdo/domain/exercise/signal.dart';
import 'package:haidonggumdo/presentation/exercise/painters/opponent_painter.dart';
import 'package:haidonggumdo/presentation/exercise/painters/signal_painter.dart';
import 'package:haidonggumdo/presentation/scene/scene_layout.dart';
import 'package:haidonggumdo/presentation/theme.dart';

/// Lienzos horizontales de las 4 proporciones de research R4.
const _sizes = {
  '20:9': (2000, 900),
  '16:9': (1600, 900),
  '16:10': (1600, 1000),
  '4:3': (1200, 900),
};

const _evasionRight = Signal(
  responseType: ResponseType.evasion,
  screenSide: Side.right,
);
const _evasionLeft = Signal(
  responseType: ResponseType.evasion,
  screenSide: Side.left,
);
const _defenseLeft = Signal(
  responseType: ResponseType.defense,
  screenSide: Side.left,
);

/// Píxeles RGBA de [painter] en un lienzo de [w] × [h].
Future<Uint8List> _render(CustomPainter painter, int w, int h) async {
  final recorder = PictureRecorder();
  painter.paint(Canvas(recorder), Size(w.toDouble(), h.toDouble()));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData();
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Catálogo real: la geometría de la escena depende de sus posturas.
final _catalog = const CatalogJsonMapper().fromJsonString(
  File('assets/catalog/catalog.json').readAsStringSync(),
);

/// Geometría compartida para un lienzo de [w] × [h] (Spec 004, research R5).
SceneLayout _layout(int w, int h, [Pattern? pattern]) => SceneLayout.compute(
  Size(w.toDouble(), h.toDouble()),
  pattern ?? _catalog.patterns.first,
);

SignalPainter _signal(Signal signal, SaberColor color, int w, int h) =>
    SignalPainter(layout: _layout(w, h), signal: signal, saberColor: color);

OpponentPainter _opponent(
  Pattern pattern,
  OpponentMotion motion,
  int w,
  int h,
) => OpponentPainter(
  layout: _layout(w, h, pattern),
  saberColor: SaberColor.blue,
  guard: pattern.guard,
  cut: pattern.cut,
  motion: motion,
);

bool _painted(Uint8List px, int i) => px[i + 3] > 0;

bool _isColor(Uint8List px, int i, Color c) =>
    (px[i] - (c.r * 255).round()).abs() <= 10 &&
    (px[i + 1] - (c.g * 255).round()).abs() <= 10 &&
    (px[i + 2] - (c.b * 255).round()).abs() <= 10 &&
    px[i + 3] > 200;

/// Columnas con al menos un píxel pintado, y cuántos píxeles tiene cada una.
Map<int, int> _columnHeights(Uint8List px, int w, int h) {
  final heights = <int, int>{};
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (_painted(px, (y * w + x) * 4)) {
        heights[x] = (heights[x] ?? 0) + 1;
      }
    }
  }
  return heights;
}

/// Alcance del oponente en píxeles (borde interior del carril) para un lienzo
/// de [w] × [h].
double _clearancePx(int w, int h) {
  final layout = _layout(w, h);
  return (layout.reachX + SceneLayout.laneGap) * layout.unit;
}

/// Largo pintado esperado: el tramo entre el alcance y el 4 % del borde, con
/// tope de 0.36 h más el contorno, que sobresale media línea en cada extremo.
double _expectedPaintedLength(int w, int h) {
  final span = w * 0.96 - (w / 2 + _clearancePx(w, h));
  final capped = 0.36 * h + kOutlineWidth;
  return span < capped ? span : capped;
}

void main() {
  group('evasión: colocación y forma (FR-006, FR-007)', () {
    for (final MapEntry(key: ratio, value: (w, h)) in _sizes.entries) {
      for (final (signal, color) in [
        (_evasionRight, SaberColor.blue),
        (_evasionLeft, SaberColor.red),
      ]) {
        final side = signal.screenSide;
        final name = '$ratio, ${side.name}';

        test('$name: en su mitad, fuera del alcance del oponente y a ≥ 4 % '
            'del borde', () async {
          final columns = _columnHeights(
            await _render(_signal(signal, color, w, h), w, h),
            w,
            h,
          ).keys;
          expect(columns, isNotEmpty);
          // ±1 px de tolerancia por el suavizado de bordes.
          final inner = w / 2 + _clearancePx(w, h) - 1;
          final outer = w * 0.96 + 1;
          for (final x in columns) {
            // La columna x cubre [x, x + 1); en la izquierda se refleja.
            final fromLeft = side == Side.right ? x : w - 1 - x;
            expect(fromLeft, greaterThanOrEqualTo(inner), reason: 'x = $x');
            expect(fromLeft + 1, lessThanOrEqualTo(outer), reason: 'x = $x');
          }
        });

        test('$name: largo y punta hacia el borde exterior', () async {
          final heights = _columnHeights(
            await _render(_signal(signal, color, w, h), w, h),
            w,
            h,
          );
          final columns = heights.keys.toList()..sort();
          // Distancia de cada columna al extremo interior, hacia el borde.
          final toEdge = side == Side.right
              ? columns
              : columns.reversed.toList();
          final length = (toEdge.last - toEdge.first).abs() + 1;
          expect(length, closeTo(_expectedPaintedLength(w, h), 3));

          int heightAt(double fraction) =>
              heights[toEdge[(fraction * (toEdge.length - 1)).round()]]!;
          final body = heightAt(0.25);
          final nearTip = heightAt(0.98);
          final tallest = toEdge.indexWhere(
            (x) => heights[x] == heights.values.reduce((a, b) => a > b ? a : b),
          );
          // El cuerpo mide 0.24 L y la punta 0.62 L: la columna más alta
          // está en la base de la punta (a 0.58 L del extremo interior).
          expect(tallest / toEdge.length, greaterThan(0.5));
          expect(heights[toEdge[tallest]]! / body, closeTo(0.62 / 0.24, 0.6));
          expect(nearTip, lessThan(body));
        });

        test('$name: relleno del color del sable, sin el otro color '
            '(FR-008)', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          final fill = color == SaberColor.blue
              ? AppColors.saberBlue
              : AppColors.saberRed;
          final other = color == SaberColor.blue
              ? AppColors.saberRed
              : AppColors.saberBlue;
          final columns = _columnHeights(px, w, h).keys.toList()..sort();
          final midX = (columns.first + columns.last) ~/ 2;
          expect(_isColor(px, ((h ~/ 2) * w + midX) * 4, fill), isTrue);
          var wrong = 0;
          for (var i = 0; i < px.length; i += 4) {
            if (_isColor(px, i, other)) wrong++;
          }
          expect(wrong, 0);
        });
      }

      test(
        '$ratio: la flecha izquierda es el reflejo exacto de la derecha',
        () async {
          final right = await _render(
            _signal(_evasionRight, SaberColor.blue, w, h),
            w,
            h,
          );
          final left = await _render(
            _signal(_evasionLeft, SaberColor.blue, w, h),
            w,
            h,
          );
          var painted = 0;
          var equal = 0;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final i = (y * w + x) * 4;
              final j = (y * w + (w - 1 - x)) * 4;
              if (right[i + 3] == 0 && left[j + 3] == 0) continue;
              painted++;
              if ([
                0,
                1,
                2,
                3,
              ].every((c) => (right[i + c] - left[j + c]).abs() <= 8)) {
                equal++;
              }
            }
          }
          expect(painted, greaterThan(0));
          expect(equal / painted, greaterThanOrEqualTo(0.99));
        },
      );
    }
  });

  group('defensa sin cambios (FR-012)', () {
    test('ignora saberColor: sigue blanca, sin azul ni rojo', () async {
      const w = 1600;
      const h = 900;
      final blue = await _render(
        _signal(_defenseLeft, SaberColor.blue, w, h),
        w,
        h,
      );
      final red = await _render(
        _signal(_defenseLeft, SaberColor.red, w, h),
        w,
        h,
      );
      expect(blue, red);
      var white = 0;
      var colored = 0;
      for (var i = 0; i < blue.length; i += 4) {
        if (_isColor(blue, i, AppColors.saberBlue) ||
            _isColor(blue, i, AppColors.saberRed)) {
          colored++;
        }
        if (_isColor(blue, i, AppColors.saberWhite)) white++;
      }
      expect(colored, 0);
      expect(white, greaterThan(0));
      final columns = _columnHeights(blue, w, h).keys;
      expect(columns.every((x) => x < w ~/ 2), isTrue);
    });
  });

  group('shouldRepaint', () {
    SignalPainter p(Signal s, SaberColor c) =>
        SignalPainter(layout: _layout(1600, 900), signal: s, saberColor: c);

    test('false con los mismos valores', () {
      expect(
        p(
          _evasionRight,
          SaberColor.blue,
        ).shouldRepaint(p(_evasionRight, SaberColor.blue)),
        isFalse,
      );
    });

    test('true si cambia la señal o el color', () {
      final base = p(_evasionRight, SaberColor.blue);
      expect(p(_evasionRight, SaberColor.red).shouldRepaint(base), isTrue);
      expect(p(_evasionLeft, SaberColor.blue).shouldRepaint(base), isTrue);
    });
  });

  group('alcance del oponente con el catálogo real (FR-007, research R4)', () {
    final catalog = const CatalogJsonMapper().fromJsonString(
      File('assets/catalog/catalog.json').readAsStringSync(),
    );
    final transversal = catalog.patterns.firstWhere(
      (p) => p.id == 'transversal',
    );

    OpponentMotion still(PoseKey key, Side side) =>
        OpponentMotion(from: key, to: key, progress: 0, side: side);

    // Todos los tramos del ataque, en pasos de 0.1, con los dos lados.
    final motions = [
      OpponentMotion.atGuard,
      for (final side in Side.values)
        for (final (from, to) in [
          (PoseKey.guard, PoseKey.stance),
          (PoseKey.stance, PoseKey.cutEnd),
          (PoseKey.cutEnd, PoseKey.guard),
        ])
          for (var i = 0; i <= 10; i++)
            OpponentMotion(from: from, to: to, progress: i / 10, side: side),
    ];

    for (final MapEntry(key: ratio, value: (w, h)) in _sizes.entries) {
      test('$ratio: ningún patrón pinta fuera del alcance en ninguna fase', () async {
        // Basta con mirar las columnas fuera del alcance, a los dos lados:
        // [0, leftEnd) y [rightStart, w).
        final limit = _clearancePx(w, h);
        final leftEnd = (w / 2 - limit).floor();
        final rightStart = (w / 2 + limit).ceil();
        final violations = <String>[];
        for (final pattern in catalog.patterns) {
          for (final motion in motions) {
            final px = await _render(_opponent(pattern, motion, w, h), w, h);
            var maxOut = 0.0;
            for (var y = 0; y < h; y++) {
              for (final range in [(0, leftEnd), (rightStart, w)]) {
                for (var x = range.$1; x < range.$2; x++) {
                  if (!_painted(px, (y * w + x) * 4)) continue;
                  final out = (x + 0.5 - w / 2).abs() - limit;
                  if (out > maxOut) maxOut = out;
                }
              }
            }
            if (maxOut > 0) {
              violations.add(
                '${pattern.id} $motion: ${maxOut.toStringAsFixed(1)} px fuera',
              );
            }
          }
        }
        expect(violations, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('$ratio: Sodose y el fin del barrido no tocan la flecha '
          '(caso límite)', () async {
        for (final (side, color, signal) in [
          (Side.right, SaberColor.blue, _evasionRight),
          (Side.left, SaberColor.red, _evasionLeft),
        ]) {
          final arrow = await _render(_signal(signal, color, w, h), w, h);
          for (final key in [PoseKey.stance, PoseKey.cutEnd]) {
            final opponent = await _render(
              _opponent(transversal, still(key, side), w, h),
              w,
              h,
            );
            var shared = 0;
            for (var i = 0; i < arrow.length; i += 4) {
              if (_painted(arrow, i) && _painted(opponent, i)) shared++;
            }
            expect(shared, 0, reason: '$side $key');
          }
        }
      });
    }
  });
}
