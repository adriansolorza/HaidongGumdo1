# Feature Specification: Nivel 4, evasión con contraataque

**Feature Branch**: `007-nivel4-contraataque`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "Spec 007: Nivel 4, evasión con contraataque. Usa como contexto @docs/000-haidonggumdo-v010.md, @docs/brief.md, @docs/design/referencia-visual-spec004.md, el boceto @docs/design/bocetos/Senales.dc.html y las specs 001 a 006. Alcance y decisiones del responsable: Nivel 4 = en cada ataque, el practicante evade lateralmente y después corta (contraataca). Propósito: combate. Señal nueva, la de contraataque: la flecha de evasión de la Spec 004 con un símbolo de sable casi junto a su punta (boceto Senales.dc.html). Mismo color que el sable, del mismo lado que la flecha de evasión; brillo y estela como las demás señales. El Nivel 4 se combina con los dos patrones (frontal y transversal). En la pantalla de selección, el Nivel 4 aparece como la cuarta tarjeta, leída del catálogo, con su ícono generado como los demás; las cuatro tarjetas deben verse sin desplazar (Spec 006, FR-012a). La regla de color, la configuración, los tiempos, los estados, la cancelación y las voces no cambian. Los Niveles 1, 2 y 3 deben comportarse exactamente igual que hoy. La señal de contraataque es un tipo de señal nuevo: entra en la excepción (a) del Principio III. Hazme antes las preguntas que necesites para resolver ambigüedades. No implementes nada."

## Contexto

Las Specs 001 a 006 entregaron el motor del ejercicio, los **Niveles 1 (defensa)**, **2 (evasión lateral)** y **3 (defensa o evasión al azar)**, los patrones **frontal** y **transversal**, la experiencia visual y la configuración de parámetros.

Esta spec agrega el **Nivel 4 (evasión con contraataque)**, el último nivel de la v1, cuyo propósito es el **combate**. En cada ataque, el practicante sale lateralmente de la línea del corte y **después corta** al oponente. Es la respuesta de competencia: no basta con salir de la línea, hay que aprovechar la apertura.

**Señal nueva.** El Nivel 4 usa la **señal de contraataque**: la flecha de evasión de la Spec 004 con un **símbolo de sable vertical** casi junto a su punta. Va del lado del color del sable, igual que la flecha de evasión, con el color, el brillo y la estela de las demás señales.

**Principio III.** La señal de contraataque es un **tipo de señal nuevo**, así que el Nivel 4 entra en la excepción (a) del Principio III (constitution 1.1.0): se agrega con **datos** en el catálogo (un nivel con un solo tipo de respuesta, el contraataque) y con el **tipo de respuesta nuevo** en el dominio. No necesita reglas de secuencia nuevas: el sorteo de lado y la regla de N ya existen (Spec 001) y, con un solo tipo de respuesta, el sorteo de tipo de la Spec 006 siempre da el contraataque.

### Hoja de ruta de la v1 (según `docs/brief.md`, rev. 3)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| 001            | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| 002            | Patrón transversal                                                         |
| 003            | Nivel 2 (señal de evasión)                                                 |
| 004            | Experiencia visual                                                         |
| 005            | Configuración de parámetros e invariante de tiempos                        |
| 006            | Nivel 3                                                                    |
| **007 (esta)** | Nivel 4                                                                    |

### Glosario (términos que agrega esta spec)

| Término               | Significado en la app                                                                                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| Contraataque          | Respuesta del Nivel 4: evadir lateralmente hacia el lado del color y después cortar al oponente                  |
| Señal de contraataque | Flecha de evasión con un símbolo de sable vertical casi junto a su punta, del color del sable                    |

Los demás términos (_Si-jak_, _Guman_, _Chayôn-se_, _Chochôn-se_, _Sodose_, _Chungmyôn begi_, _Hwengdan ilgôm begi_, ataque, tiempo de aviso, velocidad del corte, intervalo, señal de defensa, señal de evasión, tipo de respuesta, racha, HUD, tarjeta) mantienen el significado de las Specs 001 a 006.

## Clarifications

### Session 2026-11-19

