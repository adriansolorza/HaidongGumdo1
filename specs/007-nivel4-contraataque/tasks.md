---
description: "Task list for Spec 007: Nivel 4, evasión con contraataque"
---

# Tasks: Nivel 4, evasión con contraataque

**Input**: Design documents from `specs/007-nivel4-contraataque/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/counter-signal.md](./contracts/counter-signal.md), [contracts/selection-ui.md](./contracts/selection-ui.md), [quickstart.md](./quickstart.md)

**Tests**: Incluidas. El Principio VI exige pruebas para la aleatoriedad y el máximo de N, y el plan las detalla (research R9). Se escriben después del código y se derivan de la spec. La única excepción es la verificación de no regresión del refactor de presentación (plan D4): **las pruebas existentes se corren antes y después del refactor sin cambiarlas**.

**Organization**:
- La **Foundational** hace el refactor sin cambio de comportamiento y luego agrega `counter` de punta a punta: dominio, catálogo, señal e ícono. Esto va junto porque los `switch` sobre `ResponseType` son exhaustivos y el proyecto no compila con el enum a medias. Al terminar esta fase, el Nivel 4 ya se juega.
- **US1** (transversal) y **US2** (frontal) lo verifican con pruebas del dominio, de la señal y de la pantalla.
- **US3** verifica el catálogo, el ícono y la selección con cuatro niveles reales.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia de usuario (US1 transversal, US2 frontal, US3 selección)

## Path Conventions

Proyecto Flutter único: `lib/`, `test/` y `assets/` en la raíz del repositorio.

## Reglas para todas las tareas

- **Niveles 1 a 3 intactos (FR-020).** Si una prueba existente de las Specs 001 a 006 falla, **no se cambian sus expectativas**: se corrige el código. Las únicas pruebas existentes que pueden cambiar son las que enumeran los niveles del catálogo real:
  - la prueba de `test/data/catalog_json_mapper_test.dart` que espera `hasLength(3)` y `['level_1', 'level_2', 'level_3']`;
  - el mapa `catalogs` de `test/presentation/selection_screen_test.dart` (T020; aplicado en T010: `_fourLevels` → `_threeLevels`).

  Aprobadas por el responsable en T010 (2026-11-19), porque asumían que `counter` no existía; las expectativas sobre los Niveles 1 a 3 no cambian:
  - `test/presentation/level_icon_test.dart`: `_referenceGlyph` gana `case ResponseType.counter` (lanza `UnsupportedError`), y la prueba "la misma geometría que antes" recorre `[defense, evasion]` en lugar de `ResponseType.values`;
  - `test/data/catalog_json_mapper_test.dart`, `(e)`: el ejemplo de tipo desconocido pasa de `"counter"` a `"dodge"`;
  - `test/domain/exercise_engine_simulation_test.dart`, `_level3Simulations`: `containsAll(ResponseType.values)` → `containsAll(session().level.responseTypes)`.
- **`exercise_engine_sequence_regression_test.dart` y su fixture `test/domain/fixtures/sequence_regression.json` NO se tocan ni se regeneran.**
- **Dominio acotado (FR-002, Principio III, excepción a).** En `lib/domain/` solo cambian `catalog/enums.dart` y `exercise/signal.dart`. No tocar `ExerciseEngine`, `StreakSequencer`, `Attack`, `Session`, `ExerciseParameters`, `OpponentMotion` ni los eventos. Si una tarea parece requerir otra cosa, detenerse y consultarlo.
- **Sin cambios** en `SceneLayout`, `OpponentPainter`, `ExerciseHud`, `selection_screen.dart`, `selection_card.dart`, `selection_density.dart`, `lib/presentation/settings/` ni `strings_es.dart`.
- **Sin paquetes nuevos** (Principio VII). `lib/domain/` sigue siendo Dart puro.
- **Regla de color.** Rojo, azul y amarillo solo en el sable y en las señales. La empuñadura usa `AppColors.grip` y la guarda `AppColors.tsuba`. El ícono va en `AppColors.textPrimary`.

---

## Phase 1: Setup

**Purpose**: Línea base.

- [x] T001 Desde la raíz, en la rama `007-nivel4-contraataque`, ejecutar `flutter analyze` y `flutter test` y confirmar que todo pasa (línea base de las Specs 001 a 006). Si algo falla, detenerse y reportarlo.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Hacer el refactor sin cambio de comportamiento y después agregar `counter` de punta a punta. Las tres historias dependen de esta fase.

### Refactor sin cambio de comportamiento (plan D4)

- [x] T002 En `lib/presentation/exercise/painters/signal_shapes.dart`, generalizar el sable con el ángulo como parámetro (research R5; [contrato §3](./contracts/counter-signal.md#3-signalshapes-presentación-solo-geometría)):
  - `_axisPoint(double along, double across)` y `_defenseUnitBounds()` reciben `double angleDegrees`. Renombrar `_defenseUnitBounds` a `_saberUnitBounds(double angleDegrees)`.
  - Nuevo `static ({Path blade, Path guard, Path grip, Offset bladeBase, Offset bladeTip}) saber(Rect box, {required double angleDegrees})`, con el cuerpo actual de `defenseSaber` y el ángulo como parámetro.
  - Nuevo `static Rect fitSaber(Rect lane, double maxHeight, {required double angleDegrees})`, con el cuerpo actual de `fitDefense`.
  - Nuevo `static double saberAspect(double angleDegrees)`, que devuelve `ancho / alto` de `_saberUnitBounds(angleDegrees)`. A 90° el resultado es el ancho de la guarda dividido entre el largo total (≈ 0.26). Doc-comment: "Proporción ancho/alto de la caja del sable a [angleDegrees]".
  - `defenseSaber(Rect box)` pasa a ser `saber(box, angleDegrees: defenseAngleDegrees)` y `fitDefense(lane, maxHeight)` pasa a ser `fitSaber(lane, maxHeight, angleDegrees: defenseAngleDegrees)`. Se conservan sus nombres y firmas.
  - Agregar `static const counterAngleDegrees = 90.0;` con el doc-comment "Sable vertical, punta arriba, de la señal de contraataque (Spec 007, Clarifications 2026-11-19)".
  - Ajustar el doc-comment de la clase: las formas sirven a defensa, evasión y contraataque.
  - Con 115°, las operaciones aritméticas deben ser las mismas que hoy, en el mismo orden, para dar los mismos pixeles.
- [x] T003 En `lib/presentation/exercise/painters/signal_painter.dart`, extraer dos métodos privados **sin cambiar ninguna operación de dibujo** (research R6):
  - `_paintArrow(Canvas canvas, Rect box, double cy, double l, double trailLimitX, Color color)`: todo lo que `_paintEvasion` dibuja desde "Estela" hasta el reflejo blanco. `trailLimitX` es la `x` mínima hasta la que puede llegar la estela, que hoy es `lane.left + glowExtent`.
  - `_paintSaber(Canvas canvas, ({Path blade, Path guard, Path grip, Offset bladeBase, Offset bladeTip}) saber, double sigma, double h, Color color)`: todo lo que `_paintDefense` dibuja desde "Brillo de la hoja" hasta el contorno de la guarda.
  - `_paintEvasion` y `_paintDefense` calculan lo mismo que hoy y llaman a estos métodos.
- [x] T004 Ejecutar `flutter test test/presentation/signal_painter_test.dart test/presentation/level_icon_test.dart test/presentation/exercise_screen_test.dart` y confirmar que todo pasa **sin cambiar ninguna prueba** (FR-020, contrato P7 e I3). Si algo falla, corregir T002 o T003. Hacer commit de T002 y T003 **solos**: `refactor: generalizar el sable de las señales con el ángulo como parámetro`.

### Tipo `counter` de punta a punta

- [x] T005 En `lib/domain/catalog/enums.dart`:
  - Cambiar el enum a `enum ResponseType { defense, evasion, counter }` ([data-model §1](./data-model.md#1-responsetype-dominio-enum)).
  - Actualizar el doc-comment: "`evasion` se agregó en la Spec 003 y `counter` en la Spec 007 (excepción (a) del Principio III: tipo de señal nuevo)".
- [x] T006 En `lib/domain/exercise/signal.dart`, agregar a `SignalPlacement.forAttack` la rama `ResponseType.counter => Signal(responseType: attack.responseType, screenSide: attack.side)`, con el comentario "Contraataque: la señal va del lado del color del sable, como la evasión (Spec 007, FR-008)" ([data-model §3](./data-model.md#3-signal-y-signalplacement-dominio)). Actualizar el doc-comment: "una rama por tipo de respuesta" sigue siendo válido.
- [x] T007 [P] En `assets/catalog/catalog.json`, agregar al final de `levels`, después de `level_3`, exactamente la línea `{ "id": "level_4", "order": 4, "name": "Nivel 4", "responseLabel": "Evasión y contraataque", "purpose": "Combate", "responseTypes": ["counter"] }` ([data-model §2](./data-model.md#2-nivel-4-catálogo-assetscatalogcatalogjson)).
- [x] T008 En `lib/presentation/exercise/painters/signal_painter.dart`, agregar `case ResponseType.counter: _paintCounter(canvas, size, color);` en `paint`, más las constantes `_counterSaberHeightFactor = 1.10`, `_counterGapFraction = 0.10` y `_counterMinWidthFactor = 2.24`, con doc-comments (research R4; [data-model §5](./data-model.md#5-geometría-de-la-señal-de-contraataque-presentación); [contrato §4](./contracts/counter-signal.md#4-signalpainter)). `_paintCounter(Canvas canvas, Size size, Color color)` hace lo siguiente, para el lado derecho (el reflejo para el izquierdo ya lo hace `paint`):
  1. `lane = layout.rightLane`, `h = size.height`.
  2. Calcular el largo de la flecha:
     - `l2 = min(_maxArrowFraction * h, lane.width / (1.6 + 2 * 3 * _arrowGlowSigma))`, el mismo largo que la flecha de evasión;
     - `lc = min(l2, lane.width / _counterMinWidthFactor)`;
     - si `lc <= 0`, salir.
  3. `sigma = _arrowGlowSigma * lc`, `glow = 3 * sigma`.
  4. `saberHeight = _counterSaberHeightFactor * SignalShapes.arrowHeadHeight * lc` y `saberWidth = saberHeight * SignalShapes.saberAspect(SignalShapes.counterAngleDegrees)`.
  5. Centro vertical: `halfExtent = max(SignalShapes.arrowHeadHeight * lc, saberHeight) / 2 + glow` y `cy = _clampedCenterY(lane, h, halfExtent)`. Después, `saberBox = Rect.fromLTWH(lane.right - glow - saberWidth, cy - saberHeight / 2, saberWidth, saberHeight)`. **El centro del sable coincide con el eje de la flecha** (`saberBox.center.dy == cy`).
  6. Calcular la caja de la flecha: `arrowRight = saberBox.left - _counterGapFraction * lc` y `box = Rect.fromLTRB(arrowRight - lc, cy - SignalShapes.arrowHeadHeight * lc / 2, arrowRight, cy + SignalShapes.arrowHeadHeight * lc / 2)`.
  7. Llamar a `_paintArrow(canvas, box, cy, lc, lane.left + glow, color)` y después a `_paintSaber(canvas, SignalShapes.saber(saberBox, angleDegrees: SignalShapes.counterAngleDegrees), sigma, h, color)`.

  Actualizar el doc-comment de la clase con la tercera señal: "contraataque: la flecha de evasión con un sable vertical, punta arriba, casi junto a su punta y centrado en su eje (Spec 007, FR-007)".
- [x] T009 En `lib/presentation/selection/level_icon.dart`, agregar `case ResponseType.counter` en `_paintGlyph` (research R7; [contrato selection-ui §2](./contracts/selection-ui.md#2-leveliconpainter)):
  - `l = box.width / 1.80`.
  - Sable: `saberHeight = 1.10 * SignalShapes.arrowHeadHeight * l` y `saberWidth = saberHeight * SignalShapes.saberAspect(SignalShapes.counterAngleDegrees)`. La caja es `Rect.fromLTWH(box.right - saberWidth, box.center.dy - saberHeight / 2, saberWidth, saberHeight)`. Pintar `SignalShapes.saber(esaCaja, angleDegrees: SignalShapes.counterAngleDegrees)`: empuñadura, guarda y hoja en blanco.
  - Flecha: `SignalShapes.evasionArrow` de largo `l`, con su borde derecho a `0.10 * l` del borde izquierdo del sable, centrada en `box.center.dy`.
  - 3 líneas de movimiento a la izquierda de la flecha, con las mismas proporciones que el glifo de evasión, recortadas para que empiecen en `box.left`.
  - Todo en `AppColors.textPrimary`. Actualizar el doc-comment de la clase (Spec 007, FR-016).
- [x] T010 Ejecutar `flutter analyze` (sin avisos nuevos) y `flutter test`. Se espera que pase todo menos la prueba de `catalog_json_mapper_test.dart` que enumera 3 niveles; esa se corrige en T019. Si falla otra prueba existente, incluida la regresión de secuencias, corregir el código y no la prueba.
- [x] T011 [P] En `test/domain/fakes/test_session.dart`, agregar:
  - `Level _level4()` con `id: 'level_4'`, `order: 4`, `name: 'Nivel 4'`, `responseLabel: 'Evasión y contraataque'`, `purpose: 'Combate'`, `responseTypes: const [ResponseType.counter]` y el doc-comment "Nivel 4 (Spec 007, data-model §2): evasión con contraataque";
  - `Session testLevel4Session()` (patrón de `testSession`);
  - `Session testLevel4TransversalSession()` (patrón de `testTransversalSession`).

**Checkpoint**: el Nivel 4 se elige y se juega. Las pruebas de las Specs 001 a 006 pasan, salvo la enumeración de niveles del mapper (T019).

---

## Phase 3: User Story 1 - Evadir y contraatacar el corte transversal (Priority: P1) 🎯 MVP

**Goal**: Con Nivel 4 + Transversal, cada ataque muestra solo la señal de contraataque, del lado del color, fuera del alcance del oponente en todo el barrido, con la flecha a ≥ 75 % de la del Nivel 2.

**Independent Test**: `flutter test test/domain/signal_placement_test.dart test/domain/exercise_engine_level4_test.dart test/domain/exercise_engine_timeline_test.dart test/domain/exercise_engine_simulation_test.dart test/domain/exercise_engine_motion_test.dart test/presentation/signal_painter_test.dart test/presentation/exercise_screen_test.dart`, más el recorrido 2 de [quickstart.md](./quickstart.md).

- [x] T012 [P] [US1] En `test/domain/signal_placement_test.dart`, agregar `group('contraataque (Spec 007, FR-008)', …)`:
  - `counter` con `Side.right` (azul) → `screenSide == Side.right`;
  - `counter` con `Side.left` (rojo) → `Side.left`;
  - `responseType == ResponseType.counter`.
- [x] T013 [P] [US1] Crear `test/domain/exercise_engine_level4_test.dart`, con los helpers de `exercise_engine_level3_test.dart` (`_engine`, `_runToEnd`, `_attacks`, `_longestStreak`) copiados o adaptados, y un `group('Nivel 4 transversal (Spec 007, US1)', …)` con:
  - (a) todos los ataques tienen `responseType == ResponseType.counter` (FR-004), con semillas 1, 42 y 2026;
  - (b) **≡ Nivel 2**: con la misma `SeededRandomSource(seed)` y los mismos parámetros, los ataques de `testLevel4TransversalSession()` son iguales a los de `testLevel2TransversalSession()` en `index`, `side`, `signalAt`, `cutStartAt`, `cutEndAt` y `nextSignalAt`, e igual el instante de la voz de fin (research R3). Semillas 1, 42 y 2026; N 1 y 5;
  - (c) para N de 1 a 5 y 1 000 ejercicios simulados de 180 s cada uno, ninguno tiene más de N ataques seguidos al mismo lado (SC-004);
  - (d) con N = 5 y 1 000 ejercicios, la proporción de lados `right` está en [0.45, 0.55] y dos semillas distintas no dan la misma secuencia de lados (SC-005, RN1).
- [x] T014 [US1] En `test/presentation/signal_painter_test.dart`, agregar `group('contraataque (Spec 007, contrato §4)', …)` sobre 7 lienzos: los 4 de `_sizes` más `'4:3 (Spec 005)': (1024, 768)`, `'20:9 grande': (2400, 1080)` y `'teléfono 20:9': (889, 400)`. Son los mismos 7 de la Spec 006, en un mapa local `_counterCanvases`. Usar el patrón transversal para el layout. Con `_sig(ResponseType.counter, side)` y el color correspondiente (azul → `Side.right`, rojo → `Side.left`), probar:
  - **P1**: ningún pixel con alfa > 0 queda fuera de `layout.laneFor(side)`;
  - **P2** (FR-010): medido en **pixeles**, no con la fórmula de T008:
    - pintar en el mismo lienzo `_sig(ResponseType.evasion, Side.right)` y `_sig(ResponseType.counter, Side.right)`, los dos con `SaberColor.blue`;
    - en cada render, `L` es la distancia en `x` entre la columna de la punta (la columna más a la derecha de la flecha) y la base de la punta;
    - la base de la punta es la columna donde la altura del relleno sólido (`AppColors.saberBlue` ± 8 por canal, alfa = 255) pasa de la altura del cuerpo (0.46 `L`) a la de la punta (1.06 `L`);
    - entonces `L` = largo de la punta / `SignalShapes.arrowHeadLength`;
    - en el contraataque, ignorar las columnas que pertenecen al sable (a la derecha de la punta);
    - comprobar `Lcounter ≥ 0.75 × Levasion`, con tolerancia de 2 px;
    - escribir un helper `_measureArrowLength(Uint8List pixels, int w, int h, Color color)` que comparten los dos renders;
  - **P3**: del lado azul, la columna más a la derecha con color de hoja está a la derecha de la punta de la flecha, a ≤ 0.15 `Lc`; del lado rojo, en espejo;
  - **P4**: en la hoja del sable, el centro de las columnas con el color del sable, fila por fila a lo largo de su altura, tiene el mismo `x` ± 1 px (eje vertical);
  - **P5**: el centro vertical de la caja del sable está a ± 1 px de `cy`, la fila de la punta de la flecha;
  - **P6**: no hay pixeles amarillos (`AppColors.saberYellow` ± tolerancia) y el render rojo es el espejo horizontal del azul en forma: mismo conjunto de pixeles no transparentes reflejados, ± 1 px;
  - **P7** (FR-020): las pruebas de evasión y defensa existentes siguen pasando sin cambios.

  Agregar también una prueba de no colisión: con el patrón transversal y en todas las fases del ataque (muestrear el progreso del corte de 0 a 1 en 20 pasos), la caja de la señal no se cruza con la del oponente ni con la de su sable. Usar los mismos helpers que la prueba existente de la Spec 004 para la evasión (SC-003, SC-009).
- [x] T015 [US1] En `test/presentation/exercise_screen_test.dart`, agregar un `testWidgets` con el estilo de la prueba (k) del Nivel 3: "(l) Nivel 4 transversal: una sola señal por ataque, de contraataque, del lado del color". Con `h.start(tester, level: 'Nivel 4', pattern: 'Transversal')`:
  - `session.level.id == 'level_4'`;
  - en cada `SignalShown` durante al menos 5 ataques, el `SignalPainter` visible tiene `signal.responseType == ResponseType.counter` y `signal.screenSide == attack.side`, y hay un solo `SignalPainter`;
  - la señal desaparece cuando el sable vuelve a amarillo.

  En el grupo "HUD de la Spec 004", agregar el caso Nivel 4: "NIVEL 4" y "Evasión y contraataque" (FR-018).

**Checkpoint**: US1 verificada. Es el MVP.

---

## Phase 4: User Story 2 - Evadir y contraatacar el corte frontal (Priority: P2)

**Goal**: Con Nivel 4 + Frontal, las mismas reglas de señal, y el oponente se mueve exactamente igual que en los Niveles 1 a 3 frontales.

**Independent Test**: `flutter test test/domain/exercise_engine_level4_test.dart test/domain/exercise_engine_timeline_test.dart test/domain/exercise_engine_motion_test.dart test/domain/exercise_engine_simulation_test.dart test/presentation/signal_painter_test.dart`, más el recorrido 3 de [quickstart.md](./quickstart.md).

- [x] T016 [US2] En `test/domain/exercise_engine_level4_test.dart`, agregar `group('Nivel 4 frontal (Spec 007, US2)', …)` con los casos (a) a (d) de T013 sobre `testLevel4Session()` y `testLevel2Session()`.
- [x] T017 [P] [US2] Agregar helpers **nuevos** del Nivel 4 para los dos patrones. **No modificar** `_level2Group`, `_level2Simulations`, `_level3Simulations` ni `_sameMotionAsLevel1`, ni pasarles sesiones del Nivel 4: sus expectativas son de la evasión o de la mezcla del Nivel 3 (FR-020).
  - `test/domain/exercise_engine_timeline_test.dart`: `_level4Group(String name, Session Function() session)`, con la estructura de `_level2Group`, pero cada ataque es `ResponseType.counter`, con aviso de 700 ms y corte de 500 ms. El primer ataque, el intervalo y el fin (FR-013) cumplen lo mismo que en el Nivel 2. Llamarlo con `'Nivel 4 transversal (Spec 007, US1)', testLevel4TransversalSession` y con `'Nivel 4 frontal (Spec 007, US2)', testLevel4Session`.
  - `test/domain/exercise_engine_simulation_test.dart`: `_level4Simulations(String name, Session Function() session, {required bool checkMotionSide})`, con la estructura de `_level2Simulations`. En cada fotograma con ataque:
    - `signal.responseType == ResponseType.counter` y `signal.screenSide == attack.side`;
    - el color del sable es azul con `Side.right` y rojo con `Side.left` (SC-002);
    - si `checkMotionSide`, `motion.side == attack.side` (FR-012, SC-003).
    Llamarlo con el transversal (`checkMotionSide: true`) y con el frontal (`checkMotionSide: false`).
  - `test/domain/exercise_engine_motion_test.dart`: `_sameMotionAsLevel2(String name, {required Session Function() level2, required Session Function() level4})`, con la estructura de `_sameMotionAsLevel1`. Para semillas de 0 a 19, en cada fotograma, el `motion` del Nivel 4 es igual al del Nivel 2 con la misma semilla (FR-013; research R3). Llamarlo para el frontal (`testLevel2Session`, `testLevel4Session`) y el transversal (`testLevel2TransversalSession`, `testLevel4TransversalSession`).
- [x] T018 [P] [US2] En `test/presentation/signal_painter_test.dart`, repetir P1 y la prueba de no colisión de T014 con el **patrón frontal**, sobre los mismos `_counterCanvases`, en las fases de *Chochôn-se*, corte y regreso (FR-013, SC-009).

**Checkpoint**: US1 y US2 verificadas.

---

## Phase 5: User Story 3 - Elegir el Nivel 4 en la selección (Priority: P3)

**Goal**: El Nivel 4 aparece como la cuarta tarjeta, con su texto y su ícono blanco. Las 6 tarjetas se ven sin desplazar en los 7 lienzos, y los Niveles 1 a 3 no cambian.

**Independent Test**: `flutter test test/data/catalog_json_mapper_test.dart test/presentation/level_icon_test.dart test/presentation/selection_screen_test.dart`, más el recorrido 1 y 4 de [quickstart.md](./quickstart.md).

- [ ] T019 [P] [US3] En `test/data/catalog_json_mapper_test.dart`:
  - cambiar la prueba que enumera los niveles del asset a `hasLength(4)` y `['level_1', 'level_2', 'level_3', 'level_4']` (es una de las excepciones permitidas);
  - agregar `group('Nivel 4 (Spec 007)', …)`: el asset real incluye `level_4` con `order` 4, `name` "Nivel 4", `responseLabel` "Evasión y contraataque", `purpose` "Combate" y `responseTypes` `[ResponseType.counter]` (FR-001);
  - agregar un JSON mínimo con `"responseTypes": ["counter"]`, que se lee sin error;
  - comprobar que `"responseTypes": ["counter", "counter"]` lanza `CatalogException` por duplicado.
- [ ] T020 [P] [US3] En `test/presentation/selection_screen_test.dart`:
  - en el grupo de lienzos (US3-4 de la Spec 006), reemplazar el mapa `catalogs` por `{'catálogo real (4 niveles)': _realCatalog, '3 niveles': <el catálogo real sin level_4>}`. Si `_fourLevels` era un catálogo de prueba, eliminarlo o dejarlo sin uso si otras pruebas lo necesitan. Es la otra excepción permitida.
  - agregar `group('Spec 007: Nivel 4', …)` con:
    - US3-1: las tarjetas de NIVEL están en el orden "Nivel 1", "Nivel 2", "Nivel 3" y "Nivel 4", el Nivel 1 está preseleccionado y aparece el texto "Evasión y contraataque — Combate";
    - US3-2: la tarjeta del Nivel 4 contiene un `LevelIcon` con `types == [ResponseType.counter]`;
    - US3-3: Nivel 4 + Transversal muestra el resumen "Nivel 4 · Transversal · 30 s"; INICIAR crea una sesión con `level.id == 'level_4'`; Repetir la conserva;
    - US3-5: después de volver, elegir Nivel 2 + Frontal e iniciar da una sesión `level_2` cuyas señales son `evasion`.
- [ ] T021 [P] [US3] En `test/presentation/level_icon_test.dart`, agregar `group('Nivel 4 (Spec 007, contrato selection-ui §2)', …)` sobre `_size`:
  - **I1**: `LevelIconPainter([ResponseType.counter])` no produce pixeles rojos, azules ni amarillos, y los pixeles no transparentes son blancos (`AppColors.textPrimary`, con tolerancia de antialias);
  - **I2**: todos los pixeles no transparentes quedan dentro de la caja con margen del 10 %;
  - el ícono tiene pixeles en la mitad derecha que forman una columna vertical (el sable): en el cuarto derecho existe una columna `x` con pixeles blancos en al menos el 50 % del alto de la caja;
  - **I3**: las pruebas existentes de los íconos de `[defense]`, `[evasion]` y `[defense, evasion]` siguen pasando sin cambios.

**Checkpoint**: las tres historias verificadas.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T022 [P] En `specs/001-motor-nivel1-frontal/contracts/catalog.schema.json`, cambiar `levels.items.properties.responseTypes.items.enum` a `["defense", "evasion", "counter"]` (contrato counter-signal §1). Si ya tiene `"evasion"` por la Spec 003, solo agregar `"counter"`.
- [ ] T023 [P] *(Opcional, plan D7; confirmar con el responsable antes de hacerlo.)* Alinear el texto del Nivel 4 a "Evasión y contraataque" en la tabla de niveles de `docs/brief.md` y de `docs/000-haidonggumdo-v010.md` (RF4), sin cambiar nada más.
- [ ] T024 Ejecutar `flutter analyze` y `flutter test` y confirmar que todo pasa, incluida `exercise_engine_sequence_regression_test.dart` sin cambios. Confirmar con `git diff --stat main -- lib/domain` que en `lib/domain/` solo cambiaron `catalog/enums.dart` y `exercise/signal.dart`.
- [ ] T025 Recorrido manual de [quickstart.md](./quickstart.md) §2 (pasos 1 a 5) en un dispositivo o emulador Android en horizontal. Anotar en el PR cualquier diferencia visual con el boceto, además del sable vertical, que es deliberado. Las pruebas con observadores de §3 (SC-001, SC-006 y SC-007) las hace el responsable; dejarlas como pendientes en el PR si no se hicieron.
- [ ] T026 Commits con Conventional Commits, sobre el commit `refactor:` de T004:
  - `feat: Nivel 4 con señal de contraataque` (T005–T009, T011);
  - `test: pruebas del Nivel 4` (T012–T021);
  - `docs: esquema del catálogo con counter` (T022 y, si se hizo, T023).

  Marcar las tareas completadas en este archivo.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001)** → **Foundational (T002–T011)** → **US1, US2 y US3** (pueden ir en paralelo entre sí) → **Polish (T022–T026)**.
- Dentro de Foundational:
  - T002 → T003 → T004: el refactor se valida antes de agregar `counter`.
  - T005 → T006 → T008 y T009 → T010. T007 y T011 pueden ir en paralelo con T005–T009.
- T008 y T009 dependen de T002 (`saber`, `fitSaber` y `counterAngleDegrees`) y de T005 (`counter`). Sin los dos `case` nuevos, el proyecto no compila después de T005.

### User Story Dependencies

- **US1**: depende solo de Foundational.
- **US2**: depende de Foundational. T016 se agrega al archivo que crea T013, así que si van en paralelo, T016 va después de T013.
- **US3**: depende solo de Foundational.

### Within Each User Story

- Las pruebas se escriben después del código (Principio VI), que ya está completo en Foundational.
- Las tareas sobre el mismo archivo (T014 y T018 en `signal_painter_test.dart`; T013 y T016 en `exercise_engine_level4_test.dart`) van en secuencia.

### Parallel Opportunities

- Foundational: T007 y T011 en paralelo con T005–T009.
- US1: T012 y T013 en paralelo. T014 y T015 van en archivos distintos y también pueden ir en paralelo.
- US2: T017 en paralelo con T016 y T018.
- US3: T019, T020 y T021 en paralelo (archivos distintos).
- Polish: T022 y T023 en paralelo.

---

## Parallel Example: User Story 1

```text
Task: "T012 [US1] contraataque en test/domain/signal_placement_test.dart"
Task: "T013 [US1] Nivel 4 transversal en test/domain/exercise_engine_level4_test.dart"
Task: "T015 [US1] Nivel 4 en test/presentation/exercise_screen_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "T019 [US3] Nivel 4 en test/data/catalog_json_mapper_test.dart"
Task: "T020 [US3] Nivel 4 en test/presentation/selection_screen_test.dart"
Task: "T021 [US3] Nivel 4 en test/presentation/level_icon_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001).
2. Phase 2: Foundational (T002–T011). Primero el refactor validado y comprometido (T004), después `counter`.
3. Phase 3: US1 (T012–T015).
4. **Parar y validar**: Nivel 4 + Transversal en un dispositivo a 3 m (quickstart §2, paso 2).

### Incremental Delivery

1. Setup + Foundational: el Nivel 4 se juega con los dos patrones.
2. US1: verificado el corte transversal y la geometría de la señal (MVP).
3. US2: verificado el corte frontal y extendidos los grupos parametrizados.
4. US3: verificados el catálogo, el ícono y la selección con 4 niveles reales.
5. Polish: el esquema, la documentación opcional, la validación completa y los commits.

---

## Notes

- [P] = archivos distintos, sin dependencias pendientes.
- El oráculo "Nivel 4 ≡ Nivel 2" (T013 b, T016) es la prueba más fuerte de que el motor no cambió (FR-002).
- Las pruebas parametrizadas existentes son por nivel; el Nivel 4 lleva sus propios helpers (T017).
- La desviación del boceto (sable vertical) es deliberada (Clarifications, 2026-11-19); no corregirla.
- Si P2 (≥ 75 %) fallara en algún lienzo, es un error de T008: por construcción `Lc ≥ 0.82 L2` (research R4).
