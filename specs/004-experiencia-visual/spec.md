# Feature Specification: Experiencia visual ("que enamore")

**Feature Branch**: `004-experiencia-visual`

**Created**: 2026-11-10

**Status**: Draft

**Input**: User description: "Spec 004: Experiencia visual ("que enamore"). Usa como contexto @docs/brief.md, @docs/design/referencia-visual-spec004.md, los bocetos de @docs/design/bocetos/ y las specs 001, 002 y 003. Objetivo: que la app guste a los practicantes para que la usen y den comentarios, sin perder la legibilidad a 3 m. Alcance y decisiones del responsable: estilo visual "consola actual" (boceto Retro.dc.html) en la pantalla del ejercicio y en la de selección (Seleccion.dc.html); fondo de dojang (pared cálida clara, madera, duela, luz suave y viñeta) que no se confunda con las piernas del oponente; oponente con equipo de competencia (casco con rejilla, peto, coderas y guantes, sobre dobok y hakama) blanco o gris muy claro; regla de color: rojo, azul y amarillo son exclusivos del sable y de las señales; flecha de evasión corta y gruesa con una estela que se desvanece; símbolo de defensa con hoja delgada y empuñadura gruesa; sable horizontal en Sodose y durante todo el barrido transversal, visible al pasar frente al oponente (Spec 002, FR-009); HUD del ejercicio con nivel y respuesta, patrón con hangul, segundos restantes con barra de progreso y botón Detener, en paneles translúcidos; pantalla de selección con tarjetas, resumen de la sesión y botón Iniciar. No cambian el comportamiento, los tiempos, las reglas ni el motor: todas las pruebas funcionales de las specs 001–003 deben seguir pasando. Si algo exige código nuevo en el dominio, una dependencia o una tipografía nueva, dímelo antes (Principios III y VII). No implementes nada."

## Contexto

Las Specs 001 a 003 entregaron una app funcional: el motor del ejercicio, el Nivel 1 (defensa), el Nivel 2 (evasión lateral) y los patrones frontal y transversal. Su aspecto es deliberadamente sencillo: fondo negro, un oponente gris hecho de formas básicas, señales planas y una interfaz con controles estándar.

Esta spec cambia **solo el aspecto**. El objetivo es que la app **guste** a los practicantes, para que la usen y den comentarios, **sin perder la legibilidad a 3 m**, que sigue siendo la prioridad. Se adopta el estilo "consola actual" de los bocetos aprobados (`docs/design/bocetos/Retro.dc.html` y `Seleccion.dc.html`; resumen en `docs/design/referencia-visual-spec004.md`): un dojang de fondo, un oponente con equipo de competencia, señales con brillo y una interfaz de paneles translúcidos.

**Lo que no cambia.** El comportamiento, los tiempos, las reglas de aleatoriedad, el máximo de N, los estados, las voces, la cancelación y el motor. Las señales siguen en los mismos lados y con los mismos colores. Todas las pruebas funcionales de las Specs 001 a 003 siguen pasando.

**Principios III y VII.** Esta spec no requiere código nuevo en el dominio ni paquetes nuevos. Sí requiere:

- **Una tipografía nueva** (Rajdhani 500 y 700), aprobada por el responsable el 2026-11-10: se incluyen los archivos de la fuente en la app, sin paquete, y la decisión se registra como ADR en `docs/decisions/`.
- **Un cambio de datos** en el catálogo: en el Patrón transversal, la punta del sable queda a la altura de la empuñadura en _Sodose_ y en el fin del corte, para que el sable sea horizontal (ver FR-010). Es un cambio de datos, no de lógica (Principio III).

### Hoja de ruta de la v1 (según `docs/brief.md`, rev. 3)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| 001            | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| 002            | Patrón transversal                                                         |
| 003            | Nivel 2 (señal de evasión)                                                 |
| **004 (esta)** | Experiencia visual                                                         |
| 005            | Configuración de parámetros e invariante de tiempos                        |
| 006            | Nivel 3                                                                    |
| 007            | Nivel 4                                                                    |

### Glosario (términos que agrega esta spec)

