---

description: "Task list for Spec 003: Nivel 2, señal de evasión"
---

# Tasks: Nivel 2, señal de evasión

**Input**: Design documents from `specs/003-nivel2-evasion/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/catalog-and-signal.md](./contracts/catalog-and-signal.md), [quickstart.md](./quickstart.md)

**Tests**: Incluidas. El Principio VI de la constitution las exige para el dominio antes de cerrar cada historia, y el plan (research R6) las detalla. Se escriben **después del código**, derivadas de los criterios de aceptación.

**Organization**: El código de producción (enum, colocación, flecha, catálogo) es el mismo para las tres historias, así que va en la fase Foundational. Cada fase de historia agrega las pruebas y la validación manual que la cierran de forma independiente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia de usuario a la que pertenece (US1, US2, US3)

## Path Conventions

Proyecto Flutter único: `lib/`, `test/` y `assets/` en la raíz del repositorio (estructura de la Spec 001).

---

## Phase 1: Setup

**Purpose**: Confirmar la línea base antes de tocar código.

- [ ] T001 Desde la raíz del repo, en la rama `003-nivel2-evasion`, ejecutar `flutter analyze` y `flutter test` y confirmar que todo pasa sin cambios (línea base de las Specs 001 y 002, SC-007). Si algo falla, detenerse y reportarlo antes de seguir.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: El tipo de señal nuevo, su colocación, su dibujo y la entrada del Nivel 2 en el catálogo. Todas las historias dependen de esto.

**⚠️ CRITICAL**: T002, T003 y T005 deben terminarse juntos para que compile: agregar el valor al enum vuelve no exhaustivos los `switch` de `signal.dart` y `signal_painter.dart`.

- [ ] T002 Agregar el valor `evasion` a `enum ResponseType { defense }` en `lib/domain/catalog/enums.dart` (queda `{ defense, evasion }`). Reescribir el comentario del enum: `evasion` se agregó en la Spec 003 y `counter` se agregará en la Spec 006 (excepción del Principio III: tipo de señal nuevo). No tocar `VoiceCommand`.
- [ ] T003 En `SignalPlacement.forAttack` de `lib/domain/exercise/signal.dart`, agregar la rama `ResponseType.evasion => Signal(responseType: attack.responseType, screenSide: attack.side)` con el comentario "Evasión: la señal va del lado del color del sable, contrario a la defensa (FR-006)". La rama `defense` (`attack.side.opposite`) no cambia. `Signal` no cambia de forma ni gana color (data-model: "La señal no lleva color").
- [ ] T004 [P] En `lib/presentation/exercise/painters/opponent_painter.dart`, exponer la unidad del oponente como constante pública `static const unitFraction = 0.27;` en `OpponentPainter`, con doc "unidad u = 0.27 × alto del lienzo", y usarla en `final unit = size.height * unitFraction;` (hoy literal `0.27`, línea 42). Cambio solo de visibilidad, sin cambio de comportamiento (plan D4).
- [ ] T005 En `lib/presentation/exercise/painters/signal_painter.dart` (depende de T002 y T004):
  - Cambiar el constructor a `const SignalPainter({required this.signal, required this.saberColor})` con el campo `final SaberColor saberColor;` (importar `domain/exercise/exercise_snapshot.dart`).
  - `shouldRepaint`: `oldDelegate.signal != signal || oldDelegate.saberColor != saberColor`.
  - En `paint`, agregar `case ResponseType.evasion: _paintEvasionArrow(canvas, size);`. `_paintDefenseSaber` no cambia e ignora `saberColor` (sigue `AppColors.saberWhite`).
  - Agregar la constante pública `static const opponentClearanceUnits = 1.45;` (alcance del oponente en unidades `u`: mayor `|x|` del catálogo, 1.3 u, más 0.15 u de margen de hoja y contorno).
  - Implementar `_paintEvasionArrow` con la geometría de data-model.md, siendo `w × h` el lienzo y `u = OpponentPainter.unitFraction × h`:
    - Alcance del oponente: "1.45 u desde el centro"; ningún píxel a menos de `opponentClearanceUnits × u` de `w / 2`.
    - Borde exterior: "4 % del ancho desde el borde de la pantalla".
    - Largo `L`: "`min(0.36 h, tramo entre el alcance y el borde exterior)`, anclado al borde exterior".
    - Punta: "`0.42 L` de largo, `0.62 L` de alto", apuntando al borde exterior de la mitad `signal.screenSide`.
    - Cuerpo: "`0.24 L` de alto" (rectángulo entre el extremo interior y la base de la punta).
    - Centro vertical: "`h / 2`".
    - Relleno: `SaberColor.blue → AppColors.saberBlue`, `SaberColor.red → AppColors.saberRed`; para `white`/`yellow` (no ocurre con señal visible) usar `assert(false)` y no dibujar.
    - Contorno: "`AppColors.outline`, `kOutlineWidth`", con `StrokeJoin.round` como el símbolo de defensa.
    - La flecha izquierda es el reflejo exacto en `x` de la derecha (construir la derecha y reflejar con `x → w − x`).
  - Actualizar el doc de la clase para mencionar la Spec 003 (FR-006 a FR-009).
- [ ] T006 En `lib/presentation/exercise/exercise_screen.dart` (línea ~96), pasar el color del snapshot: `SignalPainter(signal: signal, saberColor: snapshot.saberColor)`, el mismo valor que ya recibe `OpponentPainter` (research R3). Depende de T005.
- [ ] T007 [P] En `assets/catalog/catalog.json`, agregar en `levels`, después de `level_1`, la entrada exacta del contrato: `{ "id": "level_2", "order": 2, "name": "Nivel 2", "responseLabel": "Evasión lateral", "purpose": "Calentamiento / base", "responseTypes": ["evasion"] }`. No tocar `glossary`, `voiceCommands` ni `patterns` (FR-003).
- [ ] T008 Ajustar `test/data/catalog_json_mapper_test.dart` (depende de T002 y T007; cambio de datos, no de lógica, plan D5):
  - Prueba (a) del catálogo real (línea ~76): esperar `hasLength(2)`, orden `['level_1', 'level_2']`, y buscar cada nivel por `id` en lugar de `levels.single`; `level_1` sigue con `[ResponseType.defense]`.
  - Grupo nuevo "Nivel 2 (Spec 003)": `level_2` con `order` 2, `name` "Nivel 2", `responseLabel` "Evasión lateral", `purpose` "Calentamiento / base" y `responseTypes` `[ResponseType.evasion]` (FR-001).
  - Grupo (e): la prueba `'con "evasion" (no existe en Spec 001)'` deja de ser válida; cambiarla a un nombre inexistente (`'counter'`, que llega en la Spec 006) y renombrarla `'con "counter" (desconocido)'`. Agregar una prueba que `['evasion']` se acepta.
- [ ] T009 [P] En `test/domain/fakes/test_session.dart`, agregar `Session testLevel2Session()` (Nivel 2 + Patrón frontal) y `Session testLevel2TransversalSession()` (Nivel 2 + Patrón transversal), reutilizando `testSession().pattern` y `testTransversalSession().pattern` sin cambiarlos, con `Level(id: 'level_2', order: 2, name: 'Nivel 2', responseLabel: 'Evasión lateral', purpose: 'Calentamiento / base', responseTypes: [ResponseType.evasion])`.
- [ ] T010 [P] En `test/domain/signal_placement_test.dart`, agregar pruebas de evasión (contrato §2): `Attack(side: right, evasion)` → `Signal(evasion, screenSide: right)`; `Attack(side: left, evasion)` → `screenSide: left`; para un mismo ataque, la señal de evasión y la de defensa quedan en lados opuestos. Las pruebas de defensa existentes no cambian.

**Checkpoint**: `flutter analyze` y `flutter test` pasan; el Nivel 2 ya aparece en la selección y se puede jugar con los dos patrones.

---

## Phase 3: User Story 1 - Evasión lateral ante el corte transversal (Priority: P1) 🎯 MVP

**Goal**: Nivel 2 + Patrón transversal: flecha del color del sable del lado del color, corte desde el costado contrario, flecha legible durante todo el barrido.

**Independent Test**: Elegir Nivel 2 + Transversal, iniciar con valores por defecto y observar desde 3 m: color y lado de la flecha en cada ataque, corte desde el costado contrario, tiempos y cierre con *Guman* (quickstart §2 pasos 2–5).

### Tests for User Story 1

- [ ] T011 [P] [US1] Crear `test/presentation/signal_painter_test.dart`, renderizando a imagen con `PictureRecorder` → `toImage` → `toByteData` como en `test/presentation/opponent_painter_test.dart` (sin goldens, research R6). Para `Signal(evasion, right)` con `SaberColor.blue` y `Signal(evasion, left)` con `SaberColor.red`, en lienzos 20:9, 16:9, 16:10 y 4:3 (p. ej. 2000×900, 1600×900, 1600×1000, 1200×900):
  - Todos los píxeles pintados están en la mitad `screenSide` y ninguno a menos de `SignalPainter.opponentClearanceUnits × OpponentPainter.unitFraction × h` del centro horizontal (FR-007).
  - Ninguno a menos del 4 % del ancho del borde.
  - El píxel central de la flecha tiene `AppColors.saberBlue` / `AppColors.saberRed` según `saberColor` (FR-008).
  - La punta apunta al borde exterior: la columna pintada más cercana al borde es más angosta que la columna en la base de la punta, y la columna más alta está del lado exterior respecto del cuerpo.
  - El largo pintado es `min(0.36 h, tramo)` con tolerancia de contorno.
  - Las imágenes izquierda y derecha son reflejos exactos en `x` (comparando máscaras de píxeles pintados).
  - Defensa: con `SaberColor.blue` y `SaberColor.red` el símbolo sigue blanco (sin píxeles azules ni rojos) y en el mismo lado que antes (FR-012).
  - `shouldRepaint` es `true` si cambia `saberColor` o `signal`, `false` si no cambia nada.
- [ ] T012 [US1] En `test/presentation/signal_painter_test.dart` (después de T011, mismo archivo), agregar la prueba de alcance contra el catálogo real: cargar `assets/catalog/catalog.json` con el mapper, recorrer todos los puntos de las poses y movimientos de todos los patrones y comprobar que `max |x| + 0.15 ≤ SignalPainter.opponentClearanceUnits` (research R4/R6).
- [ ] T013 [P] [US1] En `test/domain/exercise_engine_timeline_test.dart`, agregar un grupo "Nivel 2 transversal" con `testLevel2TransversalSession()` y los fakes existentes (`ManualClock`, `ScriptedRandomSource`): cada ataque tiene `responseType == ResponseType.evasion`; desde `signalAt` hasta `cutEndAt` el snapshot tiene `Signal(evasion, screenSide: attack.side)` (azul → `right`, rojo → `left`) y `saberColor` coherente con el lado; después de `cutEndAt` no hay señal y el sable vuelve a amarillo; los instantes (0.7 s de aviso, 0.5 s de corte) son iguales a los del Nivel 1 (US1-1, US1-2, US1-4, FR-009).
- [ ] T014 [P] [US1] En `test/domain/exercise_engine_motion_test.dart`, agregar una prueba: con la misma secuencia de `ScriptedRandomSource` y los mismos instantes de `ManualClock`, `testTransversalSession()` (Nivel 1) y `testLevel2TransversalSession()` producen poses del oponente idénticas en cada fotograma; con azul, *Sodose* y el inicio del corte quedan en el costado izquierdo de la pantalla, es decir, contrario a `signal.screenSide` (FR-010, US1-3, SC-003).
- [ ] T015 [P] [US1] En `test/domain/exercise_engine_simulation_test.dart`, parametrizar las simulaciones de aleatoriedad, máximo de N y tiempos de la 001 (SC-003 a SC-006 de la 001) para que también corran con `testLevel2TransversalSession()` y comprobar los mismos criterios; la regla de N se aplica a los lados (SC-006). Las expectativas existentes del Nivel 1 no cambian.
- [ ] T016 [US1] En `test/presentation/exercise_screen_test.dart`, agregar una prueba de widget con una sesión de Nivel 2 + Transversal: durante el aviso, el `CustomPaint` de la señal usa un `SignalPainter` con `signal.responseType == evasion` y `saberColor` igual al que recibe el `OpponentPainter`; no se dibuja ningún símbolo de defensa; tras el corte no hay `SignalPainter` (FR-009, caso límite "color de la flecha y del sable").

### Validation for User Story 1

- [ ] T017 [US1] Validación manual en dispositivo según `specs/003-nivel2-evasion/quickstart.md` §2 pasos 2–5 (y paso 5 en 4:3 o 16:10 si hay dispositivo), y §3.1 (SC-004) con el Patrón transversal, incluido el final del barrido. Si SC-004 falla, aplicar solo los ajustes de painter previstos en plan D6 / research R4–R5 en `lib/presentation/exercise/painters/signal_painter.dart` y repetir T011.

**Checkpoint**: US1 completa y validada: el MVP del Nivel 2 funciona con el Patrón transversal.

---

## Phase 4: User Story 2 - Evasión lateral ante el corte frontal (Priority: P2)

**Goal**: Nivel 2 + Patrón frontal: flecha del color del sable; el oponente se mueve exactamente como en el Nivel 1 frontal.

**Independent Test**: Elegir Nivel 2 + Frontal, iniciar con valores por defecto y comprobar color y lado de la flecha en cada ataque, y que el oponente sube a *Chochôn-se* y corta igual que en el Nivel 1 (quickstart §2 paso 7).

### Tests for User Story 2

- [ ] T018 [P] [US2] En `test/domain/exercise_engine_timeline_test.dart`, agregar un grupo "Nivel 2 frontal" con `testLevel2Session()`: ataques `evasion`, señal `Signal(evasion, screenSide: attack.side)` desde `signalAt` hasta `cutEndAt`, azul → `right`, rojo → `left` (US2-1).
- [ ] T019 [P] [US2] En `test/domain/exercise_engine_motion_test.dart`, agregar una prueba: con la misma secuencia aleatoria y los mismos instantes, `testSession()` (Nivel 1 frontal) y `testLevel2Session()` producen poses idénticas (*Chayôn-se* → *Chochôn-se* → *Chungmyôn begi* → *Chayôn-se*), y las poses no dependen del lado (US2-2, FR-002).
- [ ] T020 [P] [US2] En `test/domain/exercise_engine_simulation_test.dart`, extender la parametrización de T015 para que las simulaciones también corran con `testLevel2Session()` (SC-006). Si T015 ya parametrizó por sesión, basta con agregar la sesión a la lista.

### Validation for User Story 2

- [ ] T021 [US2] Validación manual según `specs/003-nivel2-evasion/quickstart.md` §2 paso 7 y §3.1 (SC-004) con el Patrón frontal.

**Checkpoint**: US1 y US2 funcionan; el Nivel 2 se juega con los dos patrones.

---

## Phase 5: User Story 3 - Elegir entre los dos niveles (Priority: P3)

**Goal**: La selección lista Nivel 1 y Nivel 2 desde el catálogo, con el Nivel 1 preseleccionado; Repetir conserva nivel y patrón; Volver permite cambiar de nivel.

**Independent Test**: Abrir la app, ver los dos niveles, iniciar cada combinación, usar Repetir y Volver (quickstart §2 pasos 1, 6, 8, 9).

### Tests for User Story 3

- [ ] T022 [P] [US3] En `test/presentation/selection_screen_test.dart`, agregar pruebas con un catálogo de dos niveles (el `_FakeRepository` existente con los niveles del catálogo real, o el asset real si el archivo ya lo carga): la lista "Nivel" muestra "Nivel 1" y "Nivel 2" en ese orden; el Nivel 1 está preseleccionado y el patrón Frontal también; el Nivel 2 muestra el subtítulo "Evasión lateral — Calentamiento / base"; elegir Nivel 2 + Transversal y pulsar Iniciar abre el ejercicio con una sesión cuyo `level.id == 'level_2'` y `pattern.id == 'transversal'` (US3-1, US3-2, FR-004, FR-005, SC-001: tres acciones).
- [ ] T023 [P] [US3] En `test/presentation/exercise_screen_test.dart` (después de T016 si se trabaja en el mismo archivo), agregar: al terminar un ejercicio de Nivel 2 + Frontal, Repetir inicia uno nuevo con el mismo nivel y patrón; Volver regresa a la selección, donde se puede elegir el Nivel 1 e iniciar un ejercicio que muestra `SignalPainter` con `ResponseType.defense` (US3-2, US3-3, FR-012). Detener con una flecha visible vuelve a la selección sin voz de fin (`FakeVoiceAnnouncer`).

### Validation for User Story 3

- [ ] T024 [US3] Validación manual según `specs/003-nivel2-evasion/quickstart.md` §2 pasos 1, 6, 8 y 9.

**Checkpoint**: Las tres historias funcionan de forma independiente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verificar el alcance del cambio (Principio III, SC-007) y la distinción defensa/evasión a 3 m.

- [ ] T025 Ejecutar `flutter analyze` y `flutter test` desde la raíz; todo debe pasar.
- [ ] T026 Ejecutar `git diff --stat main -- lib` y confirmar que solo cambian `lib/domain/catalog/enums.dart`, `lib/domain/exercise/signal.dart`, `lib/presentation/exercise/painters/signal_painter.dart`, `lib/presentation/exercise/painters/opponent_painter.dart` y `lib/presentation/exercise/exercise_screen.dart` (FR-002, SC-007). Ejecutar `git diff main -- test` y confirmar que en las pruebas de las Specs 001 y 002 solo cambiaron las expectativas de datos del catálogo (T008: prueba (a) y nombre desconocido en (e)), no las de la lógica del ejercicio.
- [ ] T027 Prueba manual SC-005 a 3 m según `specs/003-nivel2-evasion/quickstart.md` §3.2 (alternar Nivel 1 y Nivel 2 sin anunciar; criterio: 2 de 3 observadores aciertan "defender"/"evadir" en ≥ 95 % de los ataques), y §4 (tiempos grabados a 60 fps iguales a los del Nivel 1). Registrar el resultado en la descripción del PR.
- [ ] T028 Si quedó pendiente, comunicar al responsable la nota de plan.md "Notas para la spec" (el centro horizontal de la flecha cae entre el 85 % y el 88 % del ancho, no en el 82 % del símbolo de defensa) en la descripción del PR.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias.
- **Foundational (Phase 2)**: depende de T001. Bloquea todas las historias.
- **US1, US2, US3 (Phases 3–5)**: dependen solo de Phase 2. Son independientes entre sí, con una salvedad de archivos compartidos (abajo).
- **Polish (Phase 6)**: depende de las historias que se vayan a entregar.

### Within Phase 2

- T002 → T003 y T005 (compilación conjunta; ver aviso de la fase).
- T004 → T005 → T006.
- T002 + T007 → T008.
- T002 → T009, T010.
- T004 y T007 pueden empezar en paralelo con T002.

### User Story Dependencies

- **US1 (P1)**: tras Phase 2. Ninguna dependencia de otras historias.
- **US2 (P2)**: tras Phase 2. T020 extiende la parametrización de T015; si US2 se hace antes que US1, T020 crea la parametrización.
- **US3 (P3)**: tras Phase 2. Ninguna dependencia de otras historias.

### Archivos compartidos entre historias

Las historias son independientes en comportamiento, pero algunas tareas tocan el mismo archivo y no deben editarse a la vez:

- `test/domain/exercise_engine_timeline_test.dart`: T013 (US1) y T018 (US2).
- `test/domain/exercise_engine_motion_test.dart`: T014 (US1) y T019 (US2).
- `test/domain/exercise_engine_simulation_test.dart`: T015 (US1) y T020 (US2).
- `test/presentation/exercise_screen_test.dart`: T016 (US1) y T023 (US3).
- `test/presentation/signal_painter_test.dart`: T011 → T012.

### Parallel Opportunities

- Phase 2: T004, T007 en paralelo con T002; después T009 y T010 en paralelo con T005/T006.
- US1: T011, T013, T014 y T015 en paralelo (archivos distintos).
- US2: T018, T019 y T020 en paralelo entre sí (pero no con sus pares de US1).
- US3: T022 y T023 en paralelo.

---

## Parallel Example: User Story 1

```bash
# Tras la Phase 2, lanzar juntas las pruebas de US1 (archivos distintos):
Task: "T011 Pruebas de píxeles de la flecha en test/presentation/signal_painter_test.dart"
Task: "T013 Grupo Nivel 2 transversal en test/domain/exercise_engine_timeline_test.dart"
Task: "T014 Poses idénticas Nivel 1 vs Nivel 2 transversal en test/domain/exercise_engine_motion_test.dart"
Task: "T015 Simulaciones con el Nivel 2 transversal en test/domain/exercise_engine_simulation_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: línea base verde.
2. Phase 2: enum, colocación, flecha, catálogo y ajustes de pruebas de datos.
3. Phase 3: pruebas de US1 y validación manual del transversal.
4. **STOP and VALIDATE**: `flutter test` verde y quickstart §2 pasos 2–5.

### Incremental Delivery

1. Setup + Foundational → el Nivel 2 ya es jugable.
2. US1 → transversal probado y validado a 3 m (MVP).
3. US2 → frontal probado y validado.
4. US3 → selección, Repetir y Volver probados.
5. Polish → alcance del diff, SC-005 y PR a `main`.

---

## Notes

- [P] = archivos distintos, sin dependencias pendientes.
- Las pruebas van después del código (Principio VI), pero deben pasar antes de cerrar cada historia.
- Commits con Conventional Commits (p. ej. `feat: add level 2 evasion signal`, `test: cover level 2 evasion`) en la rama `003-nivel2-evasion`.
- No cambiar `ExerciseEngine`, `SideSequencer`, `OpponentMotion`, los datos de los patrones, el mapper ni la pantalla de selección (FR-002, research R1). Si una tarea parece requerirlo, detenerse y consultarlo.
