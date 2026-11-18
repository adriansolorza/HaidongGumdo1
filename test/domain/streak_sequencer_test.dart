import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/streak_sequencer.dart';

import 'fakes/scripted_random_source.dart';
import 'fakes/seeded_random_source.dart';

void main() {
  test('sorteo 0 → right y 1 → left', () {
    final sequencer = StreakSequencer<Side>(
      options: const [Side.right, Side.left],
      maxRepeats: 5,
      random: ScriptedRandomSource(const [0, 1]),
    );
    expect(sequencer.next(), Side.right);
    expect(sequencer.next(), Side.left);
  });

  test(
    'N = 5: tras 5 iguales el 6.º es el contrario sin consumir sorteo (CA4)',
    () {
      final random = ScriptedRandomSource(const [0, 0, 0, 0, 0, 0]);
      final sequencer = StreakSequencer<Side>(
        options: const [Side.right, Side.left],
        maxRepeats: 5,
        random: random,
      );
      for (var i = 0; i < 5; i++) {
        expect(sequencer.next(), Side.right);
      }
      expect(random.consumed, 5);
      expect(sequencer.next(), Side.left);
      expect(random.consumed, 5);
      // La racha se reinicia: el siguiente vuelve a sortear.
      expect(sequencer.next(), Side.right);
      expect(random.consumed, 6);
    },
  );

  test('N = 1: alterna siempre y solo sortea el primero', () {
    final random = ScriptedRandomSource(const [1]);
    final sequencer = StreakSequencer<Side>(
      options: const [Side.right, Side.left],
      maxRepeats: 1,
      random: random,
    );
    final sides = [for (var i = 0; i < 10; i++) sequencer.next()];
    expect(sides, [
      for (var i = 0; i < 10; i++) i.isEven ? Side.left : Side.right,
    ]);
    expect(random.consumed, 1);
  });

  test('una instancia nueva reinicia la racha', () {
    final random = ScriptedRandomSource(const [0, 0, 0, 0, 0, 0]);
    final first = StreakSequencer<Side>(
      options: const [Side.right, Side.left],
      maxRepeats: 5,
      random: random,
    );
    for (var i = 0; i < 5; i++) {
      first.next();
    }
    final second = StreakSequencer<Side>(
      options: const [Side.right, Side.left],
      maxRepeats: 5,
      random: random,
    );
    expect(second.last, isNull);
    expect(second.streak, 0);
    expect(second.next(), Side.right);
    expect(random.consumed, 6);
  });

  group('StreakSequencer genérico (Spec 006)', () {
    test('una sola opción: la devuelve siempre sin consumir sorteos (G2)', () {
      final random = ScriptedRandomSource(const []);
      final sequencer = StreakSequencer(
        options: const [ResponseType.evasion],
        maxRepeats: 5,
        random: random,
      );
      for (var i = 0; i < 100; i++) {
        expect(sequencer.next(), ResponseType.evasion);
      }
      expect(random.consumed, 0);
    });

    test('tipos con N = 2: el 3.º se fuerza sin consumir sorteo (FR-005)', () {
      final random = ScriptedRandomSource(const [0, 0, 1]);
      final sequencer = StreakSequencer(
        options: const [ResponseType.defense, ResponseType.evasion],
        maxRepeats: 2,
        random: random,
      );
      expect(sequencer.next(), ResponseType.defense);
      expect(sequencer.next(), ResponseType.defense);
      expect(random.consumed, 2);
      expect(sequencer.next(), ResponseType.evasion);
      expect(random.consumed, 2);
      expect(sequencer.next(), ResponseType.evasion);
      expect(random.consumed, 3);
    });

    test('ArgumentError con opciones vacías, duplicadas o N < 1', () {
      final random = ScriptedRandomSource(const []);
      expect(
        () => StreakSequencer<Side>(
          options: const [],
          maxRepeats: 5,
          random: random,
        ),
        throwsArgumentError,
      );
      expect(
        () => StreakSequencer(
          options: const [Side.right, Side.right],
          maxRepeats: 5,
          random: random,
        ),
        throwsArgumentError,
      );
      expect(
        () => StreakSequencer(
          options: const [Side.right, Side.left],
          maxRepeats: 0,
          random: random,
        ),
        throwsArgumentError,
      );
    });

    for (var n = 1; n <= 5; n++) {
      test('N = $n: 10 000 sorteos de tipo sin racha mayor que N (G3)', () {
        final sequencer = StreakSequencer(
          options: const [ResponseType.defense, ResponseType.evasion],
          maxRepeats: n,
          random: SeededRandomSource(n),
        );
        var longest = 0;
        for (var i = 0; i < 10000; i++) {
          sequencer.next();
          if (sequencer.streak > longest) longest = sequencer.streak;
        }
        expect(longest, lessThanOrEqualTo(n));
      });
    }
  });
}
