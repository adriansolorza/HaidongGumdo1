# Contrato: sorteo con racha máxima y orden de sorteos del motor

**Feature**: [../spec.md](../spec.md) · **Research**: R2, R3

## 1. `StreakSequencer<T>`

```dart
final class StreakSequencer<T> {
  StreakSequencer({
    required List<T> options,   // no vacía, sin duplicados; orden significativo
    required int maxRepeats,    // >= 1
    required RandomSource random,
  });                           // ArgumentError si se violan las precondiciones

  List<T> get options;
  int get maxRepeats;
  T? get last;
  int get streak;

  T next();
}
```

**`next()`**

1. Si `options.length == 1`, devuelve `options[0]` **sin llamar a `random`**.
2. `candidates = streak == maxRepeats ? options.where((o) => o != last) : options`, conservando el orden de `options`.
3. Si `candidates.length == 1`, el resultado es `candidates[0]` **sin llamar a `random`**. Si hay varios, es `candidates[random.nextInt(candidates.length)]`.
4. `streak = result == last ? streak + 1 : 1`; `last = result`.

**Garantías**

| # | Garantía | Prueba |
|---|---|---|
| G1 | Con `options: [Side.right, Side.left]`, consume y devuelve exactamente lo mismo que el `SideSequencer` anterior para cualquier guion de sorteos | Las 4 pruebas de `side_sequencer_test.dart`, renombradas y sin cambiar sus expectativas |
| G2 | Con una opción, nunca consume sorteos | Prueba nueva: `ScriptedRandomSource([])` y 100 llamadas |
| G3 | Con ≥ 2 opciones, `streak ≤ maxRepeats` | Simulación con `SeededRandomSource`, N de 1 a 5 |
| G4 | Una instancia nueva empieza en `(null, 0)` | Prueba existente, renombrada |

## 2. Orden de los sorteos en `ExerciseEngine`

Por cada señal (`_onSignal`):

```text
side         = _sides.next()           // consume 0 o 1 sorteo
responseType = _responseTypes.next()   // consume 0 sorteos si el nivel tiene un solo tipo
interval     = _drawInterval()         // consume 1 sorteo
```

Antes de la primera señal, `_onStartVoice` consume 1 sorteo de intervalo, igual que hoy.

**Garantías**

| # | Garantía | Prueba |
|---|---|---|
| E1 | Niveles 1 y 2: los ataques (lado, tipo e instantes) son idénticos a los de antes del cambio con la misma semilla | `exercise_engine_sequence_regression_test.dart`, con valores grabados antes del refactor |
| E2 | Niveles 1 y 2: `consumed == 1 + Σ(sorteos de lado + 1)` | Prueba con `ScriptedRandomSource` |
| E3 | Nivel 3: nunca más de N ataques seguidos con el mismo lado ni con el mismo tipo | 1 000 ejercicios simulados por cada N de 1 a 5 (SC-004) |
| E4 | Nivel 3 con N = 5: 45–55 % de defensas y de lados derechos | Simulación (SC-005) |
| E5 | Nivel 3: con el guion `[i, ladoA, tipoA, iA, …]`, los ataques salen en ese orden | Prueba con `ScriptedRandomSource` |
