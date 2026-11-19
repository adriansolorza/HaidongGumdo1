import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/presentation/selection/selection_density.dart';

/// Densidad de la selección (Spec 006, FR-012a; research R7; contrato
/// selection-ui §3; tasks T019, T023).
void main() {
  group('choose', () {
    test('s = 1 y 4 tarjetas: 466 dp → regular; 465 dp → compact', () {
      expect(
        SelectionDensity.choose(columnsHeight: 466, scale: 1, maxCards: 4),
        SelectionDensity.regular,
      );
      expect(
        SelectionDensity.choose(columnsHeight: 465, scale: 1, maxCards: 4),
        SelectionDensity.compact,
      );
    });

    test('teléfono de 889 × 400 (s = 0.7, ≈ 185 dp libres) con 3 niveles → '
        'compact', () {
      expect(
        SelectionDensity.choose(columnsHeight: 185, scale: 0.7, maxCards: 3),
        SelectionDensity.compact,
      );
    });
  });

  test('compact: las medidas fijas de T019, en dp', () {
    final m = SelectionDensity.compact.metrics(0.7);
    expect(m.cardMinHeight, 48);
    expect((m.cardPaddingV, m.cardPaddingH, m.cardGap), (4, 12, 6));
    // El ícono más el padding vertical no superan la altura mínima.
    expect(m.iconTile + 2 * m.cardPaddingV, m.cardMinHeight);
    expect((m.iconTile, m.iconGlyph, m.iconGap), (40, 32, 10));
    expect((m.titleSize, m.detailSize, m.secondDetailSize), (16, 12, 12));
    expect(m.checkSize, 20);
    expect((m.columnHeaderSize, m.columnHeaderGap), (13, 6));
    expect((m.headerTitleSize, m.headerSubtitleSize), (32, 14));
    expect(
      (m.pagePaddingTop, m.pagePaddingBottom, m.pagePaddingSides),
      (16, 12, 24),
    );
    expect((m.sectionGap, m.columnsGap), (10, 20));
    expect(m.detailMaxLines, 2);
    expect(m.detailLineHeight, 1.25);
  });

  test('compact: radios y bordes escalan con min(s, 0.7)', () {
    expect(SelectionDensity.compact.metrics(1.2).decorScale, 0.7);
    expect(SelectionDensity.compact.metrics(0.7).decorScale, 0.7);
  });

  test('regular con s = 1: las medidas de la Spec 004, sin maxLines', () {
    final m = SelectionDensity.regular.metrics(1);
    expect(m.decorScale, 1);
    expect(m.cardMinHeight, 104);
    expect((m.cardPaddingV, m.cardPaddingH, m.cardGap), (14, 20, 14));
    expect((m.iconTile, m.iconGlyph, m.iconGap), (72, 56, 18));
    expect((m.titleSize, m.detailSize, m.secondDetailSize), (28, 17, 15));
    expect(m.checkSize, 30);
    expect((m.columnHeaderSize, m.columnHeaderGap), (18, 14));
    expect((m.headerTitleSize, m.headerSubtitleSize), (46, 20));
    expect(
      (m.pagePaddingTop, m.pagePaddingBottom, m.pagePaddingSides),
      (40, 36, 56),
    );
    expect((m.sectionGap, m.columnsGap), (28, 40));
    expect(m.detailMaxLines, isNull);
    expect(m.detailLineHeight, isNull);
  });

  test('regular escala con s', () {
    final m = SelectionDensity.regular.metrics(1.35);
    expect(m.cardMinHeight, closeTo(104 * 1.35, 1e-9));
    expect(m.titleSize, closeTo(28 * 1.35, 1e-9));
  });
}
