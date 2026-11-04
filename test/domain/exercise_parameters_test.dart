import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/exercise_engine.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';

import 'fakes/scripted_random_source.dart';

const _ms = Duration(milliseconds: 1);

/// Valores por defecto con un solo campo cambiado.
ExerciseParameters _with({
  Duration? duration,
  int? maxRepeats,
  Duration? warningTime,
  Duration? cutSpeed,
  Duration? attackInterval,
}) {
  final d = ExerciseParameters.defaults();
  return ExerciseParameters(
    duration: duration ?? d.duration,
    maxRepeats: maxRepeats ?? d.maxRepeats,
    warningTime: warningTime ?? d.warningTime,
    cutSpeed: cutSpeed ?? d.cutSpeed,
    attackInterval: attackInterval ?? d.attackInterval,
  );
}

void main() {
  group('defaults (FR-006)', () {
    test('son válidos y tienen 30 s / 5 / 700 ms / 500 ms / 2500 ms', () {
      final d = ExerciseParameters.defaults();
      expect(d.validate(), isEmpty);
      expect(d.duration, const Duration(seconds: 30));
      expect(d.maxRepeats, 5);
      expect(d.warningTime, const Duration(milliseconds: 700));
      expect(d.cutSpeed, const Duration(milliseconds: 500));
      expect(d.attackInterval, const Duration(milliseconds: 2500));
    });

    test('intervalFloor = 1000 ms', () {
      expect(
        ExerciseParameters.defaults().intervalFloor,
        const Duration(milliseconds: 1000),
      );
    });
  });

  group('límites inclusivos (FR-006)', () {
    // Cada caso: parámetros en el extremo, y 1 unidad fuera de él.
    final cases =
        <String, (ExerciseParameters, ExerciseParameters, ParameterViolation)>{
          'duración mínima': (
            _with(duration: ParameterLimits.minDuration),
            _with(duration: ParameterLimits.minDuration - _ms),
            ParameterViolation.durationOutOfRange,
          ),
          'duración máxima': (
            _with(duration: ParameterLimits.maxDuration),
            _with(duration: ParameterLimits.maxDuration + _ms),
            ParameterViolation.durationOutOfRange,
          ),
          'N mínimo': (
            _with(maxRepeats: ParameterLimits.minMaxRepeats),
            _with(maxRepeats: ParameterLimits.minMaxRepeats - 1),
            ParameterViolation.maxRepeatsOutOfRange,
          ),
          'N máximo': (
            _with(maxRepeats: ParameterLimits.maxMaxRepeats),
            _with(maxRepeats: ParameterLimits.maxMaxRepeats + 1),
            ParameterViolation.maxRepeatsOutOfRange,
          ),
          'aviso mínimo': (
            _with(warningTime: ParameterLimits.minWarningTime),
            _with(warningTime: ParameterLimits.minWarningTime - _ms),
            ParameterViolation.warningTimeOutOfRange,
          ),
          'aviso máximo': (
            _with(warningTime: ParameterLimits.maxWarningTime),
            _with(warningTime: ParameterLimits.maxWarningTime + _ms),
            ParameterViolation.warningTimeOutOfRange,
          ),
          'corte mínimo': (
            _with(cutSpeed: ParameterLimits.minCutSpeed),
            _with(cutSpeed: ParameterLimits.minCutSpeed - _ms),
            ParameterViolation.cutSpeedOutOfRange,
          ),
          // Con corte de 1000 ms el piso es 1500 ms: el intervalo por defecto basta.
          'corte máximo': (
            _with(cutSpeed: ParameterLimits.maxCutSpeed),
            _with(cutSpeed: ParameterLimits.maxCutSpeed + _ms),
            ParameterViolation.cutSpeedOutOfRange,
          ),
          // Intervalo de 500 ms: el piso exige un corte imposible, así que se
          // comprueba solo que no aparezca la violación de rango.
          'intervalo máximo': (
            _with(attackInterval: ParameterLimits.maxAttackInterval),
            _with(attackInterval: ParameterLimits.maxAttackInterval + _ms),
            ParameterViolation.attackIntervalOutOfRange,
          ),
        };

    cases.forEach((name, c) {
      final (atLimit, outside, violation) = c;
      test('$name es válido y 1 unidad fuera da $violation', () {
        expect(atLimit.validate(), isEmpty);
        expect(outside.validate(), contains(violation));
      });
    });

    test('intervalo mínimo está en rango y 1 ms menos no', () {
      expect(
        _with(attackInterval: ParameterLimits.minAttackInterval).validate(),
        isNot(contains(ParameterViolation.attackIntervalOutOfRange)),
      );
      expect(
        _with(attackInterval: ParameterLimits.minAttackInterval - _ms)
            .validate(),
        contains(ParameterViolation.attackIntervalOutOfRange),
      );
    });
  });

  group('piso del intervalo (FR-007)', () {
    test('corte 1 s + intervalo 1.2 s → intervalBelowFloor', () {
      final p = _with(
        cutSpeed: const Duration(seconds: 1),
        attackInterval: const Duration(milliseconds: 1200),
      );
      expect(p.validate(), [ParameterViolation.intervalBelowFloor]);
    });

    test('intervalo igual al piso es válido', () {
      final p = _with(
        cutSpeed: const Duration(milliseconds: 800),
        attackInterval: const Duration(milliseconds: 1300),
      );
      expect(p.attackInterval, p.intervalFloor);
      expect(p.validate(), isEmpty);
    });

    test('1 ms bajo el piso → intervalBelowFloor', () {
      final p = _with(
        cutSpeed: const Duration(milliseconds: 800),
        attackInterval: const Duration(milliseconds: 1299),
      );
      expect(p.validate(), [ParameterViolation.intervalBelowFloor]);
    });
  });

  group('create y motor (FR-007)', () {
    test(
      'create lanza InvalidParametersException con todas las violaciones',
      () {
        expect(
          () => ExerciseParameters.create(
            duration: const Duration(seconds: 10),
            maxRepeats: 0,
            warningTime: const Duration(milliseconds: 700),
            cutSpeed: const Duration(milliseconds: 500),
            attackInterval: const Duration(milliseconds: 900),
          ),
          throwsA(
            isA<InvalidParametersException>().having(
              (e) => e.violations,
              'violations',
              unorderedEquals([
                ParameterViolation.durationOutOfRange,
                ParameterViolation.maxRepeatsOutOfRange,
                ParameterViolation.intervalBelowFloor,
              ]),
            ),
          ),
        );
      },
    );

    test('create con valores válidos devuelve los parámetros', () {
      final p = ExerciseParameters.create(
        duration: const Duration(seconds: 30),
        maxRepeats: 5,
        warningTime: const Duration(milliseconds: 700),
        cutSpeed: const Duration(milliseconds: 500),
        attackInterval: const Duration(milliseconds: 2500),
      );
      expect(p, ExerciseParameters.defaults());
    });

    test('ExerciseEngine con parámetros inválidos lanza', () {
      final session = Session(
        level: Level(
          id: 'level_1',
          order: 1,
          name: 'L',
          responseLabel: 'R',
          purpose: 'P',
          responseTypes: const [ResponseType.defense],
        ),
        pattern: const Pattern(
          id: 'p',
          order: 1,
          name: 'P',
          guardTermId: 'g',
          stanceTermId: 's',
          cutTermId: 'c',
          guard: SaberPose(hilt: Point2(0, 0.05), tip: Point2(0, -0.3)),
          cut: CutMotion(
            start: SaberPose(hilt: Point2(0, -0.9), tip: Point2(0, -1.6)),
            end: SaberPose(hilt: Point2(0, -0.2), tip: Point2(0, -0.35)),
            mirroredBySide: false,
          ),
        ),
      );
      expect(
        () => ExerciseEngine(
          session: session,
          parameters: _with(attackInterval: const Duration(milliseconds: 900)),
          random: ScriptedRandomSource(const []),
        ),
        throwsA(isA<InvalidParametersException>()),
      );
    });
  });
}
