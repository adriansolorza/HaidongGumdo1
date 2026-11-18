import 'dart:math';

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

  group('invariante y ajuste automático (FR-007, FR-008, SC-003, SC-004)', () {
    ExerciseParameters at({required int cut, required int interval}) =>
        defaults().copyWith(cutSpeed: ms(cut), attackInterval: ms(interval));

    test('US2-1: corte de 0.5 a 0.8 s sube el intervalo de 1.0 a 1.3 s', () {
      var p = at(cut: 500, interval: 1000);
      final adjustments = <Duration?>[];
      for (var i = 0; i < 6; i++) {
        final r = ParameterEditor.increment(p, ParameterField.cutSpeed);
        adjustments.add(r.adjustedInterval);
        p = r.parameters;
      }
      expect(p.cutSpeed, ms(800));
      expect(p.attackInterval, ms(1300));
      // El mínimo se redondea hacia arriba a 0.1 s: con 0.75 s el piso es
      // 1.25 s y el mínimo ya es 1.3 s, así que el sexto toque no ajusta.
      expect(adjustments, [ms(1100), null, ms(1200), null, ms(1300), null]);
    });

    test('US2-2: con corte 0.5 s el intervalo no baja de 1.0 s', () {
      expect(
        ParameterEditor.canDecrement(
          at(cut: 500, interval: 1000),
          ParameterField.attackInterval,
        ),
        isFalse,
      );
    });

    test('US2-3: con corte 0.35 s el mínimo del intervalo es 0.9 s', () {
      var p = at(cut: 350, interval: 2500);
      while (ParameterEditor.canDecrement(p, ParameterField.attackInterval)) {
        p = ParameterEditor.decrement(
          p,
          ParameterField.attackInterval,
        ).parameters;
      }
      expect(p.attackInterval, ms(900));
    });

    test('US2-4: bajar el corte nunca cambia el intervalo', () {
      var p = at(cut: 800, interval: 1300);
      while (p.cutSpeed > ms(500)) {
        final r = ParameterEditor.decrement(p, ParameterField.cutSpeed);
        expect(r.adjustedInterval, isNull);
        expect(r.parameters.attackInterval, ms(1300));
        p = r.parameters;
      }
    });

    test('US2-5: con intervalo 2.5 s, subir el corte a 1 s no ajusta', () {
      var p = at(cut: 500, interval: 2500);
      while (ParameterEditor.canIncrement(p, ParameterField.cutSpeed)) {
        final r = ParameterEditor.increment(p, ParameterField.cutSpeed);
        expect(r.adjustedInterval, isNull);
        p = r.parameters;
      }
      expect(p.cutSpeed, ms(1000));
      expect(p.attackInterval, ms(2500));
    });

    test('exhaustivo: todo toque desde todo corte e intervalo es válido y '
        'solo subir el corte bajo el piso ajusta (SC-003, SC-004)', () {
      var checked = 0;
      for (final cut in ParameterEditor.allowedValues(
        defaults(),
        ParameterField.cutSpeed,
      )) {
        final base = defaults().copyWith(cutSpeed: ms(cut));
        for (final interval in ParameterEditor.allowedValues(
          base,
          ParameterField.attackInterval,
        )) {
          final p = base.copyWith(attackInterval: ms(interval));
          expect(p.validate(), isEmpty);
          for (final field in ParameterField.values) {
            for (final isIncrement in [true, false]) {
              final r = isIncrement
                  ? ParameterEditor.increment(p, field)
                  : ParameterEditor.decrement(p, field);
              final label = '$field ${isIncrement ? '+' : '−'} desde $p';
              expect(r.parameters.validate(), isEmpty, reason: label);
              final shouldAdjust =
                  field == ParameterField.cutSpeed &&
                  isIncrement &&
                  p.attackInterval <
                      ParameterEditor.intervalMinimum(r.parameters.cutSpeed);
              expect(r.adjustedInterval != null, shouldAdjust, reason: label);
              if (shouldAdjust) {
                expect(r.adjustedInterval, r.parameters.attackInterval);
              }
              checked++;
            }
          }
        }
      }
      expect(checked, greaterThan(0));
    });

    test('recorrido aleatorio: 10 000 toques desde los defaults, siempre '
        'válidos', () {
      final random = Random(5);
      var p = defaults();
      for (var i = 0; i < 10000; i++) {
        final field =
            ParameterField.values[random.nextInt(ParameterField.values.length)];
        p = random.nextBool()
            ? ParameterEditor.increment(p, field).parameters
            : ParameterEditor.decrement(p, field).parameters;
        expect(p.validate(), isEmpty, reason: 'toque $i: $p');
      }
    });
  });
}
