import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/exercise_snapshot.dart';
import 'package:haidonggumdo/domain/exercise/exercise_status.dart';

import 'fakes/manual_clock.dart';
import 'fakes/scripted_random_source.dart';
import 'fakes/test_session.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);
Duration _s(num s) => Duration(milliseconds: (s * 1000).round());

const _frame = Duration(milliseconds: 16);
final _e = _s(33); // E = S (3 s) + 30 s

/// Guion de sorteos en el orden en que el motor los pide: el intervalo de la
/// 1.ª señal (en *Si-jak*) y, por cada ataque, el lado y el siguiente
/// intervalo. Los lados alternan para que N = 5 nunca fuerce un lado (un lado
/// forzado no consume sorteo y desalinearía el guion).
/// Un sorteo de intervalo `d` da `1000 + d` ms con los valores por defecto.
ScriptedRandomSource _script({
  required int first,
  int interval = 0,
  List<int>? intervals,
  int attacks = 40,
}) => ScriptedRandomSource([
  first,
  for (var i = 0; i < attacks; i++) ...[
    i % 2,
    intervals != null && i < intervals.length ? intervals[i] : interval,
  ],
]);

/// Motor con valores por defecto, ya iniciado (t = 0).
ExerciseEngine _started(ScriptedRandomSource random) => ExerciseEngine(
  session: testSession(),
  parameters: ExerciseParameters.defaults(),
  random: random,
)..start();

/// Avanza con el reloj manual en pasos de [step] hasta [until] o hasta un
/// estado terminal, y devuelve todos los eventos.
List<ExerciseEvent> _run(
  ExerciseEngine engine,
  ManualClock clock, {
  required Duration until,
  Duration step = _frame,
}) {
  final events = <ExerciseEvent>[];
  while (clock.elapsed < until && !engine.status.isTerminal) {
    final next = clock.elapsed + step;
    clock.set(next > until ? until : next);
    events.addAll(engine.advanceTo(clock.elapsed).events);
  }
  return events;
}

List<Attack> _signals(List<ExerciseEvent> events) => [
  for (final e in events)
    if (e is SignalShown) e.attack,
];

