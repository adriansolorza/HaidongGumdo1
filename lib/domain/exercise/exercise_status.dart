/// Estados del ejercicio (FR-020).
/// Extensión futura: `paused`, con `running`/`finishing` ⇄ `paused` y `paused → cancelled`.
enum ExerciseStatus {
  ready,
  countdown,
  running,
  finishing,
  finished,
  cancelled;

  bool get isTerminal =>
      this == ExerciseStatus.finished || this == ExerciseStatus.cancelled;
}

/// Transiciones permitidas (data-model.md). Cualquier otra lanza [StateError].
const Map<ExerciseStatus, Set<ExerciseStatus>> allowedTransitions = {
  ExerciseStatus.ready: {ExerciseStatus.countdown},
  ExerciseStatus.countdown: {ExerciseStatus.running, ExerciseStatus.cancelled},
  ExerciseStatus.running: {
    ExerciseStatus.finishing,
    ExerciseStatus.finished,
    ExerciseStatus.cancelled,
  },
  ExerciseStatus.finishing: {ExerciseStatus.finished, ExerciseStatus.cancelled},
};

void ensureTransition(ExerciseStatus from, ExerciseStatus to) {
  if (!(allowedTransitions[from]?.contains(to) ?? false)) {
    throw StateError('Transición no permitida: ${from.name} → ${to.name}');
  }
}
