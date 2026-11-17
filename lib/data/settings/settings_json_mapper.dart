import '../../domain/exercise/exercise_parameters.dart';

/// Convierte la configuración del usuario a y desde el JSON de
/// `specs/005-configuracion-parametros/contracts/settings.schema.json`.
abstract final class SettingsJsonMapper {
  static const version = 1;

  static Map<String, Object> toJson(ExerciseParameters p) => {
    'version': version,
    'durationMs': p.duration.inMilliseconds,
    'maxRepeats': p.maxRepeats,
    'warningTimeMs': p.warningTime.inMilliseconds,
    'cutSpeedMs': p.cutSpeed.inMilliseconds,
    'attackIntervalMs': p.attackInterval.inMilliseconds,
  };

  /// null si [json] no tiene el formato esperado, la versión no es 1, falta
  /// un campo o no es entero, o los valores no cumplen rangos e invariante
  /// (FR-012). Ignora campos desconocidos. Nunca lanza.
  static ExerciseParameters? fromJson(Object? json) {
    if (json is! Map) return null;
    if (json['version'] != version) return null;
    final duration = json['durationMs'];
    final maxRepeats = json['maxRepeats'];
    final warningTime = json['warningTimeMs'];
    final cutSpeed = json['cutSpeedMs'];
    final attackInterval = json['attackIntervalMs'];
    if (duration is! int ||
        maxRepeats is! int ||
        warningTime is! int ||
        cutSpeed is! int ||
        attackInterval is! int) {
      return null;
    }
    final parameters = ExerciseParameters(
      duration: Duration(milliseconds: duration),
      maxRepeats: maxRepeats,
      warningTime: Duration(milliseconds: warningTime),
      cutSpeed: Duration(milliseconds: cutSpeed),
      attackInterval: Duration(milliseconds: attackInterval),
    );
    return parameters.validate().isEmpty ? parameters : null;
  }
}
