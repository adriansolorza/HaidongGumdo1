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
| `guardTermId` | `String` | Postura de guardia; existe en el glosario (`chayon_se`) |
| `stanceTermId` | `String` | Postura de ataque; existe en el glosario (`chochon_se`) |
| `cutTermId` | `String` | Existe en el glosario (`chungmyon_begi`) |
| `guard` | `SaberPose` | Sable en la postura de guardia (reposo antes de *Si-jak*, guardia entre ataques y fin) |
| `cut` | `CutMotion` | Posición inicial (postura de ataque) y final del sable (empuñadura y punta) y si se refleja según el lado |

### `SaberPose`, guardia y `CutMotion` (value objects)

Coordenadas de pantalla relativas a la figura: origen en el centro de la figura, unidad = media altura de la figura; `x` crece hacia la derecha de la pantalla y `y` hacia abajo (cabeza ≈ −1, pies = 1). Cada componente en [−2, 2]. Las manos del oponente se dibujan en `hilt`.

| Tipo | Campo | Tipo | Reglas |
|---|---|---|---|
| `SaberPose` | `hilt` | `Point2` (`x`, `y`: `double`) | Posición de la empuñadura (manos) |
| `SaberPose` | `tip` | `Point2` | Posición visible de la punta. Acercarla a `hilt` representa el escorzo (sable apuntando al usuario) |
| `Pattern` | `guard` | `SaberPose` | Postura de guardia. Frontal (*Chayôn-se*): `hilt (0, 0.05)`, `tip (0, −0.3)`: manos a la altura del ombligo y punta hacia el usuario, en escorzo. La presentación dibuja la punta vista de frente para que el color se lea a 3 m (plan.md, D2) |
| `CutMotion` | `start` | `SaberPose` | Postura del patrón (progreso 0). Frontal: `hilt (0, −0.9)`, `tip (0, −1.6)`: sable vertical sobre la cabeza |
| `CutMotion` | `end` | `SaberPose` | Fin del corte (progreso 1). Frontal: `hilt (0, −0.2)`, `tip (0, −0.35)`: manos al pecho, sable apuntando al usuario |
| `CutMotion` | `mirroredBySide` | `bool` | `true` si el corte sale hacia el lado del ataque ("puede salir hacia ambos lados"); con lado `left` se invierte el signo de `x` de `start` y `end`, nunca el de `guard`. Frontal: `false` |

Durante cada tramo animado (subida, corte y regreso), `hilt` y `tip` se interpolan linealmente entre las dos posturas según el progreso de `OpponentMotion`.

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

| Fase | Intervalo de tiempo | Sable | Señal | Oponente (`motion`) |
|---|---|---|---|---|
| `guard` | Entre el fin de un corte (o *Si-jak*) y la siguiente señal | `yellow` | Ninguna | Regreso `cutEnd → guard` en [`cutEndAt`, `cutEndAt + 500 ms`); después, quieto en `guard` |
| `warning` | [`signalAt`, `cutStartAt`) | `blue` (derecha) / `red` (izquierda) | Visible | Subida `guard → stance` en la primera mitad; quieto en `stance` en la segunda |
| `cut` | [`cutStartAt`, `cutEndAt`) | `blue` / `red` | Visible | Corte `stance → cutEnd` con `cutProgress` |

Las fases y sus límites no cambian con la revisión 2026-11-03: la subida y el regreso ocurren dentro de `warning` y `guard`.

### `OpponentMotion` (revisión 2026-11-03)

Movimiento del oponente en un instante. El dominio calcula los tiempos; la presentación interpola entre las posturas del patrón.

| Campo | Tipo | Reglas |
|---|---|---|
| `from` | `PoseKey` | Postura de origen |
| `to` | `PoseKey` | Postura de destino; igual a `from` cuando está quieto |
| `progress` | `double` | En [0, 1]; 0 cuando está quieto |
| `side` | `Side?` | Lado del ataque al que pertenece el tramo (para `mirroredBySide`); se conserva durante el regreso. `null` antes del primer ataque y en estados terminales |

`enum PoseKey { guard, stance, cutEnd }`, que corresponden a `pattern.guard`, `pattern.cut.start` y `pattern.cut.end`.

| Estado o tramo | Intervalo | `from → to` | `progress` |
|---|---|---|---|
| `ready`, `countdown` | — | `guard → guard` | 0 |
| Subida | [`signalAt`, `signalAt + warningTime/2`) | `guard → stance` | `(t − signalAt) / (warningTime/2)` |
| Arriba | [`signalAt + warningTime/2`, `cutStartAt`) | `stance → stance` | 0 |
| Corte | [`cutStartAt`, `cutEndAt`) | `stance → cutEnd` | `cutProgress` |
| Regreso | [`cutEndAt`, `cutEndAt + 500 ms`) | `cutEnd → guard` | `(t − cutEndAt) / 500 ms` |
| Guardia | Resto de `guard` | `guard → guard` | 0 |
| `finished`, `cancelled` | — | `guard → guard` | 0 (sin animar el regreso, plan.md D4) |

`warningTime/2` se calcula en microsegundos enteros (350 ms por defecto, 165 ms con el mínimo de 330 ms). Los 500 ms del regreso son `ParameterLimits.intervalFloorMargin`: como `nextSignalAt ≥ cutEndAt + 500 ms`, el regreso siempre termina a más tardar con la señal siguiente.

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
| `motion` | `OpponentMotion` (siempre presente; ver arriba) |
| `elapsed` | `Duration` (desde que se pulsó Iniciar) |
| `remaining` | `Duration` (hasta E, nunca negativo) |

### `ExerciseEvent`

`startVoice`, `signalShown(Attack)`, `cutStarted(Attack)`, `cutEnded(Attack)`, `endVoice` y `cancelled`. `advanceTo` los devuelve **en orden** y sin repetir, aunque un solo avance cruce varios.