- Q: La señal de contraataque es más ancha que la flecha de evasión. ¿Dónde cabe? → A: En **la misma zona** que hoy ocupa la flecha de evasión (Spec 003, FR-007). La flecha y el sable se escalan juntos para caber; la flecha puede quedar algo más chica que en el Nivel 2 (sin bajar del 75 %; ver más abajo), pero ninguna parte de la señal entra en el alcance del oponente ni sale de la pantalla.
- Q: ¿Hacia dónde apunta el sable de la señal de contraataque? → A: **Vertical**, con la punta arriba y sin inclinación, como un corte frontal. Es el mismo con azul y con rojo. Se aparta del boceto `Senales.dc.html`, donde el sable va inclinado; del boceto se toman solo la flecha y la posición del sable junto a la punta.
- Q: ¿Cuándo se muestra la señal de contraataque y cuánto dura? → A: **Igual que las demás**: la flecha y el sable aparecen juntos cuando el sable del oponente cambia de color y desaparecen al terminar el corte (Spec 001, FR-016). No cambian los tiempos ni los estados.
- Q: ¿Qué texto llevan la tarjeta y el HUD del Nivel 4? → A: Tarjeta: "Nivel 4" y "Evasión y contraataque — Combate". HUD: "NIVEL 4" y "Evasión y contraataque".
- Q: Con el sable de la señal en vertical, ¿a qué altura va respecto de la flecha? → A: Centrado en vertical sobre la línea de la flecha: la punta queda arriba de la flecha y la empuñadura abajo, con un alto total igual al de la flecha o un poco mayor.
- Q: Al escalar la señal para que quepa en la zona, ¿hay un tamaño mínimo para la flecha? → A: Sí. La flecha conserva al menos el 75 % del tamaño de la flecha del Nivel 2, en todas las proporciones de 4:3 a 20:9. Si no cabe así, se ajusta la composición (por ejemplo, se acerca el sable), no se encoge más la flecha.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Evadir y contraatacar el corte transversal (Priority: P1)

Como practicante de combate de Haidong Gumdo, quiero reaccionar evadiendo lateralmente y contraatacando cortes transversales de un oponente virtual, para competir eficazmente (Nivel 4).

El usuario elige el Nivel 4 y el Patrón transversal y pulsa **INICIAR**. Aparece la cuenta regresiva 3, 2, 1 y se escucha _Si-jak_; el sable pasa de blanco a amarillo y el oponente está en _Chayôn-se_. En cada ataque el sable cambia a azul o rojo y, al mismo tiempo, aparece la **señal de contraataque** del lado del color: la flecha apunta hacia el borde exterior y, casi junto a su punta, se ve un sable vertical del mismo color. El oponente lleva el sable a _Sodose_ en el costado que indica el color y, pasado el tiempo de aviso, ejecuta _Hwengdan ilgôm begi_ igual que en los Niveles 1 a 3. El practicante sale hacia el lado de la flecha y corta. El sable vuelve a amarillo, la señal desaparece y, tras el intervalo, llega el siguiente ataque. Al cumplirse la duración suena _Guman_; si hay un ataque en curso, se termina primero.

**Why this priority**: Es el caso que motiva el nivel. Contra el corte transversal, salir de la línea y contraatacar es la respuesta de competencia. Valida la señal nueva y su colocación en el caso más exigente (el final del barrido transversal).

**Independent Test**: Elegir Nivel 4 + Patrón transversal, iniciar un ejercicio con la configuración guardada y observarlo de principio a fin desde 3 m. Se comprueban, en cada ataque, la forma, el lado y el color de la señal, que el corte sale del costado que indica el color, las rachas máximas de lado, los tiempos y el cierre con _Guman_.

**Acceptance Scenarios**:

1. **Given** un ejercicio de Nivel 4 en curso, **When** el sable cambia a rojo, **Then** aparece en el lado **izquierdo** de la pantalla una flecha roja que apunta a la izquierda con un sable rojo vertical casi junto a su punta. _(CA3)_
2. **Given** un ejercicio de Nivel 4 en curso, **When** el sable cambia a azul, **Then** aparece en el lado **derecho** una flecha azul que apunta a la derecha con un sable azul vertical casi junto a su punta.
3. **Given** un ataque de Nivel 4, **When** aparece la señal, **Then** no aparecen ni el símbolo de defensa solo ni la flecha de evasión sola; la única señal en pantalla es la de contraataque.
4. **Given** un ejercicio de Nivel 4 con el Patrón transversal, **When** el sable cambia a azul, **Then** el oponente lleva el sable a _Sodose_ en el costado **izquierdo** de la pantalla y el corte sale de ese costado; con rojo, del costado **derecho**. La señal queda siempre del lado contrario al costado del corte.
5. **Given** un ejercicio de Nivel 4 con N configurado, **When** se observan todos los ataques, **Then** nunca hay más de N ataques seguidos al mismo lado. _(CA4 y RN2)_
6. **Given** una señal que acaba de aparecer, **When** pasan el tiempo de aviso y el corte, **Then** la señal se mantiene visible todo ese tiempo, no se cruza con el oponente ni con su sable en ninguna fase, y desaparece al terminar el corte, cuando el sable vuelve a amarillo.

