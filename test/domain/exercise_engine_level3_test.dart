import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/exercise_status.dart';
import 'package:haidonggumdo/domain/exercise/opponent_motion.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';
import 'package:haidonggumdo/domain/exercise/signal.dart';
import 'package:haidonggumdo/domain/ports/random_source.dart';

import 'fakes/scripted_random_source.dart';
import 'fakes/seeded_random_source.dart';
import 'fakes/test_session.dart';

/// Nivel 3 (Spec 006): sorteo del tipo de respuesta, rachas y orden de
/// sorteos (FR-004 a FR-007, FR-016; SC-004, SC-005; contrato E2 a E5).

Duration _ms(int ms) => Duration(milliseconds: ms);

const _exercises = 1000;

/// Más allá del fin de cualquier ejercicio de 180 s con su último corte.
const _afterEverything = Duration(seconds: 200);

ExerciseEngine _engine(
  Session session,
  RandomSource random, {
  int maxRepeats = 5,
  Duration duration = const Duration(seconds: 30),
}) {
  final d = ExerciseParameters.defaults();
  return ExerciseEngine(
    session: session,
    parameters: ExerciseParameters.create(
      duration: duration,
      maxRepeats: maxRepeats,
      warningTime: d.warningTime,
      cutSpeed: d.cutSpeed,
      attackInterval: d.attackInterval,
    ),
    random: random,
  );
}

/// Ejercicio completo: el motor procesa todos los instantes pendientes en un
/// solo `advanceTo` (es una línea de tiempo pura).
List<ExerciseEvent> _runToEnd(ExerciseEngine engine) {
  engine.start();
  final events = engine.advanceTo(_afterEverything).events;
  expect(engine.status, ExerciseStatus.finished);
  return events;
}

List<Attack> _attacks(List<ExerciseEvent> events) => [
  for (final e in events)
    if (e is SignalShown) e.attack,
];

int _longestStreak<T>(List<T> values) {
  var longest = 0;
  var current = 0;
  for (var i = 0; i < values.length; i++) {
    current = i > 0 && values[i] == values[i - 1] ? current + 1 : 1;
    if (current > longest) longest = current;
  }
  return longest;
}

