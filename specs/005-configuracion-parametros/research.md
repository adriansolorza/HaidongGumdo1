# Research: Configuración de parámetros e invariante de tiempos

**Feature**: [spec.md](./spec.md) | **Base**: [Spec 001](../001-motor-nivel1-frontal/plan.md) (motor, `ExerciseParameters`, puertos) y [Spec 004](../004-experiencia-visual/plan.md) (tema, paleta, selección)

El stack y la arquitectura son los de la Spec 001. El motor ya acepta cualquier `ExerciseParameters` válido y rechaza los inválidos (`validate()`, FR-007 de la 001). Las dudas reales eran: dónde viven los pasos y el ajuste automático (R2), cómo se carga la configuración antes de que el usuario pueda pulsar INICIAR (R5), cómo se guarda sin corromper el archivo (R4) y cómo se cumple la regla de color en los avisos (R8).

## R1. Alcance del cambio (Principios II, III y IV; FR-016)

- **Decision**:
  - `lib/domain/`: **nuevo** `settings/parameter_editor.dart` (pasos, mínimos vigentes, ajuste automático) y **nuevo** puerto `ports/settings_repository.dart` con su excepción. `ExerciseParameters` solo gana `copyWith`; sus rangos, `validate()` y `defaults()` no cambian. El motor, los estados, el secuenciador y las señales **no cambian**.
  - `lib/data/settings/`: **nuevos** mapper JSON y repositorio de archivo.
  - `lib/presentation/`: `exerciseParametersProvider` pasa de valor fijo a `Notifier` con `load()` y `save()`; pantalla de configuración nueva; botón CONFIGURACIÓN y formato de duración en la selección; textos.
  - `pubspec.yaml`: + `path_provider` (ADR 0006, **aprobado** el 2026-11-16).
- **Rationale**: El controlador del ejercicio y el HUD ya leen `exerciseParametersProvider` (Spec 004, R11). Si el proveedor conserva su nombre y su tipo de valor, ninguno de los dos cambia y la duración no puede diferir entre selección, HUD y motor.
- **Alternatives considered**: Pasar los parámetros a `ExerciseController.start(session, parameters)`. Cambia la firma usada por la selección y las pruebas sin beneficio. Se rechaza.

## R2. Pasos, mínimos vigentes y ajuste automático en el dominio (FR-004, FR-007, FR-008; Principio VI)

- **Decision**: Una clase de dominio pura, `ParameterEditor`, con funciones sin estado sobre `ExerciseParameters`:
  - `canIncrement(p, field)`, `canDecrement(p, field)`, `increment(p, field)`, `decrement(p, field)` → `EditResult { parameters, adjustedInterval? }`.
  - `intervalMinimum(cutSpeed)` = piso (`cutSpeed + 500 ms`) redondeado **hacia arriba** al múltiplo de 100 ms.
  - Todos los cálculos en **milisegundos enteros**, sin `double`, para que 0.33 + 0.02 no produzca 0.35000001.
  - Valores permitidos por campo:

    | Campo | Valores (ms salvo N) |
    |---|---|
    | `duration` | 30 000, 45 000 … 180 000 (paso 15 000) |
    | `maxRepeats` | 1 … 5 |
    | `warningTime` | 330, 350, 400 … 1 000 (330 y después múltiplos de 50) |
    | `cutSpeed` | 300, 350 … 1 000 (paso 50) |
    | `attackInterval` | `intervalMinimum(cutSpeed)` … 5 000 (paso 100) |

  - `increment` va al **siguiente valor permitido mayor** que el actual y `decrement`, al **anterior menor**. Así, un valor guardado fuera de la rejilla (por ejemplo, 0.37 s escrito a mano en el archivo) vuelve a la rejilla con el primer toque.
  - Si `increment(cutSpeed)` deja `attackInterval < intervalMinimum(nuevoCorte)`, el intervalo pasa a ese mínimo y `adjustedInterval` lo informa. `decrement(cutSpeed)` nunca toca el intervalo (FR-008).