---

### User Story 2 - Evadir y contraatacar el corte frontal (Priority: P2)

Como practicante, quiero reaccionar evadiendo lateralmente y contraatacando cortes frontales, para dejar de intercambiar golpes a la cabeza y aprovechar la apertura.

El usuario elige el Nivel 4 y el Patrón frontal y pulsa **INICIAR**. El ejercicio se desarrolla como el del Nivel 2 con el Patrón frontal, pero con la señal de contraataque en lugar de la flecha de evasión. El oponente sube a _Chochôn-se_ y ejecuta _Chungmyôn begi_ sin revelar el lado; solo el color y la señal lo indican.

**Why this priority**: Completa la combinación del Nivel 4 con los dos patrones y ataca directamente el problema del combate "frente a frente": en lugar de intercambiar golpes a la cabeza, salir de la línea y cortar.

**Independent Test**: Elegir Nivel 4 + Patrón frontal, iniciar un ejercicio y comprobar en cada ataque la forma, el lado y el color de la señal, y que el oponente se mueve igual que en los Niveles 1 a 3 frontales.

**Acceptance Scenarios**:

1. **Given** un ejercicio de Nivel 4 con el Patrón frontal, **When** aparece cada señal, **Then** el lado, el color y la forma cumplen las mismas reglas que en la US1.
2. **Given** un ejercicio de Nivel 4 con el Patrón frontal, **When** aparece la señal, **Then** el oponente sube a _Chochôn-se_, ejecuta _Chungmyôn begi_ y regresa a _Chayôn-se_ exactamente como en los Niveles 1 a 3, sin que la postura revele el lado.

---

### User Story 3 - Elegir el Nivel 4 en la selección (Priority: P3)

Como practicante, quiero ver el Nivel 4 como la cuarta tarjeta de la pantalla de selección y combinarlo con cualquier patrón, para entrenar combate sin desbloqueos.

**Why this priority**: Es necesaria para llegar al Nivel 4, pero solo aporta valor una vez que el Nivel 4 existe (US1 y US2).

**Independent Test**: Abrir la app, comprobar que la columna NIVEL muestra las cuatro tarjetas en orden y sin desplazar, que el ícono del Nivel 4 muestra la señal de contraataque en blanco, elegir cada combinación del Nivel 4 con los patrones, iniciar, usar Repetir y Volver, y confirmar que el HUD muestra el nivel.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** se abre la app, **Then** la columna NIVEL muestra las tarjetas de los Niveles 1, 2, 3 y 4, en ese orden, con el Nivel 1 preseleccionado. La tarjeta del Nivel 4 dice "Nivel 4" y "Evasión y contraataque — Combate".
2. **Given** la tarjeta del Nivel 4, **When** se observa, **Then** su ícono muestra la señal de contraataque (flecha con el sable vertical junto a la punta) en blanco, sin rojo, azul ni amarillo.
3. **Given** el Nivel 4 y cualquier patrón elegidos, **When** el usuario pulsa INICIAR, **Then** el HUD muestra "NIVEL 4" y "Evasión y contraataque" durante todo el ejercicio; **When** termina y pulsa Repetir, **Then** el nuevo ejercicio conserva el nivel y el patrón.
4. **Given** la pantalla de selección en orientación horizontal con proporción 20:9, 16:9, 16:10 o 4:3, **When** se observa sin tocarla, **Then** las cuatro tarjetas de nivel y las dos de patrón se ven completas, sin desplazar ninguna columna, junto con el resumen, CONFIGURACIÓN e INICIAR. _(Spec 006, FR-012a)_
5. **Given** un ejercicio de Nivel 4 terminado o cancelado, **When** el usuario vuelve a la selección, **Then** puede elegir el Nivel 1, el 2 o el 3 e iniciar un ejercicio que se comporta exactamente como antes de esta spec.