| Término               | Significado en la app                                                                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Dojang                | Escenario de fondo: pared clara cálida, columnas y viga de madera, zócalo, duela, luz suave sobre la duela y viñeta en las orillas     |
| Equipo de competencia | Casco con rejilla, peto, coderas y guantes que lleva el oponente sobre el dobok y la _hakama_                                          |
| HUD                   | Información superpuesta a la escena del ejercicio: nivel, patrón, segundos restantes y botón Detener                                   |
| Colores de señal      | Rojo, azul y amarillo. Solo los usan el sable del oponente y las señales                                                               |
| Punta de frente       | Instante del barrido transversal en que el sable apunta al usuario y su largo en pantalla se acerca a cero; la punta se ve de frente |
| Estela                | Rastro del color del sable detrás de la flecha de evasión, que se desvanece hacia la cola                                             |

Los demás términos (_Si-jak_, _Guman_, _Chayôn-se_, _Chochôn-se_, _Sodose_, _Chungmyôn begi_, _Hwengdan ilgôm begi_, ataque, tiempo de aviso, velocidad del corte, señal de defensa, señal de evasión, alcance del oponente) mantienen el significado de las Specs 001 a 003.

## Clarifications

### Session 2026-11-10

- Q: ¿Cómo se incorpora la tipografía Rajdhani? → A: Se incluyen los archivos de la fuente (pesos 500 y 700) en la app, sin paquete nuevo, y funciona sin conexión. Se registra como ADR. El hangul y el hanja usan la fuente del sistema.
- Q: Con el sable horizontal, ¿cómo se ve el instante en que apunta al usuario y su largo en pantalla es cero? → A: Se ve la **punta de frente**: a medida que la hoja se acorta, la punta se dibuja como un disco del color del sable, con contorno y brillo, de un tamaño mínimo legible a 3 m. El sable se mantiene horizontal, a velocidad uniforme y sin trayectoria diagonal (Spec 002, FR-008).
- Q: La _hakama_ azul marino y la guarda dorada del símbolo de defensa de los bocetos rompen la regla de color. ¿Qué colores llevan? → A: Ambos neutros, sin excepciones: _hakama_ gris carbón o negra sin tinte azul, y guarda del símbolo de defensa gris, como la tsuba del oponente.
- Q: ¿Cómo se hacen los íconos de silueta de los patrones en la selección? → A: Se generan a partir de la postura del patrón en el catálogo. Un patrón nuevo tiene ícono sin cambiar código (Principio III; Spec 001, SC-009).

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Entrenar frente a un oponente en un dojang (Priority: P1)

El practicante inicia un ejercicio y ve a un oponente con equipo de competencia, de pie en un dojang, en lugar de una figura gris sobre fondo negro. El sable sigue siendo lo más llamativo de la escena: blanco en reposo, amarillo en guardia, azul o rojo en cada ataque, con un brillo suave del mismo color. En el patrón transversal, el sable se ve horizontal en _Sodose_ y durante todo el barrido, como en un corte real, y nunca desaparece al pasar frente al oponente.

**Why this priority**: Es la pantalla donde el practicante pasa casi todo el tiempo y la que más define si la app "enamora". También es la de mayor riesgo: si la escena compite con el sable, se pierde la legibilidad.

**Independent Test**: Iniciar ejercicios de Nivel 1 y Nivel 2 con los dos patrones y observarlos en el dispositivo, de cerca y a 3 m.

**Acceptance Scenarios**:

1. **Given** cualquier sesión, **When** empieza el ejercicio, **Then** el fondo es el dojang (pared clara cálida, madera, duela, luz suave y viñeta) y el oponente lleva casco con rejilla, peto, coderas y guantes blancos o gris muy claro sobre dobok y _hakama_ oscura neutra.
2. **Given** el oponente de pie frente a la pared, **When** se observa a 3 m, **Then** su silueta, incluidas las piernas, se distingue con claridad de la pared y de la duela.
3. **Given** un ataque, **When** el sable cambia de color, **Then** ningún otro elemento de la escena ni de la interfaz es rojo, azul o amarillo.
4. **Given** el Patrón transversal, **When** el oponente está en _Sodose_ y durante todo el barrido, **Then** la hoja se ve horizontal, a la altura de la cintura.
5. **Given** el barrido transversal, **When** el sable apunta al usuario, **Then** se ve la punta de frente del color del sable y el color se reconoce a 3 m.

---

### User Story 2 - Leer señales más llamativas (Priority: P2)

El practicante ve una flecha de evasión corta y gruesa, con una estela que se desvanece en la cola y un brillo del color del sable, y un símbolo de defensa con hoja delgada y empuñadura gruesa. Las dos se leen aún más rápido a 3 m y ocupan los mismos lados que antes.

**Why this priority**: Las señales son la información esencial del ejercicio. El rediseño de la flecha está pendiente desde la Spec 003 (`docs/design/flecha-evasion-boceto.png`).

