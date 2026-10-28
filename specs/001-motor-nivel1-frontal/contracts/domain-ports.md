# Contrato: puertos del dominio y API del motor

**Capa**: `lib/domain/` (Dart puro). Las firmas son el contrato; el cuerpo es de la implementación. Las implementaciones de los puertos viven en `lib/data/` y se inyectan con providers de Riverpod.

## Puertos (interfaces definidas en el dominio)

```dart
/// Fuente de catálogo. Implementación en data: AssetCatalogRepository (rootBundle).
abstract interface class CatalogRepository {
  /// Lanza CatalogException si el JSON no cumple contracts/catalog.schema.json
  /// o si una referencia a un término del glosario no existe.
  Future<Catalog> load();
}

/// Aleatoriedad inyectable (Principio VI). Data: DartRandomSource(dart:math).
abstract interface class RandomSource {
  /// Entero uniforme en [0, maxExclusive). maxExclusive >= 1.
  int nextInt(int maxExclusive);
}

/// Reloj inyectable (Principio VI). Data: StopwatchClock. Pruebas: ManualClock.
abstract interface class ElapsedClock {
  void start();      // pone el tiempo transcurrido en cero y empieza a contar
  Duration get elapsed;
}

/// Voces de mando (FR-029, FR-030). Data: FlutterTtsVoiceAnnouncer.
abstract interface class VoiceAnnouncer {
  /// Elige voz coreana o la predeterminada. Idempotente. Nunca lanza excepciones.
  Future<void> prepare(Catalog catalog);
  /// Sin espera: no bloquea el motor. No hace nada si no hay motor de voz.
  void announce(VoiceCommand command);
  /// Corta cualquier frase en curso (FR-023).
  Future<void> stop();
}

/// Pantalla encendida (FR-028). Data: WakelockPlusScreenWakeLock.
abstract interface class ScreenWakeLock {
  Future<void> enable();
  Future<void> disable();
}
```

## API del motor

```dart
final class ExerciseEngine {
  /// Lanza InvalidParametersException si parameters.validate() no está vacío.
  ExerciseEngine({
    required Session session,
    required ExerciseParameters parameters,
    required RandomSource random,
  });

  ExerciseStatus get status;

  /// ready → countdown. Fija t = 0. StateError si el estado no es ready.
  void start();

  /// Avanza el estado hasta [elapsed], medido desde start(). Debe ser monótono:
  /// un valor menor que el anterior lanza ArgumentError. Devuelve el snapshot
  /// en [elapsed] y los eventos ocurridos en (anterior, elapsed], en orden.
  /// En estados terminales devuelve el snapshot final y ningún evento.
  ExerciseTick advanceTo(Duration elapsed);

  /// countdown | running | finishing → cancelled. Emite `cancelled`.
  /// StateError en ready; no hace nada en finished o cancelled.
  ExerciseTick cancel();
}

final class ExerciseTick {
  final ExerciseSnapshot snapshot;
  final List<ExerciseEvent> events;
}
```

### Garantías verificables con pruebas

| # | Garantía | Requisito |
|---|---|---|
| G1 | Con `ManualClock` y `ScriptedRandomSource`, la misma entrada produce la misma secuencia de snapshots y eventos | FR-019 |
| G2 | `startVoice` ocurre exactamente en t = 3 s, antes de cualquier `signalShown` | FR-009, CA6 |
| G3 | Para todo ataque: `cutStartAt − signalAt = warningTime` y `cutEndAt − cutStartAt = cutSpeed` | FR-010 |
| G4 | Para ataques consecutivos: `next.signalAt − prev.cutStartAt` ∈ [`intervalFloor`, `attackInterval`] | FR-011 |
| G5 | Ningún `signalShown` con `signalAt ≥ E` | FR-013 |
| G6 | `endVoice` ocurre en `max(E, cutEndAt del último ataque con signalAt < E)`, y una sola vez | FR-013, CA5, Q1 |
| G7 | Nunca hay más de N `side` iguales seguidos | FR-018, CA4 |
| G8 | Para `defense`: `signal.screenSide == attack.side.opposite` | FR-015, CA2 |
| G9 | Después de `cancelled` no se emite ningún evento | FR-023 |
| G10 | Las transiciones de estado fuera de la tabla de [data-model.md](../data-model.md) lanzan `StateError` | FR-020 |
