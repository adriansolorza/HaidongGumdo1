import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/ports/catalog_repository.dart';
import 'package:haidonggumdo/presentation/providers.dart';
import 'package:haidonggumdo/presentation/settings/settings_screen.dart';
import 'package:haidonggumdo/presentation/theme.dart';

import 'fakes/in_memory_settings_repository.dart';

final class _AssetFileRepository implements CatalogRepository {
  @override
  Future<Catalog> load() async => const CatalogJsonMapper().fromJsonString(
    File('assets/catalog/catalog.json').readAsStringSync(),
  );
}

/// Todos los colores que pinta la pantalla de configuración, con su origen.
List<(String, Color)> _settingsColors(WidgetTester tester) {
  final found = <(String, Color)>[];
  void add(String origin, Color? c) {
    if (c != null) found.add((origin, c));
  }

  final root = find.byType(SettingsScreen);
  Iterable<T> all<T extends Widget>() =>
      tester.widgetList<T>(find.descendant(of: root, matching: find.byType(T)));

  // Textos con su estilo efectivo (RichText ya trae el DefaultTextStyle).
  for (final rich in all<RichText>()) {
    rich.text.visitChildren((span) {
      add('texto "${span.toPlainText()}"', span.style?.color);
      return true;
    });
    add('texto "${rich.text.toPlainText()}"', rich.text.style?.color);
  }
  for (final icon in all<Icon>()) {
    add('ícono ${icon.icon}', icon.color);
  }
  for (final box in all<DecoratedBox>()) {
    final d = box.decoration;
    if (d is BoxDecoration) {
      add('caja', d.color);
      final border = d.border;
      if (border is Border) {
        for (final side in [
          border.top,
          border.right,
          border.bottom,
          border.left,
        ]) {
          add('borde de caja', side.color);
        }
      }
    }
  }
  // Fondo y borde efectivos de los botones (OutlinedButton, FilledButton).
  for (final material in all<Material>()) {
    add('material', material.color);
    final shape = material.shape;
    if (shape is OutlinedBorder) add('borde de material', shape.side.color);
  }
  for (final colored in all<ColoredBox>()) {
    add('ColoredBox', colored.color);
  }
  for (final divider in all<Divider>()) {
    add('divisor', divider.color);
  }
  return found;
}

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

  testWidgets('configuración con aviso y error visibles: solo grises '
      '(Spec 005, FR-018, SC-006)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository()..failOnSave = true,
          ),
          catalogRepositoryProvider.overrideWithValue(_AssetFileRepository()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tap(String key) async {
      final finder = find.byKey(Key(key));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    bool enabled(String key) =>
        tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed !=
        null;

    while (enabled('dec-attackInterval')) {
      await tap('dec-attackInterval');
    }
    await tap('inc-cutSpeed');
    await tap('saveButton');
    expect(find.byKey(const Key('intervalAdjustedNotice')), findsOneWidget);
    expect(find.byKey(const Key('saveError')), findsOneWidget);
    // Botones desactivados presentes (− del intervalo).
    expect(enabled('dec-attackInterval'), isFalse);

    final colors = _settingsColors(tester);
    expect(colors, isNotEmpty);
    for (final (origin, c) in colors) {
      expect(_chroma(c), lessThanOrEqualTo(0.10), reason: '$origin ${_hex(c)}');
      for (final s in signal) {
        expect(
          c.withAlpha(255),
          isNot(s.withAlpha(255)),
          reason: '$origin usa un color de señal',
        );
      }
    }
  });

  test('el tema usa Rajdhani (FR-026)', () {
    final theme = buildAppTheme();
    expect(theme.textTheme.bodyMedium?.fontFamily, kFontFamily);
    expect(theme.textTheme.displayLarge?.fontFamily, kFontFamily);
    expect(kFontFamily, 'Rajdhani');
  });
}
