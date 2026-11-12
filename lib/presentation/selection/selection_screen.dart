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
import '../strings_es.dart';
import '../theme.dart';
import 'level_icon.dart';
import 'pattern_icon_painter.dart';
import 'selection_card.dart';

/// Elección de nivel y patrón (Spec 004, FR-020 a FR-025; contrato §4): el
/// dojang oscurecido de fondo, el encabezado, dos columnas de tarjetas, el
/// resumen de la sesión y el botón INICIAR. Todos los textos de niveles,
/// patrones y términos salen del catálogo (Spec 001, SC-009).
class SelectionScreen extends ConsumerWidget {
  const SelectionScreen({super.key});

  /// Solo para la geometría del fondo mientras el catálogo carga o falla:
  /// las posturas del Patrón frontal.
  static const _backgroundPattern = Pattern(
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
            catalog.value?.patterns.first ?? _backgroundPattern,
          );
          final s = layout.hudScale;

          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(painter: DojangPainter(layout: layout)),
              ),
              const ColoredBox(color: AppColors.selectionDim),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(56 * s, 40 * s, 56 * s, 36 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(scale: s),
                      SizedBox(height: 28 * s),
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
                                ),
                        ),
                      ),
                      SizedBox(height: 28 * s),
                      _Footer(
                        scale: s,
                        summary: session == null
                            ? ''
                            : '${session.level.name} · ${session.pattern.name}'
                                  ' · ${duration.inSeconds} s',
                        onStart: catalog.hasValue && session != null
                            ? () => _start(context, ref, session)
                            : null,
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
}

class _Header extends StatelessWidget {
  const _Header({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringsEs.appHeader,
          style: TextStyle(
            fontSize: 46 * s,
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
            fontSize: 20 * s,
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
  });

  final Catalog catalog;
  final Session session;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final notifier = ref.read(selectedSessionProvider.notifier);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CardColumn(
            header: StringsEs.levelHeader,
            scale: s,
            cards: [
              for (final level in catalog.levels)
                SelectionCard(
                  scale: s,
                  icon: LevelIcon(
                    type: level.responseTypes.first,
                    size: 56 * s,
                  ),
                  title: level.name.toUpperCase(),
                  lines: ['${level.responseLabel} — ${level.purpose}'],
                  selected: level == session.level,
                  onTap: () => notifier.selectLevel(level),
                ),
            ],
          ),
        ),
        SizedBox(width: 40 * s),
        Expanded(
          child: _CardColumn(
            header: StringsEs.patternHeader,
            scale: s,
            cards: [
              for (final pattern in catalog.patterns)
                SelectionCard(
                  scale: s,
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

class _CardColumn extends StatelessWidget {
  const _CardColumn({
    required this.header,
    required this.scale,
    required this.cards,
  });

  final String header;
  final double scale;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          header,
          style: TextStyle(
            fontSize: 18 * s,
            fontWeight: FontWeight.w700,
            letterSpacing: 4 * s,
            color: AppColors.columnHeader,
          ),
        ),
        SizedBox(height: 14 * s),
        Expanded(
          child: ListView.separated(
            // Margen para el anillo de la tarjeta seleccionada.
            padding: EdgeInsets.all(4 * s),
            itemCount: cards.length,
            separatorBuilder: (_, _) => SizedBox(height: 14 * s),
            itemBuilder: (_, i) => cards[i],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.scale,
    required this.summary,
    required this.onStart,
  });

  final double scale;
  final String summary;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            style: TextStyle(
              fontSize: 20 * s,
              fontWeight: FontWeight.w500,
              letterSpacing: 1 * s,
              color: AppColors.textSecondary,
            ),
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
