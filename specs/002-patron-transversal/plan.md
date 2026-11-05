# Implementation Plan: Patrón transversal

**Branch**: `002-patron-transversal` | **Date**: 2026-11-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-patron-transversal/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Agregar el Patrón transversal (guardia en *Chayôn-se*, ataque desde *Sodose*, corte *Hwengdan ilgôm begi*), jugable con el Nivel 1, **solo con datos en el catálogo** (FR-002, Principio III). El corte horizontal se expresa con el `CutMotion` de la 001 (interpolación lineal de empuñadura y punta entre *Sodose* y el impacto) con `mirroredBySide: true`. El costado de *Sodose* y del corte sigue el lado del ataque: izquierda de la pantalla con azul y derecha con rojo, que es el lado del símbolo de defensa.

Un prototipo con el painter actual confirmó que las posiciones elegidas se leen como un corte horizontal que llega por el lado de la defensa, sin tocar `lib/` (research R1). El trabajo es agregar las entradas del catálogo, ajustar las pruebas que cuentan el contenido del catálogo real y agregar pruebas del patrón nuevo. Después se valida a 3 m.

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable), sin cambios respecto de la 001

**Primary Dependencies**: `flutter_riverpod`, `flutter_tts`, `wakelock_plus` (ADR 0001–0003); gráficos con `CustomPainter` (ADR 0004). Sin paquetes nuevos.

**Storage**: Ninguno. Solo cambia el asset de solo lectura `assets/catalog/catalog.json`.

**Testing**: `flutter_test` con los fakes de la 001 (`ManualClock`, `ScriptedRandomSource`, `SeededRandomSource`, `FakeVoiceAnnouncer`, `FakeScreenWakeLock`).

**Target Platform**: Android (teléfonos y tablets), solo horizontal.

**Project Type**: mobile-app (el mismo proyecto Flutter de la 001)

**Performance Goals**: Los de la 001: 60 fps y tiempos con desviación menor a 50 ms (SC-005).

**Constraints**: FR-002 y SC-007: ningún cambio en la lógica del ejercicio ni en las pantallas (`lib/`). Legibilidad a 3 m (FR-009). Términos exactos del glosario (FR-003).

**Scale/Scope**: 2 entradas de glosario y 1 patrón en el catálogo; pruebas de datos y de selección; validación manual a 3 m.

No hay incógnitas abiertas. La única duda de diseño (si el corte cabe en `CutMotion`) se resolvió en research R1.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Sin cambios de SDK | ✅ |
| II. Clean Architecture | No se toca ninguna capa; el dominio sigue en Dart puro | ✅ |
| III. Datos sobre código | El patrón nuevo usa un tipo de respuesta existente y entra **solo como datos** del catálogo; el esquema no cambia (research R8) | ✅ |
| IV. Persistencia | Sin persistencia nueva | ✅ |
| V. Gestión de estado | Riverpod, sin cambios | ✅ |
| VI. Pruebas | Pruebas del catálogo real y de la selección derivadas de FR-001–FR-005; pruebas de movimiento y simulación con una sesión transversal (FR-007, FR-010, SC-005, SC-006); las pruebas de lógica de la 001 siguen pasando | ✅ |
| VII. Dependencias | Ninguna nueva | ✅ |
| VIII. Interfaz | Contornos y legibilidad heredados; la punta vista de frente cubre el escorzo del impacto (research R4) | ✅ |
| IX. Idioma | Términos coreanos solo desde el glosario; *Sodose* sin hangul, como en el glosario (research R5) | ✅ |
| X. Flujo | Rama `002-patron-transversal` → PR a `main`; Conventional Commits | ✅ |
| XI. Seguridad | Sin cambios | ✅ |

**Resultado (antes de Phase 0)**: PASA, sin violaciones.
**Re-check después de Phase 1**: PASA. El diseño confirma que el cambio se limita al catálogo y a las pruebas. Ningún archivo de `lib/` cambia.

## Decisiones de diseño

- **D1. Solo datos.** Dos términos de glosario y un patrón en `assets/catalog/catalog.json`, con los valores de [data-model.md](./data-model.md) y el contrato de [contracts/catalog-entries.md](./contracts/catalog-entries.md). Sin cambios en el esquema, el mapper, el motor, los painters ni las pantallas (research R1, R8).
- **D2. Posiciones.** *Sodose*: `hilt (−0.45, 0.3)`, `tip (−1.25, 0.45)`. Impacto: `hilt (−0.1, −0.05)`, `tip (−0.3, −0.1)`. Guardia igual que el frontal. Valores base para el lado `right` (azul), reflejados con `left` (research R2, R3).
- **D3. El corte termina en el impacto**, con la hoja en escorzo hacia el flanco del usuario, igual que el frontal termina con la hoja apuntando al usuario. No cruza todo el frente (research R1).
- **D4. Pruebas del catálogo real.** El test (a) del mapper pasa a esperar 2 patrones y 7 términos y a buscar cada patrón por `id` en lugar de usar `patterns.single`. Es un cambio de datos, no de lógica (research R6).
- **D5. Validación visual.** Las posiciones se validan a 3 m (quickstart §3). Si hace falta ajustarlas, se cambian solo en el catálogo.

## Notas para la spec

- **SC-007** dice que las pruebas de la 001 siguen pasando "sin cambiar sus expectativas". Una prueba de la 001 cuenta el contenido del catálogo real (1 patrón, 5 términos) y tiene que cambiar al crecer el catálogo. Se recomienda precisar SC-007: "…sin cambiar sus expectativas sobre la lógica del ejercicio (tiempos, eventos, estados, señales y movimiento)". El plan aplica esa lectura (research R6).

## Project Structure

### Documentation (this feature)

```text
specs/002-patron-transversal/
├── spec.md
├── plan.md                  # Este archivo
├── research.md              # Phase 0
├── data-model.md            # Phase 1 (solo instancias nuevas)
├── quickstart.md            # Phase 1
├── contracts/
│   └── catalog-entries.md   # Entradas nuevas del catálogo; el esquema de la 001 no cambia
├── checklists/
│   └── requirements.md
└── tasks.md                 # Phase 2 (/speckit-tasks; no lo crea este comando)
```

### Source Code (repository root)

Solo se listan los archivos que cambian; el resto de la estructura es la de la 001 ([plan de la 001](../001-motor-nivel1-frontal/plan.md#source-code-repository-root)).

```text
assets/catalog/
└── catalog.json                         # + sodose, hwengdan_ilgom_begi, patrón transversal

test/
├── data/
│   └── catalog_json_mapper_test.dart    # (a): 2 patrones y 7 términos; patrón transversal por id
├── domain/
│   ├── fakes/
│   │   └── test_session.dart            # + sesión transversal para las pruebas de movimiento
│   ├── exercise_engine_motion_test.dart # + tramos y costado con una sesión transversal
│   └── exercise_engine_simulation_test.dart  # + simulación con una sesión transversal
└── presentation/
    ├── selection_screen_test.dart       # + dos patrones reales, preselección, elegir transversal
    └── opponent_painter_test.dart       # + pintar las posturas del transversal sin errores
```

`lib/` **no cambia** (FR-002, SC-007).

**Structure Decision**: El mismo proyecto Flutter de la 001, con carpetas por capa. Esta spec solo toca el asset del catálogo y las pruebas.

## Complexity Tracking

Sin violaciones de la constitution que justificar.