**Independent Test**: Ejercicios de Nivel 1 y Nivel 2 con los dos patrones: comprobar forma, color, lado y que la señal nunca se cruza con el sable.

**Acceptance Scenarios**:

1. **Given** el Nivel 2, **When** aparece la señal, **Then** es una flecha corta y gruesa, del color del sable, con contorno oscuro, brillo suave y una estela que se desvanece hacia la cola, del mismo lado y apuntando hacia el mismo borde que en la Spec 003.
2. **Given** el Nivel 1, **When** aparece la señal, **Then** es un sable en diagonal visto desde arriba, con hoja delgada del color del sable y empuñadura más gruesa, guarda gris y contorno oscuro, del mismo lado que en la Spec 001.
3. **Given** cualquier patrón, lado, proporción de pantalla y fase del movimiento, **When** la señal está visible, **Then** ninguna parte de ella (incluidos la estela y el brillo) se cruza con el oponente ni con su sable.

---

### User Story 3 - Seguir el ejercicio de un vistazo (Priority: P3)

Durante el ejercicio, el practicante ve en paneles translúcidos el nivel y su respuesta (arriba a la izquierda), los segundos restantes en grande con una barra de progreso (arriba al centro) y el patrón con su secuencia y hangul (arriba a la derecha). Detener está abajo a la izquierda. La cuenta regresiva y los botones finales (Repetir, Volver) siguen el mismo estilo.

**Why this priority**: Da contexto y acabado sin cambiar el entrenamiento. Es menos crítico que la escena y las señales.

**Independent Test**: Iniciar una sesión de cada combinación y comprobar el contenido de cada panel, que los segundos y la barra avanzan, y que Detener, Repetir y Volver funcionan igual que antes.

**Acceptance Scenarios**:

1. **Given** Nivel 2 + Transversal, **When** corre el ejercicio, **Then** el panel izquierdo dice "NIVEL 2" y "Evasión lateral", y el derecho "TRANSVERSAL" y "Sodose → Hwengdan ilgôm begi 횡단일검베기".
2. **Given** un ejercicio en curso, **When** pasa el tiempo, **Then** los segundos restantes bajan y la barra de progreso avanza en proporción a la duración.
3. **Given** cualquier fase del ejercicio, **When** se observa la pantalla, **Then** ningún panel tapa el sable, el oponente ni la señal, en ninguna postura ni proporción de pantalla.
4. **Given** la cuenta regresiva, **When** se muestran 3, 2, 1, **Then** los números son grandes, blancos y con contorno, legibles a 3 m sobre el dojang.
5. **Given** el ejercicio terminado, **When** aparecen Repetir y Volver, **Then** tienen forma de píldora en blanco y grises y funcionan como en las Specs 001 a 003.

---

### User Story 4 - Elegir la sesión en una pantalla atractiva (Priority: P4)

El practicante abre la app y ve el encabezado "HAIDONG GUMDO" sobre el dojang oscurecido, dos columnas de tarjetas (NIVEL y PATRÓN) con ícono, nombre, detalle y hangul, un resumen de la sesión elegida y un botón INICIAR blanco.

**Why this priority**: Es la primera impresión, pero se ve pocos segundos por sesión.

**Independent Test**: Abrir la app, cambiar nivel y patrón, comprobar la selección visual y el resumen, e iniciar.

**Acceptance Scenarios**:

1. **Given** la app abierta, **When** carga el catálogo, **Then** se ven las tarjetas de Nivel 1 y Nivel 2 y de Frontal y Transversal, en el orden del catálogo, con Nivel 1 y Frontal seleccionados.
2. **Given** una tarjeta de nivel, **When** se observa, **Then** su ícono es la señal de ese nivel (símbolo de defensa o flecha de evasión) en blanco, con el nombre y "respuesta — propósito".
3. **Given** una tarjeta de patrón, **When** se observa, **Then** su ícono es la silueta de la postura del patrón, con el nombre, la secuencia en romanización y una línea con el hangul.
4. **Given** una tarjeta seleccionada, **When** se compara con las demás, **Then** tiene fondo blanco translúcido, borde blanco y palomita, sin amarillo.
5. **Given** Nivel 2 + Transversal elegidos, **When** se mira la parte inferior, **Then** el resumen dice "Nivel 2 · Transversal · 30 s", y pulsar INICIAR abre el ejercicio con esa sesión.

---

### Edge Cases

