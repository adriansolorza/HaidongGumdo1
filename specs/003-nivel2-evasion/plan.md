# Implementation Plan: Nivel 2, señal de evasión

**Branch**: `003-nivel2-evasion` | **Date**: 2026-11-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-nivel2-evasion/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Agregar el Nivel 2 (evasión lateral), jugable con los dos patrones. El nivel entra como **datos** en el catálogo, con `responseTypes: ["evasion"]`. La evasión es un **tipo de señal nuevo**, el único caso en que el Principio III admite tocar el dominio. El cambio en `lib/` se limita a:
- el valor `evasion` de `ResponseType`;
- su regla de colocación (la flecha va del lado del color: azul → derecha);
- el dibujo de la flecha en `SignalPainter`, que ahora recibe el color del sable para pintarla de azul o rojo.

El motor, los sorteos, la regla de N, los estados, el movimiento del oponente, los patrones, el mapper y la pantalla de selección no cambian (research R1). La flecha se coloca entre el alcance máximo del oponente y el borde, así que nunca se cruza con el final del barrido transversal en ninguna proporción de pantalla (research R4).

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable), sin cambios

**Primary Dependencies**: `flutter_riverpod`, `flutter_tts`, `wakelock_plus` (ADR 0001–0003); gráficos con `CustomPainter` (ADR 0004). Sin paquetes nuevos.

**Storage**: Ninguno. Solo cambia el asset de solo lectura `assets/catalog/catalog.json`.

**Testing**: `flutter_test` con los fakes de la 001 (`ManualClock`, `ScriptedRandomSource`, `SeededRandomSource`, `FakeVoiceAnnouncer`, `FakeScreenWakeLock`) y la comparación de píxeles de los painters de la 002.

**Target Platform**: Android (teléfonos y tablets), solo horizontal; proporciones de 4:3 a 20:9.

**Project Type**: mobile-app (el mismo proyecto Flutter de la 001)

**Performance Goals**: Los de la 001: 60 fps y tiempos con desviación menor a 50 ms.

**Constraints**:
- FR-002 y SC-007: sin cambios en tiempos, sorteos, N, estados, movimiento del oponente ni datos de patrones.
- FR-007: la flecha nunca se cruza con el oponente.
- FR-008: legibilidad a 3 m.
- FR-012: el Nivel 1 no cambia.

**Scale/Scope**: 1 nivel en el catálogo, 1 valor de enum, 1 rama de colocación, 1 dibujo nuevo y 1 parámetro del painter; pruebas de dominio, datos y presentación; validación manual a 3 m.

No hay incógnitas abiertas: las tres decisiones de diseño se resolvieron en research R1, R3 y R4.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Sin cambios de SDK | ✅ |
| II. Clean Architecture | El dominio solo gana un valor de enum y una rama de colocación, en Dart puro. El color de la flecha se resuelve en la presentación (research R3) | ✅ |
| III. Datos sobre código | El Nivel 2 entra como datos. El cambio de dominio se limita al tipo de señal nuevo, la excepción que el principio admite (research R1) | ✅ |
| IV. Persistencia | Sin persistencia nueva | ✅ |
| V. Gestión de estado | Riverpod, sin cambios | ✅ |
| VI. Pruebas | Pruebas de dominio para la colocación y el motor con el Nivel 2; simulaciones de aleatoriedad, N y tiempos con el Nivel 2 y los dos patrones (SC-006); pruebas de datos y presentación derivadas de FR-001 a FR-012 | ✅ |
| VII. Dependencias | Ninguna nueva | ✅ |
| VIII. Interfaz | La flecha tiene contorno definido, un contraste de relleno de 4.1:1 (azul) y 5.0:1 (rojo) y la misma orientación horizontal (research R5) | ✅ |
| IX. Idioma | El nombre, la respuesta y el propósito del nivel vienen del catálogo, en español; no hay términos coreanos nuevos | ✅ |
| X. Flujo | Rama `003-nivel2-evasion` → PR a `main`; Conventional Commits | ✅ |
| XI. Seguridad | Sin cambios | ✅ |

**Resultado (antes de Phase 0)**: PASA, sin violaciones.
**Re-check después de Phase 1**: PASA. El diseño confirma que los cambios en `lib/` son solo los del tipo de señal nuevo y el parámetro de color del painter.

## Decisiones de diseño

