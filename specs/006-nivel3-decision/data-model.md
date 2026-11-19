# Data Model: Nivel 3, decisión bajo presión

**Feature**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

## 1. `Level` (dominio; existe desde la Spec 001)

Sin cambios de campos ni de validación. El Nivel 3 es solo un dato más (R4).

| Campo | Nivel 1 | Nivel 2 | **Nivel 3 (nuevo)** |
|---|---|---|---|
| `id` | `level_1` | `level_2` | `level_3` |
| `order` | 1 | 2 | 3 |
| `name` | Nivel 1 | Nivel 2 | Nivel 3 |
| `responseLabel` | Defensa | Evasión lateral | Defensa o evasión lateral |
| `purpose` | Calentamiento | Calentamiento / base | Decisión bajo presión |
| `responseTypes` | `[defense]` | `[evasion]` | `[defense, evasion]` |

**Reglas** (las aplica el mapper actual): `responseTypes` no puede estar vacía, sus tipos deben ser conocidos y no puede tener duplicados. El orden de la lista es significativo: fija el resultado de cada sorteo (índice 0 → primer tipo) y el orden de los glifos del ícono.

## 2. `StreakSequencer<T>` (dominio; reemplaza a `SideSequencer`)

`lib/domain/exercise/streak_sequencer.dart`. Una instancia por ejercicio y por magnitud sorteada.

| Miembro | Tipo | Significado |
|---|---|---|
| `options` | `List<T>` (inmutable) | Opciones en orden; no vacía, sin duplicados |
| `maxRepeats` | `int` | N (≥ 1), el mismo de `ExerciseParameters.maxRepeats` |
| `last` | `T?` | Última opción devuelta; `null` antes del primer `next()` (antes `lastSide`) |
| `streak` | `int` | Repeticiones seguidas de `last`; 0 al inicio |
| `next()` | `T` | Sorteo con racha máxima ([contrato §1](./contracts/domain-sequencer.md#1-streaksequencert)) |

**Estado y transiciones**: `(last, streak)` empieza en `(null, 0)`. En cada `next()` pasa a `(x, streak + 1)` si `x == last`, o a `(x, 1)` si no.

**Invariante**: si `options.length ≥ 2`, entonces `streak ≤ maxRepeats` siempre. Si `options.length == 1`, la racha no tiene límite y nunca se consume un sorteo.

## 3. `ExerciseEngine` (dominio; existe desde la Spec 001)

| Campo | Antes | Después |
|---|---|---|
| `_sides` | `SideSequencer(maxRepeats, random)` | `StreakSequencer<Side>(options: [right, left], maxRepeats, random)` |
| `_responseTypes` | — (se usaba `level.responseTypes.first`) | `StreakSequencer<ResponseType>(options: session.level.responseTypes, maxRepeats, random)` |

**Orden de consumo por ataque** (R3): lado → tipo → intervalo. En los Niveles 1 y 2, el tipo no consume ningún sorteo.

## 4. `Attack`, `Signal`, `SignalPlacement`, `ExerciseParameters`, `Session`

Sin cambios. `Attack.responseType` deja de ser siempre el primer tipo del nivel y pasa a venir del sorteo. El campo y su tipo no cambian.

## 5. Presentación

| Elemento | Cambio |
|---|---|
| `LevelIcon` | `type: ResponseType` → `types: List<ResponseType>`. Dibuja `n` glifos lado a lado (R6) |
| `SelectionDensity` (nuevo, presentación pura) | `regular` o `compact`, más `choose(...)` y las medidas de cada densidad (R7, [contrato §3](./contracts/selection-ui.md#3-densidad-de-la-selección)) |
| `_CardColumn` | `ListView` → `Column` sin desplazamiento. Si ni la densidad compacta cabe, se usa el desplazamiento como red de seguridad |
| `SelectionCard` | Recibe la densidad y aplica sus medidas. En `regular` queda igual que hoy |
