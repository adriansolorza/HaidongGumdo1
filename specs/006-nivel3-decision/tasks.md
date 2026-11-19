---
description: "Task list for Spec 006: Nivel 3, decisión bajo presión"
---

# Tasks: Nivel 3, decisión bajo presión

**Input**: Design documents from `specs/006-nivel3-decision/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/domain-sequencer.md](./contracts/domain-sequencer.md), [contracts/selection-ui.md](./contracts/selection-ui.md), [quickstart.md](./quickstart.md)

**Tests**: Incluidas. El Principio VI exige pruebas para la aleatoriedad y para el máximo de N, y el plan las detalla (research R8). Se escriben después del código y se derivan de la spec. La única excepción es la **regresión de secuencias**, que se graba **antes** del refactor para comparar contra el código actual (plan D4).

**Organization**: La Foundational hace todo el cambio de dominio y de datos: regresión grabada, `StreakSequencer`, sorteo del tipo en el motor y `level_3` en el catálogo. Con eso, el Nivel 3 ya se juega. US1 (transversal) y US2 (frontal) lo verifican con pruebas del dominio y de la pantalla. US3 entrega el ícono mixto y la selección sin desplazar.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia de usuario (US1 transversal, US2 frontal, US3 selección)

## Path Conventions

Proyecto Flutter único: `lib/`, `test/` y `assets/` en la raíz del repositorio.

## Reglas para todas las tareas

- **Secuencias intactas**: con la misma fuente de aleatoriedad, los Niveles 1 y 2 deben producir exactamente los mismos ataques que antes del cambio. Si una prueba existente de dominio de las Specs 001 a 005 falla, **no se cambian sus expectativas**: se corrige el código. Las únicas pruebas existentes que pueden cambiar son:
  - `side_sequencer_test.dart`: renombre a `StreakSequencer`, `options: const [Side.right, Side.left]` y `lastSide` → `last`;
  - la prueba (a) de `catalog_json_mapper_test.dart`, que enumera los niveles del asset (SC-008).
- **Una sola regla nueva en el dominio** (FR-002): en `lib/domain/` solo cambian `exercise/side_sequencer.dart` (→ `streak_sequencer.dart`), `exercise/exercise_engine.dart` y un comentario de `catalog/enums.dart`. No tocar `Attack`, `Signal`, `SignalPlacement`, `ExerciseParameters`, `ExerciseStatus`, `Session`, `OpponentMotion` ni los eventos. Si una tarea parece requerir otra cosa, detenerse y consultarlo.
- **Sin cambios** en `lib/presentation/exercise/` (pantalla, HUD y painters de señales) ni en `lib/presentation/settings/` (research R5).
- **Sin paquetes nuevos** (Principio VII). `lib/domain/` sigue siendo Dart puro.
- `s` = `SceneLayout.hudScale`, como en la Spec 004.

---

## Phase 1: Setup

**Purpose**: Línea base.

- [x] T001 Desde la raíz, en la rama `006-nivel3-decision`, ejecutar `flutter analyze` y `flutter test` y confirmar que todo pasa (línea base de las Specs 001 a 005). Si algo falla, detenerse y reportarlo.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Grabar la regresión, generalizar el sorteo, sortear el tipo en el motor y agregar `level_3`. Las tres historias dependen de esta fase.

### Regresión de secuencias (ANTES de tocar `lib/domain/`)

- [x] T002 Crear `test/domain/exercise_engine_sequence_regression_test.dart` (research R8; contrato E1):
  - Una función `_record(Session session, int seed, int maxRepeats)` crea un `ExerciseEngine` con `ExerciseParameters.create(duration: 180 s, maxRepeats: maxRepeats, warningTime: 700 ms, cutSpeed: 500 ms, attackInterval: 2500 ms)` y `SeededRandomSource(seed)`. Llama a `start()` y avanza con `advanceTo` en pasos de 16 ms hasta un estado terminal, igual que `_simulate` en `exercise_engine_simulation_test.dart`.
  - Por cada `SignalShown` guarda la línea `'${a.index},${a.side.name},${a.responseType.name},${a.signalAt.inMilliseconds},${a.cutStartAt.inMilliseconds},${a.cutEndAt.inMilliseconds},${a.nextSignalAt.inMilliseconds}'`. Al final agrega la línea `'end,${endVoice.at.inMilliseconds}'`.
  - Casos: sesiones `testSession`, `testTransversalSession`, `testLevel2Session` y `testLevel2TransversalSession` (de `test/domain/fakes/test_session.dart`); semillas 1, 42 y 2026; `maxRepeats` 1 y 5. Son 24 casos, cada uno con la clave `'<level.id>/<pattern.id>/seed<seed>/n<N>'`.
  - El fixture vive en `test/domain/fixtures/sequence_regression.json` (mapa clave → lista de líneas).
  - Si existe la variable de entorno `UPDATE_SEQUENCE_REGRESSION=1`, la prueba **escribe** el fixture con `dart:io` (JSON con sangría de 2 espacios) y pasa. Si no existe, **lee** el fixture y hace `expect(actual, expected)` caso por caso. Si el fixture no existe, falla con un mensaje que diga cómo generarlo.
  - Doc-comment: "Grabado con el motor anterior a la Spec 006. NO regenerar después del refactor: si falla, el refactor cambió las secuencias de los Niveles 1 y 2."
- [x] T003 Generar el fixture con el código **actual**, sin cambios en `lib/`: en PowerShell, `$env:UPDATE_SEQUENCE_REGRESSION='1'; flutter test test/domain/exercise_engine_sequence_regression_test.dart; Remove-Item Env:UPDATE_SEQUENCE_REGRESSION`. Después:
  - ejecutar `flutter test test/domain/exercise_engine_sequence_regression_test.dart` sin la variable y confirmar que pasa;
  - confirmar que `test/domain/fixtures/sequence_regression.json` tiene las 24 claves y que ninguna lista está vacía;
  - hacer commit de la prueba y el fixture **solos**: `test: grabar regresión de secuencias de los Niveles 1 y 2`.

### Sorteo genérico con racha máxima

- [x] T004 Crear `lib/domain/exercise/streak_sequencer.dart` con `final class StreakSequencer<T>` según el [contrato §1](./contracts/domain-sequencer.md#1-streaksequencert) y [data-model §2](./data-model.md#2-streaksequencert-dominio-reemplaza-a-sidesequencer):
  - Constructor `StreakSequencer({required List<T> options, required int maxRepeats, required RandomSource random})`. Lanza `ArgumentError` si `options` está vacía, si tiene duplicados (`options.toSet().length != options.length`) o si `maxRepeats < 1`. Guarda `List.unmodifiable(options)`.
  - Getters `options`, `maxRepeats`, `T? last` (null al inicio) e `int streak` (0 al inicio).
  - `T next()`:
    1. Si `options.length == 1`, el resultado es `options.first` **sin llamar a `random`**.
    2. Si no, `candidates = streak == maxRepeats ? [for (final o in options) if (o != last) o] : options`.
    3. Si `candidates.length == 1`, el resultado es `candidates.first` **sin llamar a `random`**; si no, es `candidates[random.nextInt(candidates.length)]`.
    4. Después: `streak = result == last ? streak + 1 : 1; last = result;`.
  - Doc-comment: "Sortea con un máximo de [maxRepeats] repeticiones seguidas (Spec 001, FR-017 y FR-018; Spec 006, FR-005). Una instancia por ejercicio y por magnitud. Con una sola opción o un solo candidato no consume sorteo (Spec 006, research R2)."
  - Borrar `lib/domain/exercise/side_sequencer.dart`.
- [x] T005 En `lib/domain/exercise/exercise_engine.dart` (research R3; [contrato §2](./contracts/domain-sequencer.md#2-orden-de-los-sorteos-en-exerciseengine)):
  - Cambiar el import a `streak_sequencer.dart`.
  - `_sides` pasa a ser `StreakSequencer<Side>(options: const [Side.right, Side.left], maxRepeats: parameters.maxRepeats, random: random)`, con el comentario "Orden fijo: el sorteo 0 → right y 1 → left, igual que antes (research R2)".
  - Agregar `final StreakSequencer<ResponseType> _responseTypes`, inicializado en la lista de inicialización con `StreakSequencer(options: session.level.responseTypes, maxRepeats: parameters.maxRepeats, random: random)`.
  - En `_onSignal`, después de `final side = _sides.next();`, agregar `final responseType = _responseTypes.next();` con el comentario "Orden de sorteos: lado → tipo → intervalo. Con un solo tipo no consume sorteo, así que las secuencias de los Niveles 1 y 2 no cambian (Spec 006, research R3)". Pasar `responseType: responseType` al `Attack` en lugar de `session.level.responseTypes.first`. El sorteo del intervalo sigue dentro del constructor del `Attack`, después del tipo.
  - No cambiar nada más del archivo.
- [x] T006 [P] En `lib/domain/catalog/enums.dart`, corregir el comentario de `ResponseType`: "`evasion` se agregó en la Spec 003 y `counter` se agregará en la Spec 007 (excepción del Principio III: tipo de señal nuevo)". No cambiar el enum.
- [x] T007 Renombrar `test/domain/side_sequencer_test.dart` a `test/domain/streak_sequencer_test.dart` con `git mv`. En las 4 pruebas existentes, cambiar **solo**:
  - `SideSequencer(...)` → `StreakSequencer<Side>(options: const [Side.right, Side.left], ...)`;
  - `lastSide` → `last`;
  - el import a `streak_sequencer.dart`.
    Los guiones de sorteos, los `expect` y los nombres de las pruebas no cambian (contrato G1, G4).
- [x] T008 Ejecutar `flutter test test/domain/` y confirmar que pasa **todo**. En particular, `exercise_engine_sequence_regression_test.dart` debe pasar **sin** regenerar el fixture. Si falla, corregir T004/T005 y no tocar el fixture. Commit: `refactor: generalizar SideSequencer en StreakSequencer y sortear el tipo de respuesta`.

### Catálogo y sesiones de prueba

- [x] T009 En `assets/catalog/catalog.json`, agregar a `levels`, después de `level_2` y con el mismo formato de una línea: `{ "id": "level_3", "order": 3, "name": "Nivel 3", "responseLabel": "Defensa o evasión lateral", "purpose": "Decisión bajo presión", "responseTypes": ["defense", "evasion"] }` (research R4). El orden `["defense", "evasion"]` es obligatorio: el sorteo 0 → defensa.
- [x] T010 [P] En `test/domain/fakes/test_session.dart`, agregar `Level _level3()` con los mismos valores de T009 y `responseTypes: const [ResponseType.defense, ResponseType.evasion]`. Agregar también:
  - `Session testLevel3Session()`, con el patrón de `testSession()`;
  - `Session testLevel3TransversalSession()`, con el patrón de `testTransversalSession()`;
  - doc-comments que sigan el estilo de las sesiones de Nivel 2.
- [x] T011 En `test/data/catalog_json_mapper_test.dart` (SC-008):
  - en la prueba (a), cambiar `hasLength(2)` → `hasLength(3)` y `['level_1', 'level_2']` → `['level_1', 'level_2', 'level_3']`;
  - agregar el grupo `'Nivel 3 (Spec 006)'` con dos pruebas: (1) el asset real incluye `level_3` con nombre, respuesta, propósito y `responseTypes == [ResponseType.defense, ResponseType.evasion]` (FR-001); (2) el mapper acepta `responseTypes: ['defense', 'evasion']` y conserva el orden.
  - No cambiar ninguna otra prueba.

**Checkpoint**: `flutter analyze` y `flutter test` en verde, con la regresión intacta. El Nivel 3 ya aparece en la selección (con el ícono de defensa, que se corrige en US3) y se puede jugar.

---

## Phase 3: User Story 1 - Decidir entre defender y evadir ante el corte transversal (Priority: P1) 🎯 MVP

**Goal**: El Nivel 3 con el Patrón transversal: en cada ataque aparece una sola señal, de defensa o de evasión, con el lado, el color y el costado del corte correctos, y con rachas de lado y de tipo ≤ N.

**Independent Test**: Elegir Nivel 3 + Transversal e iniciar. Desde 3 m, comprobar en cada ataque qué señal aparece, su lado, su color y el costado del corte (spec US1).

### Tests for User Story 1 (después del código, Principio VI)

- [x] T012 [P] [US1] Ampliar `test/domain/streak_sequencer_test.dart` con un grupo nuevo, `'StreakSequencer genérico (Spec 006)'` (contrato G2, G3):
  - una opción (`[ResponseType.evasion]`) con `ScriptedRandomSource(const [])`: 100 llamadas devuelven `evasion` y `consumed == 0`;
  - `[ResponseType.defense, ResponseType.evasion]` con N = 2 y el guion `[0, 0, 1]`: devuelve `defense, defense, evasion (forzado), evasion`. El tercer valor no consume sorteo: `consumed` es 2 tras la tercera llamada y 3 tras la cuarta;
  - `ArgumentError` con `options: []`, con `[Side.right, Side.right]` y con `maxRepeats: 0`;
  - con `SeededRandomSource` y N de 1 a 5, 10 000 llamadas sin ninguna racha mayor que N.
- [x] T013 [P] [US1] Crear `test/domain/exercise_engine_level3_test.dart` (FR-004 a FR-007; contrato E2, E3, E4, E5):
  - **Orden de sorteos (E5)**: `ExerciseEngine` con `testLevel3TransversalSession()`, valores por defecto (N = 5) y `ScriptedRandomSource` con el guion `[i0, 0, 1, i1, 1, 0, i2, …]`. Los `i` son sorteos de intervalo válidos en `[0, 1501)`; usar 0. Comprobar que los ataques salen (right, evasion), (left, defense)…, en el orden lado → tipo → intervalo.
  - **Consumo en los Niveles 1 y 2 (E2)**: con `testSession()` y `testLevel2Session()`, contar los ataques de un ejercicio de 30 s con `ScriptedRandomSource` y comprobar `consumed == 1 + 2 × ataques`, porque con N = 5 y sin racha completa cada ataque consume lado e intervalo. Usar un guion que alterne lados para que nunca se fuerce.
  - **Rachas (E3, SC-004)**: 1 000 ejercicios de 180 s con `SeededRandomSource(seed)` por cada N de 1 a 5, con `testLevel3TransversalSession()`. En ningún ejercicio hay una racha de lado ni de tipo mayor que N.
  - **Proporciones (E4, SC-005)**: con N = 5 y los mismos 1 000 ejercicios, las defensas y los lados derechos están cada uno entre el 45 % y el 55 % del total de ataques. Además, al menos dos semillas distintas producen secuencias distintas (RN1).
  - **Reinicio (FR-007)**: dos motores creados seguidos con la misma `ScriptedRandomSource` empiezan cada uno su racha de tipo desde cero. Por ejemplo, con N = 1, el primer ataque del segundo motor vuelve a sortear el tipo.
  - **N = 1 (caso límite)**: con N = 1, solo el primer ataque consume sorteos de lado y de tipo, y la señal (`SignalPlacement.forAttack`) cae siempre en la misma `screenSide`.
  - **Estados, cancelación y voces con el Nivel 3 (FR-016)**: con `testLevel3TransversalSession()` y `ScriptedRandomSource`, comprobar:
    1. `cancel()` durante el aviso del 2.º ataque lleva a `cancelled` y emite `Cancelled` sin `EndVoice`;
    2. si el fin nominal cae a mitad de un corte, el estado pasa a `finishing`, el corte termina y después se emite `EndVoice` en `cutEndAt`;
    3. `StartVoice` llega en `startVoiceAt`, antes del primer `SignalShown`.

    Seguir las pruebas equivalentes de `exercise_engine_states_test.dart` y `exercise_engine_timeline_test.dart`, sin modificarlas.

- [x] T014 [P] [US1] En `test/domain/exercise_engine_simulation_test.dart`, agregar `_level3Simulations(String name, Session Function() session, {required bool checkMotionSide})`, con la misma estructura de `_level2Simulations`. En cada fotograma con ataque comprobar:
  - `signal != null` y `signal.responseType == attack.responseType`;
  - con `defense`, `signal.screenSide == attack.side.opposite`; con `evasion`, `signal.screenSide == attack.side`;
  - `s.saberColor` es azul con `right` y rojo con `left`;
  - si `checkMotionSide`, el costado del movimiento depende solo del color, sea cual sea el tipo: `s.motion.side == attack.side`. Es la misma relación que comprueba `_level2Simulations` (`motion.side == signal.screenSide`, con `screenSide == attack.side` en la evasión). Con defensa, por lo tanto, `motion.side == signal.screenSide.opposite` (FR-010).
  - Además, las comprobaciones de tiempos de `_level2Simulations`: intervalo en `[1000, 2500]` ms y _Guman_ entre E y E + 1 200 ms.
  - Llamarla con `'Nivel 3 transversal (Spec 006, US1)'`, `testLevel3TransversalSession` y `checkMotionSide: true`. No modificar los grupos existentes.
- [x] T015 [US1] En `test/presentation/exercise_screen_test.dart`, agregar la prueba `'(j) Nivel 3 transversal: una sola señal por ataque, del tipo sorteado, y HUD NIVEL 3'`, con el mismo arnés `h` de las pruebas (h) e (i): `h.start(tester, level: 'Nivel 3', pattern: 'Transversal')`. Comprobar que:
  - `session.level.id == 'level_3'`;
  - el HUD muestra `NIVEL 3` y `Defensa o evasión lateral`;
  - en los 6 primeros ataques, el `SignalPainter` recibe exactamente una señal con `responseType == attack.responseType`, en el lado de `SignalPlacement.forAttack(attack)` y del color del sable. El arnés ya inyecta `ScriptedRandomSource(List.filled(500, 0))` mediante `randomSourceProvider`. Con N = 5 por defecto, los ataques 1 a 5 son (right, defense) y el 6.º es (left, evasion), forzado por las dos rachas. Comprobar exactamente esa secuencia: símbolo de defensa azul a la izquierda × 5 y después flecha roja a la izquierda;
  - **FR-015**: el texto de todos los `Text` del panel de nivel del HUD es idéntico durante un ataque de defensa y durante uno de evasión, y no contiene "Defensa" ni "Evasión" como palabra suelta, solo "Defensa o evasión lateral".

**Checkpoint**: US1 está verificada. El Nivel 3 transversal cumple FR-004 a FR-011 y SC-002 a SC-005.

---

## Phase 4: User Story 2 - Decidir entre defender y evadir ante el corte frontal (Priority: P2)

**Goal**: El Nivel 3 con el Patrón frontal se comporta igual que el transversal en señales y rachas. El oponente se mueve igual que en los Niveles 1 y 2, sin revelar el lado ni la respuesta.

**Independent Test**: Elegir Nivel 3 + Frontal y comprobar las señales en cada ataque, y que el oponente sube a _Chochôn-se_ y ejecuta _Chungmyôn begi_ como en el Nivel 1 (spec US2).

### Tests for User Story 2 (después del código)

- [x] T016 [P] [US2] En `test/domain/exercise_engine_simulation_test.dart`, llamar `_level3Simulations('Nivel 3 frontal (Spec 006, US2)', testLevel3Session, checkMotionSide: false)`, con el comentario "El frontal no se refleja: la comprobación de motion.side no aplica". Depende de T014.
- [x] T017 [P] [US2] En `test/domain/exercise_engine_level3_test.dart`, agregar un grupo `'Nivel 3 frontal (Spec 006, US2)'` con dos pruebas:
  - **US2-3**: con `testLevel3Session()`, N = 5, duración de 60 s y semillas 1 a 100, cada ejercicio tiene al menos una defensa y al menos una evasión;
  - **US2-2, FR-011**: para cada ataque, la postura del oponente en `signalAt + warningTime / 2` y en `cutStartAt` es la misma con `defense` que con `evasion` para el mismo lado; es decir, `OpponentMotion` no depende del tipo de respuesta. Comparar dos ataques del mismo lado y distinto tipo de una simulación sembrada.
    Depende de T013.

**Checkpoint**: US1 y US2 están verificadas con los dos patrones.

---

## Phase 5: User Story 3 - Elegir el Nivel 3 en la selección (Priority: P3)

**Goal**: La tarjeta del Nivel 3, con el ícono de las dos señales, y todas las tarjetas visibles sin desplazar, de 4:3 a 20:9 (FR-012, FR-012a, FR-013).

**Independent Test**: En los 7 lienzos de referencia, la columna NIVEL muestra 3 tarjetas completas sin desplazar, y la del Nivel 3 lleva el sable y la flecha en blanco (spec US3).

### Implementation for User Story 3

- [x] T018 [P] [US3] En `lib/presentation/selection/level_icon.dart` (research R6; [contrato §2](./contracts/selection-ui.md#2-levelicon)):
  - Cambiar `LevelIcon({required this.type, ...})` a `LevelIcon({required this.types, required this.size})`, con `final List<ResponseType> types`. El painter recibe la lista.
  - En `paint`, `box` es igual que hoy (margen del 10 %). Con `n = types.length` y `gap = 0.08 * box.width`, cada celda mide `cellWidth = (box.width - gap * (n - 1)) / n`. La celda `i` empieza en `box.left + i * (cellWidth + gap)`, y su caja de dibujo es el cuadrado de lado `min(cellWidth, box.height)` centrado en la celda.
  - Mover el código actual de cada `case` a `void _paintGlyph(Canvas canvas, Rect box, ResponseType type)` **sin cambiar ninguna fórmula**, y llamarlo por celda.
  - Con `n = 1`, la caja de la celda debe ser exactamente `box`, para que la imagen sea idéntica a la actual.
  - `shouldRepaint` compara las listas con `listEquals` (`package:flutter/foundation.dart`).
  - Doc-comment: "Ícono de un nivel: las señales de sus tipos de respuesta, lado a lado y en blanco (Spec 004, FR-021; Spec 006, FR-013)".
- [x] T019 [P] [US3] Crear `lib/presentation/selection/selection_density.dart` con `enum SelectionDensity { regular, compact }` (research R7; [contrato §3](./contracts/selection-ui.md#3-densidad-de-la-selección)):
  - `static SelectionDensity choose({required double columnsHeight, required double scale, required int maxCards})`: devuelve `regular` si `maxCards * 104 * scale + (maxCards - 1) * 14 * scale + 8 * scale <= columnsHeight`; si no, `compact`.
  - Getters con las medidas de cada densidad, en dp: `regular` las calcula a partir de `scale` con los valores actuales de la Spec 004; `compact` usa los valores fijos de esta tabla:

    | Medida                                             | `regular`              | `compact`                                                                |
    | -------------------------------------------------- | ---------------------- | ------------------------------------------------------------------------ |
    | `cardMinHeight`                                    | `104 s`                | `48`                                                                     |
    | `cardPaddingV` / `cardPaddingH`                    | `14 s` / `20 s`        | `4` / `12` (implementación: con `6`, el ícono de 40 daba tarjetas de 52) |
    | `cardGap`                                          | `14 s`                 | `6`                                                                      |
    | `iconTile` / `iconGlyph`                           | `72 s` / `56 s`        | `40` / `32`                                                              |
    | `iconGap`                                          | `18 s`                 | `10`                                                                     |
    | `titleSize`                                        | `28 s`                 | `16`                                                                     |
    | `detailSize` / `secondDetailSize`                  | `17 s` / `15 s`        | `12` / `12`                                                              |
    | `detailLineHeight` (agregada en la implementación) | la de la letra         | `1.25`                                                                   |
    | `checkSize`                                        | `30 s`                 | `20`                                                                     |
    | `columnHeaderSize` / `columnHeaderGap`             | `18 s` / `14 s`        | `13` / `6`                                                               |
    | `headerTitleSize` / `headerSubtitleSize`           | `46 s` / `20 s`        | `32` / `14`                                                              |
    | `pagePadding` (arriba, abajo, lados)               | `40 s`, `36 s`, `56 s` | `16`, `12`, `24`                                                         |
    | `sectionGap` (encabezado–columnas–pie)             | `28 s`                 | `10`                                                                     |
    | `columnsGap` (entre columnas)                      | `40 s`                 | `20`                                                                     |

  - Dart puro, salvo el import de `dart:ui` si hiciera falta; sin `BuildContext`.

- [x] T020 [US3] En `lib/presentation/selection/selection_card.dart`, agregar `required this.density` (`SelectionDensity`) y reemplazar cada medida fija (`104 * s`, `14 * s`, `20 * s`, `72 * s`, `56 * s`, `18 * s`, `28 * s`, `17 * s`, `15 * s`, `30 * s`, `12 * s`) por el getter correspondiente de T019. El radio, el borde y el anillo siguen escalando con `s` en `regular`; en `compact` escalan con `min(s, 0.7)`. Solo en `SelectionDensity.compact`, cada texto de detalle lleva `maxLines: 2` y `overflow: TextOverflow.ellipsis`. Con `SelectionDensity.regular`, el árbol de widgets y las medidas deben quedar **idénticos** a los de hoy, sin `maxLines`. En el teléfono de 889 × 400, ningún detalle real del catálogo debe quedar cortado; T024 lo comprueba. Depende de T019.
- [x] T021 [US3] En `lib/presentation/selection/selection_screen.dart` (FR-012a; research R7):
  - En `_Columns`, pasar `LevelIcon(types: level.responseTypes, size: ...)` en lugar de `type: level.responseTypes.first`.
  - Calcular la densidad **una sola vez**, en el `LayoutBuilder` existente de `build`, a partir de la altura total `H = constraints.biggest.height`:
    - `insets = MediaQuery.paddingOf(context).vertical` (la `SafeArea`);
    - `fixedRegular = 40 s + 36 s` (márgenes) `+ 46 s + 2 s + 20 s × 1.3` (encabezado) `+ 28 s + 28 s` (separaciones) `+ 64 s` (pie) `+ 18 s × 1.3 + 14 s` (encabezado de columna);
    - `density = SelectionDensity.choose(columnsHeight: H - insets - fixedRegular, scale: s, maxCards: max(catalog.levels.length, catalog.patterns.length))`;
    - mientras el catálogo carga o falla, usar `regular`;
    - pasar `density` a `_Header`, al `Padding` de la página, a `_Columns`, a `_CardColumn` y a cada `SelectionCard`. Con `compact`, el encabezado, los márgenes y las separaciones usan las medidas compactas de T019;
    - documentar el cálculo en un comentario.
  - En `_CardColumn`, reemplazar el `ListView.separated` por un `Column` con `mainAxisSize: MainAxisSize.min` y separaciones de `density.cardGap`, conservando el margen de `4 s` para el anillo.
  - **Cambio en la implementación (2026-11-18):** la red de seguridad por fórmula se reemplazó por un `SingleChildScrollView` fijo en cada `_CardColumn`, que solo se mueve si el contenido real no cabe. Motivo: la prueba de la Spec 005 "4:3 con letra ×1.3" exige que no haya desbordes, y ninguna fórmula prevé la letra ampliada por accesibilidad. Con la densidad elegida no hay nada que desplazar (T024 comprueba `maxScrollExtent == 0`). El texto original queda abajo como referencia.
  - ~~**Red de seguridad** (research R7, punto 4): con `compact`, calcular `fixedCompact = 16 + 12 + 32 + 14 × 1.3 + 10 + 10 + 64 s + 13 × 1.3 + 6` y, **por columna**, `needed = Σ alto(tarjeta) + (n − 1) × 6 + 8`:
    - `alto(tarjeta) = max(48, 12 + 16 × 1.1 + líneas × 12 × 1.25)`;
    - `líneas` es el número de textos de detalle de la tarjeta: 1 en las de nivel ("respuesta — propósito") y 1 o 2 en las de patrón (romanización y, si existe, hangul). Cada texto cuenta como una línea, porque en el teléfono de referencia ninguno ocupa dos (T024 lo comprueba).

    Solo la columna con `needed > H - insets - fixedCompact` se envuelve en `SingleChildScrollView`. No medir el render. Con los lienzos de referencia, ninguna columna debe envolverse: T024 lo comprueba buscando que no haya ningún `SingleChildScrollView` en la selección.~~

  - Pasar `density` a cada `SelectionCard`. El pie (`_Footer`) **no cambia**.
    Depende de T018, T019 y T020.

### Tests for User Story 3 (después del código)

- [x] T022 [P] [US3] Crear `test/presentation/level_icon_test.dart`:
  - **Un tipo**: pintar `LevelIcon(types: [defense])` y `[evasion]` a 64 × 64 con `PictureRecorder`. El área pintada (bounding box de píxeles no transparentes) coincide, con una tolerancia de 1 px, con la de un painter de referencia que copia en la prueba las fórmulas del `case` anterior.
  - **Dos tipos** `[defense, evasion]`: solo hay píxeles blancos (`AppColors.textPrimary`) o transparentes, sin rojo, azul ni amarillo. Hay píxeles pintados en la mitad izquierda y en la derecha. La mitad izquierda contiene el sable y la derecha la flecha: comparar con los bounding boxes de cada glifo dibujado solo en su celda.
- [x] T023 [P] [US3] Crear `test/presentation/selection_density_test.dart` con `choose`:
  - `scale: 1`, `maxCards: 4` y `columnsHeight: 466` → `regular`; con `465` → `compact`;
  - `scale: 0.7` y `maxCards: 3` con el alto libre del teléfono de 889 × 400 (≈ 185) → `compact`;
  - los getters de `compact` devuelven los valores de la tabla de T019;
  - con `regular` y `scale: 1`, los getters devuelven las medidas de la Spec 004.
- [x] T024 [US3] En `test/presentation/selection_screen_test.dart`, agregar el grupo `'Spec 006: Nivel 3 y tarjetas sin desplazar'` ([contrato §1 y §4](./contracts/selection-ui.md#4-lienzos-de-referencia-sc-007a)):
  - **US3-1, US3-2**: con `_realCatalog()`, la columna NIVEL muestra `NIVEL 1`, `NIVEL 2` y `NIVEL 3` en orden, con el Nivel 1 seleccionado. La tarjeta del Nivel 3 dice `Defensa o evasión lateral — Decisión bajo presión` y su `LevelIcon` tiene `types == [defense, evasion]`.
  - **US3-3**: tocar `NIVEL 3` y `Transversal` hace que el resumen diga `Nivel 3 · Transversal · 30 s`; INICIAR abre el ejercicio con `level_3`. Repetir y Volver se cubren con la prueba existente (i), parametrizada si es barato; si no, basta con este paso.
  - **US3-4, SC-007a**: para cada lienzo de la tabla del contrato §4 (1778 × 800, 1422 × 800, 1280 × 800, 1067 × 800, 1024 × 768, 2400 × 1080 y 889 × 400), y con el catálogo real (3 niveles) y con un catálogo de prueba de 4 niveles (el `_testCatalog` con un nivel más):
    - no hay excepciones de overflow (`tester.takeException()` es null);
    - el `Rect` de cada `SelectionCard` (`tester.getRect`) está completamente dentro de la vista y no se superpone a los `Rect` del resumen, de `settingsButton` ni del botón INICIAR;
    - no existe ningún `Scrollable` cuyo `position.maxScrollExtent > 0` (cambio en la implementación: las columnas sí tienen un `SingleChildScrollView`, ver T021);
    - el grupo carga Rajdhani con `FontLoader` y monta la selección con `buildAppTheme()`, para medir con la letra real;
    - ningún texto de tarjeta queda cortado con puntos suspensivos (`TextPainter.didExceedMaxLines == false` para cada detalle con `maxLines`);
    - la densidad esperada es la del contrato §4: `regular` en los lienzos de 768 dp de alto o más, y `compact` en 889 × 400. Se verifica por el tamaño del título: `28 s` frente a `16`.
  - No modificar las pruebas existentes del archivo. Si alguna usaba `ListView` para encontrar tarjetas, consultarlo antes de cambiarla.

**Checkpoint**: Las tres historias están completas y verificadas.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T025 Ejecutar `flutter analyze` (sin avisos nuevos) y `flutter test` (todo en verde). Confirmar que `test/domain/fixtures/sequence_regression.json` no cambió desde T003: `git diff <commit de T003> -- test/domain/fixtures/` debe salir vacío.
- [X] T026 Revisar `git diff main --stat`. Solo pueden cambiar:
  - `assets/catalog/catalog.json`;
  - `lib/domain/catalog/enums.dart` (comentario);
  - `lib/domain/exercise/{side_sequencer.dart (borrado), streak_sequencer.dart, exercise_engine.dart}`;
  - `lib/presentation/selection/{level_icon.dart, selection_density.dart, selection_card.dart, selection_screen.dart}`;
  - las pruebas y fixtures listados en este archivo;
  - `specs/006-nivel3-decision/`;
  - `.specify/memory/constitution.md` (enmienda 1.1.0 del Principio III, aprobada el 2026-11-18).
    Cualquier otro archivo se revierte o se consulta.
- [X] T027 [P] Buscar referencias obsoletas con `rg -n "SideSequencer|side_sequencer|lastSide|responseTypes\.first" lib test specs/006-nivel3-decision`. No debe quedar ninguna en `lib/` ni en `test/`. Las menciones históricas en specs anteriores no se tocan.
- [ ] T028 Validación manual según [quickstart.md §2](./quickstart.md#2-validación-manual-dispositivo-en-horizontal), en una tablet o TV y en un teléfono en horizontal: los pasos 1 a 6, incluido el de N = 1. Anotar en la descripción del PR qué dispositivos se usaron y el resultado de la prueba de legibilidad a 3 m con 0.7 s de aviso (SC-006) y del ícono (SC-007). Pospuesta temporalmente hasta conseguir otros dispositivos.
- [ ] T029 Commits pendientes con Conventional Commits:
  - `docs: amend constitution to v1.1.0 (Principio III, regla de secuencia genérica)`. Es un commit propio, solo con `.specify/memory/constitution.md`, y puede hacerse en cualquier momento antes del PR. Antes de hacerlo, quitar del archivo el comentario Sync Impact Report;
  - `feat: agregar el Nivel 3 al catálogo` (T009–T011);
  - `test: verificar el Nivel 3 con los dos patrones` (T012–T017);
  - `feat: ícono mixto y selección sin desplazar` (T018–T024).
    Después, abrir un PR de `006-nivel3-decision` a `main` (Principio X).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001)**: sin dependencias.
- **Foundational (T002–T011)**: depende de T001. **T002 → T003 deben terminar antes de tocar `lib/domain/`** (T004–T006). Después: T004 → T005 → T007 → T008. T006 puede hacerse en paralelo con T004. T009, T010 y T011 pueden hacerse después de T008.
- **US1 (T012–T015)**: depende de la Foundational completa.
- **US2 (T016–T017)**: depende de la Foundational. T016 depende de T014 y T017 de T013 (mismos archivos).
- **US3 (T018–T024)**: depende solo de T009 (catálogo). Es independiente de US1 y US2.
- **Polish (T025–T029)**: depende de todas las historias.

### Within Each User Story

- US1 y US2 no tienen implementación propia: la regla vive en la Foundational, y sus fases son de verificación.
- US3: T018 y T019 [P] → T020 → T021 → pruebas T022 a T024.

### Archivos compartidos (no paralelizar entre sí)

- `test/domain/exercise_engine_simulation_test.dart`: T014 → T016.
- `test/domain/exercise_engine_level3_test.dart`: T013 → T017.
- `test/domain/streak_sequencer_test.dart`: T007 → T012.
- `lib/presentation/selection/selection_screen.dart`: solo T021.

### Parallel Opportunities

- Foundational: T006 junto con T004; T010 junto con T009.
- US1: T012, T013 y T014 en paralelo (archivos distintos); T015 después.
- US3: T018 y T019 en paralelo; T022 y T023 en paralelo después de T021.
- US1/US2 y US3 pueden avanzar en paralelo después de la Foundational.

---

## Parallel Example: User Story 1

```text
T012 [US1] streak_sequencer_test.dart (grupo genérico)
T013 [US1] exercise_engine_level3_test.dart (orden, rachas, proporciones)
T014 [US1] exercise_engine_simulation_test.dart (_level3Simulations transversal)
→ luego T015 [US1] exercise_screen_test.dart
```

## Parallel Example: User Story 3

```text
T018 [US3] level_icon.dart (n glifos)
T019 [US3] selection_density.dart
→ T020 selection_card.dart → T021 selection_screen.dart
→ T022 level_icon_test.dart  |  T023 selection_density_test.dart  →  T024 selection_screen_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 y Phase 2. La regresión se graba primero y debe seguir intacta tras el refactor.
2. Phase 3 (US1): verificar el Nivel 3 transversal.
3. **Parar y validar**: el Nivel 3 transversal ya se juega desde la selección (con el ícono provisional de defensa).

### Incremental Delivery

1. Foundational: el Nivel 3 se juega; los Niveles 1 y 2 quedan idénticos (regresión).
2. US1: verificado con el corte transversal.
3. US2: verificado con el corte frontal.
4. US3: ícono mixto y selección sin desplazar en todos los lienzos.
5. Polish: diff acotado, validación manual y PR.

## Notes

- La prueba de regresión es la garantía central de las condiciones del responsable. **Nunca** regenerar su fixture después de T003.
