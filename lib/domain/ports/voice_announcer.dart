import '../catalog/catalog.dart';
import '../catalog/enums.dart';

/// Voces de mando (FR-029, FR-030). Data: FlutterTtsVoiceAnnouncer.
abstract interface class VoiceAnnouncer {
  /// Elige voz coreana o la predeterminada. Idempotente. Nunca lanza excepciones.
  Future<void> prepare(Catalog catalog);

  /// Sin espera: no bloquea el motor. No hace nada si no hay motor de voz.
  void announce(VoiceCommand command);

  /// Corta cualquier frase en curso (FR-023).
  Future<void> stop();
}
