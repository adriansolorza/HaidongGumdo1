# Research: Nivel 4, evasión con contraataque

**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Fecha**: 2026-11-19

No quedaron incógnitas en el Technical Context. Cada sección registra una decisión de diseño con su justificación y las alternativas descartadas.

---

## R1. El contraataque como tipo de respuesta nuevo (`ResponseType.counter`)

- **Decision**: Agregar `counter` al enum `ResponseType` del dominio. El Nivel 4 del catálogo lleva `responseTypes: ["counter"]`.
- **Rationale**: El responsable lo definió como tipo de señal nuevo, dentro de la excepción (a) del Principio III. `enums.dart` ya lo tenía previsto ("`counter` se agregará en la Spec 007"). El mapper del catálogo resuelve los tipos por `name`, así que lee `"counter"` sin cambios. Como los `switch` sobre `ResponseType` son exhaustivos, el compilador señala los únicos tres lugares que deben atender el tipo nuevo: `SignalPlacement`, `SignalPainter` y `LevelIconPainter`.
- **Alternatives considered**:
  - *Un nivel con `["evasion", "defense"]` mostrado a la vez*: el `StreakSequencer` de la Spec 006 los sortearía, no los combinaría. Además, la señal no es la suma de la flecha y el símbolo de defensa, porque el sable va vertical y junto a la punta.
  - *Un atributo `counter: true` en el nivel*: es una regla nueva que no es un tipo de señal y no cabe en la excepción (a).

## R2. Colocación: del lado del color, como la evasión

- **Decision**: `SignalPlacement.forAttack` agrega la rama `ResponseType.counter → screenSide: attack.side`, igual que la evasión.
- **Rationale**: Es FR-008 (azul → derecha, rojo → izquierda). La colocación sigue siendo una regla de una línea por tipo, en el único lugar donde se decide.
- **Alternatives considered**: *Reutilizar la rama de evasión con un `case evasion || counter`*: es equivalente. Se prefiere una rama propia con su comentario de FR, como las otras dos.

## R3. Secuencia: sin sorteos nuevos

- **Decision**: El motor no cambia. Con `responseTypes` de un solo elemento, el `StreakSequencer<ResponseType>` de la Spec 006 devuelve `counter` **sin consumir sorteo**.
- **Rationale**: Cumple FR-002 (sin reglas de secuencia nuevas) y FR-004/FR-005. Además da un oráculo de prueba muy fuerte: con la misma fuente de aleatoriedad y la misma configuración, un ejercicio de Nivel 4 produce **exactamente** los mismos lados e instantes que uno de Nivel 2; solo cambia `responseType`.
- **Alternatives considered**: Ninguna. Cualquier cambio en el motor violaría FR-002.

## R4. Geometría de la señal de contraataque

- **Decision**: Para el lado derecho (la flecha apunta a la derecha), y reflejada en `x` para el izquierdo como las demás señales, la señal se compone así, de afuera hacia adentro:

  | Pieza | Medida (en función de `Lc`, largo de la flecha de contraataque) |
  |---|---|
  | Brillo exterior `g` | 3σ, con σ = 0.04 `Lc` (igual que la flecha de evasión) → 0.12 `Lc` |
  | Sable vertical | alto `Hs` = 1.10 × alto de la punta (1.06 `Lc`) ≈ 1.17 `Lc`; ancho = ancho de la guarda ≈ 0.26 `Hs` ≈ 0.30 `Lc` |
  | Separación sable–punta | 0.10 `Lc` ("casi junto a la punta") |
  | Flecha | la de `SignalShapes.evasionArrow`, largo `Lc` |
  | Estela | mínimo 0.6 `Lc`, máximo `Lc` según el espacio, como en la Spec 004 |
  | Brillo interior `g` | 0.12 `Lc` |

  El ancho mínimo es 2.24 `Lc`. El sable va **centrado en vertical sobre el eje de la flecha** (Clarifications) y el conjunto se centra en `h / 2` con `_clampedCenterY`, como la flecha de evasión.

  `Lc = min(L2, lane.width / 2.24)`, donde `L2` es el largo de la flecha del Nivel 2 en la misma pantalla: `L2 = min(0.30 h, lane.width / 1.84)`.

- **Rationale**:
  - **Mínimo del 75 % garantizado por construcción.** Si `L2` está limitado por el carril, `Lc = 1.84 / 2.24 · L2 ≈ 0.82 L2`. Si está limitado por el alto, `Lc` es `L2` o el límite del carril, que en ese caso es aún mayor que 0.82 `L2`. Así, `Lc ≥ 0.82 L2 > 0.75 L2` en cualquier lienzo y FR-010 se cumple sin ramas de "recomposición". La prueba SC-009 lo verifica en los 7 lienzos.
  - **Alto.** `Hs` ≈ 1.17 `Lc` frente a 1.06 `Lc` de la punta: "igual o apenas mayor" (+10 %).
  - **Dentro del carril.** Todo, incluidos el brillo y la estela, queda dentro de `layout.rightLane`, que ya excluye el alcance del oponente (Spec 004, R5). FR-010 no requiere tocar `SceneLayout`.
- **Alternatives considered**:
  - *Mantener `L2` y sacar el sable del carril*: viola FR-010 y el carril.
  - *Escalar siempre al 75 %*: hace la flecha más chica de lo necesario en 16:9 y 20:9.
  - *Sable a la altura de la punta, subiendo* (opción B de Clarifications): descartado por el responsable.

## R5. El sable vertical reutiliza la forma del símbolo de defensa

