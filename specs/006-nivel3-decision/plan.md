# Implementation Plan: Nivel 3, decisión bajo presión

**Branch**: `006-nivel3-decision` | **Date**: 2026-11-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/006-nivel3-decision/spec.md`

## Summary

Agregar el Nivel 3, en el que cada ataque pide defensa o evasión lateral al azar, con un límite de N repeticiones para el lado y otro para el tipo. Se reutilizan las señales existentes. Lo nuevo es:

- **Dominio**: `SideSequencer` se generaliza en `StreakSequencer<T>`, un único sorteo con racha máxima que sirve para lados y para tipos de respuesta. El motor lo usa dos veces y sortea en el orden lado → tipo → intervalo. Con una sola opción no se consume ningún sorteo, así que los Niveles 1 y 2 producen exactamente las mismas secuencias que hoy (R2, R3).
- **Datos**: `level_3` en el catálogo, con `responseTypes: ["defense", "evasion"]` (R4).
- **Presentación**: `LevelIcon` dibuja una o varias señales lado a lado (R6). Las columnas de la selección dejan de desplazarse y usan una densidad compacta cuando no caben (FR-012a; R7). La pantalla del ejercicio, el HUD y las señales no cambian (R5).

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable), sin cambios

**Primary Dependencies**: `flutter_riverpod`, `flutter_tts`, `wakelock_plus`, `path_provider` (ADR 0001–0003 y 0006); `CustomPainter` (ADR 0004); Rajdhani (ADR 0005). **Sin dependencias nuevas.**

**Storage**: Sin cambios. `assets/catalog/catalog.json` gana un nivel y `settings.json` no cambia.

**Testing**: `flutter_test`. La regresión grabada de secuencias va **antes** del refactor; el dominio se prueba con `ScriptedRandomSource` y `SeededRandomSource`, y los widgets en 7 lienzos de referencia (R8).

**Target Platform**: Android (teléfonos y tablets), en horizontal, de 4:3 a 20:9

**Project Type**: mobile-app (el mismo proyecto Flutter de las Specs 001 a 005)

**Performance Goals**: Sin cambios: tiempos del ejercicio con ±50 ms (Spec 001, SC-005). Un sorteo extra por ataque en el Nivel 3 no tiene costo medible.

**Constraints**:
- **Condiciones del responsable**:
  - Los Niveles 1 y 2 producen las mismas secuencias que hoy con la misma fuente de aleatoriedad.
  - Con un solo tipo de respuesta no se consume ningún sorteo para el tipo.
  - Las pruebas de dominio de las Specs 001 a 005 no cambian sus expectativas; las del `SideSequencer` solo se adaptan al nombre nuevo.
- **FR-002**: una sola regla nueva en el dominio (el sorteo del tipo). Tiempos, estados, cancelación, voces, movimiento, patrones y configuración no cambian.
- **FR-012a**: en la selección, todas las tarjetas se ven sin desplazar, de 4:3 a 20:9, con hasta 4 niveles.
- **Principio II**: `lib/domain/` sigue siendo Dart puro.

**Scale/Scope**: 1 clase de dominio renombrada y generalizada, 2 líneas en el motor, 1 entrada en el catálogo, 1 painter y 1 pantalla de presentación ajustados, 1 tipo de presentación nuevo y unas 6 suites de pruebas nuevas o ampliadas.

No hay incógnitas abiertas: las decisiones están en [research.md](./research.md), R1 a R8.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Sin cambios de SDK | ✅ |
| II. Clean Architecture | `StreakSequencer` en el dominio, Dart puro, genérico y sin dependencias del catálogo. `SelectionDensity` en presentación | ✅ |
| III. Datos sobre código | El Nivel 3 es un dato del catálogo y exige **una regla de secuencia nueva** (el sorteo del tipo) sin introducir un tipo de señal nuevo. Entra en la excepción (b) del principio (constitution 1.1.0): regla de secuencia genérica (`StreakSequencer<T>`), justificada en [Complexity Tracking](#complexity-tracking) y sin efecto sobre los Niveles 1 y 2 (regresión T002) | ✅ |
| IV. Persistencia | Sin cambios | ✅ |
| V. Gestión de estado | Riverpod sin cambios | ✅ |
| VI. Pruebas | La regla de N sobre los tipos y la aleatoriedad del tipo tienen pruebas de dominio (SC-004, SC-005). La aleatoriedad se sigue inyectando. Las pruebas salen de la spec, y la regresión de secuencias se graba antes del refactor (R8) | ✅ |
| VII. Dependencias y decisiones | Ningún paquete nuevo; no hace falta ADR | ✅ |
| VIII. Interfaz | Señales y contornos sin cambios. Ícono del Nivel 3 en blanco. Densidad compacta solo en la selección, con textos de al menos 12 dp y blancos táctiles de al menos 48 dp | ✅ |
| IX. Idioma y terminología | Identificadores en inglés (`StreakSequencer`, `SelectionDensity`); textos del catálogo en español | ✅ |
| X. Flujo de trabajo | Rama `006-nivel3-decision` → PR a `main`; commits `refactor:` (generalización), `test:` (regresión) y `feat:` (Nivel 3) | ✅ |
| XI. Seguridad y alcance | Sin cambios | ✅ |

**Re-check post-diseño (Phase 1)**: sin violaciones. El único cambio de lógica de dominio es el de III, que cumple la excepción (b) de la constitution 1.1.0 (enmendada el 2026-11-18) y queda acotado a `streak_sequencer.dart` y a `_onSignal`.

## Decisiones de diseño

- **D1. Alcance.**
  - Dominio: `side_sequencer.dart` → `streak_sequencer.dart`, y en `exercise_engine.dart` el segundo secuenciador y el orden de sorteos.
  - Datos: `catalog.json`.
  - Presentación: `level_icon.dart`, `selection_screen.dart`, `selection_card.dart` y el nuevo `selection_density.dart`.
  - Se corrige el comentario de `enums.dart` (`counter` → Spec 007) (R1).
- **D2. `StreakSequencer<T>`.** Opciones ordenadas y candidatos. Con un solo candidato o una sola opción no se consume sorteo. Equivale caso por caso al `SideSequencer` con `[right, left]` ([R2](./research.md#r2-un-único-sorteo-con-racha-máxima-streaksequencert); [contrato §1](./contracts/domain-sequencer.md#1-streaksequencert)).
- **D3. Orden de sorteos.** Lado → tipo → intervalo. En los Niveles 1 y 2, el tipo no consume nada (R3; [contrato §2](./contracts/domain-sequencer.md#2-orden-de-los-sorteos-en-exerciseengine)).
- **D4. Regresión primero.** Antes de tocar el dominio se graba la secuencia completa de ataques del motor actual (Niveles 1 y 2 × 2 patrones × 3 semillas × N ∈ {1, 5}) como prueba con valores fijos. Debe pasar sin cambios después del refactor (R8).
- **D5. Señales sin cambios.** `SignalPlacement` ya decide por ataque y el HUD ya lee el catálogo (R5).
- **D6. Ícono con n glifos.** Celdas horizontales iguales; con `n = 1` la imagen es idéntica (R6; [contrato §2](./contracts/selection-ui.md#2-levelicon)).
- **D7. Selección sin desplazar.** `regular` (Spec 004) o `compact` (medidas en dp con mínimos legibles), elegida por una función pura. El pie no se compacta. El desplazamiento solo queda como red de seguridad fuera de los lienzos de referencia (R7; [contrato §3](./contracts/selection-ui.md#3-densidad-de-la-selección)).

## Project Structure

### Documentation (this feature)

```text
specs/006-nivel3-decision/
├── spec.md
├── plan.md                    # Este archivo
├── research.md                # Phase 0 (R1–R8)
├── data-model.md              # Phase 1
├── quickstart.md              # Phase 1
├── contracts/
│   ├── domain-sequencer.md    # StreakSequencer y orden de sorteos
│   └── selection-ui.md        # Tarjeta e ícono del Nivel 3, densidad y lienzos
├── checklists/requirements.md
└── tasks.md                   # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
assets/catalog/catalog.json                     # + level_3
lib/domain/
├── catalog/enums.dart                          # solo comentario (counter → Spec 007)
└── exercise/
    ├── side_sequencer.dart                     # − se elimina
    ├── streak_sequencer.dart                   # + StreakSequencer<T>
    └── exercise_engine.dart                    # _sides genérico, + _responseTypes, orden lado → tipo → intervalo
