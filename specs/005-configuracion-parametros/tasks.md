---
description: "Task list for Spec 005: Configuración de parámetros e invariante de tiempos"
---

# Tasks: Configuración de parámetros e invariante de tiempos

**Input**: Design documents from `specs/005-configuracion-parametros/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/settings-ui.md](./contracts/settings-ui.md), [contracts/settings.schema.json](./contracts/settings.schema.json), [quickstart.md](./quickstart.md)

**Tests**: Incluidas. El Principio VI las exige (la invariante de tiempos DEBE tener pruebas) y el plan las detalla (research R11, contrato §6). Se escriben **después del código**, derivadas de los escenarios de la spec. Las pruebas de las Specs 001 a 004 no se tocan (SC-008).

**Organization**: La Foundational deja listos `copyWith`, el puerto, los formatos, los textos y el repositorio falso de pruebas. US1 entrega la edición completa con la invariante siempre cumplida y la persistencia (MVP). US2 agrega lo que el usuario **ve** de la invariante: el rango del sorteo y el aviso de ajuste. US3 agrega Cancelar y Restablecer.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia de usuario (US1 ajustar y guardar, US2 invariante al editar, US3 cancelar y restablecer)

## Path Conventions

Proyecto Flutter único: `lib/`, `test/` y `docs/` en la raíz del repositorio (estructura de la Spec 001).

## Reglas para todas las tareas

- **No cambiar** el motor ni sus reglas: en `lib/domain/exercise/` solo se agrega `ExerciseParameters.copyWith` (FR-016, research R1). `ExerciseController` y `ExerciseHud` no se tocan. Si una tarea parece requerir otra cosa, detenerse y consultarlo.
- **Único paquete nuevo**: `path_provider` (ADR 0006, aprobado). Solo se importa en `lib/presentation/providers.dart`. `lib/domain/` sigue siendo Dart puro y `lib/data/settings/` solo usa `dart:io` y `dart:convert`.
- Toda la rejilla y la invariante se calculan en **milisegundos enteros** (`Duration.inMilliseconds`), nunca con `double` (research R2).
- En la pantalla de configuración, nada de `AppColors.saberBlue`, `saberRed`, `saberYellow` ni `ColorScheme.error` (FR-018, research R8).
- `s` = `SceneLayout.hudScale`, como en la Spec 004.

---

## Phase 1: Setup

**Purpose**: Línea base y dependencia aprobada.

- [X] T001 Desde la raíz, en la rama `005-configuracion`, ejecutar `flutter analyze` y `flutter test` y confirmar que todo pasa (línea base de las Specs 001 a 004, SC-008). Si algo falla, detenerse y reportarlo.
- [X] T002 Ejecutar `flutter pub add path_provider` (línea 2.x estable vigente; ADR 0006) y confirmar que `pubspec.yaml` solo gana esa línea en `dependencies` y que `flutter pub get` termina sin errores. No agregar ningún otro paquete.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Piezas que usan las tres historias.

- [X] T003 [P] En `lib/domain/exercise/exercise_parameters.dart`, agregar `ExerciseParameters copyWith({Duration? duration, int? maxRepeats, Duration? warningTime, Duration? cutSpeed, Duration? attackInterval})` que no valida, igual que el constructor (data-model §1). No cambiar `ParameterLimits`, `validate()`, `defaults()` ni `intervalFloor`.
- [X] T004 [P] Crear `lib/domain/ports/settings_repository.dart` con `abstract interface class SettingsRepository { Future<ExerciseParameters?> load(); Future<void> save(ExerciseParameters parameters); }` y `final class SettingsSaveException implements Exception { SettingsSaveException([this.cause]); final Object? cause; }`, con doc-comments: "`load`: null si no hay configuración guardada, no se puede leer o no es válida; nunca lanza" y "`save`: lanza SettingsSaveException si no se pudo guardar; la configuración anterior queda intacta" (contrato §1, research R3).
- [X] T005 [P] Crear `lib/presentation/settings/parameter_format.dart` con funciones de nivel superior (data-model §7, research R9):
  - `String formatSeconds(Duration d)`: `ms / 1000` con punto decimal, **al menos un decimal y como máximo dos**, sin ceros finales después del primer decimal, más `' s'`. 330 → `'0.33 s'`, 350 → `'0.35 s'`, 700 → `'0.7 s'`, 1000 → `'1.0 s'`, 2500 → `'2.5 s'`. Calcular con enteros (`ms ~/ 1000`, `ms % 1000`) para evitar redondeos.
  - `String formatDuration(Duration d)`: < 60 s → `'${s} s'`; si no, `'${m} min'` y, si sobran segundos, `'${m} min ${s} s'`. 30 s → `'30 s'`, 60 s → `'1 min'`, 75 s → `'1 min 15 s'`, 180 s → `'3 min'`.
  - `String formatIntervalRange(ExerciseParameters p)`: usa `p.intervalFloor` (el piso real, no `intervalMinimum`) y `p.attackInterval`. Si son iguales → `'Cada ataque: ${formatSeconds(x)}'`; si no → `'Cada ataque: entre ${formatSeconds(floor)} y ${formatSeconds(max)}, al azar'`.
  - `String formatAdjustment(Duration interval)` → `'Intervalo ajustado a ${formatSeconds(interval)}: debe ser al menos la velocidad del corte + 0.5 s'`.
- [X] T006 [P] En `lib/presentation/strings_es.dart`, agregar las claves del contrato §5 con estos textos exactos: `settings = 'CONFIGURACIÓN'`, `save = 'GUARDAR'`, `cancel = 'CANCELAR'`, `reset = 'RESTABLECER'`, `durationLabel = 'Duración del ejercicio'`, `durationHint = 'Tiempo total del ejercicio'`, `durationRange = '30 s a 3 min'`, `maxRepeatsLabel = 'Máximo de repeticiones seguidas'`, `maxRepeatsHint = 'Ataques seguidos al mismo lado, como máximo'`, `maxRepeatsRange = '1 a 5'`, `warningTimeLabel = 'Tiempo de aviso'`, `warningTimeHint = 'Desde la señal hasta el corte'`, `warningTimeRange = '⅓ s a 1 s'`, `warningTimeReference = '1 s: cinta blanca · ⅓ s: avanzado'`, `cutSpeedLabel = 'Velocidad del corte'`, `cutSpeedHint = 'Duración del corte del oponente'`, `cutSpeedRange = '0.3 s a 1 s'`, `attackIntervalHint = 'Desde el inicio del corte hasta la siguiente señal'`, `attackIntervalLabel = 'Intervalo máximo entre ataques'`, `saveErrorTitle = 'No se pudo guardar'`, `saveErrorBody = 'Tus cambios siguen aquí. Inténtalo de nuevo.'`.
- [X] T007 [P] Crear `test/presentation/fakes/in_memory_settings_repository.dart` con `final class InMemorySettingsRepository implements SettingsRepository`: campo público `ExerciseParameters? stored`, `bool failOnSave = false`, `int saveCalls = 0`; `load()` devuelve `stored`; `save(p)` incrementa `saveCalls`, lanza `SettingsSaveException()` si `failOnSave` y, si no, `stored = p`. Depende de T004.
- [X] T008 [P] Crear `test/presentation/parameter_format_test.dart` con todos los ejemplos de T005, incluidos `formatIntervalRange` con los valores por defecto (`'Cada ataque: entre 1.0 s y 2.5 s, al azar'`), con corte 0.8 s e intervalo 1.3 s (`'Cada ataque: 1.3 s'`) y con corte 0.35 s e intervalo 0.9 s (`'Cada ataque: entre 0.85 s y 0.9 s, al azar'`), y `formatAdjustment(1300 ms)`. Depende de T005.

**Checkpoint**: `flutter analyze` y `flutter test` verdes; nada visible cambia todavía.

---

## Phase 3: User Story 1 - Ajustar y guardar los parámetros (Priority: P1) 🎯 MVP

**Goal**: Pantalla de configuración con botones − / + en pasos, borrador siempre válido, GUARDAR que persiste en `settings.json`, carga al arrancar, resumen con la duración guardada y ejercicios que usan la configuración guardada.

**Independent Test**: Cambiar cada parámetro, guardar, iniciar y comprobar los valores; cerrar la app por completo, reabrirla y comprobar que siguen (quickstart §2 pasos 1–4, 9–11 y 14).

### Implementation for User Story 1

- [X] T009 [P] [US1] Crear `lib/domain/settings/parameter_editor.dart` (data-model §2 y §3, research R2), Dart puro:
  - `enum ParameterField { duration, maxRepeats, warningTime, cutSpeed, attackInterval }`. El orden es el de las filas.
  - `final class EditResult { const EditResult(this.parameters, {this.adjustedInterval}); final ExerciseParameters parameters; final Duration? adjustedInterval; }`.
  - `abstract final class ParameterEditor` con:
    - `static Duration intervalMinimum(Duration cutSpeed)`: `((cutSpeed.inMilliseconds + 500 + 99) ~/ 100) * 100` ms. Corte 300 → 800; 350 → 900; 500 → 1000; 800 → 1300; 1000 → 1500.
    - `static List<int> allowedValues(ExerciseParameters p, ParameterField f)`, ascendente: `duration` 30000 a 180000, paso 15000; `maxRepeats` 1 a 5; `warningTime` `[330, 350, 400, …, 1000]` (330 y después múltiplos de 50 desde 350); `cutSpeed` 300 a 1000, paso 50; `attackInterval` desde `intervalMinimum(p.cutSpeed)` hasta 5000, paso 100.
    - `static int _current(p, f)`: el valor del campo en ms (o N).
    - `canIncrement(p, f)`: existe un valor permitido `> _current`. `canDecrement(p, f)`: existe uno `< _current`.
    - `increment(p, f)`: el **menor** valor permitido `> _current`; `decrement(p, f)`: el **mayor** valor permitido `< _current`. Si no existe, `EditResult(p)` sin cambios. Así, un valor fuera de la rejilla vuelve a ella con el primer toque.
    - **Ajuste automático**, solo en `increment(p, ParameterField.cutSpeed)`: si el intervalo resultante es menor que `intervalMinimum(nuevoCorte)`, se sube a ese mínimo y se devuelve `EditResult(p'', adjustedInterval: p''.attackInterval)`. `decrement` del corte **nunca** cambia el intervalo (FR-008).
  - Sin imports de Flutter. Depende de T003.
- [X] T010 [P] [US1] Crear `lib/data/settings/settings_json_mapper.dart` con `abstract final class SettingsJsonMapper` (data-model §5, [esquema](./contracts/settings.schema.json)):
  - `static Map<String, Object> toJson(ExerciseParameters p)` → `{'version': 1, 'durationMs': …, 'maxRepeats': …, 'warningTimeMs': …, 'cutSpeedMs': …, 'attackIntervalMs': …}`.
  - `static ExerciseParameters? fromJson(Object? json)`: `null` si `json` no es `Map`, si `version != 1`, si falta un campo de los seis o no es `int` (un `double` como `500.0` → `null`), o si `ExerciseParameters(...).validate()` no está vacío. Ignora campos desconocidos. Nunca lanza.
- [X] T011 [US1] Crear `lib/data/settings/json_file_settings_repository.dart` con `final class JsonFileSettingsRepository implements SettingsRepository` (research R4). Depende de T004 y T010.
  - Constructor `JsonFileSettingsRepository({required Future<Directory> Function() directory})`; constantes `fileName = 'settings.json'` y `tempFileName = 'settings.json.tmp'`.
  - `load()`: dentro de `try`, obtener la carpeta, leer `settings.json` si existe, `jsonDecode` y `SettingsJsonMapper.fromJson`. Ante cualquier excepción o si el archivo no existe → `null`.
  - `save(p)`: dentro de `try`, `await File(tmp).writeAsString(jsonEncode(toJson(p)), flush: true)` y después `await tmp.rename(path de settings.json)`. Cualquier excepción (también de `directory()`) → borrar el `.tmp` si quedó (ignorando errores) y lanzar `SettingsSaveException(e)`.
  - Solo `dart:io` y `dart:convert`; **no** importar `path_provider`.
- [X] T012 [US1] En `lib/presentation/providers.dart` (research R5, contrato §2). Depende de T011.
  - Agregar `final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => JsonFileSettingsRepository(directory: getApplicationDocumentsDirectory));`, con import de `package:path_provider/path_provider.dart`.
  - Reemplazar `exerciseParametersProvider` por `final exerciseParametersProvider = NotifierProvider<ExerciseParametersNotifier, ExerciseParameters>(ExerciseParametersNotifier.new);`, conservando el nombre, y actualizar su doc-comment (ya no "La Spec 005 lo reemplazará").
  - `final class ExerciseParametersNotifier extends Notifier<ExerciseParameters>`:
    - `build()` → `ExerciseParameters.defaults()`.
    - `Future<void> load()` → `try { state = await ref.read(settingsRepositoryProvider).load() ?? ExerciseParameters.defaults(); } catch (_) { state = ExerciseParameters.defaults(); }`.
    - `Future<void> save(ExerciseParameters p)` → `await ref.read(settingsRepositoryProvider).save(p); state = p;`. Si lanza, el estado no cambia y la excepción se propaga.
  - Verificar que `exercise_controller.dart` y `exercise_hud.dart` compilan **sin cambios**, porque `ref.read/watch(exerciseParametersProvider)` sigue devolviendo `ExerciseParameters`.
- [X] T013 [US1] En `lib/main.dart`, dentro del `try` existente y **antes** de cargar el catálogo, agregar `await container.read(exerciseParametersProvider.notifier).load();` (FR-012, research R5). Si falla, la app arranca igual: `load()` ya cae a los valores por defecto. Depende de T012.
- [X] T014 [US1] Crear `lib/presentation/settings/settings_draft.dart` (data-model §6, research R6). Depende de T009 y T012.
  - `final class SettingsDraft { const SettingsDraft({required this.values, this.intervalAdjustedTo, this.saving = false, this.saveFailed = false}); … copyWith }`. `intervalAdjustedTo` se agrega ya, pero se llena en US2 (T024).
  - `final settingsDraftProvider = NotifierProvider.autoDispose<SettingsDraftNotifier, SettingsDraft>(SettingsDraftNotifier.new);`.
  - `SettingsDraftNotifier`:
    - `build()` → `SettingsDraft(values: ref.read(exerciseParametersProvider))`.
    - `increment(ParameterField f)` / `decrement(f)` → `state = state.copyWith(values: ParameterEditor.increment/decrement(state.values, f).parameters, saveFailed: false)`.
    - `Future<bool> save()`: si `state.saving`, devuelve `false`. Pone `saving: true, saveFailed: false`; `await ref.read(exerciseParametersProvider.notifier).save(state.values)`; si tiene éxito, devuelve `true`; ante `SettingsSaveException`, pone `saving: false, saveFailed: true` y devuelve `false`.
- [X] T015 [P] [US1] Crear `lib/presentation/settings/parameter_row.dart` con `ParameterRow({required ParameterField field, required String label, required List<String> hints, required String value, required VoidCallback? onDecrement, required VoidCallback? onIncrement, required double scale, Widget? footer})` (contrato §4, research R7, R8):
  - `Key('param-${field.name}')` en la raíz.
  - A la izquierda (`Expanded`): `label` (700, `24·s`, `textPrimary`) y cada `hint` (500, `16·s`, `textSecondary`). Debajo, `footer` si se da (lo usa US2).
  - A la derecha: botón − (`Key('dec-${field.name}')`), valor (`Key('value-${field.name}')`, 700, `28·s`, `textPrimary`, ancho mínimo `120·s`, centrado, `tabularFigures`) y botón + (`Key('inc-${field.name}')`).
  - Botones circulares de `56·s` (y al menos 48 dp): `OutlinedButton` con `CircleBorder`, ícono `Icons.remove` / `Icons.add`. Activos: borde `AppColors.buttonBorder` e ícono `textPrimary`. Desactivados (`onPressed: null`): borde `cardIdleBorder`, ícono `textTertiary` al 40 % y sin *ripple*. `Semantics(label: 'Bajar ${label}' / 'Subir ${label}')`.
  - Solo colores de los grupos de interfaz de `AppColors`.
- [X] T016 [US1] Crear `lib/presentation/settings/settings_screen.dart` con `SettingsScreen extends ConsumerWidget` (contrato §4, research R7, R8). Depende de T005, T006, T014 y T015.
  - Mismo esqueleto que la selección: `LayoutBuilder` → `SceneLayout.compute(size, catalog.value?.patterns.first ?? SelectionScreen._backgroundPattern)`. Para reutilizar el patrón de fondo, hacerlo público como `SelectionScreen.backgroundPattern`, sin cambiar sus valores. Encima van `DojangPainter` en `RepaintBoundary` y la capa `AppColors.selectionDim`, con `SafeArea` y padding `40·s / 56·s / 36·s`.
  - Encabezado `StringsEs.settings` (700, `46·s`, `letterSpacing 6·s`).
  - `Expanded` con un `HudPanel` que contiene un `ListView` de 5 `ParameterRow` en el orden de `ParameterField`, separados por `Divider` (`panelBorder`):
    - Valor: `formatDuration` para la duración; `'${maxRepeats}'` para N; `formatSeconds` para los tiempos.
    - Pistas (explicación y luego rango): duración `[durationHint, durationRange]`; N `[maxRepeatsHint, maxRepeatsRange]`; aviso `[warningTimeHint, warningTimeRange, warningTimeReference]`; corte `[cutSpeedHint, cutSpeedRange]`; intervalo `[attackIntervalHint]` (US2 agrega el rango del sorteo como segunda línea) (FR-005).
    - `onDecrement` / `onIncrement`: `null` si `!ParameterEditor.canDecrement/canIncrement(draft.values, field)`; si no, `notifier.decrement/increment(field)`.
  - Barra inferior fija (fuera del `ListView`): a la derecha, GUARDAR (`FilledButton` del tema, `Key('saveButton')`, alto `64·s`, ancho mínimo `260·s`, `onPressed: draft.saving ? null : () async { if (await notifier.save() && context.mounted) Navigator.of(context).pop(); }`). US3 agrega CANCELAR y RESTABLECER a esta barra.
  - Si `draft.saveFailed`, arriba de la barra va un `HudPanel` (`Key('saveError')`) con borde `cardSelectedBorder`, `Icons.error_outline` en `textPrimary`, `StringsEs.saveErrorTitle` (700) y `saveErrorBody` (500). Sin colores de señal ni de error del tema (FR-013, FR-018).
  - Atrás del sistema hace `pop` sin guardar, que es el comportamiento por defecto: no agregar `PopScope`.
- [X] T017 [US1] En `lib/presentation/selection/selection_screen.dart` (contrato §3, research R10). Depende de T005, T006 y T016.
  - Hacer público `backgroundPattern` (ver T016).
  - Resumen: reemplazar `' · ${duration.inSeconds} s'` por `' · ${formatDuration(duration)}'`.
  - `_Footer`: agregar entre el resumen y INICIAR un `OutlinedButton` (`Key('settingsButton')`, píldora del tema, alto `64·s`, padding horizontal `28·s`, texto `StringsEs.settings` 700 `22·s` `letterSpacing 3·s`) separado `24·s` de cada lado. Al pulsarlo: `Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()))`. Siempre habilitado, también con el catálogo en carga o con error (contrato §3).
  - El resumen debe ajustarse sin desbordar en 4:3: `maxLines: 1`, `overflow: TextOverflow.ellipsis` (FR-001).
  - `_start` no cambia.
  - Ejecutar `flutter test test/presentation/selection_screen_test.dart test/presentation/exercise_screen_test.dart` **sin modificar esas pruebas** (SC-008). Si hay un desborde con el tamaño de superficie que usan, lo corrige la pantalla, no las pruebas: el resumen cede espacio (`Expanded` con `maxLines: 1` y elipsis) y CONFIGURACIÓN reduce su padding horizontal a `16·s`. INICIAR conserva su ancho mínimo.

### Tests for User Story 1 (después del código, Principio VI)

- [X] T018 [P] [US1] Crear `test/domain/parameter_editor_test.dart`, grupo "rejilla y límites" (FR-004, FR-004a). Depende de T009.
  - `allowedValues` de cada campo con los defaults: duración 11 valores, de 30000 a 180000; N `[1..5]`; aviso 15 valores que empiezan en `[330, 350, 400]` y terminan en 1000; corte 15 valores; intervalo con corte 500: de 1000 a 5000, 41 valores.
  - `intervalMinimum` con 300, 350, 500, 800 y 1000 → 800, 900, 1000, 1300 y 1500.
  - Desde los defaults, `increment(duration)` → 45 s; `decrement(warningTime)` de 350 → 330 y de 330 sin cambios con `canDecrement == false`; `increment(duration)` en 180 s sin cambios con `canIncrement == false`; N en 1 con `canDecrement == false` y en 5 con `canIncrement == false`.
  - Fuera de la rejilla: aviso 370 → `increment` 400 y `decrement` 350; intervalo 850 con corte 350 → `canDecrement == false` y `increment` 900.
- [X] T019 [P] [US1] Crear `test/data/settings_json_mapper_test.dart`. Depende de T010.
  - Ida y vuelta con los defaults y con `{60000, 1, 330, 1000, 5000}`.
  - `fromJson` → `null` para: no `Map`; `version` 2 o ausente; cada uno de los seis campos ausente; `'cutSpeedMs': 500.0`; `'durationMs': '30000'`; `durationMs` 29000; `warningTimeMs` 1001; `cutSpeedMs` 800 con `attackIntervalMs` 1000 (viola la invariante).
  - Un campo extra `'foo': 1` se ignora.
- [X] T020 [P] [US1] Crear `test/data/json_file_settings_repository_test.dart`, con un `Directory.systemTemp.createTemp()` por prueba y borrado en `tearDown`. Depende de T011.
  - Sin archivo → `load()` es `null`.
  - `save` y luego `load` en una **instancia nueva** sobre la misma carpeta → mismos valores (SC-002).
  - Después de `save`, solo existe `settings.json`, sin `.tmp`.
  - Archivo con `'basura'`, `'{}'` o fuera de rango → `null`, y el archivo sigue igual hasta el siguiente `save` correcto (FR-012, SC-007).
  - `directory` que lanza → `save` lanza `SettingsSaveException` y `load` devuelve `null`.
  - Carpeta que no existe (borrada antes de `save`) → `SettingsSaveException`, y un `settings.json` previo en otra carpeta válida queda intacto. Usar dos carpetas para comprobarlo.
- [X] T021 [US1] Crear `test/presentation/settings_screen_test.dart`, grupo US1, con `ProviderScope(overrides: [settingsRepositoryProvider.overrideWithValue(InMemorySettingsRepository()), catalogRepositoryProvider…, fakes de la 001])`, en horizontal 1280 × 800 (contrato §4 y §6). Depende de T016, T017 y T007.
  - Desde la selección, tocar `Key('settingsButton')` → se ven las 5 filas con `'30 s'`, `'5'`, `'0.7 s'`, `'0.5 s'` y `'2.5 s'` (US1-1).
  - `inc-duration` tres veces → `'1 min 15 s'`; tocarlo hasta el máximo → `'3 min'` y `inc-duration` con `onPressed == null` (US1-2, US1-3).
  - `dec-warningTime` hasta el mínimo → `'0.33 s'` y `dec-warningTime` desactivado.
  - GUARDAR → vuelve a la selección; el resumen termina en `'· 3 min'` y `repo.stored` tiene los valores nuevos (US1-5).
  - Con `repo.failOnSave = true`, GUARDAR → sigue en la pantalla, se ve `Key('saveError')` y el resumen no cambió al volver con Atrás (FR-013).
  - **Reinicio** (US1-7, SC-002): con `repo.stored = {75 s, 1, 330, 500, 2500}`, crear un `ProviderContainer` nuevo con el mismo repositorio, `await container.read(exerciseParametersProvider.notifier).load()`, montar la app con `UncontrolledProviderScope` y comprobar el resumen `'· 1 min 15 s'` y los valores en la pantalla de configuración.
  - Si `load()` lanza (repositorio falso que lanza en `load`) → valores por defecto (FR-012).
- [X] T022 [US1] En `test/presentation/exercise_screen_test.dart`, agregar **una** prueba nueva sin cambiar las existentes (US1-4, US1-5, US1-8, SC-005): con `InMemorySettingsRepository(stored: {60 s, 1, 500, 500, 2500})` y `load()`, iniciar desde la selección con el reloj manual y comprobar:
  - el corte empieza 500 ms después de la señal, por la fase del snapshot;
  - los lados se alternan (N = 1) en los primeros 6 ataques;
  - el HUD muestra 60 al terminar la cuenta;
  - REPETIR usa los mismos valores.
  Depende de T013 y T021.
- [X] T023 [P] [US1] Validación manual (quickstart §2 pasos 1–4, 9–11 y 14): valores, límites, persistencia tras cerrar la app desde recientes y archivo dañado con `adb`.

**Checkpoint**: MVP. Se configura, se guarda, se conserva y se usa; la invariante ya se cumple siempre por `ParameterEditor`, aunque todavía sin aviso visible.

---

## Phase 4: User Story 2 - Invariante de tiempos al editar (Priority: P2)

**Goal**: El usuario ve el rango real del sorteo y un aviso cuando el intervalo sube solo.

**Independent Test**: Con corte e intervalo al mínimo, subir el corte hasta 1 s y comprobar el ajuste, el aviso y que el intervalo nunca queda bajo el piso (quickstart §2 pasos 5–7).

### Implementation for User Story 2

- [X] T024 [US2] En `lib/presentation/settings/settings_draft.dart`, `SettingsDraftNotifier.increment/decrement` (data-model §6, tabla de transiciones; research R6):
  - Si `f == ParameterField.attackInterval` → `intervalAdjustedTo: null`.
  - Si no, y `result.adjustedInterval != null` → `intervalAdjustedTo: result.adjustedInterval`, que reemplaza un aviso anterior.
  - Si no → se conserva el `intervalAdjustedTo` actual.
  - `copyWith` debe permitir poner `intervalAdjustedTo` en `null` explícitamente, por ejemplo con un parámetro `bool clearAdjustment = false`.
- [X] T025 [US2] En `lib/presentation/settings/settings_screen.dart` (FR-005, FR-008, research R8). Depende de T024.
  - Fila del intervalo: `hints: [StringsEs.attackIntervalHint, formatIntervalRange(draft.values)]`, con el texto envuelto en `Key('intervalRange')`.
  - `footer` de esa fila: si `draft.intervalAdjustedTo != null`, un `HudPanel` (`Key('intervalAdjustedNotice')`) con borde `panelBorderStrong`, `Icons.info_outline` (`textPrimary`, `22·s`) y `formatAdjustment(draft.intervalAdjustedTo!)` (500, `16·s`, `textPrimary`).
  - Al aparecer el aviso, hacer visible la fila del intervalo con `Scrollable.ensureVisible` si la lista está desplazada, para que en 4:3 el usuario vea el ajuste aunque esté editando el corte.

### Tests for User Story 2

- [X] T026 [P] [US2] En `test/domain/parameter_editor_test.dart`, grupo "invariante y ajuste automático" (FR-007, FR-008, SC-003, SC-004). Depende de T009.
  - US2-1: corte 500 → 800 (seis `increment`) con intervalo 1000 → el intervalo queda en 1300 y el último `adjustedInterval == 1300 ms`.
  - US2-2: corte 500, intervalo 1000 → `canDecrement(attackInterval) == false`.
  - US2-3: corte 350, intervalo al mínimo → 900.
  - US2-4: corte 800, intervalo 1300, `decrement(cutSpeed)` hasta 500 → intervalo 1300 y `adjustedInterval == null` en cada paso.
  - US2-5: intervalo 2500, corte hasta 1000 → intervalo 2500 y ningún `adjustedInterval`.
  - **Exhaustivo** (SC-003): para cada corte de `allowedValues(cutSpeed)` y cada intervalo de `allowedValues(attackInterval)` con ese corte (y para N, duración y aviso por defecto), aplicar `increment` y `decrement` a cada `ParameterField`. Todo resultado cumple `validate().isEmpty`, y `adjustedInterval != null` si y solo si el campo es `cutSpeed`, la operación es `increment` y el intervalo de entrada era menor que `intervalMinimum` del corte nuevo (SC-004).
  - Recorrido aleatorio con `Random(seed)` fijo: 10 000 toques al azar desde los defaults, siempre válidos.
- [X] T027 [US2] En `test/presentation/settings_screen_test.dart`, grupo US2. Depende de T025.
  - Con los defaults, `Key('intervalRange')` dice `'Cada ataque: entre 1.0 s y 2.5 s, al azar'`.
  - `dec-attackInterval` hasta desactivarse → `'1.0 s'` y `'Cada ataque: 1.0 s'`.
  - `inc-cutSpeed` seis veces → valor del intervalo `'1.3 s'`, se ve `Key('intervalAdjustedNotice')` con `'Intervalo ajustado a 1.3 s: debe ser al menos la velocidad del corte + 0.5 s'` y GUARDAR habilitado (US2-1, FR-009).
  - `dec-cutSpeed` → el intervalo sigue en `'1.3 s'` y el aviso sigue visible; `inc-attackInterval` → el aviso desaparece.
  - GUARDAR → `repo.stored.validate()` vacío (US2-6).
- [X] T028 [P] [US2] Validación manual (quickstart §2 pasos 5–7), también en una tablet 4:3: el aviso se ve sin desplazar a mano.

**Checkpoint**: La invariante es visible y explicada.

---

## Phase 5: User Story 3 - Cancelar y restablecer (Priority: P3)

**Goal**: CANCELAR descarta el borrador; RESTABLECER pone los valores por defecto en el borrador.

**Independent Test**: Cambiar valores y cancelar; restablecer y cancelar; restablecer y guardar (quickstart §2 pasos 8, 12 y 13).

### Implementation for User Story 3

- [ ] T029 [US3] En `lib/presentation/settings/settings_draft.dart`, agregar `resetToDefaults()` → `state = SettingsDraft(values: ExerciseParameters.defaults())`, sin aviso, sin error y sin tocar el repositorio (FR-002, US3-2).
- [ ] T030 [US3] En `lib/presentation/settings/settings_screen.dart`, completar la barra inferior (contrato §4, research R7). Depende de T029.
  - A la izquierda, RESTABLECER (`OutlinedButton` del tema, `Key('resetButton')`, alto `64·s`, texto `StringsEs.reset`) → `notifier.resetToDefaults()`.
  - A la derecha, CANCELAR (`OutlinedButton`, `Key('cancelButton')`, `StringsEs.cancel`) → `Navigator.of(context).pop()` sin guardar, separado `24·s` de GUARDAR.
  - Sin diálogos de confirmación (Assumptions de la spec).

### Tests for User Story 3

- [ ] T031 [US3] En `test/presentation/settings_screen_test.dart`, grupo US3. Depende de T030.
  - Cambiar duración y aviso y pulsar CANCELAR → resumen sin cambios, `repo.saveCalls == 0` y, al reabrir, los valores anteriores (US3-1).
  - Lo mismo con `tester.pageBack()` o `handlePopRoute` (Atrás del sistema).
  - Con `repo.stored = {60 s, 1, 330, 1000, 5000}`: RESTABLECER → `'30 s'`, `'5'`, `'0.7 s'`, `'0.5 s'`, `'2.5 s'` y `repo.stored` sin cambios (US3-2). Luego CANCELAR → `repo.stored` sigue igual (US3-4). Otra vez RESTABLECER y GUARDAR → `repo.stored == ExerciseParameters.defaults()` (US3-3).
  - Ajuste automático y luego CANCELAR → el intervalo guardado no cambió (caso límite "Ajuste automático y luego Cancelar").
- [ ] T032 [P] [US3] Validación manual (quickstart §2 pasos 8, 12 y 13).

**Checkpoint**: Las tres historias completas.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T033 [P] Si T015, T016 o T025 agregaron colores nuevos a `AppColors`, ponerlos en el grupo `interfaceColors` de `lib/presentation/theme.dart`. Agregar a `test/presentation/palette_test.dart` una prueba que monte `SettingsScreen` con el aviso de ajuste y el error de guardado visibles y recorra todos los `Icon`, `Text`, `DecoratedBox` y `OutlinedButton` y sus estilos: ningún color usado tiene croma > 0.10 (misma función `chroma` de la Spec 004) y ninguno es `saberBlue`, `saberRed` ni `saberYellow` (FR-018, SC-006).
- [ ] T034 [P] En `test/presentation/settings_screen_test.dart`, grupo "disposición" (FR-019, FR-001): con tamaños 1024 × 768 (4:3), 1280 × 800 (16:10) y 2400 × 1080 (20:9), y `textScaler` 1.0 y 1.3, `tester.takeException()` es `null` (sin desbordes); `saveButton`, `cancelButton` y `resetButton` están dentro de la pantalla; la lista se desplaza hasta la fila del intervalo; en la selección, `settingsButton` e INICIAR no se superponen y quedan dentro de la pantalla.
- [ ] T035 [P] Comprobar el alcance del diff (quickstart §1):
  - `git diff main --stat -- lib/domain/exercise` solo con `exercise_parameters.dart` (`copyWith`).
  - `git diff main -- lib/presentation/exercise` vacío.
  - `git diff main -- pubspec.yaml` solo con `path_provider`.
  - `Select-String -Path lib/domain -Pattern "package:flutter|path_provider" -Recurse` sin resultados.
  - `path_provider` solo importado en `lib/presentation/providers.dart`.
- [ ] T036 [P] Actualizar los documentos de intención con lo decidido, sin cambiar su alcance:
  - En `docs/brief.md`, tabla "Parámetros configurables": rangos y valores por defecto (30 s a 3 min / 30 s; 1 a 5 / 5; ⅓ s a 1 s / 0.7 s; 0.3 s a 1 s / 0.5 s; tope del sorteo hasta 5 s, con mínimo = velocidad del corte + 0.5 s / 2.5 s). "Preguntas abiertas": marcarlas resueltas, con referencia a las Specs 001 y 005.
  - En `docs/000-haidonggumdo-v010.md`, RF1 (tiempo de aviso 0.33 s / 1 s / 0.7 s; intervalo aleatorio entre el piso y el valor configurado) y CL1 (el intervalo sube automáticamente; Spec 005).
- [ ] T037 Ejecutar `flutter analyze` y `flutter test` completos: todo verde, y las pruebas existentes de las Specs 001 a 004 sin cambios en sus expectativas. `git diff main -- test/domain` solo agrega `parameter_editor_test.dart` (SC-008).
- [ ] T038 Pruebas con personas (quickstart §3): SC-001 (3 personas, menos de 20 s) y SC-006 (3 observadores, con el aviso y el error visibles). Registrar los resultados en la descripción del PR.
- [ ] T039 Abrir el PR de `005-configuracion` a `main` con Conventional Commits (por ejemplo `chore: add path_provider (ADR 0006)`, `feat: add parameter editor with timing invariant`, `feat: persist settings as local json`, `feat: add settings screen`, `test: cover parameter editor and settings repository`, `docs: update brief with final parameter ranges`), mencionando el ADR 0006, y verificar en el PR la revisión de cumplimiento de la constitution.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias. T002 antes de T012.
- **Foundational (Phase 2)**: depende de T001. Bloquea todas las historias. T007 depende de T004; T008 de T005.
- **US1 (Phase 3)**: depende de la Foundational. Es el MVP.
- **US2 (Phase 4)**: depende de US1 (T014, T016): agrega el aviso y el rango a la pantalla de US1. T026 solo depende de T009 y puede adelantarse.
- **US3 (Phase 5)**: depende de US1 (T014, T016). Independiente de US2 en lógica, pero toca los mismos archivos: hacerla después de US2 o coordinar.
- **Polish (Phase 6)**: después de las historias deseadas.

### Within Each User Story

- Código antes que pruebas (Principio VI), y pruebas verdes antes de cerrar la historia.
- US1: T009 ∥ T010 ∥ T015 → T011 → T012 → T013, T014 → T016 → T017 → T018 ∥ T019 ∥ T020 → T021 → T022 → T023.
- US2: T024 → T025 → T026 ∥ T027 → T028.
- US3: T029 → T030 → T031 → T032.

### Archivos compartidos (no paralelizar entre sí)

- `lib/presentation/settings/settings_draft.dart`: T014 → T024 → T029.
- `lib/presentation/settings/settings_screen.dart`: T016 → T025 → T030.
- `lib/presentation/selection/selection_screen.dart`: T016 (hacer público `backgroundPattern`) → T017.
- `test/domain/parameter_editor_test.dart`: T018 → T026.
- `test/presentation/settings_screen_test.dart`: T021 → T027 → T031 → T034.
- `lib/presentation/providers.dart`: T012.

### Parallel Opportunities

- Phase 2: T003, T004, T005 y T006 en paralelo; luego T007 y T008.
- US1: T009, T010 y T015 en paralelo; T018, T019 y T020 en paralelo.
- US2: T026 puede escribirse en cuanto termine T009.
- Polish: T033, T034, T035 y T036 en paralelo.

---

## Parallel Example: User Story 1

```bash
# Tras T003 y T004, lanzar juntas (archivos distintos):
Task: "T009 ParameterEditor en lib/domain/settings/parameter_editor.dart"
Task: "T010 SettingsJsonMapper en lib/data/settings/settings_json_mapper.dart"
Task: "T015 ParameterRow en lib/presentation/settings/parameter_row.dart"

