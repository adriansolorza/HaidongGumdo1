import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings/parameter_editor.dart';
import '../exercise/widgets/hud_panel.dart';
import '../providers.dart';
import '../scene/dojang_painter.dart';
import '../scene/scene_layout.dart';
import '../selection/selection_screen.dart';
import '../strings_es.dart';
import '../theme.dart';
import 'parameter_format.dart';
import 'parameter_row.dart';
import 'settings_draft.dart';

/// Pantalla de configuración (Spec 005, FR-002 a FR-020; contrato §4): el
/// dojang oscurecido de fondo, la lista de los cinco parámetros con botones
/// − / + y la barra de acciones fija. Solo usa blancos y grises (FR-018).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Fila del intervalo, para hacerla visible cuando aparece el aviso.
  final _intervalRowKey = GlobalKey();

  /// Con la lista desplazada (4:3), el aviso de ajuste debe verse aunque el
  /// usuario esté editando el corte (T025).
  void _revealIntervalRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rowContext = _intervalRowKey.currentContext;
      if (!mounted || rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsDraftProvider, (previous, next) {
      final adjusted = next.intervalAdjustedTo;
      if (adjusted != null && adjusted != previous?.intervalAdjustedTo) {
        _revealIntervalRow();
      }
    });
    final catalog = ref.watch(catalogProvider);
    final draft = ref.watch(settingsDraftProvider);
    final notifier = ref.read(settingsDraftProvider.notifier);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = SceneLayout.compute(
            constraints.biggest,
            catalog.value?.patterns.first ?? SelectionScreen.backgroundPattern,
          );
          final s = layout.hudScale;
          final rows = _rows(draft, notifier, s, _intervalRowKey);

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
                      Text(
                        StringsEs.settings,
                        style: TextStyle(
                          fontSize: 46 * s,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6 * s,
                          height: 1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 24 * s),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            border: Border.all(
                              color: AppColors.panelBorder,
                              width: 1.5 * s,
                            ),
                            borderRadius: BorderRadius.circular(14 * s),
                          ),
                          // Cinco filas: todas construidas, para que
                          // ensureVisible encuentre la del intervalo.
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24 * s,
                              vertical: 8 * s,
                            ),
                            child: Column(
                              children: [
                                for (final (i, row) in rows.indexed) ...[
                                  if (i > 0)
                                    const Divider(
                                      color: AppColors.panelBorder,
                                      height: 1,
                                    ),
                                  row,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (draft.saveFailed) ...[
                        SizedBox(height: 16 * s),
                        _SaveError(scale: s),
                      ],
                      SizedBox(height: 24 * s),
                      _Actions(
                        scale: s,
                        onSave: draft.saving
                            ? null
                            : () async {
                                final saved = await notifier.save();
                                if (saved && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
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

  /// Las cinco filas en el orden de [ParameterField] (FR-004, FR-005).
  static List<Widget> _rows(
    SettingsDraft draft,
    SettingsDraftNotifier notifier,
    double s,
    Key intervalRowKey,
  ) {
    final values = draft.values;

    Widget row(
      ParameterField field,
      String label,
      List<String> hints,
      String value, {
      Key? key,
      Key? lastHintKey,
      Widget? footer,
    }) => ParameterRow(
      key: key,
      field: field,
      lastHintKey: lastHintKey,
      footer: footer,
      label: label,
      hints: hints,
      value: value,
      scale: s,
      onDecrement: ParameterEditor.canDecrement(values, field)
          ? () => notifier.decrement(field)
          : null,
      onIncrement: ParameterEditor.canIncrement(values, field)
          ? () => notifier.increment(field)
          : null,
    );

    return [
      for (final field in ParameterField.values)
        switch (field) {
          ParameterField.duration => row(field, StringsEs.durationLabel, const [
            StringsEs.durationHint,
            StringsEs.durationRange,
          ], formatDuration(values.duration)),
          ParameterField.maxRepeats => row(
            field,
            StringsEs.maxRepeatsLabel,
            const [StringsEs.maxRepeatsHint, StringsEs.maxRepeatsRange],
            '${values.maxRepeats}',
          ),
          ParameterField.warningTime => row(
            field,
            StringsEs.warningTimeLabel,
            const [
              StringsEs.warningTimeHint,
              StringsEs.warningTimeRange,
              StringsEs.warningTimeReference,
            ],
            formatSeconds(values.warningTime),
          ),
          ParameterField.cutSpeed => row(field, StringsEs.cutSpeedLabel, const [
            StringsEs.cutSpeedHint,
            StringsEs.cutSpeedRange,
          ], formatSeconds(values.cutSpeed)),
          // Rango real del sorteo y aviso de ajuste (FR-005, FR-008).
          ParameterField.attackInterval => row(
            field,
            StringsEs.attackIntervalLabel,
            [StringsEs.attackIntervalHint, formatIntervalRange(values)],
            formatSeconds(values.attackInterval),
            key: intervalRowKey,
            lastHintKey: const Key('intervalRange'),
            footer: draft.intervalAdjustedTo == null
                ? null
                : _AdjustedNotice(
                    interval: draft.intervalAdjustedTo!,
                    scale: s,
                  ),
          ),
        },
    ];
  }
}

/// Aviso del ajuste automático del intervalo (FR-008): panel neutro con
/// borde fuerte e ícono de información; nunca amarillo ni rojo (FR-018).
class _AdjustedNotice extends StatelessWidget {
  const _AdjustedNotice({required this.interval, required this.scale});

  final Duration interval;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return HudPanel(
      key: const Key('intervalAdjustedNotice'),
      scale: s,
      strong: true,
      padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 16 * s),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textPrimary, size: 22 * s),
          SizedBox(width: 10 * s),
          Flexible(
            child: Text(
              formatAdjustment(interval),
              style: TextStyle(
                fontSize: 16 * s,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error al guardar (FR-013): ícono, título en negrita y borde blanco
/// completo; nunca rojo (FR-018).
class _SaveError extends StatelessWidget {
  const _SaveError({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return DecoratedBox(
      key: const Key('saveError'),
      decoration: BoxDecoration(
        color: AppColors.panelStrong,
        border: Border.all(color: AppColors.cardSelectedBorder, width: 2 * s),
        borderRadius: BorderRadius.circular(14 * s),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 22 * s),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.textPrimary,
              size: 28 * s,
            ),
            SizedBox(width: 14 * s),
            Expanded(
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: '${StringsEs.saveErrorTitle}. ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: StringsEs.saveErrorBody),
                  ],
                ),
                style: TextStyle(
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de acciones fija. US3 agrega RESTABLECER y CANCELAR.
class _Actions extends StatelessWidget {
  const _Actions({required this.scale, required this.onSave});

  final double scale;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 64 * s,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 260 * s),
            child: FilledButton(
              key: const Key('saveButton'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40 * s),
                textStyle: TextStyle(
                  fontSize: 26 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5 * s,
                ),
              ),
              onPressed: onSave,
              child: const Text(StringsEs.save),
            ),
          ),
        ),
      ],
    );
  }
}