lib/presentation/selection/
├── level_icon.dart                             # types: List<ResponseType>, n glifos
├── selection_density.dart                      # + SelectionDensity (pura)
├── selection_card.dart                         # medidas según densidad
└── selection_screen.dart                       # Column sin desplazar, densidad, LevelIcon(types)
test/
├── domain/
│   ├── exercise_engine_sequence_regression_test.dart  # + (antes del refactor)
│   ├── side_sequencer_test.dart → streak_sequencer_test.dart  # renombre + pruebas nuevas
│   ├── exercise_engine_level3_test.dart        # + rachas, orden y proporciones del Nivel 3
│   ├── exercise_engine_{timeline,motion,simulation}_test.dart  # + grupos del Nivel 3 (reutilizando los parametrizados)
│   └── fakes/test_session.dart                 # + testLevel3Session / testLevel3TransversalSession
├── data/catalog_json_mapper_test.dart          # 3 niveles + level_3
└── presentation/
    ├── level_icon_test.dart                    # +
    ├── selection_density_test.dart             # + función pura
    ├── selection_screen_test.dart              # + 7 lienzos × {3, 4} niveles
    └── exercise_screen_test.dart               # + Nivel 3: una señal por ataque, HUD
```

**Structure Decision**: Es el mismo proyecto Flutter con capas `domain`, `data` y `presentation`. No hay directorios nuevos.

## Complexity Tracking

| Excepción (III, 1.1.0) | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| **Principio III, excepción (b)**: agregar el Nivel 3 cambia la lógica del dominio sin introducir un tipo de señal nuevo. Se generaliza `SideSequencer` → `StreakSequencer<T>` y el motor sortea el tipo de respuesta | FR-004 y FR-005 (brief, RN1 y RN2) piden sortear el tipo con un máximo de N. Hasta ahora el motor tomaba siempre `responseTypes.first`, porque ningún nivel tenía más de un tipo. Es la regla nueva que admite FR-002 (corregido el 2026-11-18). Por ser genérica, un nivel futuro que mezcle tipos volverá a ser solo datos | *Un `ResponseTypeSequencer` copiado*: duplica la regla de N (descartado por el responsable). *Sortear el par (lado, tipo) con `nextInt(4)`*: altera las secuencias de los Niveles 1 y 2. *Mezclar en el catálogo*: el catálogo no puede expresar aleatoriedad ni rachas sin lógica |
