import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_event.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';

import 'fakes/seeded_random_source.dart';
import 'fakes/test_session.dart';

/// Regresión de secuencias de los Niveles 1 y 2 (Spec 006, research R8;
/// contrato E1).
///
/// Grabado con el motor anterior a la Spec 006. NO regenerar después del
/// refactor: si falla, el refactor cambió las secuencias de los Niveles 1 y 2.
///
/// Para grabar (solo con el motor anterior):
/// `$env:UPDATE_SEQUENCE_REGRESSION='1'; flutter test <este archivo>`.

const _fixturePath = 'test/domain/fixtures/sequence_regression.json';
const _updateVariable = 'UPDATE_SEQUENCE_REGRESSION';
const _frame = Duration(milliseconds: 16);
const _seeds = [1, 42, 2026];
const _maxRepeats = [1, 5];

/// Ejercicio de 180 s con [maxRepeats] y [seed], avanzado en pasos de 16 ms
/// hasta un estado terminal. Una línea por ataque y una línea final con
/// *Guman*.
List<String> _record(Session session, int seed, int maxRepeats) {
  final engine = ExerciseEngine(
    session: session,
    parameters: ExerciseParameters.create(
      duration: const Duration(seconds: 180),
      maxRepeats: maxRepeats,
      warningTime: const Duration(milliseconds: 700),
      cutSpeed: const Duration(milliseconds: 500),
      attackInterval: const Duration(milliseconds: 2500),
    ),
    random: SeededRandomSource(seed),
  )..start();
  final lines = <String>[];
  EndVoice? endVoice;
  for (var t = Duration.zero; !engine.status.isTerminal; t += _frame) {
    for (final event in engine.advanceTo(t).events) {
      if (event is SignalShown) {
        final a = event.attack;
        lines.add(
          '${a.index},${a.side.name},${a.responseType.name},'
          '${a.signalAt.inMilliseconds},${a.cutStartAt.inMilliseconds},'
          '${a.cutEndAt.inMilliseconds},${a.nextSignalAt.inMilliseconds}',
        );
      }
      if (event is EndVoice) endVoice = event;
    }
  }
  lines.add('end,${endVoice!.at.inMilliseconds}');
  return lines;
}

Map<String, List<String>> _recordAll() {
  final sessions = [
    testSession(),
    testTransversalSession(),
    testLevel2Session(),
    testLevel2TransversalSession(),
  ];
  return {
    for (final session in sessions)
      for (final seed in _seeds)
        for (final n in _maxRepeats)
          '${session.level.id}/${session.pattern.id}/seed$seed/n$n': _record(
            session,
            seed,
            n,
          ),
  };
}

void main() {
  final actual = _recordAll();

  if (Platform.environment[_updateVariable] == '1') {
    test('graba el fixture de secuencias', () {
      final file = File(_fixturePath)..createSync(recursive: true);
      file.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(actual)}\n',
      );
    });
    return;
  }

  final file = File(_fixturePath);
  if (!file.existsSync()) {
    test('el fixture existe', () {
      fail(
        'Falta $_fixturePath. Grábalo con el motor anterior a la Spec 006: '
        "\$env:$_updateVariable='1'; flutter test "
        'test/domain/exercise_engine_sequence_regression_test.dart',
      );
    });
    return;
  }

  final expected = (jsonDecode(file.readAsStringSync()) as Map<String, Object?>)
      .map((key, value) => MapEntry(key, (value! as List).cast<String>()));

  test('el fixture tiene los 24 casos', () {
    expect(expected.keys.toSet(), actual.keys.toSet());
    expect(expected, hasLength(24));
  });

  for (final key in actual.keys) {
    test('Niveles 1 y 2 sin cambios: $key', () {
      expect(actual[key], expected[key]);
    });
  }
}
