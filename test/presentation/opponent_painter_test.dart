import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/opponent_motion.dart';
import 'package:haidonggumdo/presentation/exercise/painters/opponent_painter.dart';
import 'package:haidonggumdo/presentation/scene/scene_layout.dart';
import 'package:haidonggumdo/presentation/theme.dart';

import '../domain/fakes/test_session.dart';

final _pattern = testSession().pattern;

OpponentPainter _painter({
  SaberColor color = SaberColor.yellow,
  SaberPose? guard,
  CutMotion? cut,
  OpponentMotion motion = OpponentMotion.atGuard,
}) => OpponentPainter(
  layout: SceneLayout.compute(const Size(1600, 900), _pattern),
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
    // Catálogo real: la Spec 004 (FR-010) cambió sus posturas a horizontales.
    final transversal = const CatalogJsonMapper()
        .fromJsonString(File('assets/catalog/catalog.json').readAsStringSync())
        .patterns
        .firstWhere((p) => p.id == 'transversal');
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
        layout: SceneLayout.compute(const Size(1600, 900), transversal),
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

    /// Fracción de los píxeles del color del sable (en alguna de las dos
    /// imágenes) de [a] que también lo son en [b] volteada en horizontal. Solo
    /// cuenta el sable: el cuerpo no se refleja con el lado (Spec 004, Out of
    /// Scope).
    double saberMirrorMatch(Uint8List a, Uint8List b) {
      var painted = 0;
      var equal = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          final j = (y * width + (width - 1 - x)) * 4;
          final inA = isSaber(a, i);
          final inB = isSaber(b, j);
          if (!inA && !inB) continue;
          painted++;
          if (inA && inB) equal++;
        }
      }
      return equal / painted;
    }

    final layout = SceneLayout.compute(
      Size(width.toDouble(), height.toDouble()),
      transversal,
    );

    /// Filas (y) de todos los píxeles del color del sable.
    List<int> saberRows(Uint8List px) => [
      for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
          if (isSaber(px, (y * width + x) * 4)) y,
    ];

    test('tipDiameter: 0 en los extremos y 0.3 u a la mitad del barrido '
        '(Spec 002 FR-009; Spec 004 FR-011)', () {
      final start = transversal.cut.start;
      final end = transversal.cut.end;
      final startLength = length(start.hilt, start.tip);
      final endLength = length(end.hilt, end.tip);
      final midLength = length(
        mid(start.hilt, end.hilt),
        mid(start.tip, end.tip),
      );
      expect(startLength, closeTo(0.85, 1e-9));
      expect(endLength, closeTo(0.85, 1e-9));
      expect(midLength, closeTo(0, 1e-9));
      expect(OpponentPainter.tipDiameter(startLength), 0);
      expect(OpponentPainter.tipDiameter(endLength), 0);
      expect(OpponentPainter.tipDiameter(midLength), closeTo(0.3, 1e-9));
    });

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
              layout: SceneLayout.compute(const Size(1600, 900), transversal),
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

      test('(c) $name: el sable del lado left es el reflejo exacto del right '
          '(Spec 002 FR-011)', () async {
        final right = await render(still(key, Side.right));
        final left = await render(still(key, Side.left));
        expect(saberMirrorMatch(right, left), greaterThanOrEqualTo(0.98));
        // Control: sin reflejar no coincide, así que la prueba puede fallar.
        expect(saberMirrorMatch(right, right), lessThan(0.98));
      });

      test('$name: hoja horizontal a la altura de la cintura '
          '(Spec 004, FR-010, US1-4)', () async {
        final waist = layout.toScreen(const Point2(0, 0.1)).dy;
        for (final side in Side.values) {
          final rows = saberRows(await render(still(key, side)));
          expect(rows, isNotEmpty, reason: '$side');
          final top = rows.reduce((a, b) => a < b ? a : b);
          final bottom = rows.reduce((a, b) => a > b ? a : b);
          expect(
            bottom - top + 1,
            lessThanOrEqualTo(0.09 * layout.unit + 2 * kOutlineWidth + 2),
            reason: '$side',
          );
          expect((top + bottom + 1) / 2, closeTo(waist, 2), reason: '$side');
        }
      });
    }

    test('a la mitad del barrido se ve la punta de frente: disco del color '
        'del sable de ≥ 0.3 u (Spec 004, FR-011, US1-5)', () async {
      final center = layout.toScreen(const Point2(0, 0.1));
      final row = center.dy.round();
      for (final side in Side.values) {
        final px = await render(halfSweep(side));
        final xs = [
          for (var x = 0; x < width; x++)
            if (isSaber(px, (row * width + x) * 4)) x,
        ];
        expect(xs, isNotEmpty, reason: '$side');
        final span = xs.last - xs.first + 1;
        // El contorno se come media línea por dentro del disco.
        expect(
          span,
          greaterThanOrEqualTo(0.3 * layout.unit - kOutlineWidth - 2),
          reason: '$side',
        );
        expect((xs.first + xs.last + 1) / 2, closeTo(center.dx, 2));
      }
    });
  });

  group('escena de la Spec 004 con el catálogo real', () {
    final catalog = const CatalogJsonMapper().fromJsonString(
      File('assets/catalog/catalog.json').readAsStringSync(),
    );
    const sizes = {
      '20:9': (1600, 720),
      '16:9': (1600, 900),
      '16:10': (1440, 900),
      '4:3': (1200, 900),
    };

    final motions = [
      OpponentMotion.atGuard,
      for (final side in Side.values)
        for (final (from, to) in [
          (PoseKey.guard, PoseKey.stance),
          (PoseKey.stance, PoseKey.cutEnd),
          (PoseKey.cutEnd, PoseKey.guard),
        ])
          for (var i = 0; i <= 4; i++)
            OpponentMotion(from: from, to: to, progress: i / 4, side: side),
    ];

    for (final MapEntry(key: ratio, value: (w, h)) in sizes.entries) {
      test('$ratio: ningún píxel por encima de hudBottom en ninguna postura '
          '(FR-017, caso límite Chochôn-se)', () async {
        final violations = <String>[];
        for (final pattern in catalog.patterns) {
          final layout = SceneLayout.compute(
            Size(w.toDouble(), h.toDouble()),
            pattern,
          );
          final limit = layout.hudBottom.floor();
          for (final motion in motions) {
            final recorder = PictureRecorder();
            OpponentPainter(
              layout: layout,
              saberColor: SaberColor.blue,
              guard: pattern.guard,
              cut: pattern.cut,
              motion: motion,
            ).paint(Canvas(recorder), Size(w.toDouble(), h.toDouble()));
            final image = await recorder.endRecording().toImage(w, limit);
            final data = (await image.toByteData())!.buffer.asUint8List();
            image.dispose();
            var painted = 0;
            for (var i = 3; i < data.length; i += 4) {
              if (data[i] > 0) painted++;
            }
            if (painted > 0) violations.add('${pattern.id} $motion: $painted');
          }
        }
        expect(violations, isEmpty);
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    test('la figura no usa rojo, azul ni amarillo (FR-004, US1-3)', () async {
      const w = 1600;
      const h = 900;
      for (final pattern in catalog.patterns) {
        final recorder = PictureRecorder();
        OpponentPainter(
          layout: SceneLayout.compute(const Size(1600, 900), pattern),
          saberColor: SaberColor.white,
          guard: pattern.guard,
          cut: pattern.cut,
          motion: OpponentMotion.atGuard,
        ).paint(Canvas(recorder), const Size(1600, 900));
        final image = await recorder.endRecording().toImage(w, h);
        final px = (await image.toByteData(
          format: ImageByteFormat.rawStraightRgba,
        ))!.buffer.asUint8List();
        image.dispose();
        final wrong = <String>[];
        for (var i = 0; i < px.length; i += 4) {
          if (px[i + 3] < 128) continue;
          final r = px[i], g = px[i + 1], b = px[i + 2];
          final max = [r, g, b].reduce((a, c) => a > c ? a : c);
          final min = [r, g, b].reduce((a, c) => a < c ? a : c);
          final chroma = (max - min) / 255;
          if (chroma <= 0.10) continue;
          // Familia de la piel y la sombra (tono 15°–40°), no de señal.
          final hue = _hue(r, g, b);
          if (hue >= 15 && hue <= 40 && chroma <= 0.32) continue;
          if (wrong.length < 5) {
            wrong.add('(${(i ~/ 4) % w}, ${(i ~/ 4) ~/ w}) rgb($r, $g, $b)');
          }
        }
        expect(wrong, isEmpty, reason: pattern.id);
      }
    });
  });
}

/// Tono HSV en grados.
double _hue(int r, int g, int b) {
  final max = [r, g, b].reduce((a, c) => a > c ? a : c);
  final min = [r, g, b].reduce((a, c) => a < c ? a : c);
  final d = (max - min).toDouble();
  if (d == 0) return 0;
  double h;
  if (max == r) {
    h = ((g - b) / d) % 6;
  } else if (max == g) {
    h = (b - r) / d + 2;
  } else {
    h = (r - g) / d + 4;
  }
  return (h * 60 + 360) % 360;
}
