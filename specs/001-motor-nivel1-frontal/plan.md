# Implementation Plan: Motor del ejercicio + Nivel 1 + Patrón frontal

**Branch**: `001-motor-nivel1-frontal` | **Date**: 2026-10-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-motor-nivel1-frontal/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

App Android en Flutter que ejecuta un ejercicio de reacción de Nivel 1 (defensa) con el Patrón frontal. Tiene una cuenta regresiva y la voz *Si-jak*; después, ataques del oponente virtual con el lado aleatorio (máximo N repeticiones seguidas), la señal de defensa del lado contrario al color del sable y un corte animado de duración exacta. El ejercicio cierra con *Guman*.

El núcleo es un **motor de línea de tiempo puro** en el dominio, sin temporizadores. La presentación le pasa el tiempo transcurrido en cada cuadro y el motor devuelve el snapshot y los eventos. Así el comportamiento es determinista y fácil de probar (reloj y aleatoriedad inyectados). Los estados son explícitos para poder agregar la pausa más adelante. Niveles, patrones y glosario salen de un catálogo JSON, de modo que las specs 002–006 agreguen sobre todo datos.

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable)

**Primary Dependencies**: `flutter_riverpod` (sin codegen, ADR 0001), `flutter_tts` (ADR 0002), `wakelock_plus` (ADR 0003). Gráficos con `CustomPainter` del SDK (ADR 0004).

**Storage**: Ninguno en esta spec. El catálogo es un asset JSON de solo lectura. La persistencia de la configuración llega en la Spec 004 (JSON local detrás de un repositorio del dominio).

**Testing**: `flutter_test` / `test` del SDK. El dominio se prueba con `ManualClock` y `ScriptedRandomSource`/`SeededRandomSource`; no hace falta `fake_async`.

**Target Platform**: Android (teléfonos y tablets), solo horizontal. La TV se usa enviando la imagen desde el dispositivo.

**Project Type**: mobile-app (un solo proyecto Flutter)

**Performance Goals**: Animación a 60 fps. Tiempos de señal, corte e intervalo con desviación menor a 50 ms (SC-005). *Si-jak* coincide con el fin de la cuenta (voz preparada al arrancar la app).

**Constraints**: Sin conexión ni backend. El dominio en Dart puro. Contornos definidos y legibilidad a 3 m. Interfaz en español. Ningún paquete sin ADR.

**Scale/Scope**: 2 pantallas, 1 nivel, 1 patrón, ejercicios de 30 s a 3 min y hasta 5 personas frente a una pantalla.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Flutter 3.47.7 / Dart 3.13.5 stable, fijados en `pubspec.yaml` | ✅ |
| II. Clean Architecture | `lib/domain` (Dart puro), `lib/data` y `lib/presentation`; los puertos se definen en el dominio. Se verifica con el `grep` de quickstart §1 | ✅ |
| III. Datos sobre código | Niveles, patrones, glosario y comandos de voz en `assets/catalog/catalog.json`. Solo un tipo de respuesta o una animación de corte nuevos requieren código (excepción del principio) | ✅ |
| IV. Persistencia | Sin backend. No hay datos que persistir en 001; el repositorio de configuración llega en la 004 | ✅ |
| V. Gestión de estado | `flutter_riverpod` | ✅ |
| VI. Pruebas | Pruebas del dominio derivadas de los CA y de G1–G10; reglas de aleatoriedad, N e invariante cubiertas; reloj y aleatoriedad inyectados | ✅ |
| VII. Dependencias | 3 paquetes propuestos con pros y contras y aprobados por el responsable; ADR 0001–0004 en `docs/decisions/` | ✅ |
| VIII. Interfaz | Contorno ≥ 4 dp, fondo oscuro, colores saturados y orientación horizontal | ✅ |
| IX. Idioma | Identificadores en inglés; interfaz en español; términos coreanos desde el glosario | ✅ |
| X. Flujo | Rama `001-motor-nivel1-frontal` → PR a `main`; Conventional Commits | ✅ |
| XI. Seguridad | Sin autenticación ni autorización; sin datos personales | ✅ |