- **Proporciones de pantalla.** Entre 4:3 y 20:9, el dojang llena toda la pantalla sin franjas ni deformaciones (los elementos de las orillas pueden recortarse); el HUD y la señal no tapan al oponente ni al sable.
- **Sable alzado en _Chochôn-se_.** La punta del sable en lo alto de la postura frontal queda cerca del borde superior, donde está el panel de los segundos. El panel MUST NOT taparla en ninguna proporción.
- **Punta de frente.** En el instante central del barrido transversal, el largo de la hoja en pantalla es cero; aun así el color se ve (FR-011).
- **Sable blanco sobre fondo claro.** En reposo el sable es blanco y la pared es clara: el contorno y el brillo mantienen el sable distinguible.
- **Flecha azul sobre la pared.** La pared es gris cálida, no azul; el contorno oscuro y el brillo mantienen la flecha distinguible.
- **Catálogo con un nivel o patrón nuevo.** Su tarjeta aparece con ícono (la señal del nivel o la silueta de la postura) sin cambiar código.
- **Términos sin hangul.** _Sodose_ no tiene hangul en el glosario: la línea de hangul de la tarjeta y del HUD muestra solo los términos que lo tienen, sin huecos.
- **Catálogo en carga o con error.** Los estados de carga y error de la Spec 001 se muestran con el nuevo estilo, e INICIAR queda desactivado.
- **Dispositivo modesto.** Brillos, degradados y viñeta no deben hacer que las animaciones pierdan fluidez ni que cambien los tiempos (SC-006).

## Requirements _(mandatory)_

### Functional Requirements

**Alcance y continuidad**

- **FR-001**: Esta spec MUST cambiar solo el aspecto de la pantalla del ejercicio y de la de selección. El comportamiento, los tiempos, las reglas, los estados, las voces, la cancelación y el motor de las Specs 001 a 003 MUST NOT cambiar.
- **FR-002**: Las señales MUST conservar sus lados, colores y reglas de colocación (Spec 001, FR-015 y FR-016; Spec 003, FR-006 a FR-008), incluido que ninguna parte de la señal entre en el alcance del oponente.
- **FR-003**: La legibilidad a 3 m de las Specs 001 a 003 (Spec 001, FR-025; Spec 002, FR-009; Spec 003, SC-004) MUST mantenerse. Ante un conflicto entre estética y legibilidad, prevalece la legibilidad.

**Regla de color**

- **FR-004**: Rojo, azul y amarillo MUST usarse solo en el sable del oponente y en las señales (incluidos su brillo y su estela). El fondo, el equipo del oponente y toda la interfaz MUST usar blancos, grises, negros, fondos oscuros translúcidos y los tonos madera y pared del dojang, sin tintes que un observador pueda nombrar como rojo, azul o amarillo.
- **FR-005**: La interfaz actual que usa amarillo (selección y botón Iniciar) MUST pasar a blanco y grises.

**Escena**

- **FR-006**: La pantalla del ejercicio MUST mostrar el dojang de fondo: pared clara cálida, columnas y viga de madera, zócalo, duela, luz suave sobre la duela, viñeta en las orillas y estandartes con 해동검도 y 海東劍道, según el boceto `Retro.dc.html`.
- **FR-007**: El dojang MUST llenar la pantalla en proporciones de 4:3 a 20:9 sin deformarse y sin franjas; puede recortarse en las orillas.
- **FR-008**: El oponente MUST llevar casco con rejilla, peto, coderas y guantes, sobre dobok y _hakama_. Casco, peto y coderas MUST ser blancos o gris muy claro; guantes, cinturón y _hakama_ MUST ser oscuros y neutros (gris carbón o negro, sin tinte azul). La figura MUST tener contorno oscuro definido (Principio VIII).
- **FR-009**: La silueta del oponente, incluidas las piernas, MUST distinguirse con claridad de la pared y de la duela a 3 m.

**Sable**

- **FR-010**: En el Patrón transversal, el sable MUST verse **horizontal**, a la altura de la cintura, en _Sodose_ y durante todo el barrido. Esto se logra con datos del catálogo (punta a la altura de la empuñadura), sin cambiar la lógica del dominio.
- **FR-011**: Cuando el largo de la hoja en pantalla se acerca a cero porque el sable apunta al usuario, la punta MUST verse **de frente**: un disco del color del sable, con contorno oscuro y brillo, cuyo tamaño nunca baja de un mínimo legible a 3 m. La hoja MUST seguir avanzando a velocidad uniforme y sin trayectoria diagonal (Spec 002, FR-008), y el color MUST reconocerse en todo el barrido (Spec 002, FR-009).
- **FR-012**: La hoja del sable MUST conservar los colores de las Specs 001 a 003 (blanco, amarillo, azul, rojo) y agregar un brillo suave del mismo color. La empuñadura y la tsuba MUST ser oscura y gris, respectivamente.

