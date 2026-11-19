import 'dart:math' as math;

/// Densidad de la pantalla de selección (Spec 006, FR-012a; research R7;
/// contrato selection-ui §3). `regular` son las medidas de la Spec 004;
/// `compact` reduce tarjetas, encabezado, márgenes y separaciones cuando las
/// tarjetas no caben sin desplazar. El pie no cambia con la densidad.
enum SelectionDensity {
  regular,
  compact;

  /// `regular` si [maxCards] tarjetas de nivel o de patrón caben en
  /// [columnsHeight] con sus medidas regulares (altura mínima, separaciones
  /// y el margen del anillo de la seleccionada); si no, `compact`.
  static SelectionDensity choose({
    required double columnsHeight,
    required double scale,
    required int maxCards,
  }) {
    final s = scale;
    final needed = maxCards * 104 * s + (maxCards - 1) * 14 * s + 8 * s;
    return needed <= columnsHeight ? regular : compact;
  }

  /// Medidas en dp con la escala [scale] (`SceneLayout.hudScale`).
  SelectionMetrics metrics(double scale) => switch (this) {
    regular => SelectionMetrics._(
      decorScale: scale,
      cardMinHeight: 104 * scale,
      cardPaddingV: 14 * scale,
      cardPaddingH: 20 * scale,
      cardGap: 14 * scale,
      iconTile: 72 * scale,
      iconGlyph: 56 * scale,
      iconGap: 18 * scale,
      titleSize: 28 * scale,
      detailSize: 17 * scale,
      secondDetailSize: 15 * scale,
      checkSize: 30 * scale,
      columnHeaderSize: 18 * scale,
      columnHeaderGap: 14 * scale,
      headerTitleSize: 46 * scale,
      headerSubtitleSize: 20 * scale,
      pagePaddingTop: 40 * scale,
      pagePaddingBottom: 36 * scale,
      pagePaddingSides: 56 * scale,
      sectionGap: 28 * scale,
      columnsGap: 40 * scale,
      detailMaxLines: null,
      detailLineHeight: null,
    ),
    compact => SelectionMetrics._(
      decorScale: math.min(scale, 0.7),
      cardMinHeight: 48,
      // 40 del ícono + 2 × 4 = 48, la altura mínima (con 6 serían 52).
      cardPaddingV: 4,
      cardPaddingH: 12,
      cardGap: 6,
      iconTile: 40,
      iconGlyph: 32,
      iconGap: 10,
      titleSize: 16,
      detailSize: 12,
      secondDetailSize: 12,
      checkSize: 20,
      columnHeaderSize: 13,
      columnHeaderGap: 6,
      headerTitleSize: 32,
      headerSubtitleSize: 14,
      pagePaddingTop: 16,
      pagePaddingBottom: 12,
      pagePaddingSides: 24,
      sectionGap: 10,
      columnsGap: 20,
      detailMaxLines: 2,
      detailLineHeight: 1.25,
    ),
  };
}

/// Medidas de la selección para una densidad y una escala (Spec 006, T019).
final class SelectionMetrics {
  const SelectionMetrics._({
    required this.decorScale,
    required this.cardMinHeight,
    required this.cardPaddingV,
    required this.cardPaddingH,
    required this.cardGap,
    required this.iconTile,
    required this.iconGlyph,
    required this.iconGap,
    required this.titleSize,
    required this.detailSize,
    required this.secondDetailSize,
    required this.checkSize,
    required this.columnHeaderSize,
    required this.columnHeaderGap,
    required this.headerTitleSize,
    required this.headerSubtitleSize,
    required this.pagePaddingTop,
    required this.pagePaddingBottom,
    required this.pagePaddingSides,
    required this.sectionGap,
    required this.columnsGap,
    required this.detailMaxLines,
    required this.detailLineHeight,
  });

  /// Escala de radios, bordes, anillo y espaciado entre letras: `s` en
  /// `regular` y `min(s, 0.7)` en `compact`.
  final double decorScale;
  final double cardMinHeight;
  final double cardPaddingV;
  final double cardPaddingH;
  final double cardGap;
  final double iconTile;
  final double iconGlyph;
  final double iconGap;
  final double titleSize;
  final double detailSize;
  final double secondDetailSize;
  final double checkSize;
  final double columnHeaderSize;
  final double columnHeaderGap;
  final double headerTitleSize;
  final double headerSubtitleSize;
  final double pagePaddingTop;
  final double pagePaddingBottom;
  final double pagePaddingSides;
  final double sectionGap;
  final double columnsGap;

  /// Solo en `compact` (T020): cada texto de detalle, como máximo 2 líneas.
  final int? detailMaxLines;

  /// Solo en `compact`: altura de línea de los detalles, la que supone el
  /// cálculo de T021 (12 × 1.25). En `regular`, la de la letra (Spec 004).
  final double? detailLineHeight;
}
