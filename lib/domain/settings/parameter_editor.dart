import '../exercise/exercise_parameters.dart';

/// Parámetros editables, en el orden de las filas de la configuración
/// (Spec 005, FR-004).
enum ParameterField {
  duration,
  maxRepeats,
  warningTime,
  cutSpeed,
  attackInterval,
}

/// Resultado de un toque de − o + (data-model §3).
final class EditResult {
  const EditResult(this.parameters, {this.adjustedInterval});

  /// Valores después del toque.
  final ExerciseParameters parameters;

  /// No nulo solo si el toque provocó el ajuste automático del intervalo
  /// (FR-008).
  final Duration? adjustedInterval;
}

/// Rejilla de valores, mínimos vigentes y ajuste automático del intervalo
/// (Spec 005, FR-004, FR-007, FR-008; research R2).
///
/// Todo se calcula en milisegundos enteros (o N), nunca con `double`.
/// Garantía: si los parámetros de entrada son válidos, los de salida también.
abstract final class ParameterEditor {
  static const _durationStepMs = 15000;
  static const _timeStepMs = 50;
  static const _intervalStepMs = 100;

  /// Mínimo configurable del intervalo: el piso (velocidad del corte + 0.5 s)
  /// redondeado hacia arriba a 0.1 s. Corte 350 ms → 900 ms.
  static Duration intervalMinimum(Duration cutSpeed) {
    final floorMs =
        cutSpeed.inMilliseconds +
        ParameterLimits.intervalFloorMargin.inMilliseconds;
    final roundedUp =
        ((floorMs + _intervalStepMs - 1) ~/ _intervalStepMs) * _intervalStepMs;
    return Duration(milliseconds: roundedUp);
  }

  /// Valores permitidos del campo, en orden ascendente (ms, o N para
  /// `maxRepeats`). Los del intervalo dependen de la velocidad del corte.
  static List<int> allowedValues(ExerciseParameters p, ParameterField f) =>
      switch (f) {
        ParameterField.duration => _range(
          ParameterLimits.minDuration.inMilliseconds,
          ParameterLimits.maxDuration.inMilliseconds,
          _durationStepMs,
        ),
        ParameterField.maxRepeats => _range(
          ParameterLimits.minMaxRepeats,
          ParameterLimits.maxMaxRepeats,
          1,
        ),
        // 330 (⅓ s) y después múltiplos de 50: 350, 400 … 1000.
        ParameterField.warningTime => [
          ParameterLimits.minWarningTime.inMilliseconds,
          ..._range(350, ParameterLimits.maxWarningTime.inMilliseconds, 50),
        ],
        ParameterField.cutSpeed => _range(
          ParameterLimits.minCutSpeed.inMilliseconds,
          ParameterLimits.maxCutSpeed.inMilliseconds,
          _timeStepMs,
        ),
        ParameterField.attackInterval => _range(
          intervalMinimum(p.cutSpeed).inMilliseconds,
          ParameterLimits.maxAttackInterval.inMilliseconds,
          _intervalStepMs,
        ),
      };

  /// Existe un valor permitido mayor que el actual.
  static bool canIncrement(ExerciseParameters p, ParameterField f) =>
      _next(p, f) != null;

  /// Existe un valor permitido menor que el actual.
  static bool canDecrement(ExerciseParameters p, ParameterField f) =>
      _previous(p, f) != null;

  /// Siguiente valor permitido mayor que el actual; si no hay, sin cambios.
  /// Subir la velocidad del corte puede subir el intervalo (FR-008).
  static EditResult increment(ExerciseParameters p, ParameterField f) {
    final next = _next(p, f);
    if (next == null) return EditResult(p);
    final updated = _with(p, f, next);
    if (f != ParameterField.cutSpeed) return EditResult(updated);

    final minimum = intervalMinimum(updated.cutSpeed);
    if (updated.attackInterval >= minimum) return EditResult(updated);
    return EditResult(
      updated.copyWith(attackInterval: minimum),
      adjustedInterval: minimum,
    );
  }

  /// Anterior valor permitido menor que el actual; si no hay, sin cambios.
  /// Bajar la velocidad del corte nunca cambia el intervalo (FR-008).
  static EditResult decrement(ExerciseParameters p, ParameterField f) {
    final previous = _previous(p, f);
    if (previous == null) return EditResult(p);
    return EditResult(_with(p, f, previous));
  }

  static int? _next(ExerciseParameters p, ParameterField f) {
    final current = _current(p, f);
    for (final v in allowedValues(p, f)) {
      if (v > current) return v;
    }
    return null;
  }

  static int? _previous(ExerciseParameters p, ParameterField f) {
    final current = _current(p, f);
    for (final v in allowedValues(p, f).reversed) {
      if (v < current) return v;
    }
    return null;
  }

  static int _current(ExerciseParameters p, ParameterField f) => switch (f) {
    ParameterField.duration => p.duration.inMilliseconds,
    ParameterField.maxRepeats => p.maxRepeats,
    ParameterField.warningTime => p.warningTime.inMilliseconds,
    ParameterField.cutSpeed => p.cutSpeed.inMilliseconds,
    ParameterField.attackInterval => p.attackInterval.inMilliseconds,
  };

  static ExerciseParameters _with(
    ExerciseParameters p,
    ParameterField f,
    int value,
  ) {
    final d = Duration(milliseconds: value);
    return switch (f) {
      ParameterField.duration => p.copyWith(duration: d),
      ParameterField.maxRepeats => p.copyWith(maxRepeats: value),
      ParameterField.warningTime => p.copyWith(warningTime: d),
      ParameterField.cutSpeed => p.copyWith(cutSpeed: d),
      ParameterField.attackInterval => p.copyWith(attackInterval: d),
    };
  }

  static List<int> _range(int from, int to, int step) => [
    for (var v = from; v <= to; v += step) v,
  ];
}
