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
            'arriba y hacia el borde exterior', () async {
          final px = await _render(_signal(signal, color, w, h), w, h);
          final box = _bounds(px, w, h, (i) => px[i + 3] > 200)!;
          expect(box.height, greaterThanOrEqualTo(0.30 * h));
          final diagonal = box.size.longestSide;
          expect(box.width, greaterThanOrEqualTo(0.25 * diagonal));
          expect(box.height, greaterThanOrEqualTo(0.25 * diagonal));

          // La fila más alta del color está del lado exterior de la más baja.
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
            side == Side.right ? topX > bottomX : topX < bottomX,
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
}
