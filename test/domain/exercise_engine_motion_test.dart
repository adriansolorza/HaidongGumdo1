import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/exercise_status.dart';
import 'package:haidonggumdo/domain/exercise/opponent_motion.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';
import 'package:haidonggumdo/domain/ports/random_source.dart';

import 'fakes/manual_clock.dart';
import 'fakes/scripted_random_source.dart';
import 'fakes/seeded_random_source.dart';
import 'fakes/test_session.dart';

Duration _ms(num ms) => Duration(microseconds: (ms * 1000).round());

const _frame = Duration(milliseconds: 16);

/// Guion en el orden en que el motor sortea (ver exercise_engine_timeline_test):
/// intervalo de la 1.ª señal y, por ataque, lado e intervalo siguiente. Los
/// lados alternan (right, left, …) para no forzar lados.
ScriptedRandomSource _script({
  required int first,
  List<int> intervals = const [],
}) => ScriptedRandomSource([
  first,
  for (var i = 0; i < 40; i++) ...[
    i % 2,
    i < intervals.length ? intervals[i] : 0,
  ],
]);

ExerciseEngine _engine(
  RandomSource random, {
  ExerciseParameters? parameters,
  Session? session,
}) => ExerciseEngine(
  session: session ?? testSession(),
  parameters: parameters ?? ExerciseParameters.defaults(),
  random: random,
)..start();

OpponentMotion _motionAt(ExerciseEngine engine, num ms) =>
    engine.advanceTo(_ms(ms)).snapshot.motion;

OpponentMotion _m(PoseKey from, PoseKey to, double progress, Side side) =>
    OpponentMotion(from: from, to: to, progress: progress, side: side);

