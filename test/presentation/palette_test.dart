import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/presentation/theme.dart';

/// Croma de un color, sin contar el alfa: `(max(R,G,B) − min(R,G,B)) / 255`
/// (research R9).
double _chroma(Color c) {
  final channels = [c.r, c.g, c.b];
  final max = channels.reduce((a, b) => a > b ? a : b);
  final min = channels.reduce((a, b) => a < b ? a : b);
  return max - min;
}

String _hex(Color c) => c.toARGB32().toRadixString(16).padLeft(8, '0');

/// Regla de color (Spec 004, FR-004, FR-005; data-model §3): rojo, azul y
/// amarillo solo en el sable y las señales.
void main() {
  const signal = [
    AppColors.saberBlue,
    AppColors.saberRed,
    AppColors.saberYellow,
  ];

  test('la interfaz y el equipo del oponente son grises: croma ≤ 0.10', () {
    for (final (group, colors) in [
      ('interfaz', AppColors.interfaceColors),
      ('figura', AppColors.figureColors),
    ]) {
      for (final c in colors) {
        expect(
          _chroma(c),
          lessThanOrEqualTo(0.10),
          reason: '$group: ${_hex(c)}',
        );
      }
    }
  });

  test('los tonos del dojang son cálidos apagados: croma ≤ 0.45', () {
    for (final c in AppColors.dojangColors) {
      expect(_chroma(c), lessThanOrEqualTo(0.45), reason: _hex(c));
    }
  });

  test('los colores de señal no aparecen fuera de su grupo', () {
    for (final c in signal) {
      // Son los únicos con croma alto: muy por encima de los límites.
      expect(_chroma(c), greaterThan(0.80), reason: _hex(c));
      expect(AppColors.interfaceColors, isNot(contains(c)));
      expect(AppColors.figureColors, isNot(contains(c)));
      expect(AppColors.dojangColors, isNot(contains(c)));
    }
  });

  test('el tema no usa colores de señal ni derivados (FR-005)', () {
    final scheme = buildAppTheme().colorScheme;
    for (final (name, c) in [
      ('primary', scheme.primary),
      ('onPrimary', scheme.onPrimary),
      ('secondary', scheme.secondary),
      ('tertiary', scheme.tertiary),
      ('surface', scheme.surface),
      ('onSurface', scheme.onSurface),
      ('outline', scheme.outline),
      ('error', scheme.error),
    ]) {
      expect(_chroma(c), lessThanOrEqualTo(0.10), reason: '$name ${_hex(c)}');
    }
  });

  test('el tema usa Rajdhani (FR-026)', () {
    final theme = buildAppTheme();
    expect(theme.textTheme.bodyMedium?.fontFamily, kFontFamily);
    expect(theme.textTheme.displayLarge?.fontFamily, kFontFamily);
    expect(kFontFamily, 'Rajdhani');
  });
}
