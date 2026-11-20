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
import 'package:haidonggumdo/presentation/exercise/painters/signal_shapes.dart';
import 'package:haidonggumdo/presentation/scene/scene_layout.dart';
import 'package:haidonggumdo/presentation/theme.dart';

/// Lienzos horizontales de las 4 proporciones (Spec 003 R4; Spec 004 SC-004).
const _sizes = {
  '20:9': (2000, 900),
  '16:9': (1600, 900),
  '16:10': (1600, 1000),
  '4:3': (1200, 900),
};

Signal _sig(ResponseType type, Side side) =>
    Signal(responseType: type, screenSide: side);

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

Color _fill(SaberColor c) =>
    c == SaberColor.blue ? AppColors.saberBlue : AppColors.saberRed;

Color _other(SaberColor c) =>
    c == SaberColor.blue ? AppColors.saberRed : AppColors.saberBlue;

/// Caja de los píxeles que cumplen [test], o `null` si no hay ninguno.
Rect? _bounds(Uint8List px, int w, int h, bool Function(int i) test) {
  int? left, top, right, bottom;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!test((y * w + x) * 4)) continue;
      left = left == null || x < left ? x : left;
      right = right == null || x > right ? x : right;
      top ??= y;
      bottom = y;
    }
  }
  if (left == null) return null;
  return Rect.fromLTRB(
    left.toDouble(),
    top!.toDouble(),
    right! + 1.0,
    bottom! + 1.0,
  );
}

/// Píxeles pintados fuera de [lane] (con 1 px de tolerancia por el
/// suavizado de bordes).
int _outside(Uint8List px, int w, int h, Rect lane) {
  final allowed = lane.inflate(1);
  var count = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!_painted(px, (y * w + x) * 4)) continue;
      if (!allowed.contains(Offset(x + 0.5, y + 0.5))) count++;
    }
  }
  return count;
}

/// Fracción de píxeles pintados de [a] iguales (±8 por canal) a los de [b]
/// volteada en horizontal.
double _mirrorMatch(Uint8List a, Uint8List b, int w, int h) {
  var painted = 0;
  var equal = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final j = (y * w + (w - 1 - x)) * 4;
      if (a[i + 3] == 0 && b[j + 3] == 0) continue;
      painted++;
      if ([0, 1, 2, 3].every((c) => (a[i + c] - b[j + c]).abs() <= 8)) {
        equal++;
      }
    }
  }
  return equal / painted;
}