---

### Edge Cases

- **Final del barrido transversal.** La señal de contraataque es más ancha que la flecha, pero ocupa la misma zona (Clarifications, 2026-11-19), así que no se cruza con el oponente ni con su sable en ninguna fase, incluido el final del barrido.
- **Proporción 4:3 y teléfono horizontal.** En las pantallas más angostas, la señal completa (flecha, estela y sable) sigue cabiendo en su zona, sin recortarse en el borde exterior y sin entrar en el alcance del oponente.
- **N = 1.** Los lados se alternan siempre; la señal aparece alternando izquierda y derecha. Con un solo tipo de respuesta no hay racha de tipo que limitar.
- **Fin del tiempo durante el aviso o el corte.** Igual que en la Spec 001: el ataque se completa, la señal sigue visible hasta el fin del corte y después suena _Guman_.
- **Tiempo para el contraataque.** La señal desaparece al terminar el corte del oponente, como las demás. El practicante completa su corte durante el intervalo; la app no lo espera ni lo detecta.
- **Cancelación y segundo plano.** Detener el ejercicio o mandar la app a segundo plano cancela igual que en la Spec 001; la señal desaparece con la pantalla del ejercicio.
- **Configuración.** El Nivel 4 usa los parámetros guardados en la Spec 005 (duración, N, tiempo de aviso, velocidad del corte, intervalo) sin parámetros propios.

## Requirements _(mandatory)_

### Functional Requirements

**Catálogo (datos)**

- **FR-001**: El catálogo MUST incluir el **Nivel 4**, ordenado después del Nivel 3, con nombre "Nivel 4", respuesta "Evasión y contraataque", propósito "Combate" y **un** tipo de respuesta: **contraataque**.
- **FR-002** _(Principio III, excepción a)_: Agregar el Nivel 4 MUST requerir los datos en el catálogo y el tipo de respuesta nuevo, **contraataque**, con su señal. MUST NOT agregar reglas de secuencia nuevas ni cambiar los tiempos, los estados del ejercicio, la cancelación, las voces, el movimiento del oponente, los datos de los patrones ni la configuración.
- **FR-003**: Los dos patrones existentes (frontal y transversal) MUST poder jugarse con el Nivel 4 sin cambiar sus datos.

**Secuencia**

- **FR-004**: En cada ataque del Nivel 4, el tipo de respuesta MUST ser siempre **contraataque** (nivel con un solo tipo; Spec 006, FR-004).
- **FR-005**: El lado de cada ataque MUST sortearse al azar con la regla del máximo de N seguidos al mismo lado (Spec 001, FR-017 a FR-019), sin cambios.

**Señal de contraataque**

- **FR-006**: En cada ataque del Nivel 4 MUST mostrarse **exactamente una** señal: la **señal de contraataque**. MUST NOT aparecer el símbolo de defensa ni la flecha de evasión sola.
- **FR-007**: La señal de contraataque MUST estar formada por:
  - la **flecha de evasión** de la Spec 004 (FR-013): corta y gruesa, con contorno oscuro, brillo suave y estela que se desvanece hacia la cola;
  - un **símbolo de sable vertical**, con la punta arriba y sin inclinación, colocado **casi junto a la punta** de la flecha, del lado al que apunta la flecha, y **centrado en vertical sobre la línea de la flecha**: la punta del sable queda arriba de la flecha y la empuñadura abajo, con un alto total igual al de la flecha o apenas mayor (Clarifications, 2026-11-19). El sable tiene hoja delgada del color del sable, empuñadura más gruesa, guarda gris, contorno oscuro y brillo suave, como el símbolo de defensa (Spec 004, FR-014), pero en vertical.

  Se toma del boceto `Senales.dc.html` la flecha y la posición del sable junto a la punta; el sable va vertical, no inclinado como en el boceto (Clarifications, 2026-11-19).
