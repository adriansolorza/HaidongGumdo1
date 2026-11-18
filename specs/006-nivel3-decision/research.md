# Research: Nivel 3, decisión bajo presión

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Fecha**: 2026-11-18

No quedaban incógnitas técnicas abiertas. Cada sección registra una decisión, su razón y las alternativas que se descartaron.

---

## R1. Alcance del cambio

**Decision**: El cambio se limita a lo siguiente:

- **Dominio**: `SideSequencer` se generaliza en `StreakSequencer<T>` (R2), y el motor sortea el tipo de respuesta con una segunda instancia (R3). `ResponseType`, `Signal`, `SignalPlacement`, `Attack`, `ExerciseParameters`, los estados y las voces no cambian. Solo se corrige el comentario de `enums.dart`, que fecha `counter` en la Spec 006 en lugar de la 007.
- **Datos**: se agrega `level_3` a `assets/catalog/catalog.json` (R4). El mapper no cambia.
- **Presentación**: `LevelIcon` dibuja una o varias señales (R6). La selección deja de desplazarse y gana una densidad compacta (R7). El HUD, la pantalla del ejercicio y los painters de las señales no cambian.

**Rationale**: La spec (FR-002 corregido) admite datos y **una sola** regla nueva en el dominio. Todo lo demás ya está preparado:
- `Level.responseTypes` es una lista.
- El mapper ya acepta varios tipos sin duplicados.
- `SignalPlacement` decide la señal **por ataque**.
- El `SignalPainter` dibuja según el `responseType` de la señal.

**Alternatives considered**: Ninguna con menos cambios cumple FR-004 y FR-005.

---

## R2. Un único sorteo con racha máxima: `StreakSequencer<T>`

