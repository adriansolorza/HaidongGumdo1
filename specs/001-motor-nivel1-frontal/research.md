# Research: Motor del ejercicio + Nivel 1 + Patrón frontal

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Fecha**: 2026-10-28

Cada decisión indica qué se eligió, por qué y qué alternativas se descartaron. Las que agregan dependencias fueron aprobadas por el responsable del proyecto el 2026-10-28 (Principio VII) y están registradas en `docs/decisions/`.

---

## R1. Toolchain

- **Decision**: Flutter **3.47.7** (canal stable) y Dart **3.13.5**, instalados en el equipo de desarrollo. Se fijan en `pubspec.yaml` con `environment: sdk: ^3.13.5` y `flutter: ">=3.47.7"`.
- **Rationale**: Es el stable vigente instalado (Principio I). `flutter --version` avisa que hay una versión más nueva. Si es un parche o una versión menor del mismo stable, se puede actualizar antes del `flutter create`. Una versión mayor requiere aprobación.
- **Alternatives considered**: Canal beta. Se descarta porque la constitution exige stable.

## R2. Modelo de tiempo: motor de línea de tiempo puro

- **Decision**: El dominio expone un `ExerciseEngine` **sin temporizadores**. La presentación le pasa el tiempo transcurrido en cada cuadro (`advanceTo(elapsed)`) y el motor devuelve un `ExerciseSnapshot` (estado, fase, color del sable, señal, progreso del corte) más la lista de `ExerciseEvent` ocurridos desde la llamada anterior (*Si-jak*, señal, inicio y fin del corte, *Guman*). El tiempo viene de un puerto `ElapsedClock` inyectado. En producción es un cronómetro; en pruebas, un reloj manual.
- **Rationale**:
  - El dominio queda determinista y probable sin `fake_async` ni esperas reales (Principio VI): una prueba avanza el reloj a 33.0 s y verifica el estado.
  - La presentación avanza en cada cuadro (vsync, ~16.7 ms a 60 Hz), por debajo de la tolerancia de ±50 ms de SC-005.
  - El progreso del corte (`(t − inicioCorte) / velocidadCorte`) sale del snapshot, así que la animación dura exactamente la velocidad del corte (FR-010).
  - Si se pierden cuadros, `advanceTo` recalcula desde el tiempo absoluto y no acumula deriva.
- **Alternatives considered**:
  - `Timer`/`Future.delayed` encadenados en el dominio: acumulan deriva, son difíciles de probar y complican la pausa futura.
  - Streams con `Stream.periodic`: mismo problema de deriva y más complejidad.
  - `AnimationController` como motor: acopla el dominio a Flutter, lo que viola el Principio II.

## R3. Línea de tiempo del ejercicio

Instante 0 = el usuario pulsa Iniciar.

| Tramo | Tiempo | Notas |
|---|---|---|
| Cuenta regresiva | 0 – 3 s | Se muestra "3" en [0,1), "2" en [1,2) y "1" en [2,3) |
| *Si-jak* | 3 s = `S` | El sable pasa a amarillo; empieza a correr la duración (supuesto de la spec) |
| Fin nominal | `E = S + duración` | 33 s con los valores por defecto |
| 1.ª señal | `S + sorteo` | Sorteo en [piso, intervalo configurado] (FR-012) |
| Inicio del corte | `señal + aviso` | |
| Fin del corte | `inicioCorte + velocidad` | El sable vuelve a amarillo y la señal desaparece |
| Siguiente señal | `inicioCorte + sorteo` | Siempre ≥ fin del corte + 0.5 s, por el piso |

- Una señal **solo se programa si su instante es < `E`**. Si ya se mostró, el ataque se completa siempre (aclaración Q1).
- *Guman* suena en `max(E, finDelÚltimoCorteIniciadoAntesDeE)`. Si al llegar a `E` no hay ataque en curso, suena en `E` mismo (FR-013).
- Con los valores por defecto, el retraso máximo de *Guman* es aviso + corte = 1.2 s (SC-006).

## R4. Aleatoriedad

- **Decision**: Un puerto `RandomSource` con `int nextInt(int maxExclusive)`. En producción, `dart:math` `Random()`; en pruebas, una fuente con semilla o un guion de valores. Los sorteos se hacen en **milisegundos enteros**:
  - Lado: `nextInt(2)`. Si la racha del lado actual ya llegó a N, se fuerza el lado contrario sin consumir sorteo (FR-018).
  - Intervalo: `pisoMs + nextInt(maxMs − pisoMs + 1)`, con ambos extremos incluidos (FR-011).
- **Rationale**: Los enteros dan extremos inclusivos exactos y pruebas reproducibles (FR-019). Forzar el cambio de lado sin sortear deja la regla de N fácil de verificar.
- **Alternatives considered**: `nextDouble()`. El extremo superior queda excluido y los errores de coma flotante complican las pruebas de límites.
- **Nota**: Forzar el cambio tras N repeticiones sesga levemente la proporción hacia la alternancia. Con N = 5 el efecto es menor a ±5 % (SC-004 lo verifica por simulación).

