import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';

import 'fakes/seeded_random_source.dart';
import 'fakes/test_session.dart';

const _frame = Duration(milliseconds: 16);
const _exercises = 1000;

/// Resultado de un ejercicio simulado de principio a fin.
final class _Run {
  _Run(this.attacks, this.endVoice, this.nominalEnd);

  final List<Attack> attacks;
  final EndVoice endVoice;
  final Duration nominalEnd;

  List<Side> get sides => [for (final a in attacks) a.side];
}

/// Ejercicio de 180 s con valores por defecto y [maxRepeats], avanzado en
/// pasos de 16 ms hasta `finished`.
_Run _simulate(int seed, {int maxRepeats = 5}) {
  final d = ExerciseParameters.defaults();
  final engine = ExerciseEngine(
    session: testSession(),
    parameters: ExerciseParameters.create(
      duration: const Duration(seconds: 180),
      maxRepeats: maxRepeats,
      warningTime: d.warningTime,
      cutSpeed: d.cutSpeed,
      attackInterval: d.attackInterval,
    ),
    random: SeededRandomSource(seed),
  )..start();
  final attacks = <Attack>[];
  EndVoice? endVoice;
  for (var t = Duration.zero; !engine.status.isTerminal; t += _frame) {
    for (final event in engine.advanceTo(t).events) {
      if (event is SignalShown) attacks.add(event.attack);
      if (event is EndVoice) endVoice = event;
    }
  }
  return _Run(attacks, endVoice!, engine.nominalEnd);
}

int _longestStreak(List<Side> sides) {
  var longest = 0;
  var current = 0;
  for (var i = 0; i < sides.length; i++) {
    current = i > 0 && sides[i] == sides[i - 1] ? current + 1 : 1;
    if (current > longest) longest = current;
  }
  return longest;
}

void main() {
  // Una sola tanda de 1 000 ejercicios con N = 5 sirve para SC-003 a SC-006.
  late List<_Run> runs;

  setUpAll(() {
    runs = [for (var seed = 0; seed < _exercises; seed++) _simulate(seed)];
  });

  test(
    'SC-003: con N = 5, ningún ejercicio tiene más de 5 lados iguales seguidos',
    () {
      for (final run in runs) {
        expect(_longestStreak(run.sides), lessThanOrEqualTo(5));
      }
    },
  );

  test('SC-003: con N = 1, el 100 % alterna', () {
    for (var seed = 0; seed < _exercises; seed++) {
      final sides = _simulate(seed, maxRepeats: 1).sides;
      expect(_longestStreak(sides), 1, reason: 'semilla $seed');
    }
  });

  test('SC-004: proporción de right en 50 % ± 5 % sobre ≥ 10 000 ataques', () {
    final sides = [for (final run in runs) ...run.sides];
    expect(sides.length, greaterThanOrEqualTo(10000));
    final right = sides.where((s) => s == Side.right).length / sides.length;
    expect(right, inInclusiveRange(0.45, 0.55));
  });

  test(
    'SC-004: ningún par de ejercicios repite la secuencia completa de lados',
    () {
      final sequences = {
        for (final run in runs) run.sides.map((s) => s.index).join(),
      };
      expect(sequences, hasLength(_exercises));
    },
  );

  test('SC-005: el 100 % de los intervalos está en [1000 ms, 2500 ms]', () {
    for (final run in runs) {
      for (var i = 1; i < run.attacks.length; i++) {
        final interval =
            run.attacks[i].signalAt - run.attacks[i - 1].cutStartAt;
        expect(interval.inMilliseconds, inInclusiveRange(1000, 2500));
      }
    }
  });

  test('SC-006: Guman nunca antes de E y como máximo 1200 ms después', () {
    for (final run in runs) {
      final delay = run.endVoice.at - run.nominalEnd;
      expect(delay.isNegative, isFalse);
      expect(delay.inMilliseconds, lessThanOrEqualTo(1200));
    }
  });
}
