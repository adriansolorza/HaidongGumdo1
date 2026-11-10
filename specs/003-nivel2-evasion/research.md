# Research: Nivel 2, señal de evasión

**Feature**: [spec.md](./spec.md) | **Base**: [Spec 001](../001-motor-nivel1-frontal/plan.md) (motor, catálogo, señales) y [Spec 002](../002-patron-transversal/plan.md) (barrido transversal)

El stack, los paquetes y la arquitectura son los de la Spec 001. Las dudas reales eran tres: qué parte del código toca un tipo de señal nuevo (R1), cómo se le da a la flecha el color del sable (R3) y dónde se coloca para que nunca se cruce con el oponente (R4).

## R1. Alcance del cambio en `lib/` (Principio III)

- **Decision**: Agregar el valor `evasion` a `ResponseType`, una rama en `SignalPlacement.forAttack` y el dibujo de la flecha en `SignalPainter`. El Nivel 2 entra como datos en `assets/catalog/catalog.json`. No cambian el motor (`ExerciseEngine`), los sorteos, la regla de N, los estados, `OpponentMotion`, los patrones ni el mapper del catálogo.
- **Rationale**: El código de la 001 ya separa la señal del motor:
  - `ResponseType` es el único lugar que enumera tipos de señal; el comentario de `enums.dart` ya anunciaba `evasion` como la excepción del Principio III.
  - `SignalPlacement.forAttack` es la "única regla de colocación de la señal: una rama por tipo de respuesta".
  - El motor toma el tipo de respuesta de `session.level.responseTypes.first`; con un solo tipo por nivel, el Nivel 2 funciona sin cambios.
  - El mapper valida `responseTypes` contra `ResponseType.values` por nombre, así que acepta `"evasion"` en cuanto existe el valor.
  - La selección lista los niveles del catálogo; un segundo nivel aparece sin tocar la pantalla.
  - Los `switch` sobre `ResponseType` (colocación y painter) son exhaustivos: el compilador obliga a cubrir el valor nuevo en esos dos lugares y en ningún otro.
- **Alternatives considered**:
  - Describir la flecha como datos en el catálogo (forma, colocación). Requiere un esquema de señales y un intérprete de dibujo: más código que la rama nueva, sin beneficio hasta que existan más señales. Se rechaza.
  - Agregar la flecha como un widget nuevo en la pantalla del ejercicio. Duplica la lógica de "qué señal se dibuja" fuera de `SignalPainter`. Se rechaza.

## R2. Colocación: lado de la flecha

- **Decision**: `evasion → screenSide: attack.side`. Con `Side.right` (azul) la flecha va a la derecha; con `Side.left` (rojo), a la izquierda. La defensa sigue en `attack.side.opposite`.
- **Rationale**: `Side` ya significa "lado de respuesta del usuario, visto desde el usuario" (azul = `right`). La evasión es justo ese lado (FR-006), y queda siempre del lado contrario al símbolo de defensa.
- **Alternatives considered**: ninguna; la spec fija el lado.

## R3. Color de la flecha (sesión 2026-11-06, Q2)

- **Decision**: `SignalPainter` recibe el `SaberColor` del snapshot, el mismo valor que recibe `OpponentPainter`, y la flecha de evasión se rellena con ese color (`AppColors.saberBlue` o `AppColors.saberRed`). La pantalla del ejercicio pasa `snapshot.saberColor` al painter. El símbolo de defensa ignora el valor y sigue blanco.
- **Rationale**: Usar el valor del snapshot garantiza por construcción que la flecha y el sable tienen el mismo color en cada fotograma (caso límite "color de la flecha y del sable"); no hay una segunda regla color ↔ lado que pueda desalinearse. `Signal` sigue siendo un dato de dominio sin color.
- **Alternatives considered**:
  - Deducir el color del lado de la pantalla dentro del painter (`right → azul`). Funciona para la evasión, pero duplica la regla color ↔ lado del dominio y se rompería con la señal de contraataque del Nivel 4. Se rechaza.
  - Agregar el color a `Signal`. Mete un concepto de presentación en una entidad del dominio. Se rechaza.

## R4. Geometría y colocación de la flecha (sesión 2026-11-06, Q3)

- **Decision**: Flecha horizontal con cuerpo rectangular y punta triangular, centrada en vertical (como el símbolo de defensa) y apuntando hacia el borde exterior. En horizontal ocupa el tramo entre el **alcance del oponente** y el borde:
  - Borde exterior de la flecha: a 4 % del ancho del borde de la pantalla.
  - Borde interior: a `1.45 u` del centro de la pantalla como mínimo, donde `u = 0.27 × alto` es la unidad del `OpponentPainter`. El mayor `|x|` del catálogo es 1.3 u (punta del transversal en *Sodose* y al final del barrido); el margen de 0.15 u cubre el grosor de la hoja y el contorno. Si la prueba de T012 muestra que el círculo de la punta (radio máximo 0.15 u) más el contorno pasan de 1.45 u, se sube la constante (p. ej. a 1.5 u); es solo un cambio del painter.
  - Largo: el tramo disponible, con un máximo de `0.36 × alto`; si el tramo es más largo, la flecha se ancla al borde exterior.
  - Proporciones respecto al largo `L`: punta de `0.42 L` de largo y `0.62 L` de alto; cuerpo de `0.24 L` de alto.

  Largos resultantes:

  | Pantalla (horizontal) | Tramo disponible | Largo de la flecha |
  |---|---|---|
  | 20:9 (teléfono) | 0.63 alto | 0.36 alto (tope) |
  | 16:9 (TV, teléfono) | 0.43 alto | 0.36 alto (tope) |
  | 16:10 (tablet) | 0.35 alto | 0.35 alto |
  | 4:3 (tablet) | 0.22 alto | 0.22 alto |