- **FR-008**: La señal MUST ir del lado **del** color, igual que la flecha de evasión (Spec 003, FR-006): con el sable **azul**, en el lado **derecho**, con la flecha apuntando a la derecha; con el **rojo**, en el lado **izquierdo**, con la flecha apuntando a la izquierda. El sable de la señal MUST verse igual en los dos lados (vertical, punta arriba).
- **FR-009**: Flecha y sable MUST tener el **color del sable** del oponente en ese ataque (azul o rojo), y MUST distinguirse a 3 m de la pantalla (Spec 001, FR-025).
- **FR-010**: La señal completa MUST ocupar **la misma zona** que la flecha de evasión (Spec 003, FR-007): en su mitad, centrada en vertical y cerca del borde exterior. Para caber, flecha y sable MUST escalarse juntos, pero la flecha MUST conservar al menos el **75 %** del tamaño de la flecha del Nivel 2 en la misma pantalla; si no cabe así, se ajusta la composición (por ejemplo, se acerca el sable a la punta) y no se encoge más la flecha. Ninguna parte de la señal MUST entrar en el alcance del oponente ni salir de la pantalla, en ninguna fase del ataque y en proporciones de 4:3 a 20:9 (Spec 004, FR-002) (Clarifications, 2026-11-19).
- **FR-011**: La señal MUST aparecer al mismo tiempo que el sable cambia de color y MUST permanecer visible hasta que termina el corte (Spec 001, FR-016), igual que en los Niveles 1 a 3. Flecha y sable MUST aparecer y desaparecer juntos.
- **FR-012**: Con el Patrón transversal, el costado del corte MUST seguir determinado solo por el color (Spec 002; Spec 003, FR-010); la señal queda del lado contrario al costado del corte.
- **FR-013**: La postura y el corte del oponente MUST NOT revelar el lado; solo lo indican el color del sable y la señal.

**Selección y HUD**

- **FR-014**: La pantalla de selección MUST mostrar el Nivel 4 como la **cuarta** tarjeta de la columna NIVEL, leída del catálogo y en su orden, con nombre y "respuesta — propósito" (Spec 004, FR-021). El Nivel 1 MUST seguir preseleccionado.
- **FR-015**: Las cuatro tarjetas de nivel y las dos de patrón MUST verse completas **sin desplazar**, con las reglas de compactación de la Spec 006 (FR-012a), sin quitar texto ni compactar el pie.
- **FR-016**: El ícono de la tarjeta del Nivel 4 MUST ser la **señal de contraataque en blanco** a menor tamaño, generado a partir del tipo de respuesta del nivel en el catálogo, igual que los íconos de los demás niveles (Spec 004, FR-021; Spec 006, FR-013). MUST cumplir la regla de color (sin rojo, azul ni amarillo; Spec 004). Los íconos de los Niveles 1, 2 y 3 MUST NOT cambiar.
- **FR-017**: El usuario MUST poder combinar el Nivel 4 con cualquier patrón, sin desbloqueos. La sesión elegida MUST mantenerse al pulsar Repetir, y el usuario MUST poder cambiar de nivel o de patrón al volver a la selección.
- **FR-018**: Durante un ejercicio de Nivel 4, el HUD MUST mostrar "NIVEL 4" y "Evasión y contraataque", leídos del catálogo (Spec 004, FR-015).

**Reglas heredadas**

- **FR-019**: El ejercicio de Nivel 4 MUST cumplir sin cambios los requisitos de la Spec 001 sobre flujo, tiempos e intervalos, aleatoriedad de lados y máximo de N, estados y cancelación, presentación y voces; los de movimiento del oponente de la Spec 002; los de colocación de la señal de evasión de la Spec 003; los visuales y la regla de color de la Spec 004; los de configuración de la Spec 005, y los de la pantalla de selección de la Spec 006.
- **FR-020**: Los Niveles 1, 2 y 3 MUST comportarse exactamente igual que antes de esta spec: mismas señales, sorteos de lado y de tipo, tiempos, tarjetas e íconos.

### Key Entities _(include if feature involves data)_

