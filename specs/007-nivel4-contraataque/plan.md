# Implementation Plan: Nivel 4, evasión con contraataque

**Branch**: `007-nivel4-contraataque` | **Date**: 2026-11-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/007-nivel4-contraataque/spec.md`

## Summary

Agregar el Nivel 4: en cada ataque se muestra la **señal de contraataque**, que es la flecha de evasión con un sable vertical junto a la punta, del lado del color. Lo nuevo es:

- **Dominio**: el valor `ResponseType.counter` y su rama en `SignalPlacement` (del lado del color). El motor no cambia: con un solo tipo de respuesta, el `StreakSequencer` de la Spec 006 no consume sorteo, así que el Nivel 4 repite exactamente la secuencia del Nivel 2 (R1–R3).
- **Datos**: `level_4` en el catálogo, con `responseTypes: ["counter"]` (data-model §2).
- **Presentación**:
  - `SignalShapes.saber` se generaliza con el ángulo como parámetro (115° defensa, 90° contraataque) (R5).
  - `SignalPainter` agrega `_paintCounter`, que comparte la flecha y el sable con la evasión y la defensa (R4, R6).
  - `LevelIconPainter` agrega el glifo del contraataque (R7).
  - La selección y el HUD no cambian de código (R8).

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable), sin cambios

**Primary Dependencies**: `flutter_riverpod`, `flutter_tts`, `wakelock_plus`, `path_provider` (ADR 0001–0003 y 0006); `CustomPainter` (ADR 0004); Rajdhani (ADR 0005). **Sin dependencias nuevas.**

**Storage**: Sin cambios. `assets/catalog/catalog.json` gana `level_4`; `settings.json` no cambia.

**Testing**: `flutter_test`. Dominio con `ScriptedRandomSource` y `SeededRandomSource`. Las señales se prueban por propiedades de pixeles en los 7 lienzos de referencia (Specs 004 y 006). La regresión de secuencias de la Spec 006 debe pasar sin cambios.

**Target Platform**: Android (teléfonos y tablets), en horizontal, de 4:3 a 20:9

**Project Type**: mobile-app (el mismo proyecto Flutter de las Specs 001 a 006)

**Performance Goals**: Sin cambios: tiempos del ejercicio con ±50 ms (Spec 001, SC-005). La señal de contraataque agrega unas cuantas rutas por fotograma, sin costo medible.

**Constraints**:
- **FR-002**: solo se agregan el tipo de respuesta nuevo y su señal. No hay reglas de secuencia nuevas, y no cambian los tiempos, los estados, la cancelación, las voces, el movimiento, los patrones ni la configuración.
- **FR-010**: la señal cabe en el carril de la flecha de evasión, con la flecha a ≥ 75 % de la del Nivel 2. Por construcción queda en ≥ 82 % (R4).
- **FR-020**: los Niveles 1, 2 y 3 dan las mismas secuencias, los mismos pixeles de señal y los mismos íconos.
- **Principio II**: `lib/domain/` sigue siendo Dart puro.

**Scale/Scope**:
- 1 valor de enum y 1 rama de colocación en el dominio.
- 1 entrada en el catálogo.
- 3 archivos de presentación ajustados: `signal_shapes.dart`, `signal_painter.dart` y `level_icon.dart`.
- Unas 8 suites de pruebas nuevas o ampliadas.

No hay incógnitas abiertas: las decisiones están en [research.md](./research.md), R1 a R9.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Sin cambios de SDK | ✅ |
| II. Clean Architecture | `ResponseType.counter` y su colocación en el dominio (Dart puro). La geometría y el pintado, en presentación | ✅ |
| III. Datos sobre código | El Nivel 4 es un dato del catálogo e introduce un **tipo de señal nuevo**, la excepción (a) del principio (constitution 1.1.0). La lógica de dominio solo crece en el enum y en una rama de `SignalPlacement`. No se agregan reglas de secuencia, así que no se usa la excepción (b) | ✅ |
| IV. Persistencia | Sin cambios | ✅ |
| V. Gestión de estado | Riverpod sin cambios | ✅ |
| VI. Pruebas | La colocación, la regla de N con un solo tipo y la aleatoriedad de lados del Nivel 4 tienen pruebas de dominio (SC-004, SC-005). Las pruebas salen de la spec (R9) | ✅ |
| VII. Dependencias y decisiones | Ningún paquete nuevo; no hace falta ADR | ✅ |
| VIII. Interfaz | La señal nueva tiene contorno oscuro, brillo y legibilidad a 3 m (SC-006). Usa el color del sable y el ícono va en blanco | ✅ |
| IX. Idioma y terminología | Identificadores en inglés (`counter`, `_paintCounter`, `saber`); textos del catálogo en español | ✅ |
| X. Flujo de trabajo | Rama `007-nivel4-contraataque` → PR a `main`; commits `refactor:` (generalizar `saber`), `feat:` (Nivel 4) y `test:` | ✅ |
| XI. Seguridad y alcance | Sin cambios | ✅ |

**Re-check post-diseño (Phase 1)**: sin violaciones. El cambio de dominio queda acotado a `enums.dart` y `signal.dart`, como prevé la excepción (a).

## Decisiones de diseño

- **D1. Alcance.**
  - Dominio: `enums.dart` (`counter` y su comentario) y `signal.dart` (la rama nueva).
  - Datos: `catalog.json`.
  - Presentación: `signal_shapes.dart`, `signal_painter.dart` y `level_icon.dart`.
  - Documentación: el delta del esquema del catálogo ([contrato §1](./contracts/counter-signal.md#1-catálogo-delta-sobre-specs001-motor-nivel1-frontalcontractscatalogschemajson)).
- **D2. Motor intacto.** Un solo tipo de respuesta no consume sorteo. El oráculo de prueba es que Nivel 4 ≡ Nivel 2 salvo `responseType` (R3).
- **D3. Geometría.** `Lc = min(L2, lane.width / 2.24)`. El sable a 90° mide ≈ 1.17 `Lc` de alto, está a 0.10 `Lc` de la punta y va centrado en el eje. El mínimo del 75 % se cumple por construcción (R4; [data-model §5](./data-model.md#5-geometría-de-la-señal-de-contraataque-presentación)).
- **D4. Refactor primero.** Antes de agregar el contraataque, se generaliza `defenseSaber`/`fitDefense` en `saber`/`fitSaber` y se extraen `_paintArrow`/`_paintSaber`. Las pruebas de pixeles existentes deben pasar sin cambios: es la garantía de FR-020 (R5, R6).
- **D5. Ícono.** Líneas, flecha y sable vertical, en blanco y en una celda (R7; [contrato selection-ui §2](./contracts/selection-ui.md#2-leveliconpainter)).
- **D6. Selección y HUD sin código nuevo.** La densidad de la Spec 006 ya cubre 4 niveles. Solo se amplían las pruebas al catálogo real (R8).
- **D7. Fuera del plan.** Alinear el texto del nivel en `docs/brief.md` y `docs/000-haidonggumdo-v010.md` ("Evasión y contraataque") queda como tarea de documentación opcional al cerrar la spec.

## Project Structure

### Documentation (this feature)

```text
specs/007-nivel4-contraataque/
├── spec.md
├── plan.md                    # Este archivo
├── research.md                # Phase 0 (R1–R9)
├── data-model.md              # Phase 1
├── quickstart.md              # Phase 1
├── contracts/
│   ├── counter-signal.md      # Tipo counter, colocación, geometría y pintado
│   └── selection-ui.md        # Tarjeta, ícono y HUD del Nivel 4
├── checklists/requirements.md
└── tasks.md                   # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
assets/catalog/catalog.json                     # + level_4 (responseTypes: ["counter"])
lib/domain/
├── catalog/enums.dart                          # + ResponseType.counter
└── exercise/signal.dart                        # + rama counter → attack.side
lib/presentation/
├── exercise/painters/
│   ├── signal_shapes.dart                      # defenseSaber/fitDefense → saber/fitSaber(angleDegrees); + counterAngleDegrees
│   └── signal_painter.dart                     # + _paintCounter; _paintArrow/_paintSaber compartidos
└── selection/level_icon.dart                   # + glifo counter
test/
├── domain/
│   ├── signal_placement_test.dart              # + counter
│   ├── exercise_engine_level4_test.dart        # + todo counter, ≡ Nivel 2, rachas y proporciones
│   ├── exercise_engine_{timeline,motion,simulation}_test.dart  # + grupos del Nivel 4
│   └── fakes/test_session.dart                 # + testLevel4Session / testLevel4TransversalSession
├── data/catalog_json_mapper_test.dart          # 4 niveles + level_4
└── presentation/
    ├── signal_painter_test.dart                # + P1–P7 en 7 lienzos
    ├── level_icon_test.dart                    # + I1–I3
    ├── selection_screen_test.dart              # + catálogo real de 4 niveles
    └── exercise_screen_test.dart               # + Nivel 4: una señal por ataque, HUD
```

**Structure Decision**: Es el mismo proyecto Flutter con capas `domain`, `data` y `presentation`. No hay directorios nuevos.

## Complexity Tracking

| Excepción (III, 1.1.0) | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| **Principio III, excepción (a)**: el Nivel 4 introduce el tipo de señal `counter`, lo que agrega un valor al enum y una rama de colocación en el dominio | FR-006 a FR-008 piden una señal distinta de las existentes (flecha + sable vertical) del lado del color. El catálogo puede nombrar el tipo, pero el dominio decide dónde va cada señal (`SignalPlacement`) | *Reutilizar `evasion` y decidir el dibujo en presentación según el nivel*: rompe "datos sobre código", porque presentación dependería del id del nivel. *Mostrar `evasion` + `defense` a la vez*: el dominio entrega una sola señal por ataque, la defensa va del lado contrario y su sable va inclinado |