void main() {
  late ManualClock clock;

  setUp(() => clock = ManualClock()..start());

  group('Escenario 1 / G2: cuenta regresiva y Si-jak', () {
    test('3 en [0,1), 2 en [1,2), 1 en [2,3), con sable blanco', () {
      final engine = _started(_script(first: 0));
      final expected = {
        _ms(0): 3,
        _ms(999): 3,
        _ms(1000): 2,
        _ms(1999): 2,
        _ms(2000): 1,
        _ms(2999): 1,
      };
      expected.forEach((t, value) {
        final snapshot = engine.advanceTo(t).snapshot;
        expect(snapshot.status, ExerciseStatus.countdown, reason: '$t');
        expect(snapshot.countdownValue, value, reason: '$t');
        expect(snapshot.saberColor, SaberColor.white, reason: '$t');
      });
    });

    test(
      'StartVoice exactamente en 3 s, antes de cualquier señal; luego amarillo',
      () {
        final engine = _started(_script(first: 0));
        expect(engine.advanceTo(_ms(2999)).events, isEmpty);
        final tick = engine.advanceTo(_s(3));
        expect(tick.events, [StartVoice(_s(3))]);
        expect(tick.snapshot.status, ExerciseStatus.running);
        expect(tick.snapshot.phase, AttackPhase.guard);
        expect(tick.snapshot.saberColor, SaberColor.yellow);
        expect(tick.snapshot.countdownValue, isNull);

        final events = _run(engine, clock..set(_s(3)), until: _s(10));
        expect(events.first, isA<SignalShown>());
      },
    );
  });

  group('FR-012: primer ataque', () {
    test('sorteo 0 → 1.ª señal en 4.0 s', () {
      final events = _run(_started(_script(first: 0)), clock, until: _s(6));
      expect(_signals(events).first.signalAt, _s(4.0));
    });

    test('sorteo 1500 → 1.ª señal en 5.5 s', () {
      final events = _run(_started(_script(first: 1500)), clock, until: _s(6));
      expect(_signals(events).first.signalAt, _s(5.5));
    });
  });

  group('Escenario 5 / G3: aviso y corte', () {
    test('aviso de 700 ms y corte de 500 ms', () {
      final events = _run(_started(_script(first: 0)), clock, until: _s(20));
      for (final attack in _signals(events)) {
        expect(attack.cutStartAt - attack.signalAt, _ms(700));
        expect(attack.cutEndAt - attack.cutStartAt, _ms(500));
      }
    });

    test(
      'cutProgress 0 al inicio, 0.5 a mitad; después, sin señal y amarillo',
      () {
        final engine = _started(_script(first: 0));
        // Señal en 4.0 s, corte en [4.7 s, 5.2 s].
        final warning = engine.advanceTo(_ms(4200)).snapshot;
        expect(warning.phase, AttackPhase.warning);
        expect(warning.signal, isNotNull);
        expect(warning.cutProgress, isNull);

        final cutStart = engine.advanceTo(_ms(4700)).snapshot;
        expect(cutStart.phase, AttackPhase.cut);
        expect(cutStart.cutProgress, 0);
        expect(cutStart.signal, isNotNull);

        final half = engine.advanceTo(_ms(4950)).snapshot;
        expect(half.cutProgress, 0.5);

        final after = engine.advanceTo(_ms(5200)).snapshot;
        expect(after.phase, AttackPhase.guard);
        expect(after.signal, isNull);
        expect(after.cutProgress, isNull);
        expect(after.currentAttack, isNull);
        expect(after.saberColor, SaberColor.yellow);
      },
    );

    test('el color del sable sigue al lado: right azul, left rojo', () {
      final engine = _started(_script(first: 0));
      // Ataque 0 → right (sorteo 0); ataque 1 → left (sorteo 1), en 5.7 s.
      expect(engine.advanceTo(_ms(4100)).snapshot.saberColor, SaberColor.blue);
      expect(engine.advanceTo(_ms(5800)).snapshot.saberColor, SaberColor.red);
    });
  });

  group('Escenario 6 / G4: intervalo entre ataques', () {
    test(
      '1000 ms con sorteo 0 y 2500 ms con sorteo 1500 (extremos incluidos)',
      () {
        final events = _run(
          _started(_script(first: 0, intervals: [0, 1500])),
          clock,
          until: _s(12),
        );
        final attacks = _signals(events);
        expect(attacks[1].signalAt - attacks[0].cutStartAt, _ms(1000));
        expect(attacks[2].signalAt - attacks[1].cutStartAt, _ms(2500));
      },
    );
  });

  group('Fin del ejercicio (FR-013)', () {
    test('Escenario 8 (CA5) / G6: E a mitad de un corte → finishing y Guman en cutEndAt', () {
      // 1.ª señal en 4.8 s; luego cada 1.7 s → señal 16 en 32.0 s, corte
      // [32.7 s, 33.2 s] con E = 33 s dentro.
      final engine = _started(_script(first: 800));
      final before = _run(engine, clock, until: _e);
      expect(engine.status, ExerciseStatus.finishing);
      expect(before.whereType<EndVoice>(), isEmpty);
      final last = _signals(before).last;
      expect(last.cutStartAt < _e && _e < last.cutEndAt, isTrue);

      final after = _run(engine, clock, until: _s(40));
      expect(after.whereType<EndVoice>().toList(), [EndVoice(last.cutEndAt)]);
      expect(engine.status, ExerciseStatus.finished);
      expect(_signals(after), isEmpty);
    });

    test('Escenario 9: E durante el aviso → corte completo y Guman en su cutEndAt', () {
      // Señal cada 1.7 s desde 4.0 s → señal 17 en 32.9 s, aviso hasta 33.6 s.
      final engine = _started(_script(first: 0));
      final events = _run(engine, clock, until: _s(40));
      final last = _signals(events).last;
      expect(last.signalAt < _e && _e < last.cutStartAt, isTrue);
      expect(events.whereType<CutStarted>().last.attack, last);
      final endVoices = events.whereType<EndVoice>().toList();
      expect(endVoices, [EndVoice(last.cutEndAt)]);
      expect(endVoices.single.at - _e, lessThanOrEqualTo(_ms(1200)));
    });

    test('Escenario 10 / G5: E en guardia → Guman en 33 s y ninguna señal posterior', () {
      // Señal cada 3.2 s desde 5.5 s → la última en 31.1 s, corte hasta 32.3 s;
      // la siguiente sería en 34.3 s ≥ E.
      final engine = _started(_script(first: 1500, interval: 1500));
      final events = _run(engine, clock, until: _s(40));
      expect(events.whereType<EndVoice>().toList(), [EndVoice(_e)]);
      expect(events.last, EndVoice(_e));
      expect(_signals(events).every((a) => a.signalAt < _e), isTrue);
      expect(_signals(events).last.cutEndAt < _e, isTrue);
    });

    test('Escenario 11: tras Guman, finished, sable blanco, remaining 0 y sin eventos', () {
      final engine = _started(_script(first: 1500, interval: 1500));
      _run(engine, clock, until: _s(40));
      final tick = engine.advanceTo(_s(41));
      expect(tick.snapshot.status, ExerciseStatus.finished);
      expect(tick.snapshot.saberColor, SaberColor.white);
      expect(tick.snapshot.remaining, Duration.zero);
      expect(tick.snapshot.signal, isNull);
      expect(tick.events, isEmpty);
      expect(engine.advanceTo(_s(100)).events, isEmpty);
    });
  });

  group('Determinismo y avance', () {
    test('G1: mismo guion y mismos avances → mismos snapshots y eventos', () {
      List<Object> trace() {
        final engine = _started(_script(first: 700, intervals: [3, 1200, 50]));
        final trace = <Object>[];
        for (var t = Duration.zero; t <= _s(40); t += _frame) {
          final tick = engine.advanceTo(t);
          trace
            ..add(tick.snapshot)
            ..addAll(tick.events);
        }
        return trace;
      }

      expect(trace(), trace());
    });

    test(
      'un solo advanceTo de 0 a 40 s da los mismos eventos que pasos de 16 ms',
      () {
        final single = _started(_script(first: 800)).advanceTo(_s(40)).events;
        final stepped = _run(
          _started(_script(first: 800)),
          clock,
          until: _s(40),
        );
        expect(single, stepped);
        expect(single.toSet(), hasLength(single.length));
        for (var i = 1; i < single.length; i++) {
          expect(single[i].at >= single[i - 1].at, isTrue);
        }
        expect(single.first, StartVoice(_s(3)));
        expect(single.last, isA<EndVoice>());
      },
    );

    test(
      'advanceTo con un tiempo menor que el anterior lanza ArgumentError',
      () {
        final engine = _started(_script(first: 0))..advanceTo(_s(5));
        expect(() => engine.advanceTo(_s(4)), throwsArgumentError);
      },
    );
  });
}
