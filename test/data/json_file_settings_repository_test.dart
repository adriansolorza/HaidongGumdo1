import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/settings/json_file_settings_repository.dart';
import 'package:haidonggumdo/domain/exercise/exercise_parameters.dart';
import 'package:haidonggumdo/domain/ports/settings_repository.dart';

const _custom = ExerciseParameters(
  duration: Duration(seconds: 75),
  maxRepeats: 1,
  warningTime: Duration(milliseconds: 330),
  cutSpeed: Duration(milliseconds: 500),
  attackInterval: Duration(milliseconds: 2500),
);

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('settings_test_');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  JsonFileSettingsRepository repoIn(Directory d) =>
      JsonFileSettingsRepository(directory: () async => d);

  File settingsFile(Directory d) =>
      File('${d.path}${Platform.pathSeparator}settings.json');

  group('JsonFileSettingsRepository (Spec 005, FR-010 a FR-013)', () {
    test('sin archivo: load devuelve null', () async {
      expect(await repoIn(dir).load(), isNull);
    });

    test(
      'save y load en una instancia nueva: mismos valores (SC-002)',
      () async {
        await repoIn(dir).save(_custom);
        expect(await repoIn(dir).load(), _custom);
      },
    );

    test('guardar dos veces reemplaza el archivo', () async {
      await repoIn(dir).save(ExerciseParameters.defaults());
      await repoIn(dir).save(_custom);
      expect(await repoIn(dir).load(), _custom);
    });

    test('después de guardar solo queda settings.json, sin .tmp', () async {
      await repoIn(dir).save(_custom);
      final names = dir.listSync().map((e) => e.uri.pathSegments.last).toList();
      expect(names, ['settings.json']);
    });

    for (final (name, content) in [
      ('basura', 'basura'),
      ('objeto vacío', '{}'),
      (
        'fuera de rango',
        '{"version":1,"durationMs":1,"maxRepeats":5,"warningTimeMs":700,'
            '"cutSpeedMs":500,"attackIntervalMs":2500}',
      ),
    ]) {
      test(
        'archivo $name: null y el archivo sigue igual (FR-012, SC-007)',
        () async {
          final file = settingsFile(dir);
          await file.writeAsString(content);
          expect(await repoIn(dir).load(), isNull);
          expect(await file.readAsString(), content);

          await repoIn(dir).save(_custom);
          expect(await repoIn(dir).load(), _custom);
        },
      );
    }

    test(
      'si la carpeta no se puede obtener: save lanza y load es null',
      () async {
        final repo = JsonFileSettingsRepository(
          directory: () async => throw const FileSystemException('sin carpeta'),
        );
        await expectLater(
          repo.save(_custom),
          throwsA(isA<SettingsSaveException>()),
        );
        expect(await repo.load(), isNull);
      },
    );

    test(
      'carpeta borrada: save lanza y otra configuración queda intacta',
      () async {
        final other = await Directory.systemTemp.createTemp('settings_other_');
        addTearDown(() => other.delete(recursive: true));
        await repoIn(other).save(_custom);

        final gone = await Directory.systemTemp.createTemp('settings_gone_');
        await gone.delete();
        await expectLater(
          repoIn(gone).save(ExerciseParameters.defaults()),
          throwsA(isA<SettingsSaveException>()),
        );
        expect(await repoIn(other).load(), _custom);
      },
    );
  });
}
