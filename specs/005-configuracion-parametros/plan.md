# Implementation Plan: Configuración de parámetros e invariante de tiempos

**Branch**: `005-configuracion` | **Date**: 2026-11-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/005-configuracion-parametros/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Permitir que el usuario edite los cinco parámetros del ejercicio con botones − / +, que la invariante de tiempos se cumpla siempre al editar (el intervalo sube solo cuando hace falta) y que la configuración se conserve entre aperturas de la app. El motor no cambia. Lo nuevo:

- **Dominio**: `ParameterEditor` (rejilla de valores, mínimos vigentes y ajuste automático, en milisegundos enteros) y el puerto `SettingsRepository` (R2, R3). `ExerciseParameters` solo gana `copyWith`.
- **Datos**: `JsonFileSettingsRepository` con `settings.json` versionado y escritura atómica, sobre la carpeta de `path_provider` (R4; ADR 0006 aprobado).
- **Presentación**: `exerciseParametersProvider` pasa a `Notifier` con `load()` y `save()`, con el mismo nombre y tipo de valor, así que el controlador y el HUD no cambian (R5). Hay una pantalla de configuración con borrador `autoDispose` (R6, R7), un botón CONFIGURACIÓN y el formato de duración en la selección (R9, R10). La regla de color se cumple también en los avisos (R8).

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable), sin cambios

**Primary Dependencies**: `flutter_riverpod`, `flutter_tts`, `wakelock_plus` (ADR 0001–0003); `CustomPainter` (ADR 0004); Rajdhani (ADR 0005). **Nuevo**: `path_provider` 2.x (ADR 0006, aprobado el 2026-11-16), solo en `lib/data/settings/` (fábrica `JsonFileSettingsRepository.inAppDocuments()`).

**Storage**: Archivo JSON local `settings.json` en la carpeta de documentos de la app ([contracts/settings.schema.json](./contracts/settings.schema.json)); unos 150 bytes.

**Testing**: `flutter_test`; dominio con pruebas exhaustivas de la rejilla; repositorio con un directorio temporal de `dart:io`; pantallas con repositorios falsos (R11).

**Target Platform**: Android (teléfonos y tablets), horizontal, de 4:3 a 20:9

**Project Type**: mobile-app (el mismo proyecto Flutter de la 001)

**Performance Goals**: La carga de la configuración termina antes del primer cuadro de la selección (lectura de un archivo pequeño en `main`). Los tiempos del ejercicio, con ±50 ms (Spec 001, SC-005), no cambian.

**Constraints**:
- FR-016 / SC-008: motor, estados, secuenciador, señales, voces y cancelación sin cambios; todas las pruebas de las Specs 001 a 004 siguen pasando.
- FR-007 / FR-009: ningún borrador ni configuración guardada viola la invariante.
- FR-018: sin rojo, azul ni amarillo en la pantalla de configuración, incluidos los avisos.
- Principio II: `lib/domain/` sigue siendo Dart puro.

**Scale/Scope**: 1 clase de dominio y 1 puerto, 1 mapper y 1 repositorio, 2 notifiers, 1 pantalla nueva (5 filas) y 1 modificada, formatos y textos; unas 5 suites de pruebas nuevas o ampliadas.

No hay incógnitas abiertas: las decisiones están en [research.md](./research.md), R1 a R11.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Sin cambios de SDK | ✅ |
| II. Clean Architecture | `ParameterEditor` y `SettingsRepository` en el dominio, Dart puro. El repositorio de archivo está en datos. `path_provider` solo se importa ahí, en la fábrica `inAppDocuments()`; `providers.dart` solo la llama (R4, ADR 0006) | ✅ |
| III. Datos sobre código | Sin cambios en el catálogo; los parámetros no son datos del catálogo | ✅ |
| IV. Persistencia | JSON local detrás de una interfaz de repositorio del dominio; un backend sería otra implementación (R3, R4) | ✅ |
| V. Gestión de estado | Riverpod: `NotifierProvider` para la configuración guardada y `autoDispose` para el borrador (R5, R6) | ✅ |
| VI. Pruebas | La invariante y la rejilla se prueban en el dominio, de forma exhaustiva (SC-003). Las pruebas salen de los escenarios de la spec. No hay reloj ni aleatoriedad nuevos | ✅ |
| VII. Dependencias y decisiones | `path_provider` propuesto con alternativas y **aprobado** por el responsable: ADR 0006 | ✅ |
| VIII. Interfaz | Pantalla en horizontal y legible (botones grandes, contraste alto). Las pantallas de ejercicio no cambian | ✅ |
| IX. Idioma y terminología | Identificadores en inglés; textos en español (contrato §5) | ✅ |
| X. Flujo de trabajo | Rama `005-configuracion` → PR a `main`; Conventional Commits | ✅ |
| XI. Seguridad y alcance | Sin autenticación; archivo en la carpeta privada de la app | ✅ |

**Resultado (antes de Phase 0)**: PASA, sin violaciones.
**Re-check después de Phase 1**: PASA. El diseño mantiene el dominio puro, la única dependencia nueva está aprobada y el motor no cambia.

## Decisiones de diseño