- **Decision**: Generalizar `SignalShapes.defenseSaber(box)` a `SignalShapes.saber(box, {angleDegrees})`, que es la misma construcción con el ángulo como parámetro. `defenseSaber(box)` queda como `saber(box, angleDegrees: 115)`, y la señal de contraataque usa `angleDegrees: 90`. Lo mismo se hace con `fitDefense` → `fitSaber(lane, maxHeight, angleDegrees)`.
- **Rationale**: Es la suposición de la spec: hoja delgada, empuñadura más gruesa y guarda gris, sin un dibujo nuevo. Con 115° la geometría es idéntica bit a bit, así que el Nivel 1, el Nivel 3 y el ícono de defensa no cambian. Las pruebas de pixeles existentes lo confirman. A 90° el sable es simétrico, así que el reflejo para el lado izquierdo lo deja igual (FR-008: "igual en los dos lados").
- **Alternatives considered**: *Una forma nueva `counterSaber`*: duplica proporciones y se desalinea del símbolo de defensa.

## R6. Pintado de la señal de contraataque

- **Decision**: `SignalPainter` agrega `_paintCounter`, que:
  1. calcula `Lc` y las cajas (R4);
  2. dibuja la flecha con la misma rutina de la evasión (estela, brillo, relleno, contorno y reflejo), extraída a un método privado `_paintArrow(canvas, box, trailLimit, color)` que comparten `_paintEvasion` y `_paintCounter`;
  3. dibuja el sable vertical con la misma rutina de la defensa (brillo de la hoja, empuñadura `AppColors.grip`, hoja del color del sable, reflejo blanco y guarda `AppColors.tsuba`), extraída a `_paintSaber(canvas, saber, sigma, color)`.

  Flecha y sable se pintan en el mismo `paint`, así que aparecen y desaparecen juntos (FR-011).
- **Rationale**: Brillo y estela "como las demás señales" sin copiar código. Extraer los métodos no cambia las operaciones de dibujo de la evasión ni de la defensa: mismas llamadas, mismos parámetros y mismo orden.
- **Alternatives considered**: *Dos painters superpuestos (`evasion` + sable)*: duplican la lógica de colocación y pueden desalinearse.

## R7. Ícono del Nivel 4

- **Decision**: `LevelIconPainter._paintGlyph` agrega el caso `counter`: las 3 líneas de movimiento, la flecha y el sable vertical, en blanco y sin brillo, en una celda cuadrada. El ancho total es ≈ 1.80 `L` (líneas 0.35 `L` + flecha `L` + separación 0.10 `L` + sable 0.30 `L`), centrado en vertical. Con `types: [counter]` hay una sola celda (Spec 006, R6).
- **Rationale**: FR-016 pide el ícono "generado como los demás" a partir del tipo de respuesta. El glifo de evasión ya usa líneas, flecha y blanco, y el de contraataque solo agrega el sable vertical de R5. Los glifos de defensa y evasión no se tocan.
- **Alternatives considered**: *Ícono sin líneas de movimiento*: rompe la semejanza con el ícono del Nivel 2 que busca SC-007 ("evadir y cortar").

## R8. Selección con cuatro niveles

- **Decision**: No se toca la selección. La densidad compacta de la Spec 006 (`SelectionDensity`, FR-012a) ya se probó con un catálogo de 4 niveles en los 7 lienzos de referencia. Con el Nivel 4 en el catálogo real, esas pruebas pasan a correr también con el asset real.
- **Rationale**: FR-014 y FR-015 los cumple el trabajo de la Spec 006.
- **Alternatives considered**: Ninguna.

## R9. Estrategia de pruebas

- **Decision**:
  - **Dominio**:
    - `signal_placement_test` con el caso `counter`.
    - Nuevo `exercise_engine_level4_test` con:
      - todos los ataques `counter`;
      - lados e instantes idénticos a los del Nivel 2 con la misma semilla (R3);
      - rachas de lado ≤ N para N de 1 a 5 (SC-004);
      - proporción de lados con N = 5 (SC-005).
    - Los grupos parametrizados de `timeline`, `motion` y `simulation` se extienden al Nivel 4.
    - `exercise_engine_sequence_regression_test` **no cambia**.
  - **Datos**: `catalog_json_mapper_test` con 4 niveles y `level_4` (FR-001), y el rechazo de un tipo desconocido sigue vigente.
  - **Presentación**:
    - `signal_painter_test`, en los 7 lienzos (4 proporciones más los 3 de la Spec 006) y en todas las fases del ataque con los dos patrones:
      - la señal queda dentro del carril y fuera del alcance (SC-009);
      - `Lc ≥ 0.75 L2` (FR-010);
      - el sable es vertical (columna de color de la hoja centrada sobre el eje), centrado en vertical sobre el eje de la flecha y del lado al que apunta;
      - el reflejo es correcto para rojo;
      - la regla de color se cumple.
    - Las pruebas de pixeles de la evasión y la defensa siguen pasando sin cambios (R5, R6).
    - `level_icon_test`: el ícono del contraataque es blanco y sin rojo, azul ni amarillo, y los íconos de los Niveles 1 a 3 no cambian.
    - `selection_screen_test`: 4 tarjetas reales, en orden, con el Nivel 1 preseleccionado, y el texto "Evasión y contraataque — Combate".
    - `exercise_screen_test`: el Nivel 4 muestra una sola señal (contraataque) y el HUD dice "NIVEL 4" y "Evasión y contraataque".
- **Rationale**: Principio VI: las pruebas salen de los escenarios y los SC de la spec. La aleatoriedad y el reloj ya se inyectan.
- **Alternatives considered**: *Goldens de imagen*: el proyecto prueba propiedades de pixeles, no goldens (Spec 004). Se mantiene ese criterio.
