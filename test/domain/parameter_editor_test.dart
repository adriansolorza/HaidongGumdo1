import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/settings/parameter_editor.dart';

Duration ms(int v) => Duration(milliseconds: v);

ExerciseParameters defaults() => ExerciseParameters.defaults();

void main() {
  group('rejilla y límites (Spec 005, FR-004, FR-004a)', () {
    test('valores permitidos de cada campo con los valores por defecto', () {
      final p = defaults();
      final duration = ParameterEditor.allowedValues(
        p,
        ParameterField.duration,
      );
      expect(duration, hasLength(11));
      expect(duration.first, 30000);
      expect(duration.last, 180000);

      expect(ParameterEditor.allowedValues(p, ParameterField.maxRepeats), [
        1,
        2,
        3,
        4,
        5,
      ]);

      final warning = ParameterEditor.allowedValues(
        p,
        ParameterField.warningTime,
      );
      expect(warning, hasLength(15));
      expect(warning.take(3), [330, 350, 400]);
      expect(warning.last, 1000);

      final cut = ParameterEditor.allowedValues(p, ParameterField.cutSpeed);
      expect(cut, hasLength(15));
      expect(cut.first, 300);
      expect(cut.last, 1000);

      final interval = ParameterEditor.allowedValues(
        p,
        ParameterField.attackInterval,
      );
      expect(interval, hasLength(41));
      expect(interval.first, 1000);
      expect(interval.last, 5000);
    });

    test('mínimo del intervalo: piso redondeado hacia arriba a 0.1 s', () {
      for (final (cut, expected) in [
        (300, 800),
        (350, 900),
        (500, 1000),
        (800, 1300),
        (1000, 1500),
      ]) {
        expect(ParameterEditor.intervalMinimum(ms(cut)), ms(expected));
      }
    });

    test('un toque avanza exactamente un paso', () {
      final p = defaults();
      expect(
        ParameterEditor.increment(
          p,
          ParameterField.duration,
        ).parameters.duration,
        const Duration(seconds: 45),
      );
      expect(
        ParameterEditor.decrement(
          p,
          ParameterField.warningTime,
        ).parameters.warningTime,
        ms(650),
      );
    });

    test('tiempo de aviso: de 0.35 s baja a 0.33 s y ahí se detiene', () {
      final at350 = defaults().copyWith(warningTime: ms(350));
      final at330 = ParameterEditor.decrement(
        at350,
        ParameterField.warningTime,
      ).parameters;
      expect(at330.warningTime, ms(330));
      expect(
        ParameterEditor.canDecrement(at330, ParameterField.warningTime),
        isFalse,
      );
      expect(
        ParameterEditor.decrement(at330, ParameterField.warningTime).parameters,
        at330,
      );
    });

    test('duración en 3 min: + desactivado y sin cambios', () {
      final p = defaults().copyWith(duration: const Duration(minutes: 3));
      expect(ParameterEditor.canIncrement(p, ParameterField.duration), isFalse);
      expect(ParameterEditor.canDecrement(p, ParameterField.duration), isTrue);
      expect(
        ParameterEditor.increment(p, ParameterField.duration).parameters,
        p,
      );
    });

    test('N: − desactivado en 1 y + desactivado en 5', () {
      final one = defaults().copyWith(maxRepeats: 1);
      expect(
        ParameterEditor.canDecrement(one, ParameterField.maxRepeats),
        isFalse,
      );
      expect(
        ParameterEditor.canIncrement(defaults(), ParameterField.maxRepeats),
        isFalse,
      );
    });

    test('un valor fuera de la rejilla vuelve a ella con el primer toque', () {
      final p = defaults().copyWith(warningTime: ms(370));
      expect(
        ParameterEditor.increment(
          p,
          ParameterField.warningTime,
        ).parameters.warningTime,
        ms(400),
      );
      expect(
        ParameterEditor.decrement(
          p,
          ParameterField.warningTime,
        ).parameters.warningTime,
        ms(350),
      );

      // Intervalo igual al piso pero fuera de la rejilla (válido para el motor).
      final onFloor = defaults().copyWith(
        cutSpeed: ms(350),
        attackInterval: ms(850),
      );
      expect(onFloor.validate(), isEmpty);
      expect(
        ParameterEditor.canDecrement(onFloor, ParameterField.attackInterval),
        isFalse,
      );
      expect(
        ParameterEditor.increment(
          onFloor,
          ParameterField.attackInterval,
        ).parameters.attackInterval,
        ms(900),
      );
    });
  });
}