- **Nivel 4**: identificador, nombre ("Nivel 4"), orden (después del Nivel 3), respuesta ("Evasión y contraataque"), propósito ("Combate") y tipos de respuesta (solo contraataque).
- **Tipo de respuesta**: se agrega **contraataque** a defensa y evasión.
- **Señal**: se agrega la **señal de contraataque** (flecha de evasión + sable vertical junto a la punta), del lado del color.
- Las demás entidades (catálogo, patrón, sesión, ataque, racha, parámetros, configuración guardada) no cambian respecto de las Specs 001 a 006.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Desde que abre la app, un usuario inicia un ejercicio de Nivel 4 con cualquier patrón en menos de 15 s y con un máximo de tres acciones (elegir el nivel, elegir el patrón y pulsar INICIAR).
- **SC-002**: En 200 ataques observados de Nivel 4 (con los dos patrones), el 100 % muestra exactamente una señal, la de contraataque, del color del sable, del lado del color, con la flecha apuntando al borde exterior y el sable vertical junto a su punta.
- **SC-003**: En 200 ataques transversales observados de Nivel 4, el 100 % tiene el costado del corte determinado por el color, y en ninguno la señal se cruza con el oponente ni con su sable.
- **SC-004**: En 1 000 ejercicios simulados de Nivel 4 con cada valor de N de 1 a 5, ninguno tiene más de N ataques seguidos al mismo lado, y todos los ataques piden contraataque.
- **SC-005**: En 1 000 ejercicios simulados de Nivel 4 con N = 5, la proporción de lados está entre el 45 % y el 55 % cada uno, y las secuencias de dos ejercicios con la misma configuración no son necesariamente iguales (RN1).
- **SC-006**: En una prueba a 3 m con ejercicios de Nivel 4 y el tiempo de aviso por defecto (0.7 s), al menos 2 de cada 3 observadores distinguen la señal de contraataque de la flecha de evasión sola e identifican el lado en al menos el 95 % de los ataques, incluido el final del barrido transversal.
- **SC-007**: En la pantalla de selección, al menos 2 de cada 3 observadores reconocen en el ícono del Nivel 4 "evadir y cortar" sin leer el texto.
- **SC-008**: En un muestreo automático de la pantalla de selección en 20:9, 16:9, 16:10 y 4:3, incluido un teléfono en horizontal de 889 × 400 dp, con los cuatro niveles del catálogo, el 100 % de las tarjetas se ve completo sin desplazar, y ninguna se superpone al resumen, a CONFIGURACIÓN ni a INICIAR.
- **SC-009**: En un muestreo automático de la pantalla del ejercicio de Nivel 4 en las mismas proporciones y en todas las fases del ataque, el 100 % de las señales queda completa dentro de la pantalla y fuera del alcance del oponente, con la flecha a no menos del 75 % del tamaño de la flecha del Nivel 2 en la misma pantalla.
- **SC-010**: Fuera del tipo de respuesta y la señal nuevos (FR-002), agregar el Nivel 4 no cambia los tiempos, los estados, la cancelación, las voces, la configuración ni los datos de los patrones, y todas las pruebas de las Specs 001 a 006 siguen pasando sin cambiar sus expectativas sobre los Niveles 1, 2 y 3. Solo pueden cambiar las pruebas que enumeran los niveles o los tipos de respuesta del catálogo, para incluir el Nivel 4 y el contraataque.

## Assumptions

- **Alcance**: solo el Nivel 4 (evasión con contraataque) con los dos patrones existentes y la configuración guardada en la Spec 005.
- El contraataque es **un solo** tipo de respuesta con su propia señal, no la combinación de dos tipos (evasión + defensa) sorteados o mostrados juntos.
- El texto de la tarjeta y del HUD acorta el del brief ("Evasión lateral + corte del usuario (contraataque)") a "Evasión y contraataque" para que quepa en las tarjetas compactadas; el propósito es "Combate".
- El sable de la señal reutiliza el dibujo del símbolo de defensa (hoja delgada, empuñadura gruesa, guarda gris), girado a vertical; no hace falta un dibujo nuevo del sable.
- La flecha de la señal es la misma de la Spec 004, a no menos del 75 % de su tamaño en el Nivel 2; no se rediseña.
- No se agrega ningún aviso, sonido ni efecto propio del contraataque; la diferencia con el Nivel 2 está solo en la señal.
- La app no detecta si el usuario evade ni si contraataca; varios usuarios pueden entrenar a la vez frente a la misma pantalla.

## Out of Scope

- Mezclar el contraataque con otras respuestas al azar (por ejemplo, un nivel con evasión o contraataque).
- Una fase visual separada para el contraataque (el sable de la señal apareciendo después de la flecha) o una señal que se quede visible después del corte.
- Reacción del oponente al contraataque (retroceder, recibir el golpe, marcador).
- Contraataques con dirección o tipo de corte específico (por ejemplo, indicar a la cabeza o al costado).
- Flechas adelante, atrás, diagonales o con giro.
- Cambios en los tiempos, los estados, la cancelación, las voces, la configuración o la experiencia visual existente de los Niveles 1 a 3.
- Backend, autenticación, detección de las respuestas del usuario y marcador app vs. usuario.
