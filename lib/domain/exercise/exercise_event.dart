import 'attack.dart';

/// Suceso de la línea de tiempo; [at] es su instante desde que se pulsó Iniciar.
sealed class ExerciseEvent {
  const ExerciseEvent(this.at);

  final Duration at;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is ExerciseEvent &&
      other.at == at;

  @override
  int get hashCode => Object.hash(runtimeType, at);
}

/// Voz de inicio (*Si-jak*).
final class StartVoice extends ExerciseEvent {
  const StartVoice(super.at);
}

/// Base de los eventos ligados a un ataque.
sealed class AttackEvent extends ExerciseEvent {
  const AttackEvent(super.at, this.attack);

  final Attack attack;

  @override
  bool operator ==(Object other) =>
      super == other && other is AttackEvent && other.attack == attack;

  @override
  int get hashCode => Object.hash(super.hashCode, attack);
}

final class SignalShown extends AttackEvent {
  const SignalShown(super.at, super.attack);
}

final class CutStarted extends AttackEvent {
  const CutStarted(super.at, super.attack);
}

final class CutEnded extends AttackEvent {
  const CutEnded(super.at, super.attack);
}

/// Voz de fin (*Guman*).
final class EndVoice extends ExerciseEvent {
  const EndVoice(super.at);
}

final class Cancelled extends ExerciseEvent {
  const Cancelled(super.at);
}
