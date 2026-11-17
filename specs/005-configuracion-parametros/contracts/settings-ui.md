# Contrato: configuración (puerto, proveedor y pantallas)

**Feature**: [spec.md](../spec.md) | **Data model**: [data-model.md](../data-model.md)

## 1. Puerto del dominio

```dart
// lib/domain/ports/settings_repository.dart
abstract interface class SettingsRepository {
  Future<ExerciseParameters?> load();               // nunca lanza
  Future<void> save(ExerciseParameters parameters); // lanza SettingsSaveException
}

final class SettingsSaveException implements Exception {
  SettingsSaveException([this.cause]);
  final Object? cause;
}
```

Implementación: `JsonFileSettingsRepository` (`lib/data/settings/`), con el formato de [settings.schema.json](./settings.schema.json). Un backend futuro solo implementa este puerto (Principio IV).

## 2. Proveedores (`lib/presentation/providers.dart`)

| Proveedor | Tipo | Notas |
|---|---|---|
| `settingsRepositoryProvider` | `Provider<SettingsRepository>` | `JsonFileSettingsRepository(directory: getApplicationDocumentsDirectory)`. Se reemplaza en pruebas |
| `exerciseParametersProvider` | `NotifierProvider<ExerciseParametersNotifier, ExerciseParameters>` | **Mismo nombre y tipo de valor** que en la Spec 004: el controlador y el HUD no cambian. `load()` y `save(p)` según [data-model §6](../data-model.md#6-estado-de-presentación) |
| `settingsDraftProvider` | `NotifierProvider.autoDispose<SettingsDraftNotifier, SettingsDraft>` | Vive mientras la pantalla de configuración está abierta |

`main()`: `await container.read(exerciseParametersProvider.notifier).load()` antes de `runApp` (R5).

## 3. Pantalla de selección (cambios)

- Pie: `[resumen (Expanded)] [CONFIGURACIÓN] [INICIAR]`.
  - CONFIGURACIÓN: `OutlinedButton` píldora, borde blanco, 64 × `hudScale` de alto, `Key('settingsButton')`. Habilitado aunque el catálogo falle: la configuración no depende de él.
  - Resumen: `'${level} · ${pattern} · ${formatDuration(duration)}'`.
- INICIAR sin cambios (una sola acción, Spec 001, SC-001).

## 4. Pantalla de configuración (`lib/presentation/settings/settings_screen.dart`)

```text
┌──────────────────────────────────────────────────────────────────────┐
│ CONFIGURACIÓN                                                        │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ Duración del ejercicio · Tiempo total · 30 s a 3 min (−) 30 s (+)│ │
│ │ Máximo de repeticiones seguidas · Ataques seguidos   (−)  5   (+)│ │
│ │   al mismo lado · 1 a 5                                          │ │
│ │ Tiempo de aviso · Desde la señal hasta el corte     (−) 0.7 s (+)│ │
│ │   ⅓ s a 1 s · 1 s: cinta blanca · ⅓ s: avanzado                  │ │
│ │ Velocidad del corte · Duración del corte · 0.3 s a 1 s (−)0.5 s(+)│ │
│ │ Intervalo máximo entre ataques · Desde el inicio    (−) 2.5 s (+)│ │
│ │   del corte hasta la siguiente señal                             │ │
│ │   Cada ataque: entre 1.0 s y 2.5 s, al azar                      │ │
│ │   ⓘ Intervalo ajustado a 1.3 s: debe ser al menos …   (si aplica)│ │
│ └───────────────────────────────────────── (lista desplazable) ────┘ │
│ [RESTABLECER]                            [CANCELAR]  [  GUARDAR  ]   │
└──────────────────────────────────────────────────────────────────────┘
```

| Elemento | Key | Comportamiento |
|---|---|---|
| Fila de parámetro | `Key('param-${field.name}')` | Nombre, explicación y valor formateado (`Key('value-${field.name}')`) |
| Botón − | `Key('dec-${field.name}')` | `onPressed: null` si `!canDecrement` (FR-004a) |
| Botón + | `Key('inc-${field.name}')` | `onPressed: null` si `!canIncrement` |
| Rango del sorteo | `Key('intervalRange')` | `formatIntervalRange(values)` (FR-005) |
| Aviso de ajuste | `Key('intervalAdjustedNotice')` | Visible si `intervalAdjustedTo != null` (FR-008) |
| Error al guardar | `Key('saveError')` | Visible si `saveFailed` (FR-013) |
| RESTABLECER | `Key('resetButton')` | `resetToDefaults()` |
| CANCELAR | `Key('cancelButton')` | `pop` sin guardar; equivale a Atrás del sistema |
| GUARDAR | `Key('saveButton')` | `save()`; `pop` si tiene éxito; desactivado solo mientras `saving` |

**Colores** (FR-018): solo `AppColors` de los grupos de interfaz y dojang. Ningún widget de esta pantalla usa `saberBlue`, `saberRed` ni `saberYellow`, ni `ColorScheme.error`.

## 5. Textos (`strings_es.dart`)

| Clave | Texto |
|---|---|
| `settings` | `CONFIGURACIÓN` |
| `save` / `cancel` / `reset` | `GUARDAR` / `CANCELAR` / `RESTABLECER` |
| `durationLabel` | `Duración del ejercicio` |
| `maxRepeatsLabel` | `Máximo de repeticiones seguidas` |
| `durationHint` / `durationRange` | `Tiempo total del ejercicio` / `30 s a 3 min` |
| `maxRepeatsHint` / `maxRepeatsRange` | `Ataques seguidos al mismo lado, como máximo` / `1 a 5` |
| `warningTimeLabel` | `Tiempo de aviso` |
| `warningTimeHint` / `warningTimeRange` | `Desde la señal hasta el corte` / `⅓ s a 1 s` |
| `warningTimeReference` | `1 s: cinta blanca · ⅓ s: avanzado` |
| `cutSpeedLabel` | `Velocidad del corte` |
| `cutSpeedHint` / `cutSpeedRange` | `Duración del corte del oponente` / `0.3 s a 1 s` |
| `attackIntervalHint` | `Desde el inicio del corte hasta la siguiente señal` |
| `attackIntervalLabel` | `Intervalo máximo entre ataques` |
| `saveErrorTitle` | `No se pudo guardar` |
| `saveErrorBody` | `Tus cambios siguen aquí. Inténtalo de nuevo.` |

Los textos de rangos, ajustes y rangos del sorteo se generan con las funciones de [data-model §7](../data-model.md#7-formatos-presentación-parameter_formatdart).

## 6. Pruebas que dependen de este contrato

- `test/domain/parameter_editor_test.dart`: §3 de data-model.
- `test/data/settings_json_mapper_test.dart`, `test/data/json_file_settings_repository_test.dart`: §1 y el esquema.
- `test/presentation/settings_screen_test.dart`: §4 (keys) y §5.
- `test/presentation/settings_screen_test.dart` (grupos US1 y "disposición"): §3 (botón CONFIGURACIÓN y resumen formateado). `selection_screen_test.dart` no cambia (SC-008).
- `test/presentation/palette_test.dart`: colores nuevos, si los hay (R8).