- **Rationale**: La invariante de tiempos es regla de negocio y el Principio VI exige pruebas en el dominio. Con la rejilla en el dominio, SC-003 se prueba de forma exhaustiva y sin Flutter: 15 cortes × 43 intervalos, todos los toques posibles.
- **Edge**: Con corte 1 s, el mínimo es 1.5 s < 5 s, así que el ajuste siempre es posible. Un intervalo cargado igual al piso pero fuera de la rejilla (0.85 s con corte 0.35 s) es válido para el motor; el botón − queda desactivado porque 0.85 < 0.9.
- **Alternatives considered**:
  - Pasos en presentación y solo `validate()` en dominio: la invariante quedaría probada solo con pruebas de widget. Se rechaza.
  - `double` en segundos: riesgo de errores de redondeo en la rejilla. Se rechaza.

## R3. Puerto del repositorio (Principio IV; FR-011, FR-012, FR-013)

- **Decision**:

  ```dart
  abstract interface class SettingsRepository {
    /// null si no hay configuración guardada, no se puede leer o no es válida.
    Future<ExerciseParameters?> load();
    /// Lanza SettingsSaveException si no se pudo guardar.
    Future<void> save(ExerciseParameters parameters);
  }
  ```

  El caso "usar valores por defecto" vive en el proveedor (`load() ?? ExerciseParameters.defaults()`), no en el repositorio.
- **Rationale**: Un backend futuro solo implementa `load` y `save`. Para FR-012 no importa si el archivo falta, está dañado o viola la invariante: el resultado es el mismo. Por eso `null` basta y no hace falta un tipo de error de lectura.
- **Alternatives considered**: Que `load` lance excepciones distintas por causa. Nadie las distingue. Se rechaza.

## R4. Archivo JSON con `path_provider` (ADR 0006; FR-010 a FR-013)

- **Decision**:
  - `JsonFileSettingsRepository({required Future<Directory> Function() directory})`. En producción, `directory: getApplicationDocumentsDirectory` (ADR 0006). En pruebas, un directorio temporal de `dart:io`.
  - Archivo `settings.json` con el formato de [contracts/settings.schema.json](./contracts/settings.schema.json): `version: 1` y los cinco valores en milisegundos enteros, salvo `maxRepeats`.
  - **Lectura**: si el archivo no existe, el JSON es inválido, falta un campo, un tipo no es entero, la versión no es 1 o `validate()` devuelve violaciones → `null`. Nunca lanza.
  - **Escritura atómica**: escribe `settings.json.tmp` con `flush: true` y lo renombra a `settings.json`. Cualquier `FileSystemException` (o error al obtener la carpeta) se convierte en `SettingsSaveException`. Un archivo dañado solo se reemplaza al guardar con éxito.
- **Rationale**: El renombrado evita que un cierre a mitad de la escritura deje un JSON truncado, que se leería como "dañado" y haría perder la configuración. Usar milisegundos enteros evita decimales ambiguos.
- **Dependencia**: `path_provider` (versión estable vigente de la línea 2.x, fijada con `flutter pub add path_provider` al implementar), solo importado en `lib/data/settings/json_file_settings_repository.dart`, en la fábrica `inAppDocuments()` (ADR 0006: solo en la capa de datos). `providers.dart` llama a la fábrica y no lo importa. El constructor que recibe la carpeta queda para las pruebas.
- **Alternatives considered**: Las del ADR 0006 (`shared_preferences`, canal nativo). Escribir directo sin archivo temporal: más simple, pero arriesga corrupción. Se rechaza.

## R5. Carga al arrancar y proveedor de parámetros (FR-012, FR-014, FR-015; Principio V)

- **Decision**:
  - `settingsRepositoryProvider = Provider<SettingsRepository>(...)`, reemplazable en pruebas.
  - `exerciseParametersProvider = NotifierProvider<ExerciseParametersNotifier, ExerciseParameters>`:
    - `build()` → `ExerciseParameters.defaults()`.
    - `Future<void> load()` → `state = await repo.load() ?? defaults`; cualquier excepción → defaults.
    - `Future<void> save(p)` → `await repo.save(p)` y después `state = p`. Si falla, el estado no cambia y la excepción sube a la pantalla.
  - `main()` espera `load()` antes de `runApp`, junto a la carga del catálogo y la preparación de la voz que ya hace.