- **D1. Alcance.** Un archivo nuevo en el dominio, uno en los puertos y `copyWith` en `ExerciseParameters`; dos archivos en `lib/data/settings/`; presentación; `pubspec.yaml` (+ `path_provider`) (R1).
- **D2. Rejilla en el dominio.** Milisegundos enteros. `increment` va al siguiente valor permitido y `decrement`, al anterior. El mínimo del intervalo es el piso redondeado hacia arriba a 100 ms. Solo subir el corte puede subir el intervalo (R2, [data-model §3](./data-model.md#3-parametereditor-dominio-nuevo-libdomainsettingsparameter_editordart)).
- **D3. Puerto mínimo.** `load()` devuelve `null` en cualquier fallo y `save()` lanza `SettingsSaveException`. Los valores por defecto se resuelven en el proveedor (R3).
- **D4. Archivo.** `settings.json`, `version: 1`, valores en milisegundos; escritura con `.tmp` y renombrado; lectura tolerante (R4, [esquema](./contracts/settings.schema.json)).
- **D5. Carga en `main`.** Antes de `runApp`; `exerciseParametersProvider` conserva su nombre y su tipo de valor (R5).
- **D6. Borrador `autoDispose`.** Cancelar y Atrás no hacen nada más que cerrar. El aviso de ajuste persiste hasta tocar el intervalo o restablecer. El error al guardar es un panel junto a las acciones (R6, [data-model §6](./data-model.md#6-estado-de-presentación)).
- **D7. Pantalla.** Lista desplazable de 5 filas `[nombre · explicación] [−] valor [+]` y barra de acciones fija (R7, [contrato §4](./contracts/settings-ui.md#4-pantalla-de-configuración-libpresentationsettingssettings_screendart)).
- **D8. Color.** Botones, aviso y error solo con blancos y grises de `AppColors`, sin `ColorScheme.error` (R8).
- **D9. Formatos.** Tiempos con 1 o 2 decimales y punto; duración "45 s", "1 min", "2 min 15 s". El contador del HUD sigue en segundos (R9).
- **D10. Selección.** Pie con resumen, CONFIGURACIÓN e INICIAR; el resumen usa `formatDuration` (R10).

## Project Structure

### Documentation (this feature)

```text
specs/005-configuracion-parametros/
├── spec.md
├── plan.md                    # Este archivo
├── research.md                # Phase 0 (R1–R11)
├── data-model.md              # Phase 1
├── quickstart.md              # Phase 1
├── contracts/
│   ├── settings.schema.json   # Formato de settings.json
│   └── settings-ui.md         # Puerto, proveedores, pantallas, textos
├── checklists/
│   └── requirements.md
└── tasks.md                   # Phase 2 (/speckit-tasks; no lo crea este comando)
```

### Source Code (repository root)

Solo se listan los archivos que cambian o se crean; el resto es la estructura de la 001 y la 004.

```text
pubspec.yaml                                      # + path_provider (ADR 0006)

docs/decisions/
└── 0006-carpeta-de-la-app-path-provider.md       # ya creado y aprobado

lib/
├── main.dart                                     # await exerciseParametersProvider.notifier.load()
├── domain/
│   ├── exercise/exercise_parameters.dart         # + copyWith
│   ├── settings/                                 # nuevo
│   │   └── parameter_editor.dart                 # ParameterField, ParameterEditor, EditResult
│   └── ports/
│       └── settings_repository.dart              # nuevo: SettingsRepository, SettingsSaveException
├── data/
│   └── settings/                                 # nuevo
│       ├── settings_json_mapper.dart
│       └── json_file_settings_repository.dart
└── presentation/
    ├── providers.dart                            # settingsRepositoryProvider; exerciseParametersProvider → Notifier
    ├── strings_es.dart                           # textos de configuración
    ├── theme.dart                                # colores de interfaz nuevos, si hacen falta (grupo neutro)
    ├── selection/selection_screen.dart           # pie: CONFIGURACIÓN + formatDuration
    └── settings/                                 # nuevo
        ├── settings_screen.dart
        ├── settings_draft.dart                   # SettingsDraft + SettingsDraftNotifier + settingsDraftProvider
        ├── parameter_row.dart                    # fila con − / +
        └── parameter_format.dart                 # formatSeconds, formatDuration, formatIntervalRange, formatAdjustment

test/
├── domain/parameter_editor_test.dart             # nuevo
├── data/settings_json_mapper_test.dart           # nuevo
├── data/json_file_settings_repository_test.dart  # nuevo
└── presentation/
    ├── fakes/in_memory_settings_repository.dart  # nuevo (con modo "falla al guardar")
    ├── parameter_format_test.dart                # nuevo
    ├── settings_screen_test.dart                 # nuevo
    ├── selection_screen_test.dart                # sin cambios; debe seguir pasando (SC-008, T017)
    └── palette_test.dart                         # + colores nuevos, si los hay
```

**Structure Decision**: El mismo proyecto Flutter con las capas de la Spec 001. La configuración tiene su propia carpeta en el dominio (`settings/`), en datos y en presentación. El motor (`lib/domain/exercise/`) solo recibe `copyWith`.

## Complexity Tracking

Sin violaciones de la constitution; no aplica.