**Señales**

- **FR-013**: La señal de evasión MUST ser una flecha **corta y gruesa**, del color del sable, con contorno oscuro, brillo suave y una **estela** que se desvanece hacia la cola, según `docs/design/flecha-evasion-boceto.png` y `Senales.dc.html` (flecha propuesta). Conserva el lado, la dirección y el espacio libre de la Spec 003 (FR-006 a FR-008).
- **FR-014**: La señal de defensa MUST ser un sable en diagonal visto desde arriba, con **hoja delgada** del color del sable, **empuñadura más gruesa**, guarda gris y contorno oscuro (Spec 001, FR-025a). Conserva el lado de la Spec 001.

**HUD del ejercicio**

- **FR-015**: Durante el ejercicio, la pantalla MUST mostrar en paneles translúcidos oscuros con borde blanco tenue y esquinas redondeadas:
  - arriba a la izquierda, el nombre del nivel en mayúsculas y su respuesta (por ejemplo, "NIVEL 2" y "Evasión lateral");
  - arriba al centro, los segundos restantes en grande y una barra de progreso blanca que avanza con el tiempo transcurrido respecto de la duración;
  - arriba a la derecha, el nombre del patrón en mayúsculas y la secuencia postura → corte con romanización y hangul (por ejemplo, "Sodose → Hwengdan ilgôm begi 횡단일검베기").
  Todos los textos de nivel y patrón MUST salir del catálogo (Spec 001, SC-009).
- **FR-016**: El botón Detener MUST estar abajo a la izquierda, en forma de píldora con borde blanco, y estar disponible en las mismas fases que hoy (Spec 001, FR-021).
- **FR-017**: Ningún elemento del HUD MUST tapar el oponente, el sable o la señal, en ninguna postura, fase ni proporción de pantalla de 4:3 a 20:9.
- **FR-018**: La cuenta regresiva (3, 2, 1) MUST mostrarse con números grandes, blancos y con contorno, legibles a 3 m sobre el dojang.
- **FR-019**: Al terminar el ejercicio, Repetir y Volver MUST mostrarse en forma de píldora: Repetir blanco con texto oscuro y Volver con borde blanco. Su comportamiento no cambia.

**Pantalla de selección**

- **FR-020**: La pantalla de selección MUST mostrar el dojang de fondo bajo una capa oscura, el encabezado "HAIDONG GUMDO" con el subtítulo "Entrenamiento de reacción · 해동검도", y dos columnas de tarjetas, NIVEL y PATRÓN, según `Seleccion.dc.html`.
- **FR-021**: Cada tarjeta de nivel MUST mostrar como ícono la señal de su tipo de respuesta (símbolo de defensa o flecha de evasión) en blanco, el nombre y "respuesta — propósito".
- **FR-022**: Cada tarjeta de patrón MUST mostrar como ícono una silueta **generada a partir de la postura del patrón en el catálogo**, el nombre, la secuencia guardia → postura → corte en romanización y una línea con el hangul de los términos que lo tienen. Un patrón nuevo en el catálogo MUST tener ícono sin cambiar código.
- **FR-023**: La tarjeta seleccionada MUST distinguirse por fondo blanco translúcido, borde blanco y una palomita, sin amarillo. Nivel 1 y Frontal (los primeros del catálogo) MUST seguir preseleccionados.
- **FR-024**: La parte inferior MUST mostrar un resumen de la sesión ("Nivel · Patrón · duración", por ejemplo "Nivel 1 · Frontal · 30 s") y el botón INICIAR blanco, con texto oscuro y forma de píldora. Iniciar sigue requiriendo una sola acción (Spec 001, SC-001).
- **FR-025**: Los estados de carga y de error del catálogo MUST mostrarse con el nuevo estilo y conservar su comportamiento (Iniciar desactivado si hay error).

**Tipografía**

- **FR-026**: Los textos de la interfaz MUST usar la tipografía Rajdhani (pesos 500 y 700) incluida en la app, sin requerir conexión. El hangul y el hanja MUST mostrarse con la fuente del sistema, sin caracteres faltantes.

### Key Entities _(include if feature involves data)_