**Decision**: Se renombra y generaliza `lib/domain/exercise/side_sequencer.dart` como `lib/domain/exercise/streak_sequencer.dart`. El resultado es `final class StreakSequencer<T>`, construido con `options` (lista ordenada, no vacía y sin duplicados), `maxRepeats` (≥ 1) y `random` ([contrato §1](./contracts/domain-sequencer.md#1-streaksequencert)). El algoritmo de `next()` es:

1. Si `options` tiene **un solo** elemento, se devuelve ese elemento **sin consumir sorteo**.
2. Los candidatos son todas las opciones. Si la racha llegó a `maxRepeats`, se quita de los candidatos la última opción devuelta.
3. Si queda **un solo** candidato, se devuelve **sin consumir sorteo**. Si quedan varios, se devuelve `candidates[random.nextInt(candidates.length)]`.
4. La racha y la última opción se actualizan igual que hoy.

Los lados usan `options: const [Side.right, Side.left]`, en ese orden explícito, sin depender del orden de `Side.values`.

**Equivalencia con el `SideSequencer` actual, caso por caso:**

| Situación | `SideSequencer` hoy | `StreakSequencer<Side>` | ¿Igual? |
|---|---|---|---|
| Racha < N | `nextInt(2)`: 0 → `right`, 1 → `left` | candidatos `[right, left]`, `nextInt(2)`: 0 → `right`, 1 → `left` | Sí: mismo sorteo, mismo resultado |
| Racha = N | `lastSide.opposite`, sin sorteo | un candidato (el contrario), sin sorteo | Sí |
| Actualización de racha | `side == last ? streak + 1 : 1` | igual | Sí |

Con la misma fuente de aleatoriedad, el sorteo de lados consume exactamente los mismos números en el mismo orden y devuelve los mismos lados.

- **Getters**: `lastSide` pasa a llamarse `last`, y `streak` se mantiene. Solo cambia el nombre (condición del responsable).
- **Validación nueva en el constructor**: lanza `ArgumentError` si `options` está vacía o tiene duplicados, o si `maxRepeats < 1`. Ningún uso actual cumple esas condiciones, así que el comportamiento observable no cambia. Con una sola opción, la racha crece sin límite: es inevitable y coincide con la Spec 003 ("la regla de N sobre el tipo solo aplica desde el Nivel 3").

**Rationale**: El responsable pidió **una sola** lógica de racha para lados y tipos. El paso 1 cumple su condición explícita: un nivel con un solo tipo no consume números, así que las secuencias de los Niveles 1 y 2 no cambian. El paso 3 es la misma regla que hoy fuerza el lado contrario sin sorteo, generalizada. El tipo genérico `T` sirve igual para `Side` y para `ResponseType` sin acoplar el secuenciador al catálogo.

**Alternatives considered**:
- *Un `ResponseTypeSequencer` nuevo, copia del `SideSequencer`*: duplica la regla de N. El responsable lo descartó.
- *Un secuenciador que sortee el par (lado, tipo) de una vez con `nextInt(4)`*: cambia el consumo de números en los Niveles 1 y 2 y rompe la condición de secuencias idénticas.
- *Sortear siempre, también con una sola opción (`nextInt(1)`)*: consume un número por ataque y desplaza todos los sorteos de intervalo de los Niveles 1 y 2. Prohibido por el responsable.
- *Un `bool` "forzar alternancia" en lugar de candidatos*: solo vale para dos opciones. Con candidatos, el secuenciador sirve para cualquier número de opciones sin costo extra.

---

## R3. Orden de los sorteos en el motor

**Decision**: En `ExerciseEngine._onSignal`, el orden fijo es: (1) **lado**, con `_sides.next()`; (2) **tipo de respuesta**, con `_responseTypes.next()`; (3) **intervalo** hasta la siguiente señal, con `_drawInterval()`. El tipo se calcula en una variable local antes de construir el `Attack`. El intervalo sigue sorteándose dentro del constructor, como hoy. `_responseTypes` es un `StreakSequencer<ResponseType>` con `options: session.level.responseTypes` y el mismo `maxRepeats` de los parámetros (FR-005). Se crea junto a `_sides` en el constructor del motor, una instancia por ejercicio (FR-007).

**Rationale**:
- En los Niveles 1 y 2, el paso (2) no consume números (R2, paso 1). La secuencia de consumo sigue siendo lado → intervalo, como hoy, así que lados, tipos e instantes son idénticos.
- En el Nivel 3, el orden fijo hace que las pruebas con `ScriptedRandomSource` sean deterministas y fáciles de escribir.
- Lado y tipo salen de sorteos distintos: son independientes (FR-004) y cada uno lleva su racha (FR-006).

**Alternatives considered**:
- *Tipo antes que lado*: en los Niveles 1 y 2 da lo mismo, pero en el Nivel 3 rompe la costumbre de leer los guiones de prueba como "lado, …, intervalo". Se descarta por legibilidad.
- *Un `RandomSource` separado para el tipo*: cambia el constructor del motor y el proveedor sin necesidad.

---

## R4. Catálogo: `level_3`

**Decision**: Se agrega a `levels` en `assets/catalog/catalog.json`:

```json
{ "id": "level_3", "order": 3, "name": "Nivel 3", "responseLabel": "Defensa o evasión lateral", "purpose": "Decisión bajo presión", "responseTypes": ["defense", "evasion"] }
```

Con este orden, `nextInt(2)` da 0 → defensa y 1 → evasión, y el ícono muestra la defensa primero (FR-013, "en el orden del catálogo").

**Rationale**: Es la tabla de niveles del brief, tal cual (FR-001). El mapper ya valida que la lista no esté vacía, que los tipos se conozcan y que no se repitan.

**Alternatives considered**: Un campo `"mix": true` en el nivel. Es redundante, porque dos tipos ya significan mezcla.

---

## R5. Señales y pantalla del ejercicio sin cambios

**Decision**: No se toca `SignalPlacement`, `SignalPainter`, `SignalShapes`, `ExerciseScreen` ni `ExerciseHud`.

**Rationale**:
- La señal ya se calcula por ataque desde `attack.responseType` (Spec 003, "única regla de colocación").
- Defensa del lado contrario al color y evasión del lado del color (FR-008) es exactamente la regla vigente.
- El HUD ya muestra `level.name` y `level.responseLabel` del catálogo (FR-015).
- La señal aparece y desaparece con los mismos eventos (FR-009).
- Los painters no consultan el nivel: solo dibujan la `Signal` que reciben.

**Alternatives considered**: Ninguna. Cualquier cambio en estos archivos violaría FR-002.

---

## R6. Ícono de la tarjeta con varias señales

**Decision**: `LevelIcon` recibe `types: List<ResponseType>` en lugar de `type`. El painter divide la caja útil (con el margen actual del 10 %) en `n` celdas **horizontales** iguales, con una separación de 8 % del ancho entre ellas. En cada celda dibuja el glifo de su tipo con el mismo código de hoy, en blanco: la flecha con sus líneas de movimiento o el sable de defensa. Cada glifo se ajusta al cuadrado más grande que cabe en su celda y se centra en vertical.

- Con `n = 1`, la celda es la caja completa, así que el dibujo es **idéntico** al actual (FR-013: los íconos de los Niveles 1 y 2 no cambian).
- `selection_screen.dart` pasa `level.responseTypes` completo.

**Rationale**: El responsable eligió "las dos señales juntas, lado a lado, en blanco y a menor tamaño". El ícono se arma con datos del catálogo, así que un nivel futuro con otros tipos no necesita código nuevo (Spec 004, FR-021). La regla de color se cumple porque solo se usa `AppColors.textPrimary`.

**Alternatives considered**:
- *Un ícono propio del Nivel 3*: exige código por nivel. Viola el Principio III y la Spec 004.
- *Ensanchar la celda del ícono en la tarjeta*: desalinea las columnas de tarjetas. Hoy los glifos ya caben en 56 × 56 con margen.

---

## R7. Tarjetas sin desplazar (FR-012a, SC-007a)

**Decision**:

1. En `_CardColumn`, el `ListView.separated` se reemplaza por un `Column` que **no se desplaza**.
2. Se agrega un tipo puro de presentación, `SelectionDensity`, con dos valores: `regular` (las medidas de la Spec 004, sin cambios) y `compact`. Una función pura, `SelectionDensity.choose(...)`, elige la densidad a partir de la altura disponible para las columnas, la escala `s` y el mayor número de tarjetas por columna. Usa `regular` si las tarjetas caben a su altura mínima regular (`104 s` cada una, `14 s` entre tarjetas y `8 s` del anillo), y `compact` si no caben ([contrato §3](./contracts/selection-ui.md#3-densidad-de-la-selección)).
3. **Medidas compactas** (en dp absolutos, no escaladas por `s`):

   | Elemento | Medida |
   |---|---|
   | Tarjeta | altura mínima 48 (blanco táctil de Material), padding vertical 6 y horizontal 12, separación 6 |
   | Celda del ícono | 40, glifo de 32 |
   | Textos | título 16, detalle 12 (un texto de detalle puede ocupar dos líneas) |
   | Encabezado de columna | 13, separación 6 |
   | Encabezado de la pantalla | título 32, subtítulo 14 |
   | Márgenes | 16 arriba, 12 abajo, 24 a los lados; 10 entre encabezado, columnas y pie |

   El pie (resumen, CONFIGURACIÓN e INICIAR) **no** se compacta: conserva los botones de la Spec 005, con un alto de al menos 48 dp.
4. **Red de seguridad**: si ni la densidad `compact` cabe (alturas fuera de las proporciones y tamaños de referencia, por debajo de unos 360 dp con tres niveles), la columna vuelve a desplazarse. Así nunca hay desbordamiento ni contenido recortado.

**Presupuesto con los lienzos de referencia** (los de la Spec 004: 1778 × 800, 1422 × 800, 1280 × 800, 1067 × 800 y el teléfono de 889 × 400; más 1024 × 768 y 2400 × 1080, de la Spec 005):

| Lienzo | `s` | Alto libre para columnas | 3 niveles | 4 niveles |
|---|---|---|---|---|
| 800 dp de alto (las cuatro proporciones) | 1.0 | ≈ 470 | regular: 3 × 104 + 2 × 14 + 8 = 348 | regular: 466 |
| 1024 × 768 | 0.96 | ≈ 450 | regular | regular (≈ 447) |
| 2400 × 1080 | 1.35 | ≈ 635 | regular | regular |
| Teléfono 889 × 400 | 0.7 | regular ≈ 185 → no cabe; compacta ≈ 244 | compacta: 3 × 48–60 + 2 × 6 + 8 ≤ 200 | compacta: 4 × 48–55 + 3 × 6 + 8 ≤ 246 |

Las medidas exactas se verifican con las pruebas de widgets (SC-007a). Las cifras de la tabla sirven para dimensionar, no como expectativa de prueba.

**Rationale**:
- Con las medidas de la Spec 004 y 800 dp de alto caben hasta cuatro niveles, así que las pantallas de tablet y TV quedan **igual** que hoy.
- En los teléfonos en horizontal, hoy la columna ya se desplaza. Escalar todo por igual bajaría el detalle a unos 9 dp, que no es legible. Por eso la densidad compacta reduce sobre todo márgenes y separaciones, y los textos solo hasta un mínimo legible a la distancia de la mano (16 y 12 dp). La selección no se lee a 3 m: se usa antes de alejarse.

**Alternatives considered**:
- *Escala uniforme para que quepa*: en el teléfono deja el texto por debajo de 9 dp.
- *Rejilla de 2 × 2 en la columna de niveles*: en el teléfono, las celdas de unos 190 dp no tienen espacio para "respuesta — propósito".
- *Ocultar el subtítulo o el propósito en modo compacto*: viola la Spec 004 (FR-020, FR-021) y FR-012a.

---

## R8. Pruebas

**Decision** (las pruebas se derivan de la spec; Principio VI):

- **Regresión de secuencias (antes de tocar el motor)**: una prueba nueva, `exercise_engine_sequence_regression_test.dart`, graba como valores fijos la lista completa de ataques (lado, tipo e instantes) que produce el motor **actual**.
  - Cubre los Niveles 1 y 2 con los dos patrones, tres semillas de `SeededRandomSource` y dos valores de N (1 y 5).
  - Se escribe y se confirma en verde **antes** del refactor; después del refactor debe seguir en verde sin cambiar ningún valor.
  - Es la prueba directa de la condición "mismas secuencias que hoy".
- **`StreakSequencer`**: `side_sequencer_test.dart` pasa a `streak_sequencer_test.dart`. Sus cuatro pruebas conservan los guiones de sorteos y las expectativas, y solo cambian el nombre de la clase, `options: [Side.right, Side.left]` y `lastSide` → `last`. Se agregan pruebas nuevas:
  - una sola opción: no consume sorteos y la devuelve siempre;
  - opciones `ResponseType` con N = 1, 2 y 5;
  - validación del constructor.
- **Motor, Nivel 3** (FR-004 a FR-007; SC-004, SC-005):
  - con un guion de sorteos, el orden de consumo es lado → tipo → intervalo;
  - en los Niveles 1 y 2, el número de sorteos consumidos es exactamente 2 por ataque más 1 inicial;
  - simulación de 1 000 ejercicios por cada N de 1 a 5, sin rachas de lado ni de tipo mayores que N;
  - con N = 5, proporciones de 45–55 %;
  - las rachas de tipo se reinician con cada ejercicio;
  - el resto de los requisitos de la Spec 001 (tiempos, estados, fin con corte en curso) se cumple con el Nivel 3 y los dos patrones, reutilizando los grupos parametrizados existentes de las pruebas de línea de tiempo, movimiento y simulación.
- **Datos**: la prueba (a) del asset real pasa a esperar tres niveles. SC-008 lo permite: es una prueba que enumera los niveles del catálogo. Se agrega una prueba de `level_3` con `[defense, evasion]`.
- **Presentación**:
  - `LevelIcon` con dos tipos: solo píxeles blancos o transparentes, y un glifo en cada mitad.
  - `LevelIcon` con un tipo: misma imagen que antes.
  - Selección en los siete lienzos de R7, con el catálogo real (3 niveles) y con un catálogo de prueba de 4 niveles: ninguna tarjeta queda fuera de la vista ni se superpone al pie, y no hay desplazamiento.
  - Ejercicio de Nivel 3: en cada `SignalShown` se dibuja exactamente una señal y el HUD muestra "NIVEL 3".

**Rationale**: La regresión grabada es la única forma de demostrar la equivalencia de secuencias contra el código **actual**, en lugar de contra una reimplementación.

**Alternatives considered**: Comparar contra una copia del `SideSequencer` viejo dentro de la prueba. Prueba el secuenciador, pero no el orden de consumo del motor.