# Tras T017, las pruebas de dominio y datos:
Task: "T018 Rejilla y límites en test/domain/parameter_editor_test.dart"
Task: "T019 Mapper en test/data/settings_json_mapper_test.dart"
Task: "T020 Repositorio de archivo en test/data/json_file_settings_repository_test.dart"
```

## Parallel Example: Polish

```bash
Task: "T033 Regla de color de la pantalla en test/presentation/palette_test.dart"
Task: "T034 Disposición 4:3 a 20:9 en test/presentation/settings_screen_test.dart"
Task: "T035 Alcance del diff"
Task: "T036 Brief y documento 000"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: línea base verde y `path_provider`.
2. Phase 2: `copyWith`, puerto, formatos, textos y repositorio falso.
3. Phase 3: editor, mapper, repositorio, proveedor, carga en `main`, borrador, pantalla y botón en la selección, con sus pruebas.
4. **STOP and VALIDATE**: `flutter test` verde y quickstart §2 pasos 1–4, 9–11 y 14 en el dispositivo.

### Incremental Delivery

1. Setup + Foundational → sin cambios visibles.
2. US1 → configurar, guardar y conservar (MVP; CA7).
3. US2 → rango del sorteo y aviso de ajuste (CL1 visible).
4. US3 → CANCELAR y RESTABLECER.
5. Polish → regla de color, disposición, alcance del diff, documentos, pruebas con personas y PR.

---

## Notes

- [P] = archivos distintos, sin dependencias pendientes.
- Las pruebas van después del código (Principio VI), pero deben pasar antes de cerrar cada historia.
- En US1, Atrás del sistema ya permite salir sin guardar; US3 solo agrega los botones explícitos y sus pruebas.
- Si `flutter pub add` trae una versión de `path_provider` que exige subir el SDK, detenerse y consultarlo (Principio I).