**Resultado (antes de Phase 0)**: PASA, sin violaciones.
**Re-check después de Phase 1**: PASA. El diseño (puertos, catálogo, motor puro) no introduce dependencias del dominio hacia Flutter ni paquetes sin ADR.

## Project Structure

### Documentation (this feature)

```text
specs/001-motor-nivel1-frontal/
├── spec.md
├── plan.md              # Este archivo
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── catalog.schema.json
│   ├── domain-ports.md
│   └── ui-screens.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; no lo crea este comando)

docs/decisions/
├── 0001-riverpod-sin-codegen.md
├── 0002-voz-sintetica-flutter-tts.md
├── 0003-pantalla-encendida-wakelock-plus.md
└── 0004-graficos-custompainter.md
```

### Source Code (repository root)

```text
pubspec.yaml
analysis_options.yaml
assets/
└── catalog/
    └── catalog.json                 # Nivel 1, Patrón frontal, glosario, comandos de voz

lib/
├── main.dart                        # ProviderScope, orientación horizontal, prepare() de la voz
├── app.dart                         # MaterialApp, tema oscuro, rutas
├── domain/                          # Dart puro: sin imports de Flutter ni de paquetes
│   ├── catalog/
│   │   ├── catalog.dart             # Catalog, GlossaryTerm, Level, Pattern
│   │   ├── catalog_exception.dart
│   │   └── enums.dart               # ResponseType, CutAnimation, VoiceCommand
│   ├── exercise/
│   │   ├── exercise_engine.dart     # start / advanceTo / cancel
│   │   ├── exercise_status.dart     # enum + tabla de transiciones
│   │   ├── exercise_snapshot.dart   # ExerciseSnapshot, ExerciseTick, AttackPhase, SaberColor
│   │   ├── exercise_event.dart
│   │   ├── exercise_parameters.dart # límites, valores por defecto, invariante, validate()
│   │   ├── attack.dart              # Attack, Side
│   │   ├── side_sequencer.dart      # regla de N
│   │   ├── signal.dart              # Signal, SignalPlacement
│   │   └── session.dart
│   └── ports/
│       ├── catalog_repository.dart
│       ├── random_source.dart
│       ├── elapsed_clock.dart
│       ├── voice_announcer.dart
│       └── screen_wake_lock.dart
├── data/
│   ├── catalog/
│   │   ├── asset_catalog_repository.dart
│   │   └── catalog_json_mapper.dart # JSON → entidades + validación de referencias
│   └── platform/
│       ├── dart_random_source.dart
│       ├── stopwatch_clock.dart
│       ├── flutter_tts_voice_announcer.dart
│       └── wakelock_plus_screen_wake_lock.dart
└── presentation/
    ├── providers.dart               # providers de puertos, catálogo y sesión
    ├── strings_es.dart
    ├── theme.dart                   # colores del sable, contornos, fondo
    ├── selection/
    │   └── selection_screen.dart
    └── exercise/
        ├── exercise_controller.dart # Notifier: Ticker → advanceTo → efectos
        ├── exercise_screen.dart     # Ticker, AppLifecycleListener, botones
        └── painters/
            ├── opponent_painter.dart
            └── signal_painter.dart

test/
├── domain/
│   ├── fakes/                       # ManualClock, ScriptedRandomSource, SeededRandomSource
│   ├── exercise_parameters_test.dart
│   ├── side_sequencer_test.dart
│   ├── signal_placement_test.dart
│   ├── exercise_engine_timeline_test.dart
│   ├── exercise_engine_states_test.dart
│   └── exercise_engine_simulation_test.dart   # SC-003, SC-004, SC-006
├── data/
│   └── catalog_json_mapper_test.dart
└── presentation/
    ├── selection_screen_test.dart   # FR-004, SC-009
    └── exercise_screen_test.dart    # cancelación, ciclo de vida, efectos
```

**Structure Decision**: Un solo proyecto Flutter en la raíz del repositorio, con carpetas por capa de Clean Architecture (`domain`, `data`, `presentation`), como exige el Principio II. Las pruebas reflejan las capas, y el dominio tiene su carpeta propia para poder ejecutar `flutter test test/domain` por separado (Principio VI).

## Complexity Tracking

Sin violaciones de la constitution que justificar.
