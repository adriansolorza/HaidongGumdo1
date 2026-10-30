# Data Model: Motor del ejercicio + Nivel 1 + Patrón frontal

**Feature**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

Todas las entidades viven en `lib/domain/` y son Dart puro e inmutables (Principio II). Los identificadores de código están en inglés; los textos visibles salen del catálogo o de `strings_es.dart` (Principio IX).

---

## Catálogo (datos de solo lectura)

### `Catalog`

| Campo | Tipo | Reglas |
|---|---|---|
| `version` | `int` | ≥ 1 |
| `glossary` | `List<GlossaryTerm>` | `id` únicos |
| `voiceCommands` | `Map<VoiceCommand, String>` (id de término) | Debe tener `start` y `end`; cada id existe en `glossary` |
| `levels` | `List<Level>` | Al menos 1; `id` únicos; ordenados por `order` |
| `patterns` | `List<Pattern>` | Al menos 1; `id` únicos; ordenados por `order` |

El origen es `assets/catalog/catalog.json` ([contracts/catalog.schema.json](./contracts/catalog.schema.json)). Las referencias cruzadas (ids de términos) se validan al cargar; un catálogo inválido produce `CatalogException`.

### `GlossaryTerm`

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | `snake_case` y único |
| `romanization` | `String` | No vacío, exactamente como en el glosario (p. ej. `Chungmyôn begi`) |
| `hangul` | `String?` | Opcional (*Sodose* no lo tiene) |
| `meaning` | `String` | En español |

### `Level`

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Único (p. ej. `level_1`) |
| `order` | `int` | ≥ 1; único |
| `name` | `String` | Texto visible ("Nivel 1") |
| `responseLabel` | `String` | "Defensa" |
| `purpose` | `String` | "Calentamiento" |
| `responseTypes` | `List<ResponseType>` | Al menos 1; sin duplicados. Si hay más de uno, el tipo se sortea por ataque (Spec 005) |

### `Pattern`

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Único (p. ej. `frontal`) |
| `order` | `int` | ≥ 1; único |
| `name` | `String` | "Frontal" |
| `stanceTermId` | `String` | Existe en el glosario (`chochon_se`) |
| `cutTermId` | `String` | Existe en el glosario (`chungmyon_begi`) |
| `cut` | `CutMotion` | Posición inicial y final del sable (empuñadura y punta) y si se refleja según el lado |

### `CutMotion` y `SaberPose` (value objects)

Coordenadas de pantalla relativas a la figura: origen en el centro de la figura, unidad = media altura de la figura; `x` crece hacia la derecha de la pantalla y `y` hacia abajo (cabeza ≈ −1, pies = 1). Cada componente en [−2, 2]. Las manos del oponente se dibujan en `hilt`.

| Tipo | Campo | Tipo | Reglas |
|---|---|---|---|
| `SaberPose` | `hilt` | `Point2` (`x`, `y`: `double`) | Posición de la empuñadura (manos) |
| `SaberPose` | `tip` | `Point2` | Posición visible de la punta. Acercarla a `hilt` representa el escorzo (sable apuntando al usuario) |
| `CutMotion` | `start` | `SaberPose` | Postura del patrón (progreso 0). Frontal: `hilt (0, −0.9)`, `tip (0, −1.6)`: sable vertical sobre la cabeza |
| `CutMotion` | `end` | `SaberPose` | Fin del corte (progreso 1). Frontal: `hilt (0, −0.2)`, `tip (0, −0.35)`: manos al pecho, sable apuntando al usuario |
| `CutMotion` | `mirroredBySide` | `bool` | `true` si el corte sale hacia el lado del ataque ("puede salir hacia ambos lados"); con lado `left` se invierte el signo de `x`. Frontal: `false` |

Durante el corte, `hilt` y `tip` se interpolan linealmente entre `start` y `end` según `cutProgress`.

### Enums del dominio

| Enum | Valores en Spec 001 | Previstos |
|---|---|---|
| `ResponseType` | `defense` | `evasion` (002), `counter` (006) |
| `Side` | `right`, `left` (vistos desde el usuario) | — |
| `VoiceCommand` | `start`, `end` | — |
| `SaberColor` | `white`, `yellow`, `blue`, `red` | — |

Agregar un valor a `ResponseType` es un cambio de código permitido (excepción del Principio III: tipo de señal nuevo). Agregar niveles o patrones, incluidos cortes nuevos expresables con `CutMotion`, es solo datos.

---

## Sesión y parámetros

### `Session`

| Campo | Tipo | Reglas |
|---|---|---|
| `level` | `Level` | Del catálogo |
| `pattern` | `Pattern` | Del catálogo |

Por defecto se preselecciona el primer nivel y el primer patrón por `order` (FR-004).

### `ExerciseParameters`

| Campo | Tipo | Mínimo | Máximo | Por defecto |
|---|---|---|---|---|
| `duration` | `Duration` | 30 s | 180 s | 30 s |
| `maxRepeats` (N) | `int` | 1 | 5 | 5 |
| `warningTime` | `Duration` | 330 ms | 1000 ms | 700 ms |
| `cutSpeed` | `Duration` | 300 ms | 1000 ms | 500 ms |
| `attackInterval` (tope del sorteo) | `Duration` | 500 ms | 5000 ms | 2500 ms |

