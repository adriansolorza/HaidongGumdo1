import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/exercise_status.dart';
import 'package:haidonggumdo/domain/ports/random_source.dart';

import 'fakes/manual_clock.dart';
import 'fakes/scripted_random_source.dart';
import 'fakes/seeded_random_source.dart';
import 'fakes/test_session.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);

const _frame = Duration(milliseconds: 16);

/// Guion con la 1.ª señal en 4.0 s (aviso [4.0, 4.7), corte [4.7, 5.2)) y
/// lados alternos para no forzar lados (ver exercise_engine_timeline_test).
ScriptedRandomSource _script({int first = 0, int interval = 0}) =>
    ScriptedRandomSource([
      first,
      for (var i = 0; i < 40; i++) ...[i % 2, interval],
    ]);

ExerciseEngine _engine(RandomSource random) => ExerciseEngine(
  session: testSession(),
  parameters: ExerciseParameters.defaults(),
  random: random,
);

/// Avanza con el reloj manual en pasos de 16 ms y registra cada estado nuevo.
List<ExerciseStatus> _runStatuses(
  ExerciseEngine engine,
  ManualClock clock,
  Duration until,
) {
  final statuses = <ExerciseStatus>[engine.status];
  while (clock.elapsed < until && !engine.status.isTerminal) {
    clock.advance(_frame);
    engine.advanceTo(clock.elapsed);
    if (engine.status != statuses.last) statuses.add(engine.status);
  }
  return statuses;
}

void main() {
  late ManualClock clock;

  setUp(() => clock = ManualClock()..start());

  group('recorrido feliz (FR-020)', () {
    test('ready → countdown → running → finished', () {
      // E = 33 s cae en guardia (ver Escenario 10 del timeline).
      final engine = _engine(_script(first: 1500, interval: 1500));
      expect(engine.status, ExerciseStatus.ready);
      engine.start();
      expect(_runStatuses(engine, clock, _ms(40000)), [
        ExerciseStatus.countdown,
        ExerciseStatus.running,
        ExerciseStatus.finished,
      ]);
    });

    test('… → running → finishing → finished', () {
      // E = 33 s cae a mitad de un corte (ver Escenario 8 del timeline).
      final engine = _engine(_script(first: 800))..start();
      expect(_runStatuses(engine, clock, _ms(40000)), [
        ExerciseStatus.countdown,
        ExerciseStatus.running,
        ExerciseStatus.finishing,
        ExerciseStatus.finished,
      ]);
    });

    test('cada transición observada está en allowedTransitions', () {
      final engine = _engine(_script(first: 800))..start();
      final statuses = _runStatuses(engine, clock, _ms(40000));
      for (var i = 1; i < statuses.length; i++) {
        expect(allowedTransitions[statuses[i - 1]], contains(statuses[i]));
      }
    });
  });

  group('cancel() (G9, escenarios 1 y 2 de US2)', () {
    // Instante de cancelación → fase esperada justo antes.
    final cases = <String, (Duration, AttackPhase?)>{
      'countdown (1.5 s)': (_ms(1500), null),
      'guard': (_ms(3500), AttackPhase.guard),
      'warning': (_ms(4300), AttackPhase.warning),
      'cut': (_ms(4900), AttackPhase.cut),
    };

    cases.forEach((name, c) {
      final (at, phase) = c;
      test('en $name → cancelled con Cancelled y sin eventos después', () {
        final engine = _engine(_script())..start();
        final before = engine.advanceTo(at).snapshot;
        expect(before.phase, phase);

        final tick = engine.cancel();
        expect(engine.status, ExerciseStatus.cancelled);
        expect(tick.events, [Cancelled(at)]);
        expect(tick.snapshot.status, ExerciseStatus.cancelled);
        expect(tick.snapshot.saberColor, SaberColor.white);
        expect(tick.snapshot.phase, isNull);
        expect(tick.snapshot.signal, isNull);
        expect(tick.snapshot.currentAttack, isNull);
        expect(tick.snapshot.countdownValue, isNull);

        // Ni StartVoice (si se canceló en la cuenta) ni EndVoice.
        expect(engine.advanceTo(_ms(100000)).events, isEmpty);
        expect(engine.status, ExerciseStatus.cancelled);
      });
    });

    test('en finishing → cancelled y nunca suena EndVoice', () {
      final engine = _engine(_script(first: 800))..start();
      // E = 33 s cae en el corte [32.7 s, 33.2 s].
      engine.advanceTo(_ms(33000));
      expect(engine.status, ExerciseStatus.finishing);

      expect(engine.cancel().events, [Cancelled(_ms(33000))]);
      final after = engine.advanceTo(_ms(100000)).events;
      expect(after, isEmpty);
    });
  });

  group('llamadas no permitidas', () {
    test('start() dos veces → StateError', () {
      final engine = _engine(_script())..start();
      expect(engine.start, throwsStateError);
    });

    test('start() tras finished → StateError', () {
      final engine = _engine(_script(first: 1500, interval: 1500))..start();
      engine.advanceTo(_ms(40000));
      expect(engine.status, ExerciseStatus.finished);
      expect(engine.start, throwsStateError);
    });

    test('start() tras cancelled → StateError', () {
      final engine = _engine(_script())
        ..start()
        ..cancel();
      expect(engine.start, throwsStateError);
    });

    test('cancel() en ready → StateError', () {
      expect(_engine(_script()).cancel, throwsStateError);
    });

    test('cancel() en finished → sin eventos y sigue finished', () {
      final engine = _engine(_script(first: 1500, interval: 1500))..start();
      engine.advanceTo(_ms(40000));
      final tick = engine.cancel();
      expect(tick.events, isEmpty);
      expect(tick.snapshot.status, ExerciseStatus.finished);
    });

    test('cancel() en cancelled → sin eventos', () {
      final engine = _engine(_script())
        ..start()
        ..cancel();
      final tick = engine.cancel();
      expect(tick.events, isEmpty);
      expect(tick.snapshot.status, ExerciseStatus.cancelled);
    });
  });

  test('G10: ensureTransition lanza para todo par fuera de la tabla', () {
    for (final from in ExerciseStatus.values) {
      for (final to in ExerciseStatus.values) {
        final allowed = allowedTransitions[from]?.contains(to) ?? false;
        if (allowed) {
          expect(() => ensureTransition(from, to), returnsNormally);
        } else {
          expect(
            () => ensureTransition(from, to),
            throwsStateError,
            reason: '${from.name} → ${to.name}',
          );
        }
      }
    }
  });

  test('escenario 3: tras cancelar, un motor nuevo con otra fuente da otra secuencia de lados', () {
    List<Side> sides(int seed) {
      final engine = _engine(SeededRandomSource(seed))..start();
      return [
        for (final e in engine.advanceTo(_ms(40000)).events)
          if (e is SignalShown) e.attack.side,
      ];
    }

    final cancelled = _engine(SeededRandomSource(1))..start();
    cancelled
      ..advanceTo(_ms(10000))
      ..cancel();
    expect(cancelled.status, ExerciseStatus.cancelled);

    expect(sides(2), isNot(sides(3)));
  });
}
