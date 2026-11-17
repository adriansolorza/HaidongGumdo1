import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/settings/settings_json_mapper.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';

Duration ms(int v) => Duration(milliseconds: v);

Map<String, Object?> validJson() => {
  'version': 1,
  'durationMs': 30000,
  'maxRepeats': 5,
  'warningTimeMs': 700,
  'cutSpeedMs': 500,
  'attackIntervalMs': 2500,
};

Map<String, Object?> withField(String key, Object? value) =>
    validJson()..[key] = value;

void main() {
  group('SettingsJsonMapper (Spec 005, contracts/settings.schema.json)', () {
    test('ida y vuelta con los valores por defecto', () {
      final p = ExerciseParameters.defaults();
      expect(SettingsJsonMapper.toJson(p), validJson());
      expect(SettingsJsonMapper.fromJson(SettingsJsonMapper.toJson(p)), p);
    });

    test('ida y vuelta con valores en los extremos', () {
      const p = ExerciseParameters(
        duration: Duration(seconds: 60),
        maxRepeats: 1,
        warningTime: Duration(milliseconds: 330),
        cutSpeed: Duration(seconds: 1),
        attackInterval: Duration(seconds: 5),
      );
      expect(SettingsJsonMapper.fromJson(SettingsJsonMapper.toJson(p)), p);
    });

    test('ignora campos desconocidos', () {
      expect(
        SettingsJsonMapper.fromJson(withField('foo', 1)),
        ExerciseParameters.defaults(),
      );
    });

    group('devuelve null (FR-012)', () {
      final cases = <String, Object?>{
        'no es un mapa': [1, 2, 3],
        'null': null,
        'versión 2': withField('version', 2),
        'sin versión': validJson()..remove('version'),
        'double en lugar de int': withField('cutSpeedMs', 500.0),
        'texto en lugar de int': withField('durationMs', '30000'),
        'duración fuera de rango': withField('durationMs', 29000),
        'aviso fuera de rango': withField('warningTimeMs', 1001),
        'viola la invariante': withField('cutSpeedMs', 800)
          ..['attackIntervalMs'] = 1000,
      };
      for (final field in [
        'durationMs',
        'maxRepeats',
        'warningTimeMs',
        'cutSpeedMs',
        'attackIntervalMs',
      ]) {
        cases['sin $field'] = validJson()..remove(field);
      }
      cases.forEach((name, json) {
        test(name, () => expect(SettingsJsonMapper.fromJson(json), isNull));
      });
    });
  });
}
