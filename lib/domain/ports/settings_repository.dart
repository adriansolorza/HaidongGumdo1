import '../exercise/exercise_parameters.dart';

/// Configuración del usuario (Spec 005, FR-010 a FR-013; Principio IV).
/// Implementación en data: JsonFileSettingsRepository (JSON local). Un backend
/// futuro es solo otra implementación de esta interfaz.
abstract interface class SettingsRepository {
  /// null si no hay configuración guardada, no se puede leer o no es válida;
  /// nunca lanza.
  Future<ExerciseParameters?> load();

  /// Lanza SettingsSaveException si no se pudo guardar; la configuración
  /// anterior queda intacta.
  Future<void> save(ExerciseParameters parameters);
}

/// No se pudo guardar la configuración (FR-013).
final class SettingsSaveException implements Exception {
  SettingsSaveException([this.cause]);

  /// Error original, solo para depuración.
  final Object? cause;

  @override
  String toString() => 'SettingsSaveException: $cause';
}