## R5. Máquina de estados explícita

- **Decision**: `ExerciseStatus` es un enum con una **tabla de transiciones permitidas**: `ready → countdown → running → finishing → finished`, más `countdown | running | finishing → cancelled`. Dentro de `running` y `finishing`, la fase del ataque (`guard`, `warning`, `cut`) se deriva del tiempo. Una transición fuera de la tabla lanza `StateError`.
- **Rationale**: Cumple FR-020. Agregar `paused` más adelante es sumar un valor al enum y filas a la tabla (`running ⇄ paused`, `paused → cancelled`). El motor ya calcula todo a partir del tiempo transcurrido, así que pausar es congelar ese tiempo.
- **Alternatives considered**: Un paquete de máquina de estados. Agrega una dependencia sin necesidad para 6 estados.

## R6. Catálogo como datos

- **Decision**: Un asset JSON de solo lectura, `assets/catalog/catalog.json`, que contiene:
  - el **glosario**: términos con romanización y hangul;
  - los **comandos de voz** (`start` → *Si-jak*, `end` → *Guman*);
  - los **patrones**: postura y corte por id de término, animación del corte por clave;
  - los **niveles**: orden, nombre, propósito y tipos de respuesta.

  El dominio lo lee con el puerto `CatalogRepository`. La capa de datos lo implementa con `rootBundle` y lo traduce a entidades. Esquema: [contracts/catalog.schema.json](./contracts/catalog.schema.json).
- **Rationale**: Principios III y IX. La pantalla de selección lista lo que hay en el catálogo (FR-004). Un nivel o patrón que reutiliza tipos de respuesta y animaciones ya conocidos es solo datos (SC-009).
- **Límite**: un **tipo de respuesta** nuevo (evasión, contraataque) o una **animación de corte** nueva (transversal) sí requiere código: la regla de colocación de la señal en el dominio y un painter en la presentación. Eso cae en la excepción del Principio III.
- **Alternatives considered**:
  - Catálogo en código Dart: viola el Principio III.
  - YAML: requiere un paquete extra.

## R7. Parámetros e invariante

- **Decision**: `ExerciseParameters` es un value object inmutable con `ParameterLimits` (rangos de FR-006) y un `validate()` que comprueba rangos e invariante: intervalo ≥ velocidad del corte + 0.5 s (FR-007). Si el resultado no es válido, `ExerciseEngine` no se puede crear. En esta spec se usa siempre `ExerciseParameters.defaults()`.
- **Rationale**: La Spec 004 solo tiene que agregar edición y persistencia. Por eso todavía no se crea repositorio de configuración (Principio IV): no hay nada que persistir.
- **Alternatives considered**: Rangos en el catálogo JSON. Es posible, pero los rangos son reglas del negocio, no contenido. Se puede revisar en la Spec 004.

## R8. Voz sintética (aprobada: `flutter_tts`, ADR 0002)

- **Decision**:
  - Un puerto `VoiceAnnouncer` en el dominio con `prepare()`, `announce(VoiceCommand)` y `stop()`. La implementación con `flutter_tts` vive en datos.
  - Al iniciar la app, `prepare()` comprueba `isLanguageAvailable("ko-KR")`.
    - Si está disponible, fija coreano y pronuncia el **hangul** (시작 / 그만).
    - Si no, deja la voz predeterminada y pronuncia la **romanización** del glosario ("Si-jak" / "Guman"), porque una voz no coreana no lee hangul (FR-030).
  - Si el motor de voz falla o no existe, `announce` no hace nada y el ejercicio sigue (supuesto de la spec).
  - Al cancelar, `stop()` corta cualquier frase en curso (FR-023).
- **Rationale**: Preparar la voz al arrancar la app quita la latencia de la primera frase, así que *Si-jak* coincide con el fin de la cuenta. Los textos salen del glosario (datos).
- **Alternatives considered**: Canal nativo propio, rechazado por el responsable. Audios grabados: descartados en la aclaración Q4.

## R9. Pantalla encendida (aprobada: `wakelock_plus`, ADR 0003)

- **Decision**: Un puerto `ScreenWakeLock` con `enable()` y `disable()`, implementado con `wakelock_plus`. Se activa al entrar en `countdown` y se desactiva al llegar a `finished` o `cancelled` (FR-028).
- **Alternatives considered**: `FLAG_KEEP_SCREEN_ON` con canal propio, rechazado por el responsable.

## R10. Segundo plano y cancelación

- **Decision**: `AppLifecycleListener` (Flutter SDK). Con `onHide` u `onPause` el controlador cancela el ejercicio activo y vuelve a la selección (FR-022). `inactive` **no** cancela: en Android se dispara al bajar la barra de notificaciones o al abrir un diálogo del sistema, que no implican salir de la app. El botón **Detener** cancela por el mismo camino (FR-021).
- **Rationale**: Hay una sola ruta de cancelación: motor → `cancelled`, `voice.stop()`, `wakeLock.disable()` y navegación. Así ningún sonido se reproduce después de cancelar (SC-008).
- **Alternatives considered**: Cancelar también en `inactive`. Cancelaría por interrupciones triviales del sistema.