- **Pose del Patrón transversal** (catálogo): las posturas `cut.start` y `cut.end` cambian para que la punta quede a la altura de la empuñadura. Ninguna otra entidad cambia.
- **Paleta visual**: conjunto de colores del dojang, del equipo y de la interfaz (`docs/design/referencia-visual-spec004.md`), con dos ajustes por la regla de color: _hakama_ gris carbón o negra, y guarda del símbolo de defensa gris.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: En una prueba a 3 m con ejercicios de Nivel 1 y Nivel 2 y los dos patrones, al menos 2 de 3 observadores identifican el color del sable y el lado de la señal en al menos el 95 % de los ataques, también en el instante de punta de frente del barrido transversal (mismo criterio que la Spec 001, SC-007, y la Spec 003, SC-004).
- **SC-002**: En la misma prueba, al menos 2 de 3 observadores dicen "defender" o "evadir" correctamente en al menos el 95 % de los ataques (mismo criterio que la Spec 003, SC-005).
- **SC-003**: En una revisión con 3 observadores de las dos pantallas, ninguno nombra como rojo, azul o amarillo un elemento que no sea el sable o una señal.
- **SC-004**: En un muestreo automático de cada postura y fase de los dos patrones, en proporciones 20:9, 16:9, 16:10 y 4:3, ningún píxel de la señal ni del HUD se superpone al oponente ni a su sable.
- **SC-005**: Al mostrar la app nueva y la anterior lado a lado, al menos 4 de 5 practicantes prefieren la nueva, y al menos 3 de 5 dan un comentario concreto sobre la experiencia.
- **SC-006**: En un ejercicio grabado a 60 fps en el dispositivo de referencia, los tiempos de aviso, corte e intervalo se desvían menos de 50 ms de los previstos (Spec 001, SC-005) y la animación no muestra saltos visibles.
- **SC-007**: Todas las pruebas automáticas de comportamiento de las Specs 001 a 003 pasan sin cambiar sus expectativas sobre la lógica del ejercicio.
- **SC-008**: Desde que abre la app, un usuario inicia un ejercicio con una sola acción en menos de 10 s (Spec 001, SC-001), y elige otra combinación de nivel y patrón en tres acciones (Spec 003, SC-001).

## Assumptions

- Los bocetos `Retro.dc.html` y `Seleccion.dc.html` definen el estilo, la composición y la paleta; sus medidas en píxeles (1280 × 800) son de referencia y se adaptan a cada pantalla. `Senales.dc.html` aporta solo la forma de las señales, no su estilo cómico.
- La _hakama_ y la guarda del símbolo de defensa no siguen los colores del boceto, por la regla de color (ver Clarifications).
- La luz cálida sobre la duela y los tonos madera son desaturados y no se perciben como amarillo ni rojo; SC-003 lo verifica.
- El sable y la flecha de evasión mantienen sus colores actuales; el símbolo de defensa pasa de blanco al color del sable (FR-014). A todos se les agrega brillo y, a la flecha, la estela.
- El grosor de contorno de la figura del oponente puede ser más fino que hoy (el boceto usa 3.5 px), siempre que FR-003 y SC-001 se cumplan; el sable y las señales conservan contornos gruesos.
- Las pruebas de presentación que localizan elementos por su texto o por su tipo de control pueden ajustar solo la forma de localizarlos (por ejemplo, "INICIAR" en mayúsculas o tarjetas en lugar de listas). Las pruebas de dibujo de la flecha y del símbolo se actualizan a las formas nuevas, conservando las comprobaciones de lado, color, dirección y espacio libre. Las expectativas de datos del Patrón transversal cambian por FR-010.
- La duración del resumen y de la barra de progreso es la de los parámetros vigentes (30 s por defecto hasta la Spec 005).
- La fuente Rajdhani tiene licencia SIL Open Font License, compatible con incluirla en la app.
- El dispositivo de referencia es el de las Specs 001 a 003 (tablet Android de 10" o imagen enviada a una TV).

## Out of Scope

- Cambios de comportamiento, tiempos, reglas o motor.
- Configuración de parámetros (Spec 005).
- Señal de contraataque (Nivel 4, Spec 007); `Senales.dc.html` la muestra solo como referencia.
- Sonidos, música o efectos sonoros nuevos.
- Animaciones nuevas del oponente (pasos, respiración) o del fondo.
- Modo claro, temas alternativos o accesibilidad para daltonismo.
- Reflejar el equipo o el cuerpo del oponente según el lado: solo los brazos y el sable siguen las posturas del catálogo.
