import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exercise/exercise_parameters.dart';
import '../../domain/ports/settings_repository.dart';
import '../../domain/settings/parameter_editor.dart';
import '../providers.dart';

/// Borrador de la pantalla de configuración (Spec 005, data-model §6). Sus
/// valores son siempre válidos (FR-007): solo cambian con [ParameterEditor].
final class SettingsDraft {
  const SettingsDraft({
    required this.values,
    this.intervalAdjustedTo,
    this.saving = false,
    this.saveFailed = false,
  });

  final ExerciseParameters values;

  /// Valor al que subió el intervalo por el ajuste automático (FR-008).
  final Duration? intervalAdjustedTo;

  /// Guardar desactivado mientras es true (evita dobles toques).
  final bool saving;

  /// El último intento de guardar falló (FR-013).
  final bool saveFailed;

  SettingsDraft copyWith({
    ExerciseParameters? values,
    Duration? intervalAdjustedTo,
    bool clearAdjustment = false,
    bool? saving,
    bool? saveFailed,
  }) => SettingsDraft(
    values: values ?? this.values,
    intervalAdjustedTo: clearAdjustment
        ? null
        : intervalAdjustedTo ?? this.intervalAdjustedTo,
    saving: saving ?? this.saving,
    saveFailed: saveFailed ?? this.saveFailed,
  );
}

/// Vive mientras la pantalla de configuración está abierta: al cerrarla sin
/// guardar (CANCELAR o Atrás) el borrador se descarta (FR-002).
final settingsDraftProvider =
    NotifierProvider.autoDispose<SettingsDraftNotifier, SettingsDraft>(
      SettingsDraftNotifier.new,
    );

final class SettingsDraftNotifier extends Notifier<SettingsDraft> {
  /// Empieza igual a la configuración guardada.
  @override
  SettingsDraft build() =>
      SettingsDraft(values: ref.read(exerciseParametersProvider));

  void increment(ParameterField field) =>
      _apply(field, ParameterEditor.increment(state.values, field));

  void decrement(ParameterField field) =>
      _apply(field, ParameterEditor.decrement(state.values, field));

  /// Aviso de ajuste (data-model §6, research R6): tocar el intervalo lo
  /// borra; un ajuste nuevo lo reemplaza; cualquier otro cambio lo conserva.
  void _apply(ParameterField field, EditResult result) {
    state = state.copyWith(
      values: result.parameters,
      saveFailed: false,
      intervalAdjustedTo: result.adjustedInterval,
      clearAdjustment: field == ParameterField.attackInterval,
    );
  }

  /// Guarda el borrador. true si tuvo éxito; false si falló o ya se estaba
  /// guardando.
  Future<bool> save() async {
    if (state.saving) return false;
    state = state.copyWith(saving: true, saveFailed: false);
    try {
      await ref.read(exerciseParametersProvider.notifier).save(state.values);
      return true;
    } on SettingsSaveException {
      if (ref.mounted) {
        state = state.copyWith(saving: false, saveFailed: true);
      }
      return false;
    }
  }
}