- **Rationale**: Con la carga terminada antes de mostrar la selección, INICIAR no puede usar valores por defecto por error y el resumen nunca parpadea de 30 s al valor guardado. Leer un JSON de unos 150 bytes toma pocos milisegundos. El controlador y el HUD siguen usando `ref.read/watch(exerciseParametersProvider)` sin cambios. El ejercicio toma los parámetros en `start()`, así que un cambio guardado no afecta un ejercicio en curso; además, FR-003 impide abrir la configuración durante uno.
- **Pruebas existentes**: no sobrescriben `exerciseParametersProvider` y, sin `load()`, ven los valores por defecto. Siguen pasando sin cambios (SC-008).
- **Alternatives considered**: `AsyncNotifier` con estado de carga en la selección. Agrega estados de carga sin ningún beneficio para un archivo local. Se rechaza.

## R6. Borrador y pantalla de configuración (FR-002, FR-004a, FR-005, FR-008, FR-013)

- **Decision**:
  - `settingsDraftProvider` (`NotifierProvider.autoDispose`), con estado `SettingsDraft { values, intervalAdjustedTo?, saving, saveFailed }`. Se crea desde `ref.read(exerciseParametersProvider)` al abrir la pantalla y desaparece al cerrarla, lo que implementa Cancelar y Atrás (FR-002).
  - Métodos: `increment(field)`, `decrement(field)` (delegan en `ParameterEditor`), `resetToDefaults()` y `Future<bool> save()`.
  - **Aviso de ajuste**: se muestra debajo del intervalo mientras `intervalAdjustedTo != null`. Un ajuste nuevo lo reemplaza (caso límite "Varios ajustes seguidos"). Se borra cuando el usuario toca − o + en el intervalo o pulsa Restablecer.
  - **Error al guardar**: el panel de error queda arriba de las acciones mientras `saveFailed`, se borra con el siguiente cambio o el siguiente intento, y la pantalla no se cierra (FR-013).
  - Guardar se desactiva solo mientras `saving`, para evitar dobles toques; nunca por validez (FR-009).
- **Rationale**: Un `autoDispose` atado a la pantalla da el ciclo de vida del borrador gratis. La lógica de pasos sigue en el dominio (R2) y el notifier solo la orquesta.
- **Alternatives considered**: Estado local en un `StatefulWidget`. Funciona, pero las pruebas son más difíciles y rompe la convención Riverpod (Principio V). Se rechaza.

## R7. Disposición de la pantalla (FR-017, FR-019; 4:3 a 20:9)

- **Decision**: El mismo esqueleto que la selección (Spec 004): dojang con `selectionDim`, `hudScale` de `SceneLayout`, encabezado "CONFIGURACIÓN" y una **lista desplazable de 5 filas** en un panel translúcido. Cada fila tiene, a la izquierda, el nombre y la explicación (y el rango del sorteo o la referencia de cinta blanca y avanzado) y, a la derecha, `[−] valor [+]` con botones circulares de 56 × `hudScale` (al menos 48 dp). Abajo hay una barra fija: RESTABLECER (borde) a la izquierda, y CANCELAR (borde) y GUARDAR (blanco) a la derecha.
- **Rationale**: En 20:9 caben las 5 filas. En 4:3, o con la letra del sistema grande, la lista se desplaza y las acciones siguen fijas, como pide FR-019. Los botones grandes permiten tocarlos con guantes de entrenamiento o a distancia del brazo.
- **Alternatives considered**: Rejilla de 2 columnas: menos desplazamiento, pero las explicaciones largas se recortan en 4:3. Se rechaza.

## R8. Regla de color en controles y avisos (FR-018; SC-006)

- **Decision**:
  - Botones − / + activos: borde `buttonBorder` y signo `textPrimary`. Desactivados: borde `cardIdleBorder` y signo `textTertiary` al 40 % de opacidad, sin onda (*ripple*).
  - Aviso de ajuste: panel `panel` con borde `panelBorderStrong`, ícono `Icons.info_outline` y texto en `textPrimary`.
  - Error al guardar: el mismo panel con ícono `Icons.error_outline`, título en negrita y texto en `textPrimary`. Lo distinguen el ícono, el peso del texto y el borde blanco completo (`cardSelectedBorder`), nunca el rojo.
  - Colores nuevos, si hacen falta, solo en el grupo de interfaz de `AppColors`. La prueba de croma de la Spec 004 (`palette_test.dart`) se extiende a ellos.
  - El `ColorScheme.error` del tema ya es neutro (Spec 004, R9); se verifica que ningún widget de esta pantalla herede un color de error rojo.
