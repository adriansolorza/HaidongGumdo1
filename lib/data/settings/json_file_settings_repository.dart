import 'dart:convert';
import 'dart:io';

import '../../domain/exercise/exercise_parameters.dart';
import '../../domain/ports/settings_repository.dart';
import 'settings_json_mapper.dart';

/// Configuración en un archivo JSON local (Spec 005, FR-010 a FR-013;
/// research R4). La carpeta la da [directory]: en producción,
/// `getApplicationDocumentsDirectory` de `path_provider` (ADR 0006); en
/// pruebas, una carpeta temporal.
final class JsonFileSettingsRepository implements SettingsRepository {
  JsonFileSettingsRepository({required this.directory});

  static const fileName = 'settings.json';
  static const tempFileName = 'settings.json.tmp';

  /// Carpeta donde vive el archivo.
  final Future<Directory> Function() directory;

  @override
  Future<ExerciseParameters?> load() async {
    try {
      final dir = await directory();
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      if (!await file.exists()) return null;
      return SettingsJsonMapper.fromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      return null;
    }
  }

  /// Escribe un archivo temporal y lo renombra, para que un cierre a mitad
  /// de la escritura no deje un JSON truncado. Si falla, el archivo anterior
  /// queda intacto.
  @override
  Future<void> save(ExerciseParameters parameters) async {
    File? temp;
    try {
      final dir = await directory();
      final sep = Platform.pathSeparator;
      temp = File('${dir.path}$sep$tempFileName');
      await temp.writeAsString(
        jsonEncode(SettingsJsonMapper.toJson(parameters)),
        flush: true,
      );
      await temp.rename('${dir.path}$sep$fileName');
    } catch (e) {
      if (temp != null) {
        try {
          if (await temp.exists()) await temp.delete();
        } catch (_) {}
      }
      throw SettingsSaveException(e);
    }
  }
}
