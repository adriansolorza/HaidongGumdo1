import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/catalog/catalog.dart';
import '../../domain/exercise/session.dart';
import '../exercise/exercise_controller.dart';
import '../exercise/exercise_screen.dart';
import '../exercise/widgets/hud_panel.dart';
import '../providers.dart';
import '../scene/dojang_painter.dart';
import '../scene/scene_layout.dart';
import '../settings/parameter_format.dart';
import '../settings/settings_screen.dart';
import '../strings_es.dart';
import '../theme.dart';
import 'level_icon.dart';
import 'pattern_icon_painter.dart';
import 'selection_card.dart';
import 'selection_density.dart';

/// Elección de nivel y patrón (Spec 004, FR-020 a FR-025; contrato §4): el
/// dojang oscurecido de fondo, el encabezado, dos columnas de tarjetas, el
/// resumen de la sesión y el botón INICIAR. Todos los textos de niveles,
/// patrones y términos salen del catálogo (Spec 001, SC-009).
class SelectionScreen extends ConsumerWidget {
  const SelectionScreen({super.key});

  /// Solo para la geometría del fondo mientras el catálogo carga o falla:
  /// las posturas del Patrón frontal. También la usa la configuración.
  static const backgroundPattern = Pattern(
    id: '_background',
    order: 0,
    name: '',
    guardTermId: '',
    stanceTermId: '',
    cutTermId: '',
    guard: SaberPose(hilt: Point2(0, 0.05), tip: Point2(0, -0.3)),
    cut: CutMotion(
      start: SaberPose(hilt: Point2(0, -0.9), tip: Point2(0, -1.6)),
      end: SaberPose(hilt: Point2(0, -0.2), tip: Point2(0, -0.35)),
      mirroredBySide: false,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final session = ref.watch(selectedSessionProvider);
    final duration = ref.watch(exerciseParametersProvider).duration;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final layout = SceneLayout.compute(
            size,
            catalog.value?.patterns.first ?? backgroundPattern,
          );
          final s = layout.hudScale;
          final fit = _Fit.compute(
            catalog: catalog.value,
            height: size.height - MediaQuery.paddingOf(context).vertical,
            scale: s,
          );
          final m = fit.density.metrics(s);

          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(painter: DojangPainter(layout: layout)),
              ),
              const ColoredBox(color: AppColors.selectionDim),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    m.pagePaddingSides,
                    m.pagePaddingTop,
                    m.pagePaddingSides,
                    m.pagePaddingBottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(metrics: m),
                      SizedBox(height: m.sectionGap),
                      Expanded(
                        child: catalog.when(
                          loading: () => Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                SizedBox(height: 16 * s),
                                Text(
                                  StringsEs.loadingCatalog,
                                  style: TextStyle(
                                    fontSize: 20 * s,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          error: (_, _) => Center(
                            child: HudPanel(
                              scale: s,
                              alignment: CrossAxisAlignment.center,
                              child: Text(
                                StringsEs.catalogError,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24 * s,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          data: (catalog) => session == null
                              ? const SizedBox.shrink()
                              : _Columns(
                                  catalog: catalog,
                                  session: session,
                                  scale: s,
                                  fit: fit,
                                ),
                        ),
                      ),
                      SizedBox(height: m.sectionGap),
                      _Footer(
                        scale: s,
                        summary: session == null
                            ? ''
                            : '${session.level.name} · ${session.pattern.name}'
                                  ' · ${formatDuration(duration)}',
                        onStart: catalog.hasValue && session != null
                            ? () => _start(context, ref, session)
                            : null,
                        onSettings: () => _openSettings(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Una sola acción abre el ejercicio con la sesión elegida (SC-008).
  void _start(BuildContext context, WidgetRef ref, Session session) {
    ref.read(exerciseControllerProvider.notifier).start(session);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ExerciseScreen(session: session)),
    );
  }

  /// La configuración solo se abre desde aquí (Spec 005, FR-001, FR-003).
  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }
}

/// Densidad de la selección (Spec 006, FR-012a; research R7; tasks T021).
final class _Fit {
  const _Fit(this.density);

  /// Se decide una sola vez con la altura total [height] (sin la `SafeArea`):
  /// se restan las alturas regulares del encabezado, las separaciones, el pie
  /// y los márgenes y se pregunta a [SelectionDensity.choose] si las tarjetas
  /// caben. Mientras el catálogo carga o falla, `regular`.
  ///
  /// La red de seguridad no se decide aquí: ver [_CardColumn].
  factory _Fit.compute({
    required Catalog? catalog,
    required double height,
    required double scale,
  }) {
    if (catalog == null) return const _Fit(SelectionDensity.regular);
    final s = scale;
    // Márgenes, encabezado, separaciones, pie y encabezado de columna.
    final fixedRegular =
        40 * s +
        36 * s +
        46 * s +
        2 * s +
        20 * s * 1.3 +
        28 * s +
        28 * s +
        64 * s +
        18 * s * 1.3 +
        14 * s;
    final density = SelectionDensity.choose(
      columnsHeight: height - fixedRegular,
      scale: s,
      maxCards: math.max(catalog.levels.length, catalog.patterns.length),
    );
    return _Fit(density);
  }

  final SelectionDensity density;
}

class _Header extends StatelessWidget {
  const _Header({required this.metrics});

  final SelectionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final s = m.decorScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringsEs.appHeader,
          style: TextStyle(
            fontSize: m.headerTitleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 6 * s,
            height: 1,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 2 * s),
        Text(
          StringsEs.appSubtitle,
          style: TextStyle(
            fontSize: m.headerSubtitleSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 1 * s,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Columnas NIVEL y PATRÓN, en el orden del catálogo.
class _Columns extends ConsumerWidget {
  const _Columns({
    required this.catalog,
    required this.session,
    required this.scale,
    required this.fit,
  });

  final Catalog catalog;
  final Session session;
  final double scale;
  final _Fit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final density = fit.density;
    final m = density.metrics(s);
    final notifier = ref.read(selectedSessionProvider.notifier);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CardColumn(
            header: StringsEs.levelHeader,
            metrics: m,
            cards: [
              for (final level in catalog.levels)
                SelectionCard(
                  scale: s,
                  density: density,
                  icon: LevelIcon(
                    types: level.responseTypes,
                    size: m.iconGlyph,
                  ),
                  title: level.name.toUpperCase(),
                  lines: ['${level.responseLabel} — ${level.purpose}'],
                  selected: level == session.level,
                  onTap: () => notifier.selectLevel(level),
                ),
            ],
          ),
        ),
        SizedBox(width: m.columnsGap),
        Expanded(
          child: _CardColumn(
            header: StringsEs.patternHeader,
            metrics: m,
            cards: [
              for (final pattern in catalog.patterns)
                SelectionCard(
                  scale: s,
                  density: density,
                  icon: CustomPaint(
                    painter: PatternIconPainter(pattern: pattern),
                  ),
                  title: pattern.name.toUpperCase(),
                  lines: _patternLines(catalog, pattern),
                  selected: pattern == session.pattern,
                  onTap: () => notifier.selectPattern(pattern),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Secuencia guardia → postura → corte en romanización y, si algún término
  /// lo tiene, una línea con el hangul de esos términos (FR-022; caso límite
  /// "Términos sin hangul").
  static List<String> _patternLines(Catalog catalog, Pattern pattern) {
    final terms = [
      catalog.term(pattern.guardTermId),
      catalog.term(pattern.stanceTermId),
      catalog.term(pattern.cutTermId),
    ];
    final hangul = [for (final t in terms) ?t.hangul];
    return [
      terms.map((t) => t.romanization).join(' → '),
      if (hangul.isNotEmpty) hangul.join(' → '),
    ];
  }
}

/// Columna de tarjetas (Spec 006, FR-012a). Con la densidad que elige [_Fit],
/// las tarjetas caben y no hay nada que desplazar. Red de seguridad (research
/// R7, punto 4): las tarjetas van en un `SingleChildScrollView`, que solo se
/// mueve si el contenido real no cabe (por ejemplo, con letra ampliada por
/// accesibilidad, que ninguna fórmula puede prever). Así nunca hay
/// desbordamiento ni contenido recortado.
class _CardColumn extends StatelessWidget {
  const _CardColumn({
    required this.header,
    required this.metrics,
    required this.cards,
  });

  final String header;
  final SelectionMetrics metrics;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final s = m.decorScale;
    final list = Padding(
      // Margen para el anillo de la tarjeta seleccionada.
      padding: EdgeInsets.all(4 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) SizedBox(height: m.cardGap),
            card,
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          header,
          style: TextStyle(
            fontSize: m.columnHeaderSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 4 * s,
            color: AppColors.columnHeader,
          ),
        ),
        SizedBox(height: m.columnHeaderGap),
        Expanded(child: SingleChildScrollView(child: list)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.scale,
    required this.summary,
    required this.onStart,
    required this.onSettings,
  });

  final double scale;
  final String summary;
  final VoidCallback? onStart;

  /// Siempre habilitado: la configuración no depende del catálogo.
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20 * s,
              fontWeight: FontWeight.w500,
              letterSpacing: 1 * s,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: 24 * s),
        // Secundario frente a INICIAR: píldora con borde (Spec 005, FR-001).
        SizedBox(
          height: 64 * s,
          child: OutlinedButton(
            key: const Key('settingsButton'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 28 * s),
              textStyle: TextStyle(
                fontSize: 22 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: 3 * s,
              ),
            ),
            onPressed: onSettings,
            child: const Text(StringsEs.settings),
          ),
        ),
        SizedBox(width: 24 * s),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000), // 35 %
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 64 * s,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 360 * s),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40 * s),
                  textStyle: TextStyle(
                    fontSize: 30 * s,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6 * s,
                  ),
                ),
                onPressed: onStart,
                child: const Text(StringsEs.start),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