void main() {
  group('Niveles 1 y 2: el tipo no consume sorteos (Spec 006, FR-017, E2)', () {
    for (final (name, session) in [
      ('Nivel 1', testSession),
      ('Nivel 2', testLevel2Session),
    ]) {
      test('$name: 1 sorteo inicial + 2 por ataque (lado e intervalo)', () {
        // Lados alternos: con N = 5 nunca se fuerza un lado.
        final random = ScriptedRandomSource([
          0,
          for (var i = 0; i < 40; i++) ...[i % 2, 0],
        ]);
        final attacks = _attacks(_runToEnd(_engine(session(), random)));
        expect(attacks, isNotEmpty);
        expect(random.consumed, 1 + 2 * attacks.length);
      });
    }
  });

  group('Nivel 3 transversal (Spec 006, US1)', () {
    test('orden de sorteos: lado → tipo → intervalo (E5)', () {
      // 1.er intervalo; luego (lado, tipo, intervalo) por ataque.
      final random = ScriptedRandomSource(const [0, 0, 1, 0, 1, 0, 0, 1, 1, 0]);
      final engine = _engine(testLevel3TransversalSession(), random)..start();
      // Señales en 4.0 s, 5.7 s y 7.4 s.
      final attacks = _attacks(engine.advanceTo(_ms(7500)).events);
      expect(
        [for (final a in attacks) (a.side, a.responseType)],
        [
          (Side.right, ResponseType.evasion),
          (Side.left, ResponseType.defense),
          (Side.left, ResponseType.evasion),
        ],
      );
      expect(random.consumed, 10);
    });

    for (var n = 1; n <= 5; n++) {
      test(
        'N = $n: en $_exercises ejercicios, ninguna racha de lado ni de tipo '
        'mayor que N (E3, SC-004)',
        () {
          for (var seed = 0; seed < _exercises; seed++) {
            final attacks = _attacks(
              _runToEnd(
                _engine(
                  testLevel3TransversalSession(),
                  SeededRandomSource(seed),
                  maxRepeats: n,
                  duration: const Duration(seconds: 180),
                ),
              ),
            );
            expect(
              _longestStreak([for (final a in attacks) a.side]),
              lessThanOrEqualTo(n),
              reason: 'lados, semilla $seed',
            );
            expect(
              _longestStreak([for (final a in attacks) a.responseType]),
              lessThanOrEqualTo(n),
              reason: 'tipos, semilla $seed',
            );
          }
        },
      );
    }

    test('N = 5: defensas y lados derechos entre 45 % y 55 %; las secuencias '
        'cambian entre semillas (E4, SC-005, RN1)', () {
      final runs = [
        for (var seed = 0; seed < _exercises; seed++)
          _attacks(
            _runToEnd(
              _engine(
                testLevel3TransversalSession(),
                SeededRandomSource(seed),
                duration: const Duration(seconds: 180),
              ),
            ),
          ),
      ];
      final all = [for (final run in runs) ...run];
      expect(all.length, greaterThanOrEqualTo(10000));
      final defense =
          all.where((a) => a.responseType == ResponseType.defense).length /
          all.length;
      final right = all.where((a) => a.side == Side.right).length / all.length;
      expect(defense, inInclusiveRange(0.45, 0.55));
      expect(right, inInclusiveRange(0.45, 0.55));

      String key(List<Attack> run) =>
          run.map((a) => '${a.side.index}${a.responseType.index}').join();
      expect({for (final run in runs) key(run)}.length, greaterThan(1));
    });

    test('cada ejercicio empieza su racha de tipo desde cero (FR-007)', () {
      // A: (right, evasion); B: (left, defense). Con N = 1, si B heredara la
      // racha de A, su tipo saldría forzado sin consumir sorteo.
      final random = ScriptedRandomSource(const [0, 0, 1, 0, 0, 1, 0, 0]);
      final a = _engine(testLevel3TransversalSession(), random, maxRepeats: 1)
        ..start();
      final first = _attacks(a.advanceTo(_ms(4000)).events).single;
      final b = _engine(testLevel3TransversalSession(), random, maxRepeats: 1)
        ..start();
      final second = _attacks(b.advanceTo(_ms(4000)).events).single;
      expect(
        (first.side, first.responseType),
        (Side.right, ResponseType.evasion),
      );
      expect(
        (second.side, second.responseType),
        (Side.left, ResponseType.defense),
      );
      expect(random.consumed, 8);
    });

    test('N = 1: solo el 1.er ataque sortea lado y tipo, y la señal cae '
        'siempre en la misma mitad (caso límite)', () {
      final random = ScriptedRandomSource([0, 0, 0, ...List.filled(200, 0)]);
      final attacks = _attacks(
        _runToEnd(
          _engine(testLevel3TransversalSession(), random, maxRepeats: 1),
        ),
      );
      expect(attacks.length, greaterThan(2));
      // 1 intervalo inicial + (lado, tipo, intervalo) del 1.º + 1 intervalo
      // por cada ataque siguiente.
      expect(random.consumed, attacks.length + 3);
      final halves = {
        for (final a in attacks) SignalPlacement.forAttack(a).screenSide,
      };
      expect(halves, hasLength(1));
    });

    group('estados, cancelación y voces (FR-016)', () {
      test('cancel() en el aviso del 2.º ataque → cancelled, sin EndVoice', () {
        final engine = _engine(
          testLevel3TransversalSession(),
          ScriptedRandomSource(List.filled(500, 0)),
        )..start();
        // 2.ª señal en 5.7 s; aviso hasta 6.4 s.
        final before = engine.advanceTo(_ms(6000)).snapshot;
        expect(before.phase, AttackPhase.warning);
        expect(before.currentAttack!.index, 1);

        final tick = engine.cancel();
        expect(engine.status, ExerciseStatus.cancelled);
        expect(tick.events, [Cancelled(_ms(6000))]);
        expect(engine.advanceTo(_ms(100000)).events, isEmpty);
      });

      test('fin nominal a mitad de un corte → finishing, el corte termina y '
          'después EndVoice', () {
        // 1.ª señal en 4.8 s; la 17.ª en 32.0 s, corte [32.7 s, 33.2 s].
        final engine = _engine(
          testLevel3TransversalSession(),
          ScriptedRandomSource([800, ...List.filled(500, 0)]),
        )..start();
        engine.advanceTo(_ms(33000));
        expect(engine.status, ExerciseStatus.finishing);

        final events = engine.advanceTo(_ms(100000)).events;
        expect(engine.status, ExerciseStatus.finished);
        final cutEnd = events.whereType<CutEnded>().single;
        final endVoice = events.whereType<EndVoice>().single;
        expect(events.indexOf(endVoice), greaterThan(events.indexOf(cutEnd)));
        expect(endVoice.at, cutEnd.attack.cutEndAt);
        expect(endVoice.at, _ms(33200));
      });

      test('StartVoice en startVoiceAt, antes del 1.er SignalShown', () {
        final engine = _engine(
          testLevel3TransversalSession(),
          ScriptedRandomSource(List.filled(500, 0)),
        );
        final events = _runToEnd(engine);
        final start = events.whereType<StartVoice>().single;
        expect(start.at, engine.startVoiceAt);
        expect(
          events.indexOf(start),
          lessThan(events.indexWhere((e) => e is SignalShown)),
        );
      });
    });
  });

  group('Nivel 3 frontal (Spec 006, US2)', () {
    test('US2-3: en 1 min con N = 5 aparecen defensas y evasiones', () {
      for (var seed = 1; seed <= 100; seed++) {
        final types = {
          for (final a in _attacks(
            _runToEnd(
              _engine(
                testLevel3Session(),
                SeededRandomSource(seed),
                duration: const Duration(seconds: 60),
              ),
            ),
          ))
            a.responseType,
        };
        expect(types, {
          ResponseType.defense,
          ResponseType.evasion,
        }, reason: 'semilla $seed');
      }
    });

    // FR-011: la postura del oponente no depende del tipo de respuesta. Se
    // comparan ataques del mismo lado y distinto tipo de una simulación
    // sembrada, a mitad del aviso y al inicio del corte.
    for (final (name, session) in [
      ('frontal', testLevel3Session),
      ('transversal', testLevel3TransversalSession),
    ]) {
      test('US2-2, FR-011 ($name): el movimiento no revela el tipo', () {
        ExerciseEngine engine() => _engine(
          session(),
          SeededRandomSource(7),
          duration: const Duration(seconds: 180),
        );
        final attacks = _attacks(_runToEnd(engine()));

        // Misma semilla: el segundo motor repite los mismos ataques.
        final replay = engine()..start();
        final halfWarning = ExerciseParameters.defaults().warningTime ~/ 2;
        final motions =
            <(Side, ResponseType), Set<(OpponentMotion, OpponentMotion)>>{};
        for (final a in attacks) {
          final atHalf = replay.advanceTo(a.signalAt + halfWarning).snapshot;
          final atCut = replay.advanceTo(a.cutStartAt).snapshot;
          expect(atHalf.currentAttack, a);
          motions.putIfAbsent((a.side, a.responseType), () => {}).add((
            atHalf.motion,
            atCut.motion,
          ));
        }

        for (final side in Side.values) {
          final defense = motions[(side, ResponseType.defense)];
          final evasion = motions[(side, ResponseType.evasion)];
          expect(defense, isNotNull, reason: '$side sin defensas');
          expect(evasion, isNotNull, reason: '$side sin evasiones');
          // Todas las posturas de un mismo lado son idénticas, sea cual sea
          // el tipo.
          expect(defense, hasLength(1), reason: '$side, defensa');
          expect(evasion, defense, reason: '$side');
        }
      });
    }
  });
}