- **D1. Nivel 2 como datos.** Una entrada `level_2` en `assets/catalog/catalog.json` ([contrato](./contracts/catalog-and-signal.md#1-catálogo-assetscatalogcatalogjson)). El mapper, la selección y el motor la aceptan sin cambios (research R1).
- **D2. Tipo de señal nuevo.** `ResponseType.evasion` en `lib/domain/catalog/enums.dart` (se actualiza el comentario que la anunciaba). La regla de colocación en `SignalPlacement.forAttack` es `evasion → attack.side`, del lado contrario a la defensa (research R2).
- **D3. Color de la flecha.** `SignalPainter` recibe `saberColor` (el `SaberColor` del snapshot) y `ExerciseScreen` le pasa `snapshot.saberColor`. La flecha se pinta con ese color; la defensa lo ignora y sigue blanca (research R3).
- **D4. Geometría de la flecha.** Es horizontal, con cuerpo y punta, centrada en vertical y apuntando al borde. Ocupa el tramo entre `1.45 u` del centro y el 4 % del ancho desde el borde, con un largo máximo de `0.36 × alto` ([data-model.md](./data-model.md#geometría-de-la-flecha-presentación), research R4). La unidad del oponente (`0.27 × alto`) se expone como una constante pública de `OpponentPainter`, para que los dos painters compartan el mismo valor. Es un cambio de visibilidad sin cambio de comportamiento.
- **D5. Pruebas del catálogo real.** La prueba (a) del mapper pasa a esperar 2 niveles y a buscar cada nivel por `id` en lugar de usar `levels.single`. Es un cambio de datos, no de lógica (research R6, SC-007).
- **D6. Ajustes previstos tras el dojang.** Si SC-004 falla por contraste, se agrega un contorno claro a la flecha. Si falla en 4:3 por el largo, se sube la flecha sobre la línea de la cintura. Los dos ajustes son solo del painter (research R4, R5).

## Notas para la spec

- **FR-007** dice "centrada en su mitad". Con D4, el centro horizontal de la flecha queda entre el 85 % y el 88 % del ancho, no en el 82 % del símbolo de defensa, para no cruzarse con el barrido en pantallas 16:10 y 4:3. Es la lectura de "misma zona, cerca del borde" que cumple el resto de FR-007. No hace falta editar la spec, pero conviene que el responsable lo sepa.

## Project Structure

### Documentation (this feature)

```text
specs/003-nivel2-evasion/
├── spec.md
├── plan.md                        # Este archivo
├── research.md                    # Phase 0
├── data-model.md                  # Phase 1 (ResponseType, Signal, Nivel 2, geometría de la flecha)
├── quickstart.md                  # Phase 1
├── contracts/
│   └── catalog-and-signal.md      # Entrada del catálogo, colocación y dibujo de la señal
├── checklists/
│   └── requirements.md
└── tasks.md                       # Phase 2 (/speckit-tasks; no lo crea este comando)
```

### Source Code (repository root)

Solo se listan los archivos que cambian; el resto de la estructura es la de la 001 ([plan de la 001](../001-motor-nivel1-frontal/plan.md#source-code-repository-root)).

```text
assets/catalog/
└── catalog.json                              # + level_2 (evasion)

lib/
├── domain/
│   ├── catalog/enums.dart                    # + ResponseType.evasion
│   └── exercise/signal.dart                  # + rama evasion → attack.side
└── presentation/exercise/
    ├── exercise_screen.dart                  # pasa snapshot.saberColor a SignalPainter
    └── painters/
        ├── signal_painter.dart               # + saberColor; + flecha de evasión
        └── opponent_painter.dart             # unidad (0.27 × alto) como constante pública

test/
├── data/
│   └── catalog_json_mapper_test.dart         # (a): 2 niveles por id; + grupo del Nivel 2
├── domain/
│   ├── fakes/test_session.dart               # + sesiones de Nivel 2 (frontal y transversal)
│   ├── signal_placement_test.dart            # + evasión azul/rojo
│   ├── exercise_engine_timeline_test.dart    # + ataques evasion y señal del lado del color
│   └── exercise_engine_simulation_test.dart  # + simulaciones con el Nivel 2
└── presentation/
    ├── signal_painter_test.dart              # nuevo: lado, color, punta, alcance, reflejo, 4 proporciones
    ├── selection_screen_test.dart            # + dos niveles reales, preselección, elegir Nivel 2
    └── exercise_screen_test.dart             # + Repetir conserva el Nivel 2; Volver al Nivel 1
```

**Structure Decision**: El mismo proyecto Flutter de la 001, con carpetas por capa.

## Complexity Tracking

Sin violaciones de la constitution que justificar. El cambio de dominio es la excepción prevista por el Principio III (tipo de señal nuevo).
