import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/opponent_motion.dart';
import 'package:haidonggumdo/presentation/exercise/painters/opponent_painter.dart';
import 'package:haidonggumdo/presentation/theme.dart';

import '../domain/fakes/test_session.dart';

final _pattern = testSession().pattern;

OpponentPainter _painter({
  SaberColor color = SaberColor.yellow,
  SaberPose? guard,
  CutMotion? cut,
  OpponentMotion motion = OpponentMotion.atGuard,
}) => OpponentPainter(
  saberColor: color,
  guard: guard ?? _pattern.guard,
  cut: cut ?? _pattern.cut,
  motion: motion,
);

void main() {
  group('tipDiameter (plan.md D2)', () {
    test('sin punta con una hoja larga', () {
      expect(OpponentPainter.tipDiameter(0.8), 0);
      expect(OpponentPainter.tipDiameter(1.0), 0);
    });

    test('punta máxima (0.3 u) con una hoja muy corta', () {
      expect(OpponentPainter.tipDiameter(0.2), closeTo(0.3, 1e-9));
      expect(OpponentPainter.tipDiameter(0.1), closeTo(0.3, 1e-9));
    });

    test('0.225 u con la guardia frontal (0.35 u visibles)', () {
      expect(OpponentPainter.tipDiameter(0.35), closeTo(0.225, 1e-9));
    });
  });

  group('shouldRepaint', () {
    test('false con los mismos valores', () {
      expect(_painter().shouldRepaint(_painter()), isFalse);
    });

    test('true si cambia el color, la guardia, el corte o el movimiento', () {
      final base = _painter();
      expect(_painter(color: SaberColor.blue).shouldRepaint(base), isTrue);
      expect(
        _painter(
          guard: const SaberPose(hilt: Point2(0, 0.1), tip: Point2(0, -0.2)),
        ).shouldRepaint(base),
        isTrue,
      );
      expect(
        _painter(
          cut: CutMotion(
            start: _pattern.cut.start,
            end: _pattern.cut.end,
            mirroredBySide: true,
          ),
        ).shouldRepaint(base),
        isTrue,
      );
      expect(
        _painter(
          motion: const OpponentMotion(
            from: PoseKey.guard,
            to: PoseKey.stance,
            progress: 0.5,
            side: Side.right,
          ),
        ).shouldRepaint(base),
        isTrue,
      );
    });
  });

  test('pinta cada postura y tramo en un lienzo de 1600×900 sin lanzar', () {
    final motions = [
      OpponentMotion.atGuard,
      for (final side in Side.values) ...[
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
        OpponentMotion(
          from: PoseKey.stance,
          to: PoseKey.cutEnd,
          progress: 0.7,
          side: side,
        ),
        OpponentMotion(
          from: PoseKey.cutEnd,
          to: PoseKey.guard,
          progress: 0.3,
          side: side,
        ),
      ],
    ];
    for (final motion in motions) {
      for (final cut in [
        _pattern.cut,
        CutMotion(
          start: _pattern.cut.start,
          end: _pattern.cut.end,
          mirroredBySide: true,
        ),
      ]) {
        final recorder = PictureRecorder();
        expect(
          () => _painter(
            cut: cut,
            motion: motion,
          ).paint(Canvas(recorder), const Size(1600, 900)),
          returnsNormally,
          reason: '$motion',
        );
        recorder.endRecording().dispose();
      }
    }
  });

  group('Patrón transversal (Spec 002)', () {
    final transversal = testTransversalSession().pattern;
    const width = 1600;
    const height = 900;

    double length(Point2 hilt, Point2 tip) {
      final dx = tip.x - hilt.x;
      final dy = tip.y - hilt.y;
      return sqrt(dx * dx + dy * dy);
    }

    Point2 mid(Point2 a, Point2 b) => Point2((a.x + b.x) / 2, (a.y + b.y) / 2);

    OpponentMotion still(PoseKey key, Side side) =>
        OpponentMotion(from: key, to: key, progress: 0, side: side);

    OpponentMotion halfSweep(Side side) => OpponentMotion(
      from: PoseKey.stance,
      to: PoseKey.cutEnd,
      progress: 0.5,
      side: side,
    );

    /// Pinta el patrón transversal con sable azul y devuelve los píxeles RGBA.
    Future<Uint8List> render(OpponentMotion motion) async {
      final recorder = PictureRecorder();
      OpponentPainter(
        saberColor: SaberColor.blue,
        guard: transversal.guard,
        cut: transversal.cut,
        motion: motion,
      ).paint(Canvas(recorder), const Size(1600, 900));
      final image = await recorder.endRecording().toImage(width, height);
      final data = await image.toByteData();
      image.dispose();
      return data!.buffer.asUint8List();
    }

    bool isSaber(Uint8List px, int i) {
      const c = AppColors.saberBlue;
      return (px[i] - (c.r * 255).round()).abs() <= 10 &&
          (px[i + 1] - (c.g * 255).round()).abs() <= 10 &&
          (px[i + 2] - (c.b * 255).round()).abs() <= 10 &&
          px[i + 3] > 200;
    }

    /// Columnas (x) de todos los píxeles del color del sable.
    List<int> saberColumns(Uint8List px) => [
      for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
          if (isSaber(px, (y * width + x) * 4)) x,
    ];

    double leftShare(Uint8List px) {
      final columns = saberColumns(px);
      expect(columns, isNotEmpty, reason: 'no se dibujó el sable');
      return columns.where((x) => x < width ~/ 2).length / columns.length;
    }

    /// Fracción de los píxeles pintados (no transparentes en alguna de las
    /// dos imágenes) de [a] que coinciden (±8 por canal) con [b] volteada en
    /// horizontal. El fondo transparente no cuenta: inflaría el resultado.
    double mirrorMatch(Uint8List a, Uint8List b) {
      var painted = 0;
      var equal = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          final j = (y * width + (width - 1 - x)) * 4;
          if (a[i + 3] == 0 && b[j + 3] == 0) continue;
          painted++;
          var same = true;
          for (var c = 0; c < 4; c++) {
            if ((a[i + c] - b[j + c]).abs() > 8) {
              same = false;
              break;
            }
          }
          if (same) equal++;
        }
      }
      return equal / painted;
    }

    test(
      'tipDiameter: 0 en los extremos y 0.3 u a la mitad del barrido (FR-009)',
      () {
        final start = transversal.cut.start;
        final end = transversal.cut.end;
        final startLength = length(start.hilt, start.tip);
        final endLength = length(end.hilt, end.tip);
        final midLength = length(
          mid(start.hilt, end.hilt),
          mid(start.tip, end.tip),
        );
        expect(startLength, closeTo(0.873, 0.001));
        expect(endLength, closeTo(0.873, 0.001));
        expect(midLength, closeTo(0.2, 1e-9));
        expect(OpponentPainter.tipDiameter(startLength), 0);
        expect(OpponentPainter.tipDiameter(endLength), 0);
        expect(OpponentPainter.tipDiameter(midLength), closeTo(0.3, 1e-9));
      },
    );

    test('pinta cada postura y tramo con ambos lados sin lanzar', () {
      for (final side in Side.values) {
        for (final motion in [
          OpponentMotion.atGuard,
          OpponentMotion(
            from: PoseKey.guard,
            to: PoseKey.stance,
            progress: 0.5,
            side: side,
          ),
          still(PoseKey.stance, side),
          halfSweep(side),
          still(PoseKey.cutEnd, side),
          OpponentMotion(
            from: PoseKey.cutEnd,
            to: PoseKey.guard,
            progress: 0.5,
            side: side,
          ),
        ]) {
          final recorder = PictureRecorder();
          expect(
            () => OpponentPainter(
              saberColor: SaberColor.blue,
              guard: transversal.guard,
              cut: transversal.cut,
              motion: motion,
            ).paint(Canvas(recorder), const Size(1600, 900)),
            returnsNormally,
            reason: '$motion',
          );
          recorder.endRecording().dispose();
        }
      }
    });

    test('(a) Sodose en el costado del corte (FR-007, SC-002)', () async {
      expect(
        leftShare(await render(still(PoseKey.stance, Side.right))),
        greaterThanOrEqualTo(0.95),
      );
      expect(
        leftShare(await render(still(PoseKey.stance, Side.left))),
        lessThanOrEqualTo(0.05),
      );
    });

    test('(a) el fin del barrido en el costado contrario (FR-008)', () async {
      expect(
        leftShare(await render(still(PoseKey.cutEnd, Side.right))),
        lessThanOrEqualTo(0.05),
      );
      expect(
        leftShare(await render(still(PoseKey.cutEnd, Side.left))),
        greaterThanOrEqualTo(0.95),
      );
    });

    test('(b) a la mitad del barrido el sable se ve, en la franja central (FR-009)', () async {
      for (final side in Side.values) {
        final columns = saberColumns(await render(halfSweep(side)));
        expect(columns, isNotEmpty, reason: '$side');
        expect(
          columns.every((x) => x >= width * 0.45 && x < width * 0.55),
          isTrue,
          reason: '$side',
        );
      }
    });

    for (final key in [PoseKey.stance, PoseKey.cutEnd]) {
      final name = key == PoseKey.stance ? 'Sodose' : 'el fin del barrido';

      test(
        '(c) $name: el lado left es el reflejo exacto del right (FR-011)',
        () async {
          final right = await render(still(key, Side.right));
          final left = await render(still(key, Side.left));
          expect(mirrorMatch(right, left), greaterThanOrEqualTo(0.99));
          // Control: sin reflejar no coincide, así que la prueba puede fallar.
          expect(mirrorMatch(right, right), lessThan(0.99));
        },
      );
    }
  });
}
