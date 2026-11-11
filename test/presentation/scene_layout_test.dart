import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/presentation/scene/dojang_painter.dart';
import 'package:haidonggumdo/presentation/scene/scene_layout.dart';
import 'package:haidonggumdo/presentation/theme.dart';

/// Lienzos de data-model §2: 20:9, 16:9, 16:10, 4:3 y un teléfono 20:9.
const _sizes = {
  '20:9': Size(1778, 800),
  '16:9': Size(1422, 800),
  '16:10': Size(1280, 800),
  '4:3': Size(1067, 800),
  'teléfono': Size(889, 400),
};

/// Caja de la figura sin sable (data-model §4), en u.
const _figureLeft = -0.70;
const _figureRight = 0.70;
const _figureTop = -1.03;
const _figureBottom = 1.42;

List<Point2> _posePoints(Pattern p) => [
  p.guard.hilt,
  p.guard.tip,
  p.cut.start.hilt,
  p.cut.start.tip,
  p.cut.end.hilt,
  p.cut.end.tip,
];

void main() {
  final catalog = const CatalogJsonMapper().fromJsonString(
    File('assets/catalog/catalog.json').readAsStringSync(),
  );
  final frontal = catalog.patterns.firstWhere((p) => p.id == 'frontal');

  group('valores de referencia (data-model §2)', () {
    test('1280 × 800 con el frontal', () {
      final layout = SceneLayout.compute(const Size(1280, 800), frontal);
      expect(layout.hudScale, 1);
      expect(layout.hudBottom, closeTo(129, 1e-9));
      expect(layout.unit, closeTo(204.1, 0.5));
      expect(layout.origin.dy, closeTo(482, 1));
      expect(layout.origin.dx, 640);
      expect(layout.reachX, closeTo(1.43, 1e-9));
    });

    test('889 × 400: la escala del HUD no baja de 0.7', () {
      final layout = SceneLayout.compute(const Size(889, 400), frontal);
      expect(layout.hudScale, 0.7);
    });
  });

  for (final pattern in catalog.patterns) {
    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      group('${pattern.id}, $name', () {
        final layout = SceneLayout.compute(size, pattern);
        final w = size.width;
        final h = size.height;
        final figure = Rect.fromPoints(
          layout.toScreen(const Point2(_figureLeft, _figureTop)),
          layout.toScreen(const Point2(_figureRight, _figureBottom)),
        );

        test('la figura y el sable quedan entre hudBottom y 0.965 h '
            '(FR-017)', () {
          for (final p in _posePoints(pattern)) {
            final top = layout.toScreen(
              Point2(p.x, p.y - SceneLayout.saberExtent),
            );
            expect(
              top.dy,
              greaterThanOrEqualTo(layout.hudBottom - 1e-9),
              reason: '$p',
            );
          }
          expect(
            layout.origin.dy + SceneLayout.figureBottom * layout.unit,
            lessThanOrEqualTo(0.965 * h + 1e-9),
          );
          expect(figure.top, greaterThanOrEqualTo(layout.hudBottom));
        });

        test('los carriles quedan fuera del alcance y a 4 % del borde '
            '(FR-002)', () {
          final reach = layout.reachX * layout.unit;
          expect(
            layout.rightLane.left,
            greaterThanOrEqualTo(layout.origin.dx + reach),
          );
          expect(
            layout.leftLane.right,
            lessThanOrEqualTo(layout.origin.dx - reach),
          );
          expect(layout.rightLane.right, closeTo(0.96 * w, 1e-9));
          expect(layout.leftLane.left, closeTo(0.04 * w, 1e-9));
          expect(layout.rightLane.width, greaterThanOrEqualTo(0.20 * h - 1e-9));
        });

        test('los carriles no tocan las zonas de botón y cabe la defensa '
            'más alta (FR-017)', () {
          for (final lane in [layout.leftLane, layout.rightLane]) {
            expect(lane.overlaps(layout.bottomLeftButton), isFalse);
            expect(lane.overlaps(layout.bottomRightButton), isFalse);
            expect(
              lane.height,
              greaterThanOrEqualTo(0.45 * h + 2 * (3 * 0.009 * h)),
            );
          }
        });

        test('los botones no se cruzan con la figura', () {
          expect(layout.bottomLeftButton.overlaps(figure), isFalse);
          expect(layout.bottomRightButton.overlaps(figure), isFalse);
        });

        test('laneFor devuelve el carril de cada mitad', () {
          expect(layout.leftLane.center.dx, lessThan(w / 2));
          expect(layout.rightLane.center.dx, greaterThan(w / 2));
        });
      });
    }
  }

  test('un patrón que sube más el sable reduce la figura y conserva las '
      'invariantes (Principio III)', () {
    final tall = Pattern(
      id: 'test_tall',
      order: 9,
      name: 'Alto',
      guardTermId: frontal.guardTermId,
      stanceTermId: frontal.stanceTermId,
      cutTermId: frontal.cutTermId,
      guard: frontal.guard,
      cut: const CutMotion(
        start: SaberPose(hilt: Point2(0, -0.9), tip: Point2(0, -1.9)),
        end: SaberPose(hilt: Point2(0, -0.2), tip: Point2(0, -0.35)),
        mirroredBySide: false,
      ),
    );
    const size = Size(1280, 800);
    final base = SceneLayout.compute(size, frontal);
    final layout = SceneLayout.compute(size, tall);
    expect(layout.unit, lessThan(base.unit));
    final top = layout.toScreen(
      const Point2(0, -1.9 - SceneLayout.saberExtent),
    );
    expect(top.dy, greaterThanOrEqualTo(layout.hudBottom - 1e-9));
    expect(
      layout.origin.dy + SceneLayout.figureBottom * layout.unit,
      lessThanOrEqualTo(0.965 * size.height + 1e-9),
    );
  });

  group('dojang (FR-007)', () {
    bool near(int value, double channel, int tolerance) =>
        (value - (channel * 255).round()).abs() <= tolerance;

    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      test('$name: llena la pantalla sin franjas y sin deformarse', () async {
        final layout = SceneLayout.compute(size, frontal);
        final w = size.width.toInt();
        final h = size.height.toInt();
        final recorder = PictureRecorder();
        DojangPainter(layout: layout).paint(Canvas(recorder), size);
        final image = await recorder.endRecording().toImage(w, h);
        final px = (await image.toByteData())!.buffer.asUint8List();
        image.dispose();

        var transparent = 0;
        for (var i = 3; i < px.length; i += 4) {
          if (px[i] != 255) transparent++;
        }
        expect(transparent, 0, reason: 'píxeles sin cubrir');

        int at(Offset o) => (o.dy.round() * w + o.dx.round()) * 4;

        // Zócalo a la misma altura en u en todas las proporciones.
        final baseboard = at(layout.toScreen(const Point2(0, 0.57)));
        const c = AppColors.baseboard;
        expect(near(px[baseboard], c.r, 3), isTrue, reason: 'zócalo R');
        expect(near(px[baseboard + 1], c.g, 3), isTrue, reason: 'zócalo G');
        expect(near(px[baseboard + 2], c.b, 3), isTrue, reason: 'zócalo B');

        // Pared: dentro del degradado (con el haz de luz encima, más claro).
        final wall = at(layout.toScreen(const Point2(0, 0.40)));
        for (final (ch, lo, hi) in [
          (0, AppColors.wallBottom.r, AppColors.wallTop.r),
          (1, AppColors.wallBottom.g, AppColors.wallTop.g),
          (2, AppColors.wallBottom.b, AppColors.wallTop.b),
        ]) {
          expect(
            px[wall + ch],
            inInclusiveRange((lo * 255).round() - 3, (hi * 255).round() + 3),
            reason: 'pared canal $ch',
          );
        }
      });
    }
  });
}
