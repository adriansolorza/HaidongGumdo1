/// Rangos de los parámetros del ejercicio (FR-006), inclusivos en ambos extremos.
abstract final class ParameterLimits {
  static const minDuration = Duration(seconds: 30);
  static const maxDuration = Duration(seconds: 180);
  static const minMaxRepeats = 1;
  static const maxMaxRepeats = 5;
  static const minWarningTime = Duration(milliseconds: 330);
  static const maxWarningTime = Duration(milliseconds: 1000);
  static const minCutSpeed = Duration(milliseconds: 300);
  static const maxCutSpeed = Duration(milliseconds: 1000);
  static const minAttackInterval = Duration(milliseconds: 500);
  static const maxAttackInterval = Duration(milliseconds: 5000);

  /// Piso del intervalo = velocidad del corte + este margen (FR-007).
  static const intervalFloorMargin = Duration(milliseconds: 500);
}

enum ParameterViolation {
  durationOutOfRange,
  maxRepeatsOutOfRange,
  warningTimeOutOfRange,
  cutSpeedOutOfRange,
  attackIntervalOutOfRange,
  intervalBelowFloor,
}

final class InvalidParametersException implements Exception {
  InvalidParametersException(List<ParameterViolation> violations)
    : violations = List.unmodifiable(violations);

  final List<ParameterViolation> violations;

  @override
  String toString() =>
      'InvalidParametersException: ${violations.map((v) => v.name).join(', ')}';
}

/// Parámetros de un ejercicio. El constructor no valida; usar [validate] o
/// [ExerciseParameters.create]. El motor rechaza parámetros inválidos (FR-007).
final class ExerciseParameters {
  const ExerciseParameters({
    required this.duration,
    required this.maxRepeats,
    required this.warningTime,
    required this.cutSpeed,
    required this.attackInterval,
  });

  /// Lanza [InvalidParametersException] con todas las violaciones encontradas.
  factory ExerciseParameters.create({
    required Duration duration,
    required int maxRepeats,
    required Duration warningTime,
    required Duration cutSpeed,
    required Duration attackInterval,
  }) {
    final parameters = ExerciseParameters(
      duration: duration,
      maxRepeats: maxRepeats,
      warningTime: warningTime,
      cutSpeed: cutSpeed,
      attackInterval: attackInterval,
    );
    final violations = parameters.validate();
    if (violations.isNotEmpty) throw InvalidParametersException(violations);
    return parameters;
  }

  /// Valores por defecto de FR-006; siempre válidos.
  factory ExerciseParameters.defaults() => const ExerciseParameters(
    duration: Duration(seconds: 30),
    maxRepeats: 5,
    warningTime: Duration(milliseconds: 700),
    cutSpeed: Duration(milliseconds: 500),
    attackInterval: Duration(milliseconds: 2500),
  );

  final Duration duration;

  /// Máximo de ataques seguidos al mismo lado (N).
  final int maxRepeats;

  /// Tiempo desde la señal hasta el inicio del corte.
  final Duration warningTime;

  /// Duración del corte.
  final Duration cutSpeed;

  /// Tope del sorteo del intervalo entre ataques.
  final Duration attackInterval;

  /// Valor mínimo del sorteo del intervalo.
  Duration get intervalFloor => cutSpeed + ParameterLimits.intervalFloorMargin;

  List<ParameterViolation> validate() => [
    if (!_inRange(
      duration,
      ParameterLimits.minDuration,
      ParameterLimits.maxDuration,
    ))
      ParameterViolation.durationOutOfRange,
    if (maxRepeats < ParameterLimits.minMaxRepeats ||
        maxRepeats > ParameterLimits.maxMaxRepeats)
      ParameterViolation.maxRepeatsOutOfRange,
    if (!_inRange(
      warningTime,
      ParameterLimits.minWarningTime,
      ParameterLimits.maxWarningTime,
    ))
      ParameterViolation.warningTimeOutOfRange,
    if (!_inRange(
      cutSpeed,
      ParameterLimits.minCutSpeed,
      ParameterLimits.maxCutSpeed,
    ))
      ParameterViolation.cutSpeedOutOfRange,
    if (!_inRange(
      attackInterval,
      ParameterLimits.minAttackInterval,
      ParameterLimits.maxAttackInterval,
    ))
      ParameterViolation.attackIntervalOutOfRange,
    if (attackInterval < intervalFloor) ParameterViolation.intervalBelowFloor,
  ];

  @override
  bool operator ==(Object other) =>
      other is ExerciseParameters &&
      other.duration == duration &&
      other.maxRepeats == maxRepeats &&
      other.warningTime == warningTime &&
      other.cutSpeed == cutSpeed &&
      other.attackInterval == attackInterval;

  @override
  int get hashCode =>
      Object.hash(duration, maxRepeats, warningTime, cutSpeed, attackInterval);
}

bool _inRange(Duration value, Duration min, Duration max) =>
    value >= min && value <= max;
