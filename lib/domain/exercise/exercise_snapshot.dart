import 'attack.dart';
import 'exercise_event.dart';
import 'exercise_status.dart';
import 'signal.dart';

/// Fase del ataque dentro de `running` y `finishing`.
enum AttackPhase { guard, warning, cut }

enum SaberColor { white, yellow, blue, red }

/// Estado visible del ejercicio en un instante.
final class ExerciseSnapshot {
  const ExerciseSnapshot({
    required this.status,
    this.phase,
    this.countdownValue,
    required this.saberColor,
    this.currentAttack,
    this.signal,
    this.cutProgress,
    required this.elapsed,
    required this.remaining,
  });

  final ExerciseStatus status;

  /// Solo en `running` y `finishing`.
  final AttackPhase? phase;

  /// 3, 2, 1 solo en `countdown`.
  final int? countdownValue;

  /// `white` en `ready`, `countdown`, `finished` y `cancelled`; `yellow` en
  /// `guard`; `blue` (`right`) o `red` (`left`) en `warning` y `cut`.
  final SaberColor saberColor;

  /// Ataque en `warning` o `cut`.
  final Attack? currentAttack;

  /// En `warning` y `cut`.
  final Signal? signal;

  /// En [0, 1], solo en `cut`.
  final double? cutProgress;

  /// Desde que se pulsó Iniciar.
  final Duration elapsed;

  /// Hasta E, nunca negativo.
  final Duration remaining;

  @override
  bool operator ==(Object other) =>
      other is ExerciseSnapshot &&
      other.status == status &&
      other.phase == phase &&
      other.countdownValue == countdownValue &&
      other.saberColor == saberColor &&
      other.currentAttack == currentAttack &&
      other.signal == signal &&
      other.cutProgress == cutProgress &&
      other.elapsed == elapsed &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(
    status,
    phase,
    countdownValue,
    saberColor,
    currentAttack,
    signal,
    cutProgress,
    elapsed,
    remaining,
  );
}

/// Resultado de avanzar el motor: el snapshot y los eventos ocurridos, en orden.
final class ExerciseTick {
  ExerciseTick({required this.snapshot, required List<ExerciseEvent> events})
    : events = List.unmodifiable(events);

  final ExerciseSnapshot snapshot;
  final List<ExerciseEvent> events;
}
