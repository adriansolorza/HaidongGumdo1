---

description: "Lista de tareas de la Spec 001: motor del ejercicio + Nivel 1 + Patrón frontal"
---

# Tasks: Motor del ejercicio + Nivel 1 + Patrón frontal

**Input**: Documentos de diseño en `specs/001-motor-nivel1-frontal/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (catalog.schema.json, domain-ports.md, ui-screens.md), quickstart.md

**Tests**: SÍ se incluyen. La constitution (Principio VI) exige pruebas del dominio **antes de cerrar cada historia**, escritas **después del código** y **derivadas de los criterios de aceptación** de la spec (no del código). Por eso, en cada historia las pruebas van después de la implementación. Las pruebas de datos y presentación vienen de research.md R14.

**Organization**: Las tareas se agrupan por historia de usuario para implementar y probar cada una por separado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia a la que pertenece (US1, US2)
- Cada descripción incluye la ruta exacta del archivo

## Path Conventions

Un solo proyecto Flutter en la raíz del repositorio (plan.md, "Structure Decision"): `lib/domain/` (Dart puro), `lib/data/`, `lib/presentation/`, `assets/catalog/` y `test/` reflejando las capas.

**Reglas generales para todas las tareas**:

- `lib/domain/**` NO importa `package:flutter`, `flutter_riverpod`, `flutter_tts` ni `wakelock_plus` (Principio II). Solo `dart:core`/`dart:math`/`dart:async` si hace falta.
- Identificadores en inglés; textos visibles en español desde `lib/presentation/strings_es.dart` o desde el catálogo; términos coreanos solo desde el glosario del catálogo, nunca escritos en el código (Principios III y IX).
- No agregar ningún paquete fuera de `flutter_riverpod`, `flutter_tts` y `wakelock_plus` (Principio VII, ADR 0001–0003).
- Entidades del dominio inmutables (`final` en todos los campos, constructores `const` cuando se pueda, `==`/`hashCode` en value objects).
- Commits con Conventional Commits (`feat:`, `test:`, `chore:`…) en la rama `001-motor-nivel1-frontal`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dejar el proyecto Flutter ya creado (`flutter create`) listo para la estructura del plan.

- [X] T001 Actualizar `pubspec.yaml`: `description: "Entrenamiento de reacción para Haidong Gumdo"`; mantener `environment: sdk: ^3.13.5` y agregar `flutter: ">=3.47.7"` (research R1); quitar `cupertino_icons` (no se usa, solo Android); agregar con `flutter pub add` las dependencias aprobadas `flutter_riverpod`, `flutter_tts` y `wakelock_plus` (última estable compatible con Dart 3.13.5); declarar el asset `assets/catalog/catalog.json` en la sección `flutter: assets:`. Ejecutar `flutter pub get` y confirmar que `pubspec.lock` se actualiza
- [X] T002 [P] Endurecer `analysis_options.yaml`: mantener `include: package:flutter_lints/flutter.yaml` y activar las reglas `prefer_single_quotes`, `prefer_const_constructors`, `prefer_final_fields`, `always_declare_return_types` y `directives_ordering` (sin paquetes nuevos)
- [X] T003 [P] Crear la estructura de carpetas vacía del plan: `lib/domain/catalog/`, `lib/domain/exercise/`, `lib/domain/ports/`, `lib/data/catalog/`, `lib/data/platform/`, `lib/presentation/selection/`, `lib/presentation/exercise/painters/`, `assets/catalog/`, `test/domain/fakes/`, `test/data/`, `test/presentation/`
- [X] T004 [P] Eliminar la prueba de plantilla `test/widget_test.dart` (prueba el contador de `flutter create`, que se reemplaza)
- [X] T005 [P] Fijar la orientación horizontal en Android: en `android/app/src/main/AndroidManifest.xml`, agregar `android:screenOrientation="sensorLandscape"` a la `activity` principal (complementa `SystemChrome` de R11) y verificar que la etiqueta `android:label` sea `Haidong Gumdo`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Catálogo, parámetros, puertos y esqueleto de la app que ambas historias necesitan.

**⚠️ CRITICAL**: Ninguna historia puede empezar hasta terminar esta fase.

### Dominio: enums, catálogo y puertos

- [ ] T006 [P] Crear los enums del catálogo en `lib/domain/catalog/enums.dart`: `enum ResponseType { defense }`, `enum VoiceCommand { start, end }`. Agregar un comentario de una línea indicando que `evasion` (002) y `counter` (006) se agregan en specs futuras (excepción del Principio III: tipo de señal nuevo)
- [ ] T007 [P] Crear `CatalogException implements Exception` en `lib/domain/catalog/catalog_exception.dart`, con un campo `final String message` y `toString()` que lo incluya
- [ ] T008 Crear las entidades del catálogo en `lib/domain/catalog/catalog.dart` (depende de T006, T007), inmutables y con `==`/`hashCode`, según data-model.md:
  - `GlossaryTerm`: `id` (`String`, "`snake_case` y único"), `romanization` (`String`, "No vacío, exactamente como en el glosario"), `hangul` (`String?`, "Opcional"), `meaning` (`String`, "En español")
  - `Level`: `id` (`String`, "Único"), `order` (`int`, "≥ 1; único"), `name`, `responseLabel`, `purpose` (`String`), `responseTypes` (`List<ResponseType>`, "Al menos 1; sin duplicados"; lista inmodificable)
  - `Pattern`: `id` (`String`, "Único"), `order` (`int`, "≥ 1; único"), `name`, `stanceTermId` ("Existe en el glosario"), `cutTermId` ("Existe en el glosario"), `cut` (`CutMotion`)
  - `Point2` (`x`, `y`: `double`), `SaberPose` (`hilt`, `tip`: `Point2`) y `CutMotion` (`start`, `end`: `SaberPose`; `mirroredBySide`: `bool`), value objects con `==`/`hashCode` (data-model.md)
  - `Catalog`: `version` (`int`, "≥ 1"), `glossary` (`List<GlossaryTerm>`, "`id` únicos"), `voiceCommands` (`Map<VoiceCommand, String>`, "Debe tener `start` y `end`; cada id existe en `glossary`"), `levels` (`List<Level>`, "Al menos 1; `id` únicos; ordenados por `order`"), `patterns` (`List<Pattern>`, "Al menos 1; `id` únicos; ordenados por `order`"). Métodos `GlossaryTerm term(String id)` (lanza `CatalogException` si no existe) y `GlossaryTerm voiceTerm(VoiceCommand c)`
- [ ] T009 [P] Crear `Session` en `lib/domain/exercise/session.dart`: value object con `final Level level` y `final Pattern pattern` (depende de T008)
- [ ] T010 [P] Crear los puertos en `lib/domain/ports/` copiando exactamente las firmas y comentarios de `contracts/domain-ports.md`: `catalog_repository.dart` (`CatalogRepository.load()`), `random_source.dart` (`RandomSource.nextInt(int maxExclusive)`, "Entero uniforme en [0, maxExclusive). maxExclusive >= 1"), `elapsed_clock.dart` (`ElapsedClock.start()`, `Duration get elapsed`), `voice_announcer.dart` (`prepare(Catalog)`, `announce(VoiceCommand)` sin espera, `stop()`), `screen_wake_lock.dart` (`enable()`, `disable()`). Todas como `abstract interface class` (depende de T008)

### Dominio: parámetros e invariante (FR-006, FR-007)

- [ ] T011 Crear `lib/domain/exercise/exercise_parameters.dart` (research R7, data-model.md):
  - `ParameterLimits` con constantes: `duration` 30 s – 180 s; `maxRepeats` 1 – 5; `warningTime` 330 ms – 1000 ms; `cutSpeed` 300 ms – 1000 ms; `attackInterval` 500 ms – 5000 ms; `intervalFloorMargin = 500 ms`
  - `enum ParameterViolation { durationOutOfRange, maxRepeatsOutOfRange, warningTimeOutOfRange, cutSpeedOutOfRange, attackIntervalOutOfRange, intervalBelowFloor }`
  - `InvalidParametersException implements Exception` con `final List<ParameterViolation> violations`
  - `ExerciseParameters` inmutable con `duration`, `maxRepeats`, `warningTime`, `cutSpeed`, `attackInterval`; getter `intervalFloor = cutSpeed + 500 ms`; `List<ParameterViolation> validate()` (rangos inclusivos en ambos extremos + "`attackInterval ≥ intervalFloor`"); fábrica `ExerciseParameters.create(...)` que lanza `InvalidParametersException` si `validate()` no está vacío; `ExerciseParameters.defaults()` = 30 s, N = 5, 700 ms, 500 ms, 2500 ms (siempre válido)

### Datos: catálogo

- [ ] T012 [P] Crear `assets/catalog/catalog.json` con exactamente el ejemplo de `contracts/catalog.schema.json`: `version: 1`; glosario `si_jak` ("Si-jak", "시작", "Voz de inicio"), `guman` ("Guman", "그만", "Voz de fin"), `chochon_se` ("Chochôn-se", "초천세", "Postura con el sable sobre la cabeza"), `chungmyon_begi` ("Chungmyôn begi", "정면베기", "Corte frontal"); `voiceCommands` `{start: si_jak, end: guman}`; nivel `level_1` (order 1, "Nivel 1", "Defensa", "Calentamiento", `["defense"]`); patrón `frontal` (order 1, "Frontal", `chochon_se`, `chungmyon_begi`, `cut: {start: {hilt: [0, -0.9], tip: [0, -1.6]}, end: {hilt: [0, -0.2], tip: [0, -0.35]}, mirroredBySide: false}`). Guardar en UTF-8 y comprobar que la romanización y el hangul coinciden carácter por carácter con el glosario de spec.md (FR-003)
- [ ] T013 Crear `CatalogJsonMapper` en `lib/data/catalog/catalog_json_mapper.dart` con `Catalog fromJsonString(String source)` (depende de T008): parsear con `dart:convert`; validar a mano las reglas de `contracts/catalog.schema.json` (campos requeridos, `additionalProperties: false`, ids con patrón `^[a-z][a-z0-9_]*$`, `version ≥ 1`, `order ≥ 1`, `minItems: 1`, `minLength: 1`, `responseTypes` sin duplicados y dentro de los valores de `ResponseType`, `cut` con `start`/`end` (`hilt` y `tip` como pares `[x, y]` con cada valor en [−2, 2]) y `mirroredBySide`); validar ids únicos de términos, niveles y patrones, `order` único por lista, y que `stanceTermId`, `cutTermId`, `voiceCommands.start` y `voiceCommands.end` existan en `glossary`; ordenar `levels` y `patterns` por `order`. Cualquier violación o JSON mal formado lanza `CatalogException` con un mensaje que indique la ruta del campo (p. ej. `patterns[0].cutTermId`)
- [ ] T014 Crear `AssetCatalogRepository implements CatalogRepository` en `lib/data/catalog/asset_catalog_repository.dart` (depende de T010, T013): constructor con `AssetBundle bundle` (por defecto `rootBundle`) y `String assetPath = 'assets/catalog/catalog.json'`; `load()` lee con `loadString` y delega en `CatalogJsonMapper`
- [ ] T015 [P] Escribir `test/data/catalog_json_mapper_test.dart` (research R14): (a) el asset real `assets/catalog/catalog.json` leído con `File` se parsea, tiene 1 nivel, 1 patrón y los 4 términos con romanización y hangul exactos; (b) `cutTermId` inexistente → `CatalogException`; (c) JSON mal formado → `CatalogException`; (d) falta `voiceCommands.end` → `CatalogException`; (e) `responseTypes` vacío o con `"evasion"` → `CatalogException`; (f) ids de nivel duplicados → `CatalogException`; (g) dos niveles con `order` 2 y 1 salen ordenados por `order`; (h) `cut` ausente, un punto con 1 o 3 componentes, o un valor fuera de [−2, 2] → `CatalogException`

### Dominio: fakes de prueba

- [ ] T016 [P] Crear los fakes en `test/domain/fakes/` (depende de T010): `manual_clock.dart` (`ManualClock implements ElapsedClock` con `advance(Duration)` y `set(Duration)`); `scripted_random_source.dart` (`ScriptedRandomSource` que devuelve una lista de enteros en orden, lanza `StateError` si se agota o si un valor ≥ `maxExclusive`, y expone `int consumed`); `seeded_random_source.dart` (`SeededRandomSource(int seed)` sobre `dart:math` `Random(seed)`); `fake_voice_announcer.dart` (registra `prepare`, `announce(command)` y `stop` en una lista `calls`); `fake_screen_wake_lock.dart` (registra `enable`/`disable` y expone `bool enabled`)

### Presentación: esqueleto de la app

- [ ] T017 [P] Crear `lib/presentation/theme.dart` (research R12, Principio VIII): constantes `AppColors.background = Color(0xFF121212)`, `saberBlue = Color(0xFF1E6BFF)`, `saberRed = Color(0xFFFF2D2D)`, `saberYellow = Color(0xFFFFD400)`, `saberWhite = Color(0xFFFFFFFF)`, `outline = Color(0xFF000000)`; `const double kOutlineWidth = 4.0` (dp, mínimo); `ThemeData buildAppTheme()` oscuro con `scaffoldBackgroundColor` = fondo y tipografía grande para la cuenta regresiva
- [ ] T018 [P] Crear `lib/presentation/strings_es.dart` (research R15) con una clase `StringsEs` de constantes estáticas: `appTitle = 'Haidong Gumdo'`, `levelHeader = 'Nivel'`, `patternHeader = 'Patrón'`, `start = 'Iniciar'`, `stop = 'Detener'`, `repeat = 'Repetir'`, `back = 'Volver'`, `loadingCatalog = 'Cargando catálogo…'`, `catalogError = 'No se pudo cargar el catálogo de ejercicios.'`, `remaining = 'Restante'`. Ningún término coreano aquí
- [ ] T019 Crear `lib/presentation/providers.dart` (research R13, sin codegen) con los providers de puertos `catalogRepositoryProvider` (→ `AssetCatalogRepository()`), `randomSourceProvider`, `elapsedClockProvider`, `voiceAnnouncerProvider`, `screenWakeLockProvider` (los cuatro últimos lanzan `UnimplementedError` hasta que US1 conecte sus adaptadores; se reemplazan con `overrides` en pruebas), y `catalogProvider = FutureProvider<Catalog>` que llama a `catalogRepositoryProvider.load()` (depende de T010, T014)
- [ ] T020 Crear `lib/app.dart` con `HaidongGumdoApp extends StatelessWidget`: `MaterialApp(title: StringsEs.appTitle, theme: buildAppTheme(), debugShowCheckedModeBanner: false, home: …)` con `home` temporal `Scaffold` vacío hasta T036 (depende de T017, T018)
- [ ] T021 Reescribir `lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])` (R11), `runApp(const ProviderScope(child: HaidongGumdoApp()))`. La llamada a `voice.prepare()` se agrega en T040 (depende de T020)

**Checkpoint**: `flutter analyze` sin errores y `flutter test test/data` en verde. Lista la base: las historias pueden empezar.

---

## Phase 3: User Story 1 - Ejercicio de defensa ante el corte frontal (Priority: P1) 🎯 MVP

**Goal**: Desde la selección, pulsar Iniciar y ver un ejercicio completo de Nivel 1 / Patrón frontal: cuenta 3-2-1, *Si-jak*, ataques con lado aleatorio (máx. N seguidos), señal de defensa del lado contrario al color, corte animado de duración exacta y cierre con *Guman*, con Repetir/Volver al final.

**Independent Test**: Iniciar un ejercicio con los valores por defecto y observarlo de principio a fin desde 3 m (quickstart.md §2, pasos 1–5 y 9–10): cuenta regresiva, *Si-jak*, azul → símbolo a la izquierda, rojo → a la derecha, tiempos, cierre con *Guman* y botones Repetir/Volver.

### Implementación del dominio (US1)

- [ ] T022 [P] [US1] Crear `lib/domain/exercise/attack.dart`: `enum Side { right, left }` con getter `Side get opposite`; `Attack` inmutable con `index` (`int`, "0, 1, 2… dentro del ejercicio"), `side` (`Side`, "azul = `right`, rojo = `left`"), `responseType` (`ResponseType`, "Uno de `level.responseTypes`"), `signalAt` (`Duration`, "< E"), `cutStartAt` ("`signalAt + warningTime`"), `cutEndAt` ("`cutStartAt + cutSpeed`"), `nextSignalAt` ("`cutStartAt + sorteo`, con el sorteo en [`intervalFloor`, `attackInterval`]")
- [ ] T023 [P] [US1] Crear `lib/domain/exercise/signal.dart` (depende de T022): `Signal` inmutable con `responseType` y `screenSide` (`Side`); `abstract final class SignalPlacement` con `static Signal forAttack(Attack attack)` usando un `switch` exhaustivo sobre `ResponseType`: `defense` → `screenSide = attack.side.opposite` (FR-015). Es la única regla de colocación de la señal
- [ ] T024 [P] [US1] Crear `lib/domain/exercise/side_sequencer.dart` (research R4, FR-017, FR-018; depende de T010, T022): `SideSequencer({required int maxRepeats, required RandomSource random})`, estado `Side? lastSide` y `int streak` reiniciados por instancia; `Side next()`: si `streak == maxRepeats` devuelve `lastSide!.opposite` **sin llamar a `random`**; si no, `random.nextInt(2) == 0 ? Side.right : Side.left`; actualiza `lastSide`/`streak`
- [ ] T025 [P] [US1] Crear `lib/domain/exercise/exercise_status.dart` (FR-020, research R5): `enum ExerciseStatus { ready, countdown, running, finishing, finished, cancelled }`; `const Map<ExerciseStatus, Set<ExerciseStatus>> allowedTransitions` con exactamente las filas de data-model.md (`ready→countdown`, `countdown→running|cancelled`, `running→finishing|finished|cancelled`, `finishing→finished|cancelled`); función `void ensureTransition(ExerciseStatus from, ExerciseStatus to)` que lanza `StateError` si no está en la tabla; getter `bool get isTerminal` (`finished`, `cancelled`). Comentario de una línea sobre la extensión futura `paused`
- [ ] T026 [P] [US1] Crear `lib/domain/exercise/exercise_event.dart` (depende de T022): `sealed class ExerciseEvent` con subclases `StartVoice`, `SignalShown(Attack)`, `CutStarted(Attack)`, `CutEnded(Attack)`, `EndVoice`, `Cancelled`, cada una con `final Duration at` (instante en la línea de tiempo) y `==`/`hashCode`
- [ ] T027 [US1] Crear `lib/domain/exercise/exercise_snapshot.dart` (depende de T022, T023, T025, T026): `enum AttackPhase { guard, warning, cut }`; `enum SaberColor { white, yellow, blue, red }`; `ExerciseSnapshot` inmutable con `status`, `phase` (`AttackPhase?`, "solo en `running` y `finishing`"), `countdownValue` (`int?`, "3, 2, 1 solo en `countdown`"), `saberColor` ("`white` en `ready`, `countdown`, `finished` y `cancelled`"; `yellow` en `guard`; `blue` si `side == right` y `red` si `side == left` en `warning`/`cut`), `currentAttack` (`Attack?`), `signal` (`Signal?`, "en `warning` y `cut`"), `cutProgress` (`double?` "en [0,1] (solo en `cut`)"), `elapsed`, `remaining` ("hasta E, nunca negativo"); y `ExerciseTick` con `final ExerciseSnapshot snapshot` y `final List<ExerciseEvent> events` (inmodificable)
- [ ] T028 [US1] Implementar `ExerciseEngine` en `lib/domain/exercise/exercise_engine.dart` con `start()` y `advanceTo()` según `contracts/domain-ports.md` y research R2/R3 (depende de T009, T011, T023, T024, T025, T027):
  - Constructor `ExerciseEngine({required Session session, required ExerciseParameters parameters, required RandomSource random})`; lanza `InvalidParametersException` si `parameters.validate()` no está vacío (FR-007)
  - Constantes: `countdownLength = 3 s`; `S = 3 s` (*Si-jak*); `E = S + duration`
  - `start()`: `ready → countdown` vía `ensureTransition`; t = 0
  - `advanceTo(elapsed)`: `ArgumentError` si `elapsed` es menor que el anterior; en estado terminal devuelve el snapshot final sin eventos; si no, procesa en orden todos los instantes cruzados en (anterior, elapsed] sin repetir eventos: `S` → `countdown→running` + `StartVoice`; programa la 1.ª señal en `S + draw` (FR-012); para cada señal programada con instante `< E`: `SignalShown` (lado de `SideSequencer`, `responseType = level.responseTypes.first`), `CutStarted` en `signalAt + warningTime`, `CutEnded` en `cutStartAt + cutSpeed`; siguiente señal en `cutStartAt + draw` (FR-011). Una señal con instante `≥ E` no se programa ni se emite (G5)
  - Sorteo del intervalo en ms enteros: `floorMs + random.nextInt(maxMs − floorMs + 1)` con `floorMs = intervalFloor`, `maxMs = attackInterval` (ambos incluidos)
  - Fin (FR-013, G6): al cruzar `E` con ataque en curso (`signalAt ≤ t < cutEndAt`) → `running→finishing`; al llegar a `cutEndAt` de ese ataque → `finishing→finished` + `EndVoice`. Al cruzar `E` sin ataque en curso → `running→finished` + `EndVoice` en `E`. `EndVoice` se emite una sola vez
  - El snapshot se calcula a partir del tiempo absoluto (sin acumular deriva): `countdownValue = 3 − floor(t/1 s)` en [0,3); `phase`; `cutProgress = (t − cutStartAt) / cutSpeed` limitado a [0,1]; `remaining = max(0, E − t)`
  - Toda transición pasa por `ensureTransition` (G10). Dejar `cancel()` sin implementar en esta tarea (`UnimplementedError`; lo hace T047)

### Implementación de datos (US1)

- [ ] T029 [P] [US1] Crear `DartRandomSource implements RandomSource` en `lib/data/platform/dart_random_source.dart` sobre `dart:math` `Random()`; `nextInt` lanza `ArgumentError` si `maxExclusive < 1`
- [ ] T030 [P] [US1] Crear `StopwatchClock implements ElapsedClock` en `lib/data/platform/stopwatch_clock.dart` sobre `Stopwatch` de `dart:core`: `start()` hace `reset()` + `start()`; `elapsed` devuelve `stopwatch.elapsed`
- [ ] T031 [P] [US1] Crear `FlutterTtsVoiceAnnouncer implements VoiceAnnouncer` en `lib/data/platform/flutter_tts_voice_announcer.dart` (research R8, FR-029, FR-030): `prepare(catalog)` idempotente; si `isLanguageAvailable('ko-KR')` es `true` → `setLanguage('ko-KR')` y textos = `hangul` de los términos de `catalog.voiceTerm(start/end)`; si no → no cambia el idioma y textos = `romanization`; `announce(command)` llama a `speak(texto)` sin `await` (fire-and-forget con `unawaited`); todas las llamadas envueltas en `try/catch` que no relanza, y si `prepare` falló `announce` no hace nada; `stop()` llama a `tts.stop()` con `try/catch`
- [ ] T032 [P] [US1] Crear `WakelockPlusScreenWakeLock implements ScreenWakeLock` en `lib/data/platform/wakelock_plus_screen_wake_lock.dart` (research R9): `enable()` → `WakelockPlus.enable()`, `disable()` → `WakelockPlus.disable()`, ambos con `try/catch` que no relanza

### Implementación de la presentación (US1)

- [ ] T033 [US1] Conectar los adaptadores en `lib/presentation/providers.dart` (depende de T019, T029–T032): `randomSourceProvider` → `DartRandomSource()`, `elapsedClockProvider` → `StopwatchClock()`, `voiceAnnouncerProvider` → `FlutterTtsVoiceAnnouncer(FlutterTts())`, `screenWakeLockProvider` → `WakelockPlusScreenWakeLock()`. Agregar `selectedSessionProvider = NotifierProvider<SelectedSessionNotifier, Session?>` cuyo `build()` observa `catalogProvider` y devuelve `Session(level: catalog.levels.first, pattern: catalog.patterns.first)` (FR-004), con métodos `selectLevel(Level)` y `selectPattern(Pattern)` (FR-005)
- [ ] T034 [US1] Crear `ExerciseController extends Notifier<ExerciseSnapshot>` y `exerciseControllerProvider` en `lib/presentation/exercise/exercise_controller.dart` (research R13, contracts/ui-screens.md "Efectos secundarios"; depende de T028, T033): `start(Session session)` crea un `ExerciseEngine` nuevo con `ExerciseParameters.defaults()` y `randomSourceProvider`, llama `clock.start()`, `engine.start()`, `wakeLock.enable()` y publica el snapshot; `onFrame()` llama `engine.advanceTo(clock.elapsed)`, publica el snapshot y aplica efectos por evento: `StartVoice` → `voice.announce(VoiceCommand.start)`, `EndVoice` → `voice.announce(VoiceCommand.end)`; al llegar a `finished` → `wakeLock.disable()`. `repeat()` vuelve a llamar `start` con la misma sesión (FR-014). Estado inicial: snapshot `ready` con sable blanco
- [ ] T035 [US1] Crear `SelectionScreen extends ConsumerWidget` en `lib/presentation/selection/selection_screen.dart` (contracts/ui-screens.md; depende de T033): con `catalogProvider.when` → cargando (`CircularProgressIndicator` + `StringsEs.loadingCatalog`), error (`StringsEs.catalogError` y botón Iniciar desactivado), datos → dos listas seleccionables lado a lado (horizontal): "Nivel" con una opción por `Level` en orden de `order` mostrando `name — responseLabel — purpose`; "Patrón" con una opción por `Pattern` mostrando `name — <romanización> (<hangul>) → <romanización> (<hangul>)` de `stanceTermId`/`cutTermId` vía `catalog.term(id)`. Selección inicial y cambios vía `selectedSessionProvider`. Botón grande **Iniciar** que navega con `Navigator.push` a `ExerciseScreen(session)` y llama `exerciseControllerProvider.notifier.start(session)`. Ningún texto de nivel, patrón o término coreano escrito en el código (SC-009)
- [ ] T036 [US1] Cambiar `home` de `lib/app.dart` a `SelectionScreen()` (depende de T035)
- [ ] T037 [P] [US1] Crear `OpponentPainter extends CustomPainter` en `lib/presentation/exercise/painters/opponent_painter.dart` (research R12, FR-010, FR-010a, FR-024, FR-025): recibe `SaberColor saberColor`, `bool inStance` (`false` en `ready`/`countdown`: reposo con sable bajo; `true` desde *Si-jak*: postura *Chochôn-se*, sable sobre la cabeza), `CutMotion cut`, `Side? side` y `double? cutProgress`. Dibuja de frente y centrado cabeza, torso y brazos y el sable como trazo grueso, todo relleno + contorno `AppColors.outline` de `kOutlineWidth` (≥ 4 dp) sobre fondo `#121212`. El sable es el segmento de `hilt` a `tip`, con ambos puntos interpolados linealmente entre `cut.start` y `cut.end` según `cutProgress` (coordenadas de data-model.md: origen en el centro de la figura, unidad = media altura, `y` hacia abajo), con `x` invertido si `cut.mirroredBySide && side == Side.left`; las manos se dibujan en `hilt`; sin `cutProgress` se dibuja la postura fija en `cut.start` (cambio instantáneo, FR-010a). Sin ramas por patrón en el código. `shouldRepaint` compara los cinco campos. Mapeo `SaberColor` → `AppColors.saber*`
- [ ] T038 [P] [US1] Crear `SignalPainter extends CustomPainter` en `lib/presentation/exercise/painters/signal_painter.dart` (research R12, FR-015, FR-016): recibe `Signal signal`; para `ResponseType.defense` dibuja un símbolo de sable (hoja + guarda + empuñadura) en la mitad de la pantalla indicada por `signal.screenSide` (`left` = lado izquierdo de la pantalla visto por el usuario), con alto ≥ 30 % del alto disponible, relleno blanco y contorno `kOutlineWidth`. `switch` exhaustivo sobre `ResponseType`
- [ ] T039 [US1] Crear `ExerciseScreen extends ConsumerStatefulWidget` en `lib/presentation/exercise/exercise_screen.dart` con `SingleTickerProviderStateMixin` (contracts/ui-screens.md; depende de T034, T037, T038): un `Ticker` que llama `exerciseControllerProvider.notifier.onFrame()` en cada cuadro y se detiene en estados terminales; con `ref.listen(exerciseControllerProvider, …)`, cuando el estado pasa de terminal a `countdown` (p. ej. tras **Repetir**) se vuelve a arrancar el `Ticker` si no está activo; `Stack` a pantalla completa con fondo `AppColors.background`: `CustomPaint(OpponentPainter)` centrado, con `cut = session.pattern.cut` y `side = snapshot.currentAttack?.side`; `CustomPaint(SignalPainter)` cuando `snapshot.signal != null`; número grande de `countdownValue` en `countdown`; tiempo restante discreto (`StringsEs.remaining` + segundos) en una esquina superior; en `finished`, botones **Repetir** (`controller.repeat()`) y **Volver** (`Navigator.pop`). Sin botón Detener aún (lo agrega T049)
- [ ] T040 [US1] En `lib/main.dart`, antes de `runApp`, crear un `ProviderContainer`, cargar el catálogo (`container.read(catalogProvider.future)`) y llamar `await container.read(voiceAnnouncerProvider).prepare(catalog)` dentro de `try/catch` (si falla, la app arranca igual sin voz); usar `UncontrolledProviderScope(container: container, child: const HaidongGumdoApp())` (research R8: voz preparada al arrancar para que *Si-jak* coincida con el fin de la cuenta) (depende de T033)

### Pruebas de US1 (obligatorias para el dominio; derivadas de los CA, escritas después del código)

- [ ] T041 [P] [US1] Escribir `test/domain/exercise_parameters_test.dart` (FR-006, FR-007, invariante obligatoria por el Principio VI): `defaults()` es válido y tiene 30 s / 5 / 700 ms / 500 ms / 2500 ms; `intervalFloor` de los valores por defecto = 1000 ms; cada límite mínimo y máximo de la tabla FR-006 es válido (inclusivo) y 1 ms (o 1 unidad para N) fuera de cada extremo produce la violación correspondiente; `cutSpeed = 1 s` + `attackInterval = 1.2 s` → `intervalBelowFloor`; `attackInterval == intervalFloor` es válido; `create(...)` lanza `InvalidParametersException` con todas las violaciones; `ExerciseEngine` con parámetros inválidos lanza `InvalidParametersException`
- [ ] T042 [P] [US1] Escribir `test/domain/side_sequencer_test.dart` (FR-017, FR-018, CA4, G7) con `ScriptedRandomSource`: con N = 5 y guion `[0,0,0,0,0,…]` el 6.º lado es el contrario y **no consume** sorteo (`consumed` no aumenta); con N = 1 los lados se alternan siempre sin consumir sorteos tras el primero; el sorteo 0 → `right` y 1 → `left`; una instancia nueva reinicia la racha
- [ ] T043 [P] [US1] Escribir `test/domain/signal_placement_test.dart` (FR-015, CA2, G8; escenarios 2 y 3): `defense` con `Side.right` (sable azul) → `screenSide == Side.left`; con `Side.left` (sable rojo) → `Side.right`
- [ ] T044 [US1] Escribir `test/domain/exercise_engine_timeline_test.dart` con `ManualClock` y `ScriptedRandomSource` y los parámetros por defecto (G1–G6, escenarios 1 y 4–11 de US1, casos límite):
  - Escenario 1 / G2: `countdownValue` 3 en [0,1), 2 en [1,2), 1 en [2,3), sable blanco; `StartVoice` exactamente en t = 3 s y antes de cualquier `SignalShown`; sable amarillo en `guard` después
  - FR-012 / caso "Primer ataque": con sorteo 0 la 1.ª señal está en 4.0 s; con sorteo 1500 en 5.5 s
  - Escenario 5 / G3: `cutStartAt − signalAt = 700 ms`, `cutEndAt − cutStartAt = 500 ms`; `cutProgress` 0 al inicio, 0.5 a mitad, sin señal ni corte después de `cutEndAt` y sable amarillo
  - Escenario 6 / G4: `next.signalAt − prev.cutStartAt` = 1000 ms con sorteo 0 y 2500 ms con sorteo 1500 (extremos incluidos)
  - Escenario 8 (CA5) / G6: E = 33 s cae a mitad de un corte → `finishing`, `EndVoice` en `cutEndAt`, una sola vez
  - Escenario 9: E cae durante `warning` → el corte se ejecuta completo y `EndVoice` en su `cutEndAt` (≤ E + 1.2 s)
  - Escenario 10: E cae en `guard` → `EndVoice` exactamente en 33 s y ningún `SignalShown` posterior (G5)
  - Escenario 11: tras `EndVoice` el estado es `finished`, sable blanco, `remaining == 0`, y `advanceTo` posteriores no emiten eventos
  - G1: dos motores con el mismo guion y la misma secuencia de `advanceTo` producen snapshots y eventos iguales
  - Un solo `advanceTo` que cruza varios instantes (p. ej. de 0 a 40 s) devuelve todos los eventos en orden y sin duplicados, igual que avanzar cada 16 ms; `advanceTo` con tiempo menor que el anterior lanza `ArgumentError`
- [ ] T045 [US1] Escribir `test/domain/exercise_engine_simulation_test.dart` con `SeededRandomSource` (SC-003, SC-004, SC-005, SC-006), avanzando cada ejercicio en pasos de 16 ms hasta `finished`:
  - SC-003: 1 000 ejercicios de 180 s con N = 5 → ninguno tiene más de 5 lados iguales seguidos; con N = 1 el 100 % alterna
  - SC-004: con ≥ 10 000 ataques en total, la proporción de `right` está en 50 % ± 5 %; ningún par de 1 000 ejercicios de 180 s (semillas distintas) tiene la misma secuencia completa de lados
  - SC-005: el 100 % de los intervalos `next.signalAt − prev.cutStartAt` está en [1000 ms, 2500 ms] con los valores por defecto
  - SC-006: en todos, `EndVoice.at ≥ E` y `EndVoice.at − E ≤ 1200 ms`

- [ ] T046 [P] [US1] Escribir `test/presentation/selection_screen_test.dart` (FR-004, FR-005, SC-009) con `ProviderScope(overrides: …)`: un `CatalogRepository` falso que devuelve un catálogo de prueba con 2 niveles y 2 patrones (usando solo `defense`, con un segundo patrón cuyo `cut` tenga otras posiciones) → la pantalla muestra ambos niveles y ambos patrones por `order`, preselecciona el primero de cada lista, permite elegir el segundo y Iniciar abre `ExerciseScreen` con esa sesión; con el catálogo real se ve "Chochôn-se (초천세)" y "Chungmyôn begi (정면베기)" (FR-003); un repositorio que lanza `CatalogException` muestra `StringsEs.catalogError` y el botón Iniciar desactivado. Puertos de voz, reloj, aleatoriedad y pantalla encendida reemplazados por los fakes de `test/domain/fakes/`
- [ ] T059 [P] [US1] Escribir `test/data/flutter_tts_voice_announcer_test.dart` (FR-029, FR-030, casos límite "Sin voz coreana" y "Sin ninguna voz sintética"; depende de T031) con `class FakeFlutterTts extends Fake implements FlutterTts` de `flutter_test` (sin paquetes nuevos), que registra llamadas y permite configurar respuestas: (a) `isLanguageAvailable('ko-KR')` → `true` ⇒ `setLanguage('ko-KR')` y `announce(start)`/`announce(end)` llaman `speak('시작')`/`speak('그만')`; (b) → `false` ⇒ no se llama `setLanguage` y se pronuncia `'Si-jak'`/`'Guman'`; (c) `isLanguageAvailable` lanza ⇒ `prepare` no relanza y `announce` no llama `speak` ni lanza; (d) `speak` lanza ⇒ `announce` no relanza; (e) `prepare` dos veces ⇒ una sola configuración (idempotente). Los textos se toman de un catálogo de prueba, no escritos en la prueba salvo para comparar
**Checkpoint**: `flutter test test/domain` en verde y, en el dispositivo, quickstart.md §2 pasos 1–5, 9 y 10 se cumplen. US1 es el MVP entregable.

---

## Phase 4: User Story 2 - Cancelar un ejercicio en curso (Priority: P2)

**Goal**: Detener el ejercicio con el botón Detener o al mandar la app a segundo plano lo cancela de forma limpia: sin *Guman* ni ningún sonido o señal posterior, y de vuelta en la pantalla de selección.

**Independent Test**: Iniciar un ejercicio y, en cada fase (cuenta regresiva, aviso, corte, guardia), pulsar Detener o pulsar Inicio de Android; al volver se ve la selección y no se escuchó ningún sonido (quickstart.md §2 pasos 6–8). Iniciar de nuevo empieza desde la cuenta regresiva.

### Implementación (US2)

- [ ] T047 [US2] Implementar `ExerciseTick cancel()` en `lib/domain/exercise/exercise_engine.dart` (FR-020, FR-021, FR-023, G9, G10): `countdown | running | finishing → cancelled` vía `ensureTransition`, devuelve snapshot `cancelled` (sable blanco, sin fase, señal ni ataque) y `events = [Cancelled]`; `StateError` en `ready`; en `finished` o `cancelled` no hace nada y devuelve el snapshot actual sin eventos. Después de `cancelled`, `advanceTo` nunca emite eventos (incluidos `StartVoice` si se canceló en la cuenta regresiva y `EndVoice`)
- [ ] T048 [US2] Agregar `Future<bool> cancel()` a `ExerciseController` en `lib/presentation/exercise/exercise_controller.dart` (research R10, contracts/ui-screens.md; depende de T047): si hay motor y su estado no es terminal, llama `engine.cancel()`, publica el snapshot, `await voice.stop()` y `await wakeLock.disable()`; devuelve `true` solo si esta llamada canceló el ejercicio y `false` si ya estaba en estado terminal (idempotente). Asegurar que `onFrame()` no hace nada si el estado es terminal (ningún `announce` tras cancelar). `start()` siempre crea un motor nuevo, así que la secuencia de lados es nueva (escenario 3)
- [ ] T049 [US2] En `lib/presentation/exercise/exercise_screen.dart` (depende de T048): agregar el botón **Detener** (`StringsEs.stop`) visible solo en `countdown`, `running` y `finishing`, que llama `controller.cancel()` y, solo si devuelve `true`, `Navigator.popUntil(route.isFirst)`; agregar un `AppLifecycleListener` en `initState` (liberado en `dispose`) con `onHide` y `onPause` que usan la misma rutina (Android emite ambos seguidos: la segunda llamada no debe navegar) (FR-022); **no** cancelar en `onInactive` (R10, barra de notificaciones); en `dispose`, llamar `controller.cancel()` si el ejercicio sigue activo (p. ej. botón Atrás de Android) y detener el `Ticker`

### Pruebas de US2

- [ ] T050 [US2] Escribir `test/domain/exercise_engine_states_test.dart` con `ManualClock` y `ScriptedRandomSource` (FR-020, G9, G10; escenarios 1–3 de US2, caso "Interrupción durante la cuenta regresiva"):
  - Recorrido feliz: `ready → countdown → running → finished` y `→ finishing → finished` cumplen la tabla
  - `cancel()` en `countdown` (t = 1.5 s), en `guard`, en `warning` y en `cut`, y en `finishing` → `cancelled` con evento `Cancelled`; después, `advanceTo(100 s)` no emite ningún evento (ni `StartVoice` ni `EndVoice`) (G9)
  - `start()` dos veces y `start()` tras `finished`/`cancelled` → `StateError`; `cancel()` en `ready` → `StateError`; `cancel()` en `finished` o `cancelled` → sin eventos
  - `ensureTransition` lanza `StateError` para cada par (desde, hacia) fuera de `allowedTransitions` (recorrer todas las combinaciones del enum) (G10)
  - Dos motores creados tras cancelar, con fuentes de aleatoriedad distintas, producen secuencias de lados distintas (escenario 3)
- [ ] T051 [P] [US2] Escribir `test/presentation/exercise_screen_test.dart` (FR-021–FR-023, FR-028, SC-008) con `ManualClock`, `ScriptedRandomSource`, `FakeVoiceAnnouncer` y `FakeScreenWakeLock` como overrides, avanzando el reloj manual y bombeando cuadros con `tester.pump`: (a) al entrar en `countdown` `enabled == true`; en t = 3 s se llama `announce(start)`; al terminar, `announce(end)` y `enabled == false`, y aparecen Repetir y Volver; (b) pulsar Detener durante `warning` → se llama `stop()`, `enabled == false`, se ve `SelectionScreen` y no hay más `announce` aunque avance el reloj; (c) `tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden)` y luego `paused` durante `cut` → mismo resultado que (b), y además `find.byType(SelectionScreen)` encuentra exactamente uno y `Navigator.canPop()` es `false` (la selección sigue siendo la raíz); (d) `AppLifecycleState.inactive` solo → el ejercicio continúa; (e) cancelar en `countdown` → nunca se llama `announce(start)`; (f) tras `finished`, pulsar Repetir → se ve la cuenta 3; avanzando el reloj 3 s se llama `announce(start)` otra vez y `enabled == true`; la secuencia usa sorteos nuevos (FR-014)

**Checkpoint**: `flutter test` completo en verde y quickstart.md §2 pasos 6–8 se cumplen en el dispositivo. US1 y US2 funcionan juntas.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Verificaciones de la constitution, documentación y validación manual.

- [ ] T052 Verificar el Principio II ejecutando `grep -rE "package:flutter|package:flutter_riverpod|package:flutter_tts|package:wakelock_plus" lib/domain` (no debe devolver nada) y corregir cualquier import en `lib/domain/`
- [ ] T053 Ejecutar `flutter analyze` (cero errores y advertencias) y `dart format --output=none --set-exit-if-changed lib test`; corregir lo que aparezca en `lib/` y `test/`
- [ ] T054 [P] Buscar textos coreanos o de nivel/patrón escritos en el código con `grep -rnE "[가-힣]|Chochôn|Chungmyôn|Si-jak|Guman|Nivel 1|Frontal" lib` (solo se permiten en comentarios); moverlos al catálogo o a `lib/presentation/strings_es.dart` (Principios III y IX)
- [ ] T055 [P] Reemplazar el `README.md` de plantilla por uno en español: propósito de la app, requisitos (Flutter 3.47.7 / Dart 3.13.5, Android), cómo ejecutar (`flutter run`), cómo probar (`flutter test test/domain`, `flutter test`), estructura por capas, cómo agregar un nivel o patrón editando `assets/catalog/catalog.json` y enlace a `docs/decisions/`
- [ ] T056 Ejecutar `flutter test` completo y `flutter build apk --release`; confirmar ambos en verde
- [ ] T057 Validar en un dispositivo Android real todos los pasos de `specs/001-motor-nivel1-frontal/quickstart.md` §2 (1–10), y anotar el resultado (fecha, dispositivo, versión de Android, ✅/❌ por paso) en una sección "Resultados de validación" al final de `specs/001-motor-nivel1-frontal/quickstart.md`
- [ ] T058 Ejecutar la prueba manual de legibilidad a 3 m (quickstart.md §3, SC-007) y la de precisión de tiempos con video a ≥ 60 fps (quickstart.md §4, SC-005); anotar resultados en la misma sección de `specs/001-motor-nivel1-frontal/quickstart.md`. Si SC-007 falla, ajustar grosor de contorno o tamaño de la señal en `lib/presentation/theme.dart` y los painters, y repetir

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sin dependencias. T001 primero (dependencias del `pubspec.yaml`); T002–T005 en paralelo.
- **Foundational (Phase 2)**: Depende de Setup. BLOQUEA ambas historias.
- **US1 (Phase 3)**: Depende de Foundational. Es el MVP.
- **US2 (Phase 4)**: Depende de Foundational y de **US1** (cancela el motor, el controlador y la pantalla del ejercicio que crea US1). Se puede probar por separado, pero no implementar en paralelo con US1.
- **Polish (Phase 5)**: Depende de US1 y US2.

### Dependencias clave entre tareas

```text
T006,T007 → T008 → T009, T010, T013
T010 → T014 → T019 → T020 → T021
T008, T011 → (US1) T022 → T023, T024, T026 → T027 → T028
T025 ─────────────────────────────────────────────┘
T029–T032 → T033 → T034 → T035 → T036
T037, T038 + T034 → T039
T033 → T040
T028 → T041–T045; T035 → T046; T031 → T059
T028 → (US2) T047 → T048 → T049 → T050–T051
```

### Within Each User Story

- Dominio antes que datos de plataforma y presentación.
- Entidades (`Attack`, `Signal`, `SideSequencer`, `ExerciseStatus`, eventos) antes que el snapshot; el snapshot antes que el motor.
- Pruebas **después** del código (Principio VI) y antes de cerrar la historia.

### Parallel Opportunities

- Setup: T002, T003, T004, T005.
- Foundational: T006 ∥ T007; luego T009 ∥ T010 ∥ T012; T015, T016, T017, T018 en paralelo una vez listas sus dependencias.
- US1: T022 ∥ T025; luego T023 ∥ T024 ∥ T026; T029 ∥ T030 ∥ T031 ∥ T032 (no dependen del motor); T037 ∥ T038; pruebas T041 ∥ T042 ∥ T043 ∥ T046 ∥ T059.
- US2: T050 ∥ T051 (archivos distintos) una vez hechas T047–T049.

---

## Parallel Example: User Story 1

```bash
# Entidades del dominio (archivos distintos):
Task: "T022 Crear Side y Attack en lib/domain/exercise/attack.dart"
Task: "T025 Crear ExerciseStatus y la tabla de transiciones en lib/domain/exercise/exercise_status.dart"

# Adaptadores de plataforma (independientes del motor):
Task: "T029 DartRandomSource en lib/data/platform/dart_random_source.dart"
Task: "T030 StopwatchClock en lib/data/platform/stopwatch_clock.dart"
Task: "T031 FlutterTtsVoiceAnnouncer en lib/data/platform/flutter_tts_voice_announcer.dart"
Task: "T032 WakelockPlusScreenWakeLock en lib/data/platform/wakelock_plus_screen_wake_lock.dart"

# Painters:
Task: "T037 OpponentPainter en lib/presentation/exercise/painters/opponent_painter.dart"
Task: "T038 SignalPainter en lib/presentation/exercise/painters/signal_painter.dart"

# Pruebas unitarias del dominio tras T028:
Task: "T041 test/domain/exercise_parameters_test.dart"
Task: "T042 test/domain/side_sequencer_test.dart"
Task: "T043 test/domain/signal_placement_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup.
2. Phase 2: Foundational (catálogo, parámetros, puertos, esqueleto).
3. Phase 3: US1 (motor, adaptadores, selección, pantalla del ejercicio, pruebas del dominio).
4. **STOP and VALIDATE**: `flutter test test/domain` + quickstart.md §2 pasos 1–5, 9, 10 en el dispositivo.
5. Demo con el responsable del proyecto.

### Incremental Delivery

1. Setup + Foundational → base lista (`flutter test test/data` en verde).
2. US1 → ejercicio completo → demo (MVP).
3. US2 → cancelación limpia por botón y segundo plano → demo.
4. Polish → verificaciones de la constitution, README, validación manual → PR a `main`.

### Notas

- [P] = archivos distintos y sin dependencias pendientes.
- Commit al terminar cada tarea o grupo lógico (`feat:` para código, `test:` para pruebas, `chore:` para setup, `docs:` para README/quickstart).
- Evitar: lógica de tiempo en la presentación (todo sale del snapshot), `Timer`/`Future.delayed` en el dominio, y textos del catálogo escritos en el código.