- **Rationale**: Material pinta los errores en rojo por defecto. Fijar los colores explícitamente y probarlos evita que se cuele un tinte prohibido.

## R9. Formato de valores (FR-006, FR-015)

- **Decision**: `parameter_format.dart` en presentación:
  - Tiempos: `ms / 1000` con **al menos un decimal y como máximo dos**, con punto decimal: 330 → "0.33 s", 700 → "0.7 s", 1000 → "1.0 s", 2500 → "2.5 s".
  - Duración: menos de 60 s → "45 s"; desde 60 s → "1 min", "2 min 15 s", "3 min".
  - Rango del sorteo: "Cada ataque: entre {min} y {max}, al azar", o "Cada ataque: {valor}" si coinciden (FR-005).
- **Resumen de la selección**: usa el formato de duración ("Nivel 1 · Frontal · 1 min").
- **HUD del ejercicio**: conserva su contador de segundos restantes y su barra (Spec 004), ahora calculados sobre la duración guardada, que ya leen del proveedor. El formato de FR-006 aplica al resumen y a la configuración, no al contador del HUD, que es una cuenta regresiva en segundos.
- **Alternatives considered**: Coma decimal ("0,7 s"), habitual en parte del mundo hispanohablante. La spec y el brief usan punto. Se mantiene el punto.

## R10. Navegación y botón CONFIGURACIÓN (FR-001, FR-003)

- **Decision**: `MaterialPageRoute` a `SettingsScreen` desde el pie de la selección. El pie queda así: resumen (`Expanded`) · CONFIGURACIÓN (`OutlinedButton`, píldora con borde, 64 × `hudScale` de alto) · INICIAR (sin cambios). La configuración solo se abre desde la selección; la pantalla del ejercicio no tiene acceso (FR-003). Atrás del sistema y CANCELAR hacen `pop` sin guardar.
- **Rationale**: Es el mismo patrón de navegación que el ejercicio y no necesita paquetes de rutas.

## R11. Pruebas (Principio VI; SC-002 a SC-008)

- **Decision**:
  - **Dominio** (`test/domain/parameter_editor_test.dart`): rejilla de cada campo; límites `canIncrement` y `canDecrement`; valores fuera de rejilla; ajuste automático (escenarios de US2); recorrido exhaustivo de todas las combinaciones de corte e intervalo y todos los toques, que siempre producen `validate().isEmpty` (SC-003); aviso solo cuando hay ajuste (SC-004).
  - **Datos** (`test/data/settings_json_mapper_test.dart`, `test/data/json_file_settings_repository_test.dart`): ida y vuelta; archivo ausente, JSON inválido, campo faltante, tipo incorrecto, versión desconocida, fuera de rango y viola invariante → `null` (SC-007); escritura atómica, que no deja `.tmp` y no cambia el archivo si falla; fallo de carpeta → `SettingsSaveException`. Todo con un directorio temporal.
  - **Presentación** (`test/presentation/settings_screen_test.dart`, más ajustes en `selection_screen_test.dart`): botones desactivados en los límites; aviso de ajuste; Restablecer, Cancelar y Atrás; Guardar actualiza el resumen; error al guardar con un repositorio falso que lanza; "reinicio", con un `ProviderContainer` nuevo sobre el mismo repositorio en memoria o en disco temporal, que vuelve a cargar la configuración (SC-002); la duración guardada llega al HUD y al motor (SC-005); sin rojo, azul ni amarillo en la pantalla (SC-006).
  - **Regresión**: todas las pruebas de las Specs 001 a 004 sin cambios (SC-008).
- **Con personas**: SC-001 (cambiar, guardar y volver en menos de 20 s) y SC-006 (3 observadores) se validan a mano ([quickstart](./quickstart.md)).
