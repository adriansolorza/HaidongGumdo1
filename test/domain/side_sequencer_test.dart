import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/side_sequencer.dart';

import 'fakes/scripted_random_source.dart';

void main() {
  test('sorteo 0 → right y 1 → left', () {
    final sequencer = SideSequencer(
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
      final sequencer = SideSequencer(maxRepeats: 5, random: random);
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
    final sequencer = SideSequencer(maxRepeats: 1, random: random);
    final sides = [for (var i = 0; i < 10; i++) sequencer.next()];
    expect(sides, [
      for (var i = 0; i < 10; i++) i.isEven ? Side.left : Side.right,
    ]);
    expect(random.consumed, 1);
  });

  test('una instancia nueva reinicia la racha', () {
    final random = ScriptedRandomSource(const [0, 0, 0, 0, 0, 0]);
    final first = SideSequencer(maxRepeats: 5, random: random);
    for (var i = 0; i < 5; i++) {
      first.next();
    }
    final second = SideSequencer(maxRepeats: 5, random: random);
    expect(second.lastSide, isNull);
    expect(second.streak, 0);
    expect(second.next(), Side.right);
    expect(random.consumed, 6);
  });
}
