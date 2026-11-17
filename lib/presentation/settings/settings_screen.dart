import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings/parameter_editor.dart';
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
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final rows = _rows(draft, notifier, s);

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
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24 * s,
                              vertical: 8 * s,
                            ),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => const Divider(
                              color: AppColors.panelBorder,
                              height: 1,
                            ),
                            itemBuilder: (_, i) => rows[i],
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
  ) {
    final values = draft.values;

    Widget row(
      ParameterField field,
      String label,
      List<String> hints,
      String value,
    ) => ParameterRow(
      field: field,
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
          // US2 agrega el rango del sorteo y el aviso de ajuste.
          ParameterField.attackInterval => row(
            field,
            StringsEs.attackIntervalLabel,
            const [StringsEs.attackIntervalHint],
            formatSeconds(values.attackInterval),
          ),
        },
    ];
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
