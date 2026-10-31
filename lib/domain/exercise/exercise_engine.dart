import '../ports/random_source.dart';
import 'attack.dart';
import 'exercise_event.dart';
import 'exercise_parameters.dart';
import 'exercise_snapshot.dart';
import 'exercise_status.dart';
import 'session.dart';
import 'side_sequencer.dart';
import 'signal.dart';

/// Motor del ejercicio como línea de tiempo pura (research R2, R3): no tiene
/// temporizadores; la presentación le pasa el tiempo transcurrido con
/// [advanceTo] y el motor calcula todo a partir de ese tiempo absoluto.
final class ExerciseEngine {
  /// Lanza [InvalidParametersException] si `parameters.validate()` no está vacío.
  ExerciseEngine({
    required this.session,
    required this.parameters,
    required RandomSource random,
  }) : _random = random,
       _sides = SideSequencer(
         maxRepeats: parameters.maxRepeats,
         random: random,
       ) {
    final violations = parameters.validate();
    if (violations.isNotEmpty) throw InvalidParametersException(violations);
  }

  static const countdownLength = Duration(seconds: 3);

  final Session session;
  final ExerciseParameters parameters;
  final RandomSource _random;
  final SideSequencer _sides;

  ExerciseStatus _status = ExerciseStatus.ready;
  Duration _elapsed = Duration.zero;

  /// Último ataque mostrado y qué eventos suyos ya se emitieron.
  Attack? _attack;
  bool _cutStartEmitted = false;
  bool _cutEndEmitted = false;

  /// Instante de la siguiente señal (la 1.ª se sortea en *Si-jak*).
  Duration? _nextSignalAt;
  int _attackCount = 0;

  ExerciseStatus get status => _status;

  /// Instante de *Si-jak* (S).
  Duration get startVoiceAt => countdownLength;

  /// Fin nominal del ejercicio (E = S + duración).
  Duration get nominalEnd => countdownLength + parameters.duration;

  /// ready → countdown. Fija t = 0. StateError si el estado no es ready.
  void start() {
    _transition(ExerciseStatus.countdown);
    _elapsed = Duration.zero;
  }

  /// Avanza el estado hasta [elapsed], medido desde [start]. Debe ser monótono:
  /// un valor menor que el anterior lanza ArgumentError. Devuelve el snapshot
  /// en [elapsed] y los eventos ocurridos en (anterior, elapsed], en orden.
  /// En estados terminales devuelve el snapshot final y ningún evento.
  ExerciseTick advanceTo(Duration elapsed) {
    if (_status == ExerciseStatus.ready) {
      throw StateError('advanceTo antes de start()');
    }
    if (elapsed < _elapsed) {
      throw ArgumentError.value(
        elapsed,
        'elapsed',
        'Menor que el tiempo anterior ($_elapsed)',
      );
    }
    if (_status.isTerminal) {
      return ExerciseTick(snapshot: _snapshot(), events: const []);
    }

    final events = <ExerciseEvent>[];
    while (true) {
      final step = _nextStep();
      if (step == null || step.at > elapsed) break;
      events.addAll(step.apply());
      if (_status.isTerminal) {
        // El snapshot final queda congelado en el instante del fin.
        _elapsed = step.at;
        return ExerciseTick(snapshot: _snapshot(), events: events);
      }
    }
    _elapsed = elapsed;
    return ExerciseTick(snapshot: _snapshot(), events: events);
  }

  /// countdown | running | finishing → cancelled. Emite `cancelled`.
  /// StateError en ready; no hace nada en finished o cancelled.
  ExerciseTick cancel() => throw UnimplementedError('Se implementa en T047');

  /// Próximo instante pendiente de la línea de tiempo. Con instantes iguales,
  /// el orden es: fin del corte, inicio del corte, señal, fin nominal.
  _Step? _nextStep() {
    if (_status == ExerciseStatus.countdown) {
      return _Step(startVoiceAt, _onStartVoice);
    }
    final attack = _attack;
    final candidates = <_Step>[
      if (attack != null && !_cutEndEmitted) _Step(attack.cutEndAt, _onCutEnd),
      if (attack != null && !_cutStartEmitted)
        _Step(attack.cutStartAt, _onCutStart),
      if (_status == ExerciseStatus.running &&
          _nextSignalAt != null &&
          _nextSignalAt! < nominalEnd)
        _Step(_nextSignalAt!, _onSignal),
      if (_status == ExerciseStatus.running) _Step(nominalEnd, _onNominalEnd),
    ];
    if (candidates.isEmpty) return null;
    // Orden estable: ante empates gana el primero de la lista.
    var next = candidates.first;
    for (final candidate in candidates.skip(1)) {
      if (candidate.at < next.at) next = candidate;
    }
    return next;
  }