void main() {
  late ManualClock clock;

  setUp(() => clock = ManualClock()..start());

  test('FR-008: en guardia (atGuard) en la cuenta regresiva y tras Si-jak', () {
    final engine = _engine(_script(first: 0));
    expect(_motionAt(engine, 0), OpponentMotion.atGuard);
    expect(_motionAt(engine, 2500), OpponentMotion.atGuard);
    expect(_motionAt(engine, 3500), OpponentMotion.atGuard);
  });

  group('un ataque con los valores por defecto (FR-010)', () {
    // Señal en 4.0 s; subida hasta 4.35 s; corte [4.7 s, 5.2 s); regreso
    // hasta 5.7 s; la señal siguiente, con sorteo 1500, en 7.2 s.
    late ExerciseEngine engine;

    setUp(() => engine = _engine(_script(first: 0, intervals: [1500])));

    test('paso 2: subida guard → stance en la primera mitad del aviso', () {
      expect(
        _motionAt(engine, 4000),
        _m(PoseKey.guard, PoseKey.stance, 0, Side.right),
      );
      expect(
        _motionAt(engine, 4175),
        _m(PoseKey.guard, PoseKey.stance, 0.5, Side.right),
      );
      expect(engine.riseDuration, _ms(350));
    });

    test('paso 2: quieto en stance la segunda mitad, hasta el corte', () {
      expect(
        _motionAt(engine, 4350),
        _m(PoseKey.stance, PoseKey.stance, 0, Side.right),
      );
      expect(
        _motionAt(engine, 4699),
        _m(PoseKey.stance, PoseKey.stance, 0, Side.right),
      );
    });

    test('paso 3: corte stance → cutEnd con progress == cutProgress', () {
      for (final ms in [4700, 4825, 4950, 5199]) {
        final snapshot = engine.advanceTo(_ms(ms)).snapshot;
        expect(snapshot.phase, AttackPhase.cut);
        expect(snapshot.motion.from, PoseKey.stance);
        expect(snapshot.motion.to, PoseKey.cutEnd);
        expect(snapshot.motion.progress, snapshot.cutProgress);
        expect(snapshot.motion.side, Side.right);
      }
    });

    test('paso 4: regreso cutEnd → guard en 500 ms con el lado del ataque, luego atGuard', () {
      final atCutEnd = engine.advanceTo(_ms(5200)).snapshot;
      expect(atCutEnd.phase, AttackPhase.guard);
      expect(atCutEnd.motion, _m(PoseKey.cutEnd, PoseKey.guard, 0, Side.right));
      expect(
        _motionAt(engine, 5450),
        _m(PoseKey.cutEnd, PoseKey.guard, 0.5, Side.right),
      );
      expect(_motionAt(engine, 5700), OpponentMotion.atGuard);
      expect(_motionAt(engine, 7199), OpponentMotion.atGuard);
    });
  });

  test('el regreso de un ataque a la izquierda conserva side == left', () {
    // Ataque 1 (left): señal en 5.7 s, corte hasta 6.9 s.
    final engine = _engine(_script(first: 0, intervals: [0, 1500]));
    expect(
      _motionAt(engine, 7150),
      _m(PoseKey.cutEnd, PoseKey.guard, 0.5, Side.left),
    );
  });

  test('con warningTime = 330 ms la subida dura 165 ms', () {
    final d = ExerciseParameters.defaults();
    final engine = _engine(
      _script(first: 0),
      parameters: ExerciseParameters.create(
        duration: d.duration,
        maxRepeats: d.maxRepeats,
        warningTime: _ms(330),
        cutSpeed: d.cutSpeed,
        attackInterval: d.attackInterval,
      ),
    );
    expect(engine.riseDuration, _ms(165));
    expect(
      _motionAt(engine, 4082.5),
      _m(PoseKey.guard, PoseKey.stance, 0.5, Side.right),
    );
    expect(
      _motionAt(engine, 4165),
      _m(PoseKey.stance, PoseKey.stance, 0, Side.right),
    );
  });

  test('con el intervalo mínimo la señal siguiente llega justo al terminar el regreso', () {
    // Sorteo 0: señal siguiente en 4.7 s + 1.0 s = 5.7 s = cutEndAt + 500 ms.
    final engine = _engine(_script(first: 0));
    expect(_motionAt(engine, 5699).from, PoseKey.cutEnd);
    final atSignal = engine.advanceTo(_ms(5700));
    expect(atSignal.events.whereType<SignalShown>(), hasLength(1));
    expect(
      atSignal.snapshot.motion,
      _m(PoseKey.guard, PoseKey.stance, 0, Side.left),
    );
  });

  group('el regreso nunca se cruza con la señal siguiente (simulación)', () {
    void simulate(ExerciseParameters parameters) {
      for (var seed = 0; seed < 100; seed++) {
        final engine = _engine(
          SeededRandomSource(seed),
          parameters: parameters,
        );
        final attacks = <Attack>[];
        for (var t = Duration.zero; !engine.status.isTerminal; t += _frame) {
          final tick = engine.advanceTo(t);
          attacks.addAll([
            for (final e in tick.events)
              if (e is SignalShown) e.attack,
          ]);
          final s = tick.snapshot;
          // Con la señal visible, el oponente nunca está regresando.
          if (s.signal != null) {
            expect(
              s.motion.from,
              isNot(PoseKey.cutEnd),
              reason: 'semilla $seed, $t',
            );
          }
        }
        for (var i = 1; i < attacks.length; i++) {
          expect(
            attacks[i - 1].cutEndAt + ExerciseEngine.returnDuration <=
                attacks[i].signalAt,
            isTrue,
            reason: 'semilla $seed, ataque $i',
          );
        }
      }
    }

    ExerciseParameters params({
      required Duration cutSpeed,
      required Duration attackInterval,
    }) {
      final d = ExerciseParameters.defaults();
      return ExerciseParameters.create(
        duration: const Duration(seconds: 180),
        maxRepeats: d.maxRepeats,
        warningTime: d.warningTime,
        cutSpeed: cutSpeed,
        attackInterval: attackInterval,
      );
    }

    test('valores por defecto, 180 s', () {
      simulate(params(cutSpeed: _ms(500), attackInterval: _ms(2500)));
    });

    test('corte de 1000 ms con el intervalo en el piso (1500 ms)', () {
      simulate(params(cutSpeed: _ms(1000), attackInterval: _ms(1500)));
    });
  });

  group('estados terminales: atGuard sin animar el regreso (plan.md D4)', () {
    test('finished desde running', () {
      final engine = _engine(
        _script(first: 1500, intervals: List.filled(40, 1500)),
      );
      final snapshot = engine.advanceTo(_ms(40000)).snapshot;
      expect(snapshot.status, ExerciseStatus.finished);
      expect(snapshot.motion, OpponentMotion.atGuard);
    });

    test('finished tras finishing (Guman al terminar el corte)', () {
      // E = 33 s cae en el corte [32.7 s, 33.2 s] (Escenario 8 del timeline).
      final engine = _engine(_script(first: 800));
      engine.advanceTo(_ms(33000));
      expect(engine.status, ExerciseStatus.finishing);
      final snapshot = engine.advanceTo(_ms(33200)).snapshot;
      expect(snapshot.status, ExerciseStatus.finished);
      expect(snapshot.motion, OpponentMotion.atGuard);
    });

    test('cancelled durante un corte', () {
      final engine = _engine(_script(first: 0))..advanceTo(_ms(4900));
      expect(engine.cancel().snapshot.motion, OpponentMotion.atGuard);
    });
  });

  test('el reloj manual avanza la subida igual que advanceTo directo', () {
    final engine = _engine(_script(first: 0));
    clock.set(_ms(4175));
    expect(
      engine.advanceTo(clock.elapsed).snapshot.motion,
      _m(PoseKey.guard, PoseKey.stance, 0.5, Side.right),
    );
  });

  group('Patrón transversal (Spec 002)', () {
    // Mismos tramos que el frontal (FR-007, FR-010): señal en 4.0 s; subida
    // hasta 4.35 s; barrido [4.7 s, 5.2 s), frente al oponente en 4.95 s;
    // regreso hasta 5.7 s; la señal siguiente, con sorteo 1500, en 7.2 s.
    late ExerciseEngine engine;

    setUp(
      () => engine = _engine(
        _script(first: 0, intervals: [1500]),
        session: testTransversalSession(),
      ),
    );

    test('subida guard → stance (Sodose) en la primera mitad del aviso', () {
      expect(
        _motionAt(engine, 4000),
        _m(PoseKey.guard, PoseKey.stance, 0, Side.right),
      );
      expect(
        _motionAt(engine, 4175),
        _m(PoseKey.guard, PoseKey.stance, 0.5, Side.right),
      );
    });

    test('quieto en Sodose la segunda mitad, hasta el barrido', () {
      expect(
        _motionAt(engine, 4350),
        _m(PoseKey.stance, PoseKey.stance, 0, Side.right),
      );
      expect(
        _motionAt(engine, 4699),
        _m(PoseKey.stance, PoseKey.stance, 0, Side.right),
      );
    });

    test(
      'barrido stance → cutEnd con progress == cutProgress; frente a la mitad',
      () {
        for (final ms in [4700, 4950, 5199]) {
          final snapshot = engine.advanceTo(_ms(ms)).snapshot;
          expect(snapshot.motion.from, PoseKey.stance);
          expect(snapshot.motion.to, PoseKey.cutEnd);
          expect(snapshot.motion.progress, snapshot.cutProgress);
          expect(snapshot.motion.side, Side.right);
        }
      },
    );

    test('el barrido pasa frente al oponente a la mitad (0.25 s)', () {
      expect(_motionAt(engine, 4950).progress, 0.5);
    });

    test('regreso cutEnd → guard con el lado del ataque, luego atGuard', () {
      expect(
        _motionAt(engine, 5450),
        _m(PoseKey.cutEnd, PoseKey.guard, 0.5, Side.right),
      );
      expect(_motionAt(engine, 5700), OpponentMotion.atGuard);
      expect(_motionAt(engine, 7199), OpponentMotion.atGuard);
    });

    test('un ataque a la izquierda conserva side == left en el regreso', () {
      final left = _engine(
        _script(first: 0, intervals: [0, 1500]),
        session: testTransversalSession(),
      );
      expect(
        _motionAt(left, 7150),
        _m(PoseKey.cutEnd, PoseKey.guard, 0.5, Side.left),
      );
    });
  });
}
