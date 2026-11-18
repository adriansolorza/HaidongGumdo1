import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/presentation/settings/parameter_format.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  group('formatSeconds (Spec 005, FR-006)', () {
    test('entre uno y dos decimales, con punto', () {
      expect(formatSeconds(ms(330)), '0.33 s');
      expect(formatSeconds(ms(350)), '0.35 s');
      expect(formatSeconds(ms(700)), '0.7 s');
      expect(formatSeconds(ms(1000)), '1.0 s');
      expect(formatSeconds(ms(2500)), '2.5 s');
      expect(formatSeconds(ms(850)), '0.85 s');
      expect(formatSeconds(ms(5000)), '5.0 s');
    });
  });

  group('formatDuration (Spec 005, FR-006)', () {
    test('segundos por debajo de 1 min; minutos y segundos desde 1 min', () {
      expect(formatDuration(const Duration(seconds: 30)), '30 s');
      expect(formatDuration(const Duration(seconds: 45)), '45 s');
      expect(formatDuration(const Duration(seconds: 60)), '1 min');
      expect(formatDuration(const Duration(seconds: 75)), '1 min 15 s');
      expect(formatDuration(const Duration(seconds: 135)), '2 min 15 s');
      expect(formatDuration(const Duration(seconds: 180)), '3 min');
    });
  });

  group('formatIntervalRange (Spec 005, FR-005)', () {
    test('valores por defecto: entre el piso y el tope, al azar', () {
      expect(
        formatIntervalRange(ExerciseParameters.defaults()),
        'Cada ataque: entre 1.0 s y 2.5 s, al azar',
      );
    });

    test('piso igual al tope: un solo valor', () {
      final p = ExerciseParameters.defaults().copyWith(
        cutSpeed: ms(800),
        attackInterval: ms(1300),
      );
      expect(formatIntervalRange(p), 'Cada ataque: 1.3 s');
    });

    test('usa el piso real, no el mínimo redondeado', () {
      final p = ExerciseParameters.defaults().copyWith(
        cutSpeed: ms(350),
        attackInterval: ms(900),
      );
      expect(
        formatIntervalRange(p),
        'Cada ataque: entre 0.85 s y 0.9 s, al azar',
      );
    });
  });

  test('formatAdjustment (Spec 005, FR-008)', () {
    expect(
      formatAdjustment(ms(1300)),
      'Intervalo ajustado a 1.3 s: debe ser al menos la velocidad del corte '
      '+ 0.5 s',
    );
  });
}