  List<ExerciseEvent> _onStartVoice() {
    _transition(ExerciseStatus.running);
    // La 1.ª señal sale un sorteo después de Si-jak (FR-012).
    _nextSignalAt = startVoiceAt + _drawInterval();
    return [StartVoice(startVoiceAt)];
  }

  List<ExerciseEvent> _onSignal() {
    final signalAt = _nextSignalAt!;
    final side = _sides.next();
    final cutStartAt = signalAt + parameters.warningTime;
    final attack = Attack(
      index: _attackCount++,
      side: side,
      responseType: session.level.responseTypes.first,
      signalAt: signalAt,
      cutStartAt: cutStartAt,
      cutEndAt: cutStartAt + parameters.cutSpeed,
      nextSignalAt: cutStartAt + _drawInterval(),
    );
    _attack = attack;
    _cutStartEmitted = false;
    _cutEndEmitted = false;
    _nextSignalAt = attack.nextSignalAt;
    return [SignalShown(signalAt, attack)];
  }

  List<ExerciseEvent> _onCutStart() {
    _cutStartEmitted = true;
    return [CutStarted(_attack!.cutStartAt, _attack!)];
  }

  List<ExerciseEvent> _onCutEnd() {
    _cutEndEmitted = true;
    final attack = _attack!;
    final events = <ExerciseEvent>[CutEnded(attack.cutEndAt, attack)];
    if (_status == ExerciseStatus.finishing) {
      _transition(ExerciseStatus.finished);
      events.add(EndVoice(attack.cutEndAt));
    }
    return events;
  }

  List<ExerciseEvent> _onNominalEnd() {
    // Un ataque ya mostrado se completa siempre (FR-013, aclaración Q1).
    final attackInProgress = _attack != null && !_cutEndEmitted;
    if (attackInProgress) {
      _transition(ExerciseStatus.finishing);
      return const [];
    }
    _transition(ExerciseStatus.finished);
    return [EndVoice(nominalEnd)];
  }

  /// Intervalo en ms enteros en [intervalFloor, attackInterval], ambos incluidos.
  Duration _drawInterval() {
    final floorMs = parameters.intervalFloor.inMilliseconds;
    final maxMs = parameters.attackInterval.inMilliseconds;
    return Duration(
      milliseconds: floorMs + _random.nextInt(maxMs - floorMs + 1),
    );
  }

  void _transition(ExerciseStatus to) {
    ensureTransition(_status, to);
    _status = to;
  }

  ExerciseSnapshot _snapshot() {
    final t = _elapsed;
    final remaining = nominalEnd - t;
    final clampedRemaining = remaining.isNegative ? Duration.zero : remaining;

    switch (_status) {
      case ExerciseStatus.ready ||
          ExerciseStatus.finished ||
          ExerciseStatus.cancelled:
        return ExerciseSnapshot(
          status: _status,
          saberColor: SaberColor.white,
          elapsed: t,
          remaining: _status == ExerciseStatus.finished
              ? Duration.zero
              : clampedRemaining,
        );
      case ExerciseStatus.countdown:
        return ExerciseSnapshot(
          status: _status,
          countdownValue: 3 - t.inSeconds,
          saberColor: SaberColor.white,
          elapsed: t,
          remaining: clampedRemaining,
        );
      case ExerciseStatus.running || ExerciseStatus.finishing:
        final attack = _attack;
        if (attack == null || t >= attack.cutEndAt) {
          return ExerciseSnapshot(
            status: _status,
            phase: AttackPhase.guard,
            saberColor: SaberColor.yellow,
            elapsed: t,
            remaining: clampedRemaining,
          );
        }
        final inCut = t >= attack.cutStartAt;
        return ExerciseSnapshot(
          status: _status,
          phase: inCut ? AttackPhase.cut : AttackPhase.warning,
          saberColor: attack.side == Side.right
              ? SaberColor.blue
              : SaberColor.red,
          currentAttack: attack,
          signal: SignalPlacement.forAttack(attack),
          cutProgress: inCut
              ? ((t - attack.cutStartAt).inMicroseconds /
                        parameters.cutSpeed.inMicroseconds)
                    .clamp(0.0, 1.0)
              : null,
          elapsed: t,
          remaining: clampedRemaining,
        );
    }
  }
}

/// Instante pendiente de la línea de tiempo y la acción que lo procesa.
final class _Step {
  const _Step(this.at, this.apply);

  final Duration at;
  final List<ExerciseEvent> Function() apply;
}