## R11. Orientación

- **Decision**: La app completa se fija en horizontal (`landscapeLeft` y `landscapeRight`) con `SystemChrome.setPreferredOrientations` (FR-024). El color y la posición de la señal se definen **vistos desde el usuario**; como el usuario mira la pantalla de frente, el lado izquierdo de la pantalla es su izquierda.
- **Alternatives considered**: Bloquear la horizontal solo en la pantalla del ejercicio. Provoca rotaciones al navegar y no aporta nada en v1.

## R12. Gráficos (aprobado: `CustomPainter`, ADR 0004)

- **Decision**:
  - `OpponentPainter` dibuja una figura estilizada de frente (cabeza, torso y brazos) con el sable como trazo grueso. Todo lleva **contorno negro de al menos 4 dp sobre fondo oscuro** (Principio VIII).
  - El color del sable (blanco, amarillo, azul o rojo) sale del snapshot.
  - El corte *Chungmyôn begi* interpola el ángulo del sable desde *Chochôn-se* (sobre la cabeza) hasta la horizontal frontal, según `cutProgress` ∈ [0,1].
  - `SignalPainter` dibuja el símbolo de sable de defensa en el lado indicado, con al menos **30 % del alto de la pantalla** y contorno.
  - Colores saturados: azul `#1E6BFF`, rojo `#FF2D2D`, amarillo `#FFD400` y blanco `#FFFFFF`, sobre `#121212`.
- **Rationale**: El control exacto de contornos y del ángulo en función del tiempo garantiza la legibilidad a 3 m (FR-025) y la duración del corte (FR-010).
- **Legibilidad**: SC-007 se valida con una tablet de 10" o más, o con la imagen enviada a una TV. En un teléfono, los 3 m dependen de enviar la imagen a una TV (aclaración Q3).
- **Alternatives considered**: Rive o Lottie, rechazados por el responsable.

## R13. Estado en la presentación (aprobado: `flutter_riverpod` sin codegen, ADR 0001)

- **Decision**: Providers escritos a mano.
  - Puertos: `catalogRepositoryProvider`, `randomSourceProvider`, `elapsedClockProvider`, `voiceAnnouncerProvider` y `screenWakeLockProvider`. Se reemplazan con `overrides` en las pruebas.
  - `catalogProvider` (`FutureProvider`).
  - `selectedSessionProvider` (`NotifierProvider`).
  - `exerciseControllerProvider` (`NotifierProvider<ExerciseController, ExerciseSnapshot>`). Lo alimenta un `Ticker` desde la pantalla del ejercicio.
- **Alternatives considered**: `riverpod_generator`, rechazado por el responsable.

## R14. Pruebas

- **Decision**:
  - **Dominio** (obligatorias, Principio VI): pruebas unitarias con `ManualClock` y `ScriptedRandomSource` o `SeededRandomSource`, una por criterio de aceptación (CA2, CA4, CA5, CA6, escenarios 1–11, casos límite). También simulaciones de SC-003, SC-004 y SC-006: 1 000 ejercicios de 3 min y 10 000 ataques.
  - **Datos**: el parseo del catálogo (asset válido, término inexistente, JSON inválido).
  - **Presentación**: pruebas de widgets de la selección generada desde el catálogo (FR-004, SC-009 con un catálogo de prueba de 2 niveles), de la cancelación y del ciclo de vida. Los puertos de voz y pantalla encendida se reemplazan por fakes.
  - Solo se usan `flutter_test` y `test` del SDK; no hace falta `fake_async` gracias a R2.
  - SC-007 (legibilidad con observadores) y la percepción de la voz se verifican **manualmente** con [quickstart.md](./quickstart.md).

## R15. Textos de la interfaz

- **Decision**: Las cadenas en español se centralizan en `lib/presentation/strings_es.dart`. No se usan `intl` ni `flutter_localizations` en v1, porque la interfaz es solo en español (Principio IX). Los términos coreanos se muestran desde el glosario del catálogo, nunca escritos en el código.
- **Alternatives considered**: ARB/`gen-l10n`. Es sobreingeniería para un solo idioma; se puede adoptar cuando haya un segundo.

## Dependencias resultantes

| Paquete | Tipo | Aprobación |
|---|---|---|
| `flutter_riverpod` | runtime | Principio V + ADR 0001 |
| `flutter_tts` | runtime | ADR 0002 |
| `wakelock_plus` | runtime | ADR 0003 |
| `flutter_lints` | dev | Plantilla estándar de `flutter create` (registrada en ADR 0001) |
| `flutter_test` | dev (SDK) | Parte del SDK |

Las versiones exactas se fijan al agregarlas (última estable compatible con Dart 3.13.5) y quedan registradas en `pubspec.lock`.
