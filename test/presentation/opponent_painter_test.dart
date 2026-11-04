import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/opponent_motion.dart';
import 'package:haidonggumdo/presentation/exercise/painters/opponent_painter.dart';

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
}