- **Rationale**:
  - **FR-007 (no cruzarse con el oponente)**: con el Patrón transversal y sable azul, el barrido termina con la punta en `x = +1.3 u`, del lado de la flecha, a la altura de la cintura. Si la flecha se centrara en el 82 % del ancho como el símbolo de defensa, con un largo fijo, en 16:10 y 4:3 su extremo interior quedaría encima de la punta del sable. Acotarla por el alcance del oponente la mantiene libre en cualquier proporción y en todas las fases (subida, corte, regreso), porque ningún dato del catálogo pasa de 1.3 u.
  - **"Misma zona que el símbolo de defensa"**: la flecha queda en la mitad correspondiente, cerca del borde y centrada en vertical; su centro horizontal cae entre el 85 % y el 88 % del ancho según la proporción, junto al 82 % del símbolo.
  - **Lectura a 3 m**: en una TV de 50" (unos 62 cm de alto) la flecha mide unos 22 cm de largo y 14 cm de alto en la punta. La forma (horizontal, con punta) y el color la distinguen del símbolo de defensa (vertical, blanco), lo que sirve a SC-005.
- **Alternatives considered**:
  - Centrar la flecha en el 82 % del ancho con largo fijo. Se cruza con el final del barrido en 16:10 y 4:3. Se rechaza.
  - Subir la flecha por encima de la línea de la cintura para que tenga el largo completo en cualquier proporción. Se aleja de "la misma zona que el símbolo de defensa" (Q3). Queda como recurso si la validación a 3 m en 4:3 falla.
  - Calcular el alcance a partir de los patrones del catálogo en cada fotograma. Más general, pero acopla el painter de la señal al patrón; una prueba que compara la constante con el catálogo real (R6) cubre el riesgo. Se rechaza por ahora.

## R5. Contraste de la flecha sobre el fondo

- **Decision**: Relleno azul o rojo del sable con el contorno negro de siempre (`kOutlineWidth`), igual que el sable del oponente.
- **Rationale**: Contraste del relleno contra el fondo `#121212`: azul `#1E6BFF` ≈ 4.1 : 1 y rojo `#FF2D2D` ≈ 5.0 : 1, por encima del 3 : 1 que pide WCAG para gráficos (1.4.11). La flecha es mucho más grande que la hoja del sable, que usa los mismos colores. El contorno negro no se ve contra el fondo oscuro, pero mantiene el estilo de todas las figuras y separa la flecha si algo pasara cerca. El "contorno definido" del Principio VIII lo da el borde del relleno contra el fondo (contraste ≥ 3 : 1), igual que la hoja del sable del oponente en las Specs 001 y 002 (decisión del responsable, análisis del 2026-11-06).
- **Alternatives considered**: contorno blanco o halo claro. Mejora el borde contra el fondo, pero rompe la consistencia visual. Queda como ajuste solo del painter si SC-004 falla en el dojang.

## R6. Pruebas

- **Decision**: Pruebas derivadas de la spec, después del código (Principio VI):
  - **Dominio**: colocación de la evasión (azul → derecha, rojo → izquierda); el motor con una sesión de Nivel 2 genera ataques `evasion` y snapshots con la señal del mismo lado que el color; simulaciones de aleatoriedad, N y tiempos de la 001 con el Nivel 2 y los dos patrones (SC-006).
  - **Datos**: el catálogo real tiene 2 niveles en orden, con el Nivel 2 y `responseTypes: ["evasion"]`. La prueba (a) del mapper, que hoy espera 1 nivel y usa `levels.single`, pasa a esperar 2 y a buscar por `id`. La prueba (e) que rechazaba `"evasion"` pasa a usar un nombre desconocido (`"counter"`), y se agrega una que acepta `"evasion"`. Los dos son cambios de datos del catálogo, no de la lógica del ejercicio (SC-007).
  - **Presentación**: el painter de la evasión dibuja en la mitad correcta, con el color del sable, la punta hacia el borde y sin píxeles dentro del alcance del oponente en 20:9, 16:9, 16:10 y 4:3; los dos lados son reflejos. Una prueba comprueba que la constante de alcance (1.45 u) cubre el mayor `|x|` del catálogo real más el radio máximo de la punta y el contorno, y otra que los píxeles del oponente en *Sodose* y al final del barrido no se cruzan con los de la flecha. La selección muestra los dos niveles con el Nivel 1 preseleccionado y "Evasión lateral — Calentamiento / base"; Repetir conserva el Nivel 2 y Volver permite elegir el Nivel 1.
- **Rationale**: Cubre FR-001 a FR-012 y SC-002, SC-003, SC-006 y SC-007 de forma automática; SC-004 y SC-005 se validan a 3 m (quickstart §3).
- **Alternatives considered**: pruebas de golden (imagen de referencia). Frágiles ante cambios de proporción y de la Spec 004. Se rechazan, como en la 002.

## R7. Lo que no cambia

- **Patrones y costado del corte**: el costado de *Sodose* y del barrido depende solo del color (sesión 2026-11-06, Q1). Los datos de los patrones no cambian (FR-003, FR-010).
- **Regla de N**: se aplica a los lados. El Nivel 2 tiene un solo tipo de respuesta, así que la regla de N sobre el tipo (Nivel 3) no aplica.
- **Textos**: el nombre, la respuesta y el propósito del Nivel 2 vienen del catálogo; no hay textos nuevos en `strings_es`.
