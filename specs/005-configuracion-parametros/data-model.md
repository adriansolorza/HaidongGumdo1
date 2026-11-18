# Data Model: Configuración de parámetros e invariante de tiempos

**Feature**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

Todas las duraciones del dominio son `Duration`, y la rejilla se calcula en milisegundos enteros (R2).

## 1. `ExerciseParameters` (dominio; existe desde la Spec 001)

Sin cambios en campos, rangos, `validate()`, `defaults()` ni `intervalFloor`. Solo gana:

```dart
ExerciseParameters copyWith({Duration? duration, int? maxRepeats,
    Duration? warningTime, Duration? cutSpeed, Duration? attackInterval});
```

| Campo | Tipo | Rango (Spec 001, FR-006) | Por defecto |
|---|---|---|---|
| `duration` | `Duration` | 30 s – 180 s | 30 s |
| `maxRepeats` | `int` | 1 – 5 | 5 |
| `warningTime` | `Duration` | 330 ms – 1 000 ms | 700 ms |
| `cutSpeed` | `Duration` | 300 ms – 1 000 ms | 500 ms |
| `attackInterval` | `Duration` | 500 ms – 5 000 ms y ≥ `intervalFloor` | 2 500 ms |

**Invariante**: `attackInterval ≥ cutSpeed + 500 ms` (`ParameterViolation.intervalBelowFloor`).

## 2. `ParameterField` (dominio, nuevo)

```dart
enum ParameterField { duration, maxRepeats, warningTime, cutSpeed, attackInterval }
```

El orden del enum es el orden de las filas en la pantalla (FR-004).

## 3. `ParameterEditor` (dominio, nuevo; `lib/domain/settings/parameter_editor.dart`)

Funciones puras, sin estado ni reloj.

| Miembro | Contrato |
|---|---|
| `static Duration intervalMinimum(Duration cutSpeed)` | `ceilTo100ms(cutSpeed + 500 ms)`. Corte 350 ms → 900 ms; corte 500 ms → 1 000 ms |
| `static List<int> allowedValues(ExerciseParameters p, ParameterField f)` | Valores en la rejilla (ms o N) de [research R2](./research.md#r2-pasos-mínimos-vigentes-y-ajuste-automático-en-el-dominio-fr-004-fr-007-fr-008-principio-vi). Para `attackInterval` dependen de `p.cutSpeed` |
| `static bool canIncrement(p, f)` | Existe un valor permitido mayor que el actual |
| `static bool canDecrement(p, f)` | Existe un valor permitido menor que el actual |
| `static EditResult increment(p, f)` | Siguiente valor permitido mayor. Si no hay, devuelve `p` sin cambios |
| `static EditResult decrement(p, f)` | Anterior valor permitido menor. Si no hay, devuelve `p` sin cambios |

**Regla del ajuste automático** (solo en `increment(p, cutSpeed)`): si `p'.attackInterval < intervalMinimum(p'.cutSpeed)`, entonces `p'' = p'.copyWith(attackInterval: intervalMinimum(p'.cutSpeed))` y `adjustedInterval = p''.attackInterval`.

**Garantía** (probada de forma exhaustiva): si `p.validate().isEmpty`, entonces `increment(p, f).parameters.validate().isEmpty` y `decrement(p, f).parameters.validate().isEmpty`, para todo `f`.

### `EditResult`

| Campo | Tipo | Significado |
|---|---|---|
| `parameters` | `ExerciseParameters` | Valores después del toque |
| `adjustedInterval` | `Duration?` | No nulo solo si el toque provocó el ajuste automático |

## 4. `SettingsRepository` (dominio, puerto nuevo; `lib/domain/ports/settings_repository.dart`)

| Método | Contrato |
|---|---|
| `Future<ExerciseParameters?> load()` | `null` si no existe, no se puede leer, el formato no es válido o `validate()` no está vacío. Nunca lanza |
| `Future<void> save(ExerciseParameters p)` | Guarda `p` de forma atómica. Lanza `SettingsSaveException` si falla; en ese caso la configuración anterior queda intacta |

`SettingsSaveException implements Exception` (`lib/domain/ports/settings_repository.dart`), con un `cause` opcional para depuración.

## 5. Archivo `settings.json` (datos)

Formato: [contracts/settings.schema.json](./contracts/settings.schema.json).

```json
{
  "version": 1,
  "durationMs": 60000,
  "maxRepeats": 5,
  "warningTimeMs": 500,
  "cutSpeedMs": 500,
  "attackIntervalMs": 2500
}
```

- Carpeta: `getApplicationDocumentsDirectory()` (ADR 0006); archivo temporal `settings.json.tmp` durante la escritura.
- `SettingsJsonMapper.fromJson(Map) → ExerciseParameters?` y `toJson(ExerciseParameters) → Map`. Los campos desconocidos se ignoran; uno faltante o no entero → `null`.

## 6. Estado de presentación

### `exerciseParametersProvider` → `ExerciseParametersNotifier` (configuración guardada)

| Estado | `ExerciseParameters` (siempre válido) |
|---|---|
| `build()` | `defaults()` |
| `load()` | `repo.load() ?? defaults()`; ante cualquier excepción → `defaults()` |
| `save(p)` | `repo.save(p)` y luego `state = p`; si lanza, el estado no cambia y la excepción se propaga |

### `settingsDraftProvider` → `SettingsDraftNotifier` (`autoDispose`; borrador)

```dart
final class SettingsDraft {
  final ExerciseParameters values;     // siempre válido
  final Duration? intervalAdjustedTo;  // aviso de ajuste (FR-008)
  final bool saving;                   // Guardar desactivado mientras es true
  final bool saveFailed;               // panel de error (FR-013)
}
```

Transiciones:

| Acción | `values` | `intervalAdjustedTo` | `saveFailed` |
|---|---|---|---|
| abrir pantalla | configuración guardada | `null` | `false` |
| `increment/decrement(f)`, `f ≠ attackInterval` | `ParameterEditor` | `adjustedInterval` del resultado si no es nulo; si es nulo, se conserva | `false` |
| `increment/decrement(attackInterval)` | `ParameterEditor` | `null` | `false` |
| `resetToDefaults()` | `defaults()` | `null` | `false` |
| `save()` empieza | — | — | `false`, `saving = true` |
| `save()` correcto | — | — | la pantalla hace `pop` |
| `save()` falla | sin cambios | sin cambios | `true`, `saving = false` |
| Cancelar o Atrás | se descarta (`autoDispose`) | — | — |

## 7. Formatos (presentación; `parameter_format.dart`)

| Función | Ejemplos |
|---|---|
| `formatSeconds(Duration)` | 330 ms → "0.33 s"; 700 → "0.7 s"; 1 000 → "1.0 s"; 2 500 → "2.5 s" |
| `formatDuration(Duration)` | 30 s → "30 s"; 45 s → "45 s"; 60 s → "1 min"; 135 s → "2 min 15 s"; 180 s → "3 min" |
| `formatIntervalRange(p)` | piso 1.0 s y tope 2.5 s → "Cada ataque: entre 1.0 s y 2.5 s, al azar"; 1.3 y 1.3 → "Cada ataque: 1.3 s" |
| `formatAdjustment(Duration)` | 1.3 s → "Intervalo ajustado a 1.3 s: debe ser al menos la velocidad del corte + 0.5 s" |

El rango del sorteo usa el **piso real** (`intervalFloor`), no `intervalMinimum`, porque es lo que hace el motor (Spec 001, FR-011).
