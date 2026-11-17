import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/ports/settings_repository.dart';

/// Repositorio de configuración en memoria para pruebas (Spec 005, T007).
final class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({this.stored});

  /// Última configuración guardada; null si no hay.
  ExerciseParameters? stored;

  /// Si es true, `save` lanza SettingsSaveException y no guarda.
  bool failOnSave = false;

  /// Número de llamadas a `save`, incluidas las que fallan.
  int saveCalls = 0;

  @override
  Future<ExerciseParameters?> load() async => stored;

  @override
  Future<void> save(ExerciseParameters parameters) async {
    saveCalls++;
    if (failOnSave) throw SettingsSaveException('fallo simulado');
    stored = parameters;
  }
}
