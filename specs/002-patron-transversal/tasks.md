---
description: "Lista de tareas de la Spec 002: Patrón transversal"
---

# Tasks: Patrón transversal

**Input**: Documentos de diseño en `specs/002-patron-transversal/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/catalog-entries.md, quickstart.md. Base: el código y las pruebas de la Spec 001 (`specs/001-motor-nivel1-frontal/`).

**Tests**: SÍ se incluyen. La constitution (Principio VI) exige pruebas **derivadas de los criterios de aceptación** y escritas **después del cambio**. Aquí el cambio es solo de datos (plan.md D1), así que cada historia trae primero su cambio en el catálogo y después las pruebas que lo verifican.

**Organization**: Las tareas se agrupan por historia de usuario para implementar y probar cada una por separado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia a la que pertenece (US1, US2)
- Cada descripción incluye la ruta exacta del archivo

## Path Conventions

El mismo proyecto Flutter de la 001: `assets/catalog/`, `lib/` (dominio, datos y presentación) y `test/` reflejando las capas.

**Reglas generales para todas las tareas**:

- **`lib/` no cambia** (FR-002, SC-007, plan.md D1). Si una tarea parece exigir un cambio en `lib/`, detenerse y volver al plan.
- Los términos coreanos se escriben solo en el catálogo, exactamente como en el glosario de la spec (FR-003, Principios III y IX). En las pruebas solo aparecen para comparar.
- No agregar paquetes (Principio VII).
- Commits con Conventional Commits (`feat:` para el catálogo, `test:` para pruebas, `chore:`/`docs:`) en la rama `002-patron-transversal`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Partir de un estado conocido y en verde.

- [ ] T001 Comprobar el punto de partida en la rama `002-patron-transversal`: `flutter analyze` sin problemas y `flutter test` en verde (112 pruebas de la 001). Revisar `git status`: los archivos regenerados de plugins de escritorio (`macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`) no son parte de esta spec; no incluirlos en los commits de la 002 (consultar al responsable si se descartan con `git restore`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Las entradas del catálogo que ambas historias necesitan.

**⚠️ CRITICAL**: Ninguna historia puede empezar hasta terminar esta fase.

- [ ] T002 Agregar a `assets/catalog/catalog.json` exactamente las entradas de `specs/002-patron-transversal/contracts/catalog-entries.md` (data-model.md):
  - En `glossary`, después de `chungmyon_begi`: `sodose` ("Sodose", **sin `hangul`**, "Postura con el sable a un costado del cuerpo") y `hwengdan_ilgom_begi` ("Hwengdan ilgôm begi", "횡단일검베기", "Corte transversal")
  - En `patterns`, después de `frontal`: `transversal` con `order: 2`, `name: "Transversal"`, `guardTermId: "chayon_se"`, `stanceTermId: "sodose"`, `cutTermId: "hwengdan_ilgom_begi"`, `guard: {hilt: [0, 0.05], tip: [0, -0.3]}`, `cut: {start: {hilt: [-0.45, 0.3], tip: [-1.25, 0.45]}, end: {hilt: [-0.1, -0.05], tip: [-0.3, -0.1]}, mirroredBySide: true}`
  - Guardar en UTF-8 y comprobar carácter por carácter la romanización y el hangul contra el glosario de spec.md (FR-003). No modificar las entradas existentes
- [ ] T003 Ajustar la prueba (a) de `test/data/catalog_json_mapper_test.dart` al catálogo que crece (plan.md D4, research R6): `catalog.patterns` tiene longitud 2 y `catalog.glossary` longitud 7; agregar `sodose` (`hangul` nulo) y `hwengdan_ilgom_begi` ("Hwengdan ilgôm begi", "횡단일검베기") al mapa de términos esperados; reemplazar `catalog.patterns.single` por la búsqueda del patrón con `id == 'frontal'` y mantener todas sus comprobaciones actuales sin cambios (depende de T002)

**Checkpoint**: `flutter test` en verde y `git diff --stat main -- lib` vacío. El catálogo tiene los dos patrones.

---

## Phase 3: User Story 1 - Ejercicio de defensa ante el corte transversal (Priority: P1) 🎯 MVP

**Goal**: Un ejercicio de Nivel 1 con el Patrón transversal: guardia en _Chayôn-se_, _Sodose_ en el costado del corte (izquierda de la pantalla con azul, derecha con rojo), corte horizontal a la altura del torso que llega por el lado de la defensa, regreso a la guardia y todas las reglas de la 001.

**Independent Test**: Elegir Nivel 1 + Patrón transversal e iniciar con los valores por defecto (quickstart.md §2, pasos 2–6 y 9): _Sodose_ y el corte en el costado del símbolo de defensa, reflejados con el rojo, y tiempos y _Guman_ como en la 001.

### Implementación (US1)

La implementación es el patrón agregado al catálogo en T002 (plan.md D1). Esta historia no tiene tareas de código.

### Pruebas de US1 (derivadas de los CA, escritas después del cambio)

- [ ] T004 [P] [US1] Agregar `Session testTransversalSession()` en `test/domain/fakes/test_session.dart`, junto a `testSession()`, con el mismo nivel y un `Pattern` con los valores literales de data-model.md: `id: 'transversal'`, `order: 2`, `name: 'Transversal'`, `guardTermId: 'chayon_se'`, `stanceTermId: 'sodose'`, `cutTermId: 'hwengdan_ilgom_begi'`, `guard` `hilt (0, 0.05)` / `tip (0, −0.3)`, `cut.start` `hilt (−0.45, 0.3)` / `tip (−1.25, 0.45)`, `cut.end` `hilt (−0.1, −0.05)` / `tip (−0.3, −0.1)`, `mirroredBySide: true`. Las pruebas del dominio no leen el asset
- [ ] T005 [US1] Agregar a `test/data/catalog_json_mapper_test.dart` un grupo "Patrón transversal (Spec 002)" sobre el asset real (depende de T003; mismo archivo): (a) el patrón con `id == 'transversal'` es el segundo de `catalog.patterns` y tiene los términos `chayon_se`, `sodose` y `hwengdan_ilgom_begi`, y la `guard`, `cut.start`, `cut.end` y `mirroredBySide: true` de data-model.md (FR-001, FR-007, FR-008); (b) su `guard` es igual a la del patrón `frontal` (FR-006); (c) el costado base es el izquierdo de la pantalla: `cut.start.hilt.x < 0`, `cut.start.tip.x < cut.start.hilt.x` y `cut.end.tip.x < 0` (FR-007, research R3); (d) `catalog.term('sodose').hangul` es `null` (FR-003)
- [ ] T006 [P] [US1] Agregar a `test/domain/exercise_engine_motion_test.dart` un grupo "Patrón transversal (Spec 002)" que repita con `testTransversalSession()` las comprobaciones de tramos con los valores por defecto (depende de T004; FR-007, FR-010): subida `guard → stance` con progreso 0 en 4.0 s y 0.5 en 4.175 s; `stance → stance` de 4.35 s a 4.7 s; corte `stance → cutEnd` con `progress == cutProgress`; regreso `cutEnd → guard` con progreso 0.5 en 5.45 s y `atGuard` desde 5.7 s (guion `_script(first: 0, intervals: [1500])`, como en el grupo "un ataque con los valores por defecto" de la 001: la señal siguiente llega en 7.2 s), y el lado del regreso igual al del ataque. Agregar un parámetro opcional de sesión al helper `_engine` en lugar de duplicarlo
- [ ] T007 [P] [US1] En `test/domain/exercise_engine_simulation_test.dart`, agregar un parámetro opcional `Session session` a `_simulate` (por defecto `testSession()`) y un grupo "Patrón transversal (Spec 002)" que, con 1 000 ejercicios de 180 s de `testTransversalSession()` (semillas 0–999), compruebe lo mismo que SC-003 a SC-006 de la 001: rachas ≤ 5 con N = 5, alternancia con N = 1, proporción de `right` en 50 % ± 5 % sobre al menos 10 000 ataques, ninguna secuencia completa de lados repetida entre los 1 000 ejercicios, intervalos en [1000 ms, 2500 ms] y _Guman_ entre E y E + 1200 ms (depende de T004; SC-005, SC-006 de la 002)
- [ ] T008 [P] [US1] Agregar a `test/presentation/opponent_painter_test.dart` un grupo "Patrón transversal (Spec 002)" con `testTransversalSession().pattern` (depende de T004; FR-009, research R4): `OpponentPainter.tipDiameter` vale 0 con la longitud de _Sodose_ (≈ 0.81 u) y ≈ 0.297 u con la del impacto (≈ 0.206 u), calculadas a partir de `cut.start` y `cut.end`; pintar en un `Canvas` de 1600×900 cada `PoseKey` y cada tramo con `side` `right` y `left` no lanza. Además (FR-007, FR-011, SC-002), dibujar _Sodose_ (`stance → stance`) y el impacto (`cutEnd → cutEnd`) en una imagen de 1600×900 con el **mismo** `SaberColor` (p. ej. azul) y `side` `right` y `left`, y leer los píxeles con `toByteData`: (a) **costado**: con `right`, al menos el 95 % de los píxeles del color del sable están en la mitad izquierda; con `left`, en la mitad derecha; (b) **reflejo**: la imagen `left` volteada en horizontal coincide con la imagen `right` en al menos el 99 % de los píxeles, con una tolerancia de ±8 por canal para el antialiasing. Sin archivos de imagen de referencia ni paquetes nuevos

**Checkpoint**: `flutter test` en verde y `git diff --stat main -- lib` vacío. El ejercicio transversal se puede jugar eligiéndolo en la selección.

---

## Phase 4: User Story 2 - Elegir entre los dos patrones (Priority: P2)

**Goal**: La selección muestra el frontal (preseleccionado) y el transversal con sus tres términos. La sesión elegida se mantiene con Repetir y se puede cambiar al volver.

**Independent Test**: quickstart.md §2, pasos 1, 7 y 8: los dos patrones en la lista, Repetir conserva el transversal, y Volver permite iniciar un frontal sin reiniciar la app.

### Implementación (US2)

La lista sale del catálogo (T002) y la pantalla de la 001 ya muestra un término sin hangul solo con la romanización (research R5). Esta historia no tiene tareas de código.

### Pruebas de US2

- [ ] T009 [P] [US2] Agregar a `test/presentation/selection_screen_test.dart`, con el catálogo real (`_realCatalog`), una prueba "dos patrones reales (Spec 002)" (FR-004, US2 escenario 1): se ven "Frontal" y "Transversal", con "Frontal" arriba y preseleccionado; se ve exactamente una vez el texto "Chayôn-se (자연세) → Sodose → Hwengdan ilgôm begi (횡단일검베기)"; al tocar "Transversal" queda seleccionado, y al pulsar Iniciar se abre `ExerciseScreen` cuya `session.pattern.id` es `'transversal'`. La prueba existente del catálogo real (texto del frontal) no cambia
- [ ] T010 [P] [US2] Agregar a `test/presentation/exercise_screen_test.dart` una prueba "(g) Repetir conserva el transversal y Volver permite elegir el frontal (Spec 002)" (FR-005, US2 escenarios 2 y 3): con el harness existente, antes de pulsar Iniciar tocar "Transversal" (agregar a `_Harness.start` un parámetro opcional `String? pattern` en lugar de duplicar el harness); avanzar hasta `_finishedAt`; pulsar Repetir y comprobar que la `ExerciseScreen` visible tiene `session.pattern.id == 'transversal'`; terminar de nuevo, pulsar Volver, tocar "Frontal", Iniciar y comprobar que la `session.pattern.id` es `'frontal'`. Las pruebas (a)–(f) no cambian

**Checkpoint**: `flutter test` en verde. US1 y US2 funcionan juntas.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Comprobar el Principio III y la calidad, y validar a mano.

- [ ] T011 Verificar FR-002 y SC-007: `git diff --stat main -- lib` no lista archivos, y una búsqueda en UTF-8 de `Sodose|Hwengdan|횡단일검베기` en `lib/` no encuentra nada fuera de comentarios (Principios III y IX). Si algo aparece, moverlo al catálogo o volver al plan
- [ ] T012 Ejecutar `flutter analyze` (cero problemas) y `dart format --output=none --set-exit-if-changed lib test`; corregir lo que aparezca en `test/`
- [ ] T013 Ejecutar `flutter test` completo y `flutter build apk --release`; confirmar ambos en verde (el aviso de `flutter_tts` sobre el plugin de Kotlin de Gradle ya es conocido desde la 001)
- [ ] T014 _(Manual, la hace el responsable)_ Validar en un dispositivo Android real los pasos 1–9 de `specs/002-patron-transversal/quickstart.md` §2 y anotar el resultado (fecha, dispositivo, versión de Android, ✅/❌ por paso) en una sección "Resultados de validación" al final de ese archivo
- [ ] T015 _(Manual, la hace el responsable)_ Ejecutar las pruebas a 3 m de quickstart.md §3 (legibilidad, SC-003; distinguir patrones, SC-004) y la de tiempos de §4 (SC-005); anotar los resultados en la misma sección. Si alguna falla, ajustar solo las posiciones del patrón en `assets/catalog/catalog.json`, actualizar data-model.md, contracts/catalog-entries.md y las pruebas de T004, T005 y T008, y repetir

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias.
- **Foundational (Phase 2)**: Depende de Setup. BLOQUEA ambas historias (T002 agrega el patrón; T003 mantiene en verde la suite al crecer el catálogo).
- **US1 (Phase 3)**: Depende de Foundational. Es el MVP.
- **US2 (Phase 4)**: Depende de Foundational. Es independiente de US1 (sus pruebas leen el catálogo real), así que puede hacerse en paralelo con US1.
- **Polish (Phase 5)**: Depende de US1 y US2. T014 y T015 son manuales y los hace el responsable.

### Dependencias clave entre tareas

```text
T001 → T002 → T003 → T005
T002 → T004 → T006, T007, T008
T002 → T009, T010
T003–T010 → T011 → T012 → T013 → T014, T015
```

### Within Each User Story

- El cambio en el catálogo (Phase 2) antes que las pruebas (Principio VI: pruebas después del cambio, derivadas de los CA).
- Los fixtures (T004) antes que las pruebas que los usan.

### Parallel Opportunities

- US1: T004 en paralelo con T009 y T010 (archivos distintos); luego T006 ∥ T007 ∥ T008. T005 va solo, porque comparte archivo con T003.
- US2: T009 ∥ T010, en paralelo con US1.

---

## Parallel Example: User Story 1

```bash
# Tras T004 (fixture de la sesión transversal):
Task: "T006 Tramos con la sesión transversal en test/domain/exercise_engine_motion_test.dart"
Task: "T007 Simulación con la sesión transversal en test/domain/exercise_engine_simulation_test.dart"
Task: "T008 Painter con el patrón transversal en test/presentation/opponent_painter_test.dart"

# En paralelo con US1 (Phase 4):
Task: "T009 Dos patrones reales en test/presentation/selection_screen_test.dart"
Task: "T010 Repetir y Volver con el transversal en test/presentation/exercise_screen_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (estado en verde).
2. Phase 2: catálogo (T002, T003).
3. Phase 3: pruebas de US1.
4. **STOP and VALIDATE**: `flutter test`, `git diff --stat main -- lib` vacío y quickstart.md §2 pasos 2–6 en el dispositivo.
5. Demo con el responsable.

### Incremental Delivery

1. Setup + Foundational → el patrón ya aparece y se puede jugar.
2. US1 → pruebas del patrón y del movimiento → demo (MVP).
3. US2 → pruebas de selección, Repetir y Volver.
4. Polish → verificación del Principio III, build y validación manual → PR a `main`.

### Notas

- [P] = archivos distintos y sin dependencias pendientes.
- Commit al terminar cada tarea o grupo lógico (`feat:` para el catálogo, `test:` para las pruebas, `docs:` para quickstart).
- Si la validación a 3 m (T015) pide otras posiciones, el cambio sigue siendo solo de datos. Si con datos no alcanza, se vuelve al plan (FR-002).