Propiedades derivadas y reglas:

- `intervalFloor = cutSpeed + 500 ms`.
- **Invariante (FR-007)**: `attackInterval ≥ intervalFloor`. Por eso `attackInterval > cutSpeed`.
- `validate()` devuelve la lista de violaciones: cada campo fuera de rango y `intervalBelowFloor`. La fábrica `ExerciseParameters.create(...)` lanza `InvalidParametersException` si la lista no está vacía; `ExerciseParameters.defaults()` siempre es válido.
- Ejemplo inválido: `cutSpeed = 1 s` con `attackInterval = 1.2 s`, porque el piso es 1.5 s.

---

## Ejercicio

### `ExerciseStatus` (máquina de estados, FR-020)

```text
            start()            t = 3 s              t ≥ E con ataque en curso
  ready ───────────▶ countdown ────────▶ running ─────────────────────────▶ finishing
                        │                   │  t ≥ E sin ataque en curso         │ fin del último corte
                        │                   └─────────────────────▶ finished ◀───┘
                        │ cancel()          │ cancel()                           │ cancel()
                        └──────────────▶ cancelled ◀─────────────────────────────┘
```

| Desde | Hacia | Disparador |
|---|---|---|
| `ready` | `countdown` | `start()` |
| `countdown` | `running` | t ≥ 3 s (evento `startVoice`) |
| `running` | `finishing` | t ≥ E con un ataque en curso (señal visible o corte) |
| `running` | `finished` | t ≥ E sin ataque en curso (evento `endVoice`) |
| `finishing` | `finished` | Fin del último corte (evento `endVoice`) |
| `countdown`, `running`, `finishing` | `cancelled` | `cancel()` (botón Detener o app en segundo plano) |

`finished` y `cancelled` son estados terminales: repetir el ejercicio crea un `ExerciseEngine` nuevo. Cualquier transición que no esté en la tabla lanza `StateError`.

**Extensión futura**: `paused`, con `running`/`finishing` ⇄ `paused` y `paused → cancelled`. El motor congela el tiempo transcurrido mientras está pausado.

### `AttackPhase` (dentro de `running` y `finishing`)

| Fase | Intervalo de tiempo | Sable | Señal |
|---|---|---|---|
| `guard` | Entre el fin de un corte (o *Si-jak*) y la siguiente señal | `yellow` | Ninguna |
| `warning` | [`signalAt`, `cutStartAt`) | `blue` (derecha) / `red` (izquierda) | Visible |
| `cut` | [`cutStartAt`, `cutEndAt`) | `blue` / `red` | Visible |

### `Attack`

| Campo | Tipo | Reglas |
|---|---|---|
| `index` | `int` | 0, 1, 2… dentro del ejercicio |
| `side` | `Side` | Lado de respuesta del usuario; azul = `right`, rojo = `left` |
| `responseType` | `ResponseType` | Uno de `level.responseTypes` (en 001, siempre `defense`) |
| `signalAt` | `Duration` | < E |
| `cutStartAt` | `Duration` | `signalAt + warningTime` |
| `cutEndAt` | `Duration` | `cutStartAt + cutSpeed` |
| `nextSignalAt` | `Duration` | `cutStartAt + sorteo`, con el sorteo en [`intervalFloor`, `attackInterval`] |

### `Signal`

| Campo | Tipo | Reglas |
|---|---|---|
| `responseType` | `ResponseType` | — |
| `screenSide` | `Side` | Para `defense`: el lado **contrario** a `attack.side` (FR-015). Para `evasion` (futuro): el mismo lado |

`SignalPlacement.forAttack(attack)` es la única regla de colocación de la señal: una función por tipo de respuesta, definida en el dominio.

### `SideSequencer`

- Estado: `lastSide` y `streak`, reiniciados en cada ejercicio.
- `next()`: si `streak == maxRepeats`, devuelve el lado contrario sin sortear. Si no, `random.nextInt(2)`.
- Garantiza que nunca haya más de N ataques seguidos al mismo lado (FR-018).

### `ExerciseSnapshot` (salida de `advanceTo`)

| Campo | Tipo |
|---|---|
| `status` | `ExerciseStatus` |
| `phase` | `AttackPhase?` (solo en `running` y `finishing`) |
| `countdownValue` | `int?` (3, 2, 1 solo en `countdown`) |
| `saberColor` | `SaberColor` (`white` en `ready`, `countdown`, `finished` y `cancelled`) |
| `currentAttack` | `Attack?` |
| `signal` | `Signal?` (en `warning` y `cut`) |
| `cutProgress` | `double?` en [0,1] (solo en `cut`) |
| `elapsed` | `Duration` (desde que se pulsó Iniciar) |
| `remaining` | `Duration` (hasta E, nunca negativo) |

### `ExerciseEvent`

`startVoice`, `signalShown(Attack)`, `cutStarted(Attack)`, `cutEnded(Attack)`, `endVoice` y `cancelled`. `advanceTo` los devuelve **en orden** y sin repetir, aunque un solo avance cruce varios.