void main() {
  group('evasión: flecha corta con estela (Spec 003 FR-006 a FR-008; '
      'Spec 004 FR-002, FR-013)', () {
    for (final MapEntry(key: ratio, value: (w, h)) in _sizes.entries) {
      for (final (side, color) in [
        (Side.right, SaberColor.blue),
        (Side.left, SaberColor.red),
      ]) {
        final name = '$ratio, ${side.name}';
        final signal = _sig(ResponseType.evasion, side);
        final lane = _layout(w, h).laneFor(side);

        test('$name: en su mitad y sin píxeles fuera del carril', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          final box = _bounds(px, w, h, (i) => _painted(px, i))!;
          expect(
            side == Side.right ? box.left >= w / 2 : box.right <= w / 2,
            isTrue,
          );
          expect(_outside(px, w, h, lane), 0);
        });

        test('$name: punta hacia el borde exterior y estela hacia el '
            'centro', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          final fill = _fill(color);
          final body = _bounds(px, w, h, (i) => _isColor(px, i, fill))!;
          // La punta (extremo angosto) está del lado del borde exterior; el
          // extremo interior es la cola del cuerpo, más alta. Además, la
          // columna más alta (base de la punta) es más alta que el cuerpo.
          int heightAt(int x) {
            var n = 0;
            for (var y = 0; y < h; y++) {
              if (_isColor(px, (y * w + x) * 4, fill)) n++;
            }
            return n;
          }

          final inset = (0.05 * body.width).round();
          final rightEnd = heightAt(body.right.toInt() - 1 - inset);
          final leftEnd = heightAt(body.left.toInt() + inset);
          final (outerEnd, innerEnd) = side == Side.right
              ? (rightEnd, leftEnd)
              : (leftEnd, rightEnd);
          expect(outerEnd, lessThan(innerEnd), reason: 'punta hacia el borde');
          var tallest = 0;
          for (var x = body.left.toInt(); x < body.right; x++) {
            final n = heightAt(x);
            if (n > tallest) tallest = n;
          }
          expect(tallest, greaterThan(1.8 * innerEnd), reason: 'punta ancha');

          // Estela: píxeles semitransparentes del color más allá de la cola
          // (fuera del alcance del brillo, 3σ = 0.12 L).
          final l = body.width;
          final beyond = side == Side.right
              ? body.left - 0.15 * l
              : body.right + 0.15 * l;
          final pastTipLimit = side == Side.right
              ? body.right + 0.15 * l
              : body.left - 0.15 * l;
          var trail = 0;
          var pastTip = 0;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final i = (y * w + x) * 4;
              final a = px[i + 3];
              if (a == 0 || a > 200) continue;
              final tinted = color == SaberColor.blue
                  ? px[i + 2] > px[i]
                  : px[i] > px[i + 2];
              if (!tinted) continue;
              if (side == Side.right ? x < beyond : x > beyond) trail++;
              if (side == Side.right ? x > pastTipLimit : x < pastTipLimit) {
                pastTip++;
              }
            }
          }
          expect(trail, greaterThan(0), reason: 'estela hacia el centro');
          expect(pastTip, 0, reason: 'nada más allá de la punta');
        });

        test('$name: relleno del color del sable, sin el otro color '
            '(Spec 003 FR-008)', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          final body = _bounds(px, w, h, (i) => _isColor(px, i, _fill(color)))!;
          final center = body.center.dy.toInt() * w + body.center.dx.toInt();
          expect(_isColor(px, center * 4, _fill(color)), isTrue);
          var wrong = 0;
          for (var i = 0; i < px.length; i += 4) {
            if (_isColor(px, i, _other(color))) wrong++;
          }
          expect(wrong, 0);
        });
      }

      test('$ratio: la flecha izquierda es el reflejo exacto de la '
          'derecha', () async {
        final right = await _render(
          _signal(
            _sig(ResponseType.evasion, Side.right),
            SaberColor.blue,
            w,
            h,
          ),
          w,
          h,
        );
        final left = await _render(
          _signal(_sig(ResponseType.evasion, Side.left), SaberColor.blue, w, h),
          w,
          h,
        );
        expect(_mirrorMatch(right, left, w, h), greaterThanOrEqualTo(0.99));
      });
    }
  });

  group('defensa del color del sable (Spec 004, FR-014)', () {
    for (final MapEntry(key: ratio, value: (w, h)) in _sizes.entries) {
      for (final (side, color) in [
        (Side.left, SaberColor.blue),
        (Side.right, SaberColor.red),
      ]) {
        final name = '$ratio, ${side.name}';
        final signal = _sig(ResponseType.defense, side);
        final lane = _layout(w, h).laneFor(side);

        test('$name: en su carril, con hoja del color, guarda gris y sin el '
            'otro color', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          expect(_outside(px, w, h, lane), 0);
          var blade = 0;
          var guard = 0;
          var wrong = 0;
          for (var i = 0; i < px.length; i += 4) {
            if (_isColor(px, i, _fill(color))) blade++;
            if (_isColor(px, i, AppColors.tsuba)) guard++;
            if (_isColor(px, i, _other(color))) wrong++;
          }
          expect(blade, greaterThan(0));
          expect(guard, greaterThan(0));
          expect(wrong, 0);
        });

        test('$name: en diagonal, de al menos 30 % del alto, con la punta '
            'arriba y hacia el centro (hacia el oponente)', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          final box = _bounds(px, w, h, (i) => px[i + 3] > 200)!;
          expect(box.height, greaterThanOrEqualTo(0.30 * h));
          final diagonal = box.size.longestSide;
          expect(box.width, greaterThanOrEqualTo(0.25 * diagonal));
          expect(box.height, greaterThanOrEqualTo(0.25 * diagonal));

          // La fila más alta del color está del lado del centro respecto de la
          // más baja (punta hacia el oponente; spec, Clarifications 2026-11-16).
          final fill = _fill(color);
          final colored = _bounds(px, w, h, (i) => _isColor(px, i, fill))!;
          double meanX(int row) {
            var sum = 0, n = 0;
            for (var x = 0; x < w; x++) {
              if (_isColor(px, (row * w + x) * 4, fill)) {
                sum += x;
                n++;
              }
            }
            return sum / n;
          }

          final topX = meanX(colored.top.toInt() + 2);
          final bottomX = meanX(colored.bottom.toInt() - 3);
          expect(
            side == Side.right ? topX < bottomX : topX > bottomX,
            isTrue,
            reason: 'top $topX, bottom $bottomX',
          );
        });
      }

      test('$ratio: la defensa izquierda es el reflejo exacto de la '
          'derecha', () async {
        final right = await _render(
          _signal(_sig(ResponseType.defense, Side.right), SaberColor.red, w, h),
          w,
          h,
        );
        final left = await _render(
          _signal(_sig(ResponseType.defense, Side.left), SaberColor.red, w, h),
          w,
          h,
        );
        expect(_mirrorMatch(right, left, w, h), greaterThanOrEqualTo(0.99));
      });
    }
  });

  group('shouldRepaint', () {
    SignalPainter p(Signal s, SaberColor c, [int w = 1600]) =>
        SignalPainter(layout: _layout(w, 900), signal: s, saberColor: c);
    final right = _sig(ResponseType.evasion, Side.right);
    final left = _sig(ResponseType.evasion, Side.left);

    test('false con los mismos valores', () {
      expect(
        p(right, SaberColor.blue).shouldRepaint(p(right, SaberColor.blue)),
        isFalse,
      );
    });

    test('true si cambia la señal, el color o la geometría', () {
      final base = p(right, SaberColor.blue);
      expect(p(right, SaberColor.red).shouldRepaint(base), isTrue);
      expect(p(left, SaberColor.blue).shouldRepaint(base), isTrue);
      expect(p(right, SaberColor.blue, 2000).shouldRepaint(base), isTrue);
    });
  });

  group('alcance con el catálogo real (Spec 003 FR-007; Spec 004 SC-004)', () {
    OpponentMotion still(PoseKey key, Side side) =>
        OpponentMotion(from: key, to: key, progress: 0, side: side);

    // Tramos de T024: guardia, subida a la postura, postura, mitad del
    // barrido, fin del corte y regreso, con los dos lados.
    final motions = [
      OpponentMotion.atGuard,
      for (final side in Side.values) ...[
        OpponentMotion(
          from: PoseKey.guard,
          to: PoseKey.stance,
          progress: 0.5,
          side: side,
        ),
        still(PoseKey.stance, side),
        OpponentMotion(
          from: PoseKey.stance,
          to: PoseKey.cutEnd,
          progress: 0.5,
          side: side,
        ),
        still(PoseKey.cutEnd, side),
        OpponentMotion(
          from: PoseKey.cutEnd,
          to: PoseKey.guard,
          progress: 0.5,
          side: side,
        ),
      ],
    ];

    for (final MapEntry(key: ratio, value: (w, h)) in _sizes.entries) {
      test('$ratio: ningún patrón pinta dentro de los carriles en ninguna '
          'fase', () async {
        final layout = _layout(w, h);
        final violations = <String>[];
        for (final pattern in _catalog.patterns) {
          for (final motion in [
            ...motions,
            for (final side in Side.values)
              for (var i = 0; i <= 10; i++)
                OpponentMotion(
                  from: PoseKey.stance,
                  to: PoseKey.cutEnd,
                  progress: i / 10,
                  side: side,
                ),
          ]) {
            final px = await _render(_opponent(pattern, motion, w, h), w, h);
            var inside = 0;
            for (final lane in [layout.leftLane, layout.rightLane]) {
              for (var y = lane.top.floor(); y < lane.bottom.ceil(); y++) {
                for (var x = lane.left.floor(); x < lane.right.ceil(); x++) {
                  if (_painted(px, (y * w + x) * 4)) inside++;
                }
              }
            }
            if (inside > 0) violations.add('${pattern.id} $motion: $inside');
          }
        }
        expect(violations, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('$ratio: ninguna señal comparte píxeles con el oponente ni cae en '
          'las zonas de botón (SC-004, FR-017)', () async {
        final layout = _layout(w, h);
        final signals = <String, Uint8List>{};
        for (final type in ResponseType.values) {
          for (final (side, color) in [
            (Side.right, SaberColor.blue),
            (Side.left, SaberColor.red),
          ]) {
            final name = '${type.name} ${side.name}';
            final px = await _render(
              _signal(_sig(type, side), color, w, h),
              w,
              h,
            );
            signals[name] = px;
            var inButtons = 0;
            for (final zone in [
              layout.bottomLeftButton,
              layout.bottomRightButton,
            ]) {
              for (var y = zone.top.floor(); y < zone.bottom.ceil(); y++) {
                for (var x = zone.left.floor(); x < zone.right.ceil(); x++) {
                  if (px[(y * w + x) * 4 + 3] > 2) inButtons++;
                }
              }
            }
            expect(inButtons, 0, reason: name);
          }
        }
        final shared = <String>[];
        for (final pattern in _catalog.patterns) {
          for (final motion in motions) {
            final opponent = await _render(
              _opponent(pattern, motion, w, h),
              w,
              h,
            );
            for (final MapEntry(key: name, value: px) in signals.entries) {
              var n = 0;
              for (var i = 0; i < px.length; i += 4) {
                if (_painted(px, i) && _painted(opponent, i)) n++;
              }
              if (n > 0) shared.add('${pattern.id} $motion $name: $n');
            }
          }
        }
        expect(shared, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 3)));
    }
  });

  group('contraataque (Spec 007, contrato §4)', () {
    final transversal = _catalog.patterns.firstWhere(
      (p) => p.id == 'transversal',
    );

    for (final MapEntry(key: ratio, value: (w, h))
        in _counterCanvases.entries) {
      final layout = _layout(w, h, transversal);
      SignalPainter painter(ResponseType type, Side side, SaberColor color) =>
          SignalPainter(
            layout: layout,
            signal: _sig(type, side),
            saberColor: color,
          );

      for (final (side, color) in [
        (Side.right, SaberColor.blue),
        (Side.left, SaberColor.red),
      ]) {
        test('$ratio, ${side.name}: P1, ningún píxel fuera de su carril y '
            'del lado de su mitad', () async {
          final px = await _render(
            painter(ResponseType.counter, side, color),
            w,
            h,
          );
          final box = _bounds(px, w, h, (i) => _painted(px, i))!;
          expect(
            side == Side.right ? box.left >= w / 2 : box.right <= w / 2,
            isTrue,
          );
          expect(_outside(px, w, h, layout.laneFor(side)), 0);
        });

        test('$ratio, ${side.name}: P6, flecha y hoja del color del sable, '
            'guarda gris, sin el otro color ni amarillo', () async {
          final px = await _render(
            painter(ResponseType.counter, side, color),
            w,
            h,
          );
          var fill = 0, guard = 0, wrong = 0, yellow = 0;
          for (var i = 0; i < px.length; i += 4) {
            if (_isColor(px, i, _fill(color))) fill++;
            if (_isColor(px, i, AppColors.tsuba)) guard++;
            if (_isColor(px, i, _other(color))) wrong++;
            if (_isColor(px, i, AppColors.saberYellow)) yellow++;
          }
          expect(fill, greaterThan(0));
          expect(guard, greaterThan(0));
          expect(wrong, 0);
          expect(yellow, 0);
        });
      }

      test('$ratio: P2, la flecha mide al menos 75 % de la flecha de evasión '
          '(FR-010)', () async {
        final evasion = await _render(
          painter(ResponseType.evasion, Side.right, SaberColor.blue),
          w,
          h,
        );
        final counter = await _render(
          painter(ResponseType.counter, Side.right, SaberColor.blue),
          w,
          h,
        );
        final le = _measureArrowLength(evasion, w, h, AppColors.saberBlue);
        final lc = _measureArrowLength(counter, w, h, AppColors.saberBlue);
        expect(
          lc,
          greaterThanOrEqualTo(0.75 * le - 2),
          reason: 'Lc $lc, L2 $le',
        );
        expect(lc, lessThanOrEqualTo(le + 2), reason: 'Lc $lc, L2 $le');
      });

      test('$ratio: P3 a P5, sable vertical junto a la punta y centrado en el '
          'eje de la flecha (FR-007)', () async {
        final px = await _render(
          painter(ResponseType.counter, Side.right, SaberColor.blue),
          w,
          h,
        );
        final arrow = _arrowGeometry(px, w, h, AppColors.saberBlue);
        final lc = arrow.length;

        // Hoja: interior opaco y claro (relleno del color y reflejo blanco,
        // sin el contorno oscuro) a la derecha de la punta. El reflejo va a
        // un lado de la hoja, así que el relleno solo no está centrado. Se
        // empieza después del contorno de la punta de la flecha, cuyos bordes
        // suavizados también son claros.
        bool bladeInterior(int i) =>
            px[i + 3] > 200 && px[i] + px[i + 1] + px[i + 2] > 300;
        final rows = <int, (int, int)>{};
        final firstX = arrow.tipX + 2 * kOutlineWidth.ceil() + 1;
        for (var y = 0; y < h; y++) {
          for (var x = firstX; x < w; x++) {
            if (!bladeInterior((y * w + x) * 4)) continue;
            final (lo, hi) = rows[y] ?? (x, x);
            rows[y] = (x < lo ? x : lo, x > hi ? x : hi);
          }
        }
        expect(rows, isNotEmpty, reason: 'sin hoja a la derecha de la punta');
        final ys = rows.keys.toList()..sort();
        final top = ys.first, bottom = ys.last;

        // P6 (FR-009): la hoja se ve del color del sable en casi toda su
        // altura, no solo contorno y reflejo (pantallas chicas incluidas).
        var blueRows = 0;
        for (final y in ys) {
          for (var x = firstX; x < w; x++) {
            if (_isColor(px, (y * w + x) * 4, AppColors.saberBlue)) {
              blueRows++;
              break;
            }
          }
        }
        expect(
          blueRows,
          greaterThanOrEqualTo(0.6 * (bottom - top)),
          reason: 'filas de la hoja con azul: $blueRows de ${bottom - top}',
        );

        // P4: el centro de la hoja tiene el mismo x en toda su altura.
        final centers = [
          for (final y in ys)
            if (y > top + 0.1 * (bottom - top) &&
                y < bottom - 0.1 * (bottom - top))
              (rows[y]!.$1 + rows[y]!.$2) / 2,
        ];
        final axisX = centers.reduce((a, b) => a + b) / centers.length;
        for (final c in centers) {
          expect((c - axisX).abs(), lessThanOrEqualTo(1), reason: 'eje $axisX');
        }

        // P3: el eje del sable está del lado de la punta (hacia el borde) y la
        // caja del sable (eje ± 0.15 Lc) empieza a ≤ 0.15 Lc de la punta.
        expect(axisX, greaterThan(arrow.tipX));
        // El relleno medido acaba antes del vértice por el contorno (3 px de
        // trazo hacia dentro, √2 veces más en la punta de 90°).
        expect(
          axisX - arrow.tipX,
          lessThanOrEqualTo(0.30 * lc + 2 * kOutlineWidth),
        );

        // P5: el sable (de la punta de la hoja al extremo de la empuñadura,
        // sobre su eje) está centrado en el eje de la flecha.
        final column = axisX.round();
        int? saberTop, saberBottom;
        for (var y = 0; y < h; y++) {
          if (px[(y * w + column) * 4 + 3] > 200) {
            saberTop ??= y;
            saberBottom = y;
          }
        }
        final saberCenter = (saberTop! + saberBottom! + 1) / 2;
        expect(
          (saberCenter - arrow.cy).abs(),
          lessThanOrEqualTo(2),
          reason: 'sable $saberCenter, flecha ${arrow.cy}',
        );
        // Alto: igual al de la punta o apenas mayor (Clarifications). El
        // sable se mide con su contorno (más largo en la punta afilada) y la
        // flecha solo con su relleno.
        final saberHeight = saberBottom - saberTop + 1;
        expect(
          saberHeight,
          inInclusiveRange(
            0.95 * arrow.headHeight,
            1.35 * arrow.headHeight + 2 * kOutlineWidth,
          ),
        );
      });

      test('$ratio: P6, el contraataque izquierdo es el reflejo exacto del '
          'derecho', () async {
        final right = await _render(
          painter(ResponseType.counter, Side.right, SaberColor.blue),
          w,
          h,
        );
        final left = await _render(
          painter(ResponseType.counter, Side.left, SaberColor.blue),
          w,
          h,
        );
        expect(_mirrorMatch(right, left, w, h), greaterThanOrEqualTo(0.99));
      });

      test('$ratio: la señal no comparte píxeles con el oponente transversal '
          'en ninguna fase del corte (SC-003, SC-009)', () async {
        final violations = <String>[];
        for (final (side, color) in [
          (Side.right, SaberColor.blue),
          (Side.left, SaberColor.red),
        ]) {
          final signal = await _render(
            painter(ResponseType.counter, side, color),
            w,
            h,
          );
          // El corte sale del costado que indica el color: con azul
          // (motion.side right), del lado contrario a la señal.
          for (final motion in [
            OpponentMotion.atGuard,
            OpponentMotion(
              from: PoseKey.guard,
              to: PoseKey.stance,
              progress: 0.5,
              side: side,
            ),
            for (var i = 0; i <= 20; i++)
              OpponentMotion(
                from: PoseKey.stance,
                to: PoseKey.cutEnd,
                progress: i / 20,
                side: side,
              ),
            OpponentMotion(
              from: PoseKey.cutEnd,
              to: PoseKey.guard,
              progress: 0.5,
              side: side,
            ),
          ]) {
            final opponent = await _render(
              _opponent(transversal, motion, w, h),
              w,
              h,
            );
            var n = 0;
            for (var i = 0; i < signal.length; i += 4) {
              if (_painted(signal, i) && _painted(opponent, i)) n++;
            }
            if (n > 0) violations.add('${side.name} $motion: $n');
          }
        }
        expect(violations, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });

  _counterFrontalGroup();
}

/// Spec 007, US2 (T018): con el patrón frontal, la señal de contraataque queda
/// en su carril y no comparte píxeles con el oponente al subir a
/// *Chochôn-se*, durante el corte ni al regresar (FR-013, SC-009).
void _counterFrontalGroup() {
  group('contraataque con el patrón frontal (Spec 007, US2)', () {
    final frontal = _catalog.patterns.firstWhere((p) => p.id == 'frontal');

    for (final MapEntry(key: ratio, value: (w, h))
        in _counterCanvases.entries) {
      final layout = _layout(w, h, frontal);

      test('$ratio: P1 en su carril y sin píxeles compartidos con el oponente '
          'en ninguna fase', () async {
        final violations = <String>[];
        for (final (side, color) in [
          (Side.right, SaberColor.blue),
          (Side.left, SaberColor.red),
        ]) {
          final signal = await _render(
            SignalPainter(
              layout: layout,
              signal: _sig(ResponseType.counter, side),
              saberColor: color,
            ),
            w,
            h,
          );
          expect(
            _outside(signal, w, h, layout.laneFor(side)),
            0,
            reason: side.name,
          );
          for (final motion in [
            OpponentMotion.atGuard,
            OpponentMotion(
              from: PoseKey.guard,
              to: PoseKey.stance,
              progress: 0.5,
              side: side,
            ),
            OpponentMotion(
              from: PoseKey.stance,
              to: PoseKey.stance,
              progress: 0,
              side: side,
            ),
            for (var i = 0; i <= 20; i++)
              OpponentMotion(
                from: PoseKey.stance,
                to: PoseKey.cutEnd,
                progress: i / 20,
                side: side,
              ),
            OpponentMotion(
              from: PoseKey.cutEnd,
              to: PoseKey.guard,
              progress: 0.5,
              side: side,
            ),
          ]) {
            final opponent = await _render(
              _opponent(frontal, motion, w, h),
              w,
              h,
            );
            var n = 0;
            for (var i = 0; i < signal.length; i += 4) {
              if (_painted(signal, i) && _painted(opponent, i)) n++;
            }
            if (n > 0) violations.add('${side.name} $motion: $n');
          }
        }
        expect(violations, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });
}

/// Los 7 lienzos de referencia de la Spec 006 (Spec 007, T014).
const _counterCanvases = {
  ..._sizes,
  '4:3 (Spec 005)': (1024, 768),
  '20:9 grande': (2400, 1080),
  'teléfono 20:9': (889, 400),
};

/// Geometría de la flecha que apunta a la derecha, medida en píxeles de
/// relleno sólido de [color]. La flecha es el tramo de columnas contiguas con
/// más relleno: la estela puede dejar columnas sueltas del color y el sable
/// del contraataque queda separado por la abertura.
({int tipX, double length, double headHeight, double cy}) _arrowGeometry(
  Uint8List px,
  int w,
  int h,
  Color color,
) {
  final counts = List<int>.filled(w, 0);
  final tops = List<int>.filled(w, h);
  final bottoms = List<int>.filled(w, -1);
  for (var x = 0; x < w; x++) {
    for (var y = 0; y < h; y++) {
      if (_isColor(px, (y * w + x) * 4, color)) {
        counts[x]++;
        if (y < tops[x]) tops[x] = y;
        bottoms[x] = y;
      }
    }
  }
  var startX = 0, endX = -1, best = 0;
  for (var x = 0; x < w;) {
    if (counts[x] == 0) {
      x++;
      continue;
    }
    final from = x;
    var total = 0;
    while (x < w && counts[x] > 0) {
      total += counts[x++];
    }
    if (total > best) (best, startX, endX) = (total, from, x - 1);
  }
  final heights = counts.sublist(startX, endX + 1);
  // Eje: centro de los bordes de arriba y abajo de la flecha (la punta es
  // simétrica); el reflejo blanco quita relleno solo arriba.
  var top = h, bottom = -1;
  for (var x = startX; x <= endX; x++) {
    if (tops[x] < top) top = tops[x];
    if (bottoms[x] > bottom) bottom = bottoms[x];
  }
  final maxHeight = heights.reduce((a, b) => a > b ? a : b);
  final headStart = heights.indexWhere((n) => n >= 0.8 * maxHeight);
  final tipX = startX + heights.length - 1;
  final headLength = (heights.length - headStart).toDouble();
  return (
    tipX: tipX,
    length: headLength / SignalShapes.arrowHeadLength,
    headHeight: (bottom - top + 1).toDouble(),
    cy: (top + bottom + 1) / 2,
  );
}

/// Largo `L` de la flecha que apunta a la derecha, medido en píxeles
/// (Spec 007, contrato P2): largo de la punta / `arrowHeadLength`.
double _measureArrowLength(Uint8List px, int w, int h, Color color) =>
    _arrowGeometry(px, w, h, color).length;
