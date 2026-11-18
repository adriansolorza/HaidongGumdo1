# Feature Specification: Nivel 3, decisión bajo presión

**Feature Branch**: `006-nivel3-decision`

**Created**: 2026-11-18

**Status**: Draft

**Input**: User description: "Spec 006: Nivel 3, decisión bajo presión. Usa como contexto @docs/000-haidonggumdo-v010.md, @docs/brief.md y las specs 001 a 005. Alcance y decisiones del responsable: Nivel 3 = en cada ataque, la respuesta pedida es defensa o evasión lateral, elegida al azar. Propósito: entrenar la decisión bajo presión; el practicante debe leer en un instante qué respuesta se le pide y hacia qué lado. Se reutilizan las señales que ya existen, sin señales nuevas: el símbolo de defensa (Specs 001 y 004) y la flecha de evasión (Specs 003 y 004), con sus mismos lados y colores. El color del sable sigue indicando el lado. La regla del máximo de N repeticiones seguidas aplica a los lados y también al tipo de respuesta: no más de N defensas ni N evasiones seguidas (brief, RN2). N es el mismo valor configurado en la Spec 005. El Nivel 3 se combina con los dos patrones (frontal y transversal). En la pantalla de selección, el Nivel 3 aparece como una tarjeta más, leída del catálogo, con un ícono que represente la mezcla de defensa y evasión. Los Niveles 1 y 2 deben comportarse exactamente igual que hoy. No cambian los tiempos, los estados, la cancelación, las voces ni la configuración. Hazme antes las preguntas que necesites para resolver ambigüedades. No implementes nada."

## Contexto

Las Specs 001 a 005 entregaron el motor del ejercicio, el **Nivel 1 (defensa)**, el **Nivel 2 (evasión lateral)**, los patrones **frontal** y **transversal**, la experiencia visual y la configuración de parámetros. En los dos niveles existentes, cada ataque pide siempre el mismo tipo de respuesta: el Nivel 1 muestra siempre el símbolo de defensa y el Nivel 2, siempre la flecha de evasión.

Esta spec agrega el **Nivel 3 (defensa o evasión lateral, mezcladas al azar)**, cuyo propósito es entrenar la **decisión bajo presión**. En cada ataque se sortea, además del lado, el **tipo de respuesta**: unas veces aparece el símbolo de defensa y otras la flecha de evasión. El practicante debe leer en un instante **qué** respuesta se le pide y **hacia qué lado**.

**Sin señales nuevas.** El Nivel 3 usa las dos señales que ya existen, con sus mismos lados, colores, formas y reglas de colocación (Spec 001, FR-015; Spec 003, FR-006 a FR-008; Spec 004, FR-013 y FR-014). El color del sable sigue indicando el lado de la respuesta.

**Principio III.** El Nivel 3 no introduce un tipo de señal nuevo. Se agrega con **datos** en el catálogo (un nivel con dos tipos de respuesta) y **una sola regla nueva en el dominio**: el tipo de respuesta de cada ataque se sortea entre los tipos del nivel, con la regla de N aplicada también a ese tipo, como ya dicen el brief y la especificación general (RN1, RN2). Hoy el motor usa siempre el primer tipo del nivel (FR-002, FR-004, FR-005).

### Hoja de ruta de la v1 (según `docs/brief.md`, rev. 3)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| 001            | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| 002            | Patrón transversal                                                         |
| 003            | Nivel 2 (señal de evasión)                                                 |
| 004            | Experiencia visual                                                         |
| 005            | Configuración de parámetros e invariante de tiempos                        |
| **006 (esta)** | Nivel 3                                                                    |
| 007            | Nivel 4                                                                    |

### Glosario (términos que agrega esta spec)

| Término                 | Significado en la app                                                                                                       |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Tipo de respuesta       | Lo que la señal pide hacer en un ataque: **defensa** (símbolo de sable) o **evasión** lateral (flecha)                        |
| Decisión bajo presión   | Propósito del Nivel 3: elegir entre defender y evadir, y hacia qué lado, dentro del tiempo de aviso                          |
| Racha                   | Serie de ataques seguidos con el mismo lado o con el mismo tipo de respuesta                                                 |

Los demás términos (_Si-jak_, _Guman_, _Chayôn-se_, _Chochôn-se_, _Sodose_, _Chungmyôn begi_, _Hwengdan ilgôm begi_, ataque, tiempo de aviso, velocidad del corte, intervalo, señal de defensa, señal de evasión, HUD, tarjeta) mantienen el significado de las Specs 001 a 005.

## Clarifications

### Session 2026-11-18

- Q: El lado y el tipo se sortean por separado, cada uno con su límite de N. Como la señal de defensa y la de evasión se dibujan en mitades opuestas para un mismo color, la señal puede caer muchas veces seguidas en la misma mitad de la pantalla (con N = 1, siempre en la misma). ¿Se limita también eso? → A: No. Solo se limitan el lado (color) y el tipo de respuesta, cada uno con N, como dice el brief (RN2). Que la señal caiga muchas veces en la misma mitad se acepta y queda documentado como caso límite.
- Q: ¿Cómo se ve el ícono de la tarjeta del Nivel 3? → A: Las dos señales juntas: el símbolo de defensa y la flecha de evasión en blanco, lado a lado y a menor tamaño. El ícono se arma a partir de los tipos de respuesta del nivel en el catálogo, así que un nivel nuevo sigue teniendo ícono sin cambiar código (Spec 004, FR-021).
- Q: Con tres tarjetas en la columna NIVEL (y cuatro cuando llegue el Nivel 4), ¿deben verse todas sin desplazar la columna en pantallas horizontales de 4:3 a 20:9? → A: Sí. Todas las tarjetas de NIVEL y PATRÓN se ven completas sin desplazar, de 4:3 a 20:9; si hace falta, las tarjetas se compactan (ícono y textos más pequeños) sin bajar de un tamaño legible.
- Q: ¿Con qué tiempo de aviso se hace la prueba de legibilidad a 3 m del Nivel 3 (SC-006)? → A: Solo con el tiempo de aviso por defecto (0.7 s).
- Q: ¿Agregar el Nivel 3 requiere solo datos en el catálogo (FR-002)? → A: No. FR-004 y FR-005 requieren una regla nueva en el dominio: sortear el tipo de respuesta con racha máxima N, porque hoy el motor usa siempre el primer tipo del nivel. FR-002 se corrige: el Nivel 3 requiere los datos en el catálogo y esa sola regla nueva; fuera de ella no cambia nada más del dominio.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Decidir entre defender y evadir ante el corte transversal (Priority: P1)

Como practicante de combate de Haidong Gumdo, quiero reaccionar defendiendo o evadiendo, según la señal, cortes transversales de un oponente virtual, para mejorar la decisión bajo presión (Nivel 3).

El usuario elige el Nivel 3 y el Patrón transversal y pulsa **INICIAR**. Aparece la cuenta regresiva 3, 2, 1 y se escucha _Si-jak_; el sable pasa de blanco a amarillo y el oponente está en _Chayôn-se_. En cada ataque el sable cambia a azul o rojo y, al mismo tiempo, aparece **una** de las dos señales: el símbolo de defensa (del lado contrario al color, como en el Nivel 1) o la flecha de evasión (del lado del color, como en el Nivel 2). El oponente lleva el sable a _Sodose_ en el costado que indica el color y, pasado el tiempo de aviso, ejecuta _Hwengdan ilgôm begi_ igual que en los Niveles 1 y 2. El sable vuelve a amarillo, la señal desaparece y, tras el intervalo, llega el siguiente ataque, que puede pedir la misma respuesta o la otra. Al cumplirse la duración suena _Guman_; si hay un ataque en curso, se termina primero.

**Why this priority**: Es el caso que motiva el nivel. Contra el corte transversal, defender y evadir son dos respuestas técnicamente válidas y distintas, y el practicante debe elegir la correcta en el tiempo de aviso. Valida que el motor mezcla los dos tipos de señal sin rediseño.

**Independent Test**: Elegir Nivel 3 + Patrón transversal, iniciar un ejercicio con la configuración guardada y observarlo de principio a fin desde 3 m. Se comprueban, en cada ataque, qué señal aparece, su lado y su color, que el corte sale del costado que indica el color, las rachas máximas, los tiempos y el cierre con _Guman_.

**Acceptance Scenarios**:

1. **Given** un ejercicio de Nivel 3 en curso, **When** el sable cambia a azul y el ataque pide **defensa**, **Then** aparece el símbolo de defensa azul en el lado **izquierdo** de la pantalla y no aparece la flecha. _(como CA2)_
2. **Given** un ejercicio de Nivel 3 en curso, **When** el sable cambia a azul y el ataque pide **evasión**, **Then** aparece la flecha azul en el lado **derecho** de la pantalla, apuntando a la derecha, y no aparece el símbolo de defensa. _(como CA1)_
3. **Given** un ejercicio de Nivel 3 en curso, **When** el sable cambia a rojo, **Then** aparece el símbolo de defensa rojo en el lado **derecho** o la flecha roja en el lado **izquierdo** apuntando a la izquierda, nunca las dos.
4. **Given** un ejercicio de Nivel 3 con el Patrón transversal, **When** el sable cambia a azul, **Then** el oponente lleva el sable a _Sodose_ en el costado **izquierdo** de la pantalla y el corte sale de ese costado, sea cual sea la señal; con rojo, del costado **derecho**. El símbolo de defensa queda del lado del costado del corte y la flecha, del lado contrario.
5. **Given** un ejercicio de Nivel 3 con N configurado, **When** se observan todos los ataques, **Then** nunca hay más de N ataques seguidos al mismo lado ni más de N ataques seguidos con el mismo tipo de respuesta. _(CA4 y RN2)_
6. **Given** una señal que acaba de aparecer, **When** pasan el tiempo de aviso y el corte, **Then** la señal se mantiene visible todo ese tiempo y desaparece al terminar el corte, cuando el sable vuelve a amarillo.

---

### User Story 2 - Decidir entre defender y evadir ante el corte frontal (Priority: P2)

Como practicante, quiero reaccionar defendiendo o evadiendo, según la señal, cortes frontales, para dejar de intercambiar golpes a la cabeza y decidir bajo presión.

El usuario elige el Nivel 3 y el Patrón frontal y pulsa **INICIAR**. El ejercicio se desarrolla como el del Nivel 1 o el 2 con el Patrón frontal, pero en cada ataque se sortea si aparece el símbolo de defensa o la flecha de evasión. El oponente sube a _Chochôn-se_ y ejecuta _Chungmyôn begi_ sin revelar el lado ni la respuesta; solo la señal y el color los indican.

**Why this priority**: Completa la combinación del Nivel 3 con los dos patrones. Contra el corte frontal, el lado importa menos técnicamente, pero el ejercicio entrena igual leer la señal y decidir.

**Independent Test**: Elegir Nivel 3 + Patrón frontal, iniciar un ejercicio y comprobar en cada ataque qué señal aparece, su lado y su color, y que el oponente se mueve igual que en los Niveles 1 y 2 frontales.

**Acceptance Scenarios**:

1. **Given** un ejercicio de Nivel 3 con el Patrón frontal, **When** aparece cada señal, **Then** el lado y el color cumplen las mismas reglas que en la US1 (defensa del lado contrario al color, evasión del lado del color).
2. **Given** un ejercicio de Nivel 3 con el Patrón frontal, **When** aparece la señal, **Then** el oponente sube a _Chochôn-se_, ejecuta _Chungmyôn begi_ y regresa a _Chayôn-se_ exactamente como en los Niveles 1 y 2, sin que la postura revele el lado ni la respuesta.
3. **Given** un ejercicio de Nivel 3 de al menos 1 min con N = 5, **When** se observa, **Then** aparecen tanto defensas como evasiones.

---

### User Story 3 - Elegir el Nivel 3 en la selección (Priority: P3)

Como practicante, quiero ver el Nivel 3 como una tarjeta más en la pantalla de selección y combinarlo con cualquier patrón, para entrenar la decisión sin desbloqueos.

**Why this priority**: Es necesaria para llegar al Nivel 3, pero solo aporta valor una vez que el Nivel 3 existe (US1 y US2).

**Independent Test**: Abrir la app, comprobar que la columna NIVEL muestra las tres tarjetas en orden, que el ícono del Nivel 3 muestra las dos señales, elegir cada combinación del Nivel 3 con los patrones, iniciar, usar Repetir y Volver, y confirmar que el HUD muestra el nivel.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** se abre la app, **Then** la columna NIVEL muestra las tarjetas del Nivel 1, el Nivel 2 y el Nivel 3, en ese orden, con el Nivel 1 preseleccionado. La tarjeta del Nivel 3 dice "Nivel 3" y "Defensa o evasión lateral — Decisión bajo presión".
2. **Given** la tarjeta del Nivel 3, **When** se observa, **Then** su ícono muestra el símbolo de defensa y la flecha de evasión en blanco, lado a lado, sin rojo, azul ni amarillo.
3. **Given** el Nivel 3 y cualquier patrón elegidos, **When** el usuario pulsa INICIAR, **Then** el HUD muestra "NIVEL 3" y "Defensa o evasión lateral" durante todo el ejercicio; **When** termina y pulsa Repetir, **Then** el nuevo ejercicio conserva el nivel y el patrón.
4. **Given** la pantalla de selección en orientación horizontal con proporción 20:9, 16:9, 16:10 o 4:3, **When** se observa sin tocarla, **Then** las tres tarjetas de nivel y las dos de patrón se ven completas, sin desplazar ninguna columna, junto con el resumen, CONFIGURACIÓN e INICIAR.
5. **Given** un ejercicio de Nivel 3 terminado o cancelado, **When** el usuario vuelve a la selección, **Then** puede elegir el Nivel 1 o el 2 e iniciar un ejercicio que se comporta exactamente como antes de esta spec.

---

### Edge Cases

- **Señal en la misma mitad de la pantalla.** Con un mismo color, la defensa y la evasión aparecen en mitades opuestas, y con colores opuestos pueden caer en la misma (azul + defensa y rojo + evasión van a la izquierda). Por eso la señal puede aparecer más de N veces seguidas en la misma mitad aunque se respeten las rachas de lado y de tipo. Se acepta (Clarifications, 2026-11-18): la regla de N se aplica solo al lado (color) y al tipo de respuesta.
- **N = 1.** Los lados se alternan siempre y los tipos de respuesta también, así que solo el primer ataque es al azar y los siguientes se repiten en un ciclo de dos (por ejemplo, azul + defensa, rojo + evasión, azul + defensa…). Con ese ciclo, la señal aparece siempre en la misma mitad de la pantalla. Es la consecuencia esperada de N = 1 y no es un error.
- **Rachas máximas alcanzadas a la vez.** Si los últimos N ataques fueron al mismo lado **y** con el mismo tipo, el siguiente cambia de lado **y** de tipo. Las dos reglas son independientes y siempre se pueden cumplir a la vez.
- **Racha de tipo entre ejercicios.** Las rachas empiezan de cero en cada ejercicio, incluido al pulsar Repetir, igual que la racha de lados (Spec 001).
- **Fin del tiempo durante el aviso o el corte.** Igual que en la Spec 001: el ataque se completa, la señal sigue visible hasta el fin del corte y después suena _Guman_.
- **Final del barrido transversal.** Con cualquiera de las dos señales, la señal sigue visible y no se cruza con el oponente ni con el sable en ninguna fase, porque ambas ocupan las zonas ya definidas en las Specs 001, 003 y 004.
- **Cancelación y segundo plano.** Detener el ejercicio o mandar la app a segundo plano cancela igual que en la Spec 001; la señal desaparece con la pantalla del ejercicio.
- **Configuración.** El Nivel 3 usa los parámetros guardados en la Spec 005 (duración, N, tiempo de aviso, velocidad del corte, intervalo) sin parámetros propios.

## Requirements _(mandatory)_

### Functional Requirements

**Catálogo (datos)**

- **FR-001**: El catálogo MUST incluir el **Nivel 3**, ordenado después del Nivel 2, con nombre "Nivel 3", respuesta "Defensa o evasión lateral", propósito "Decisión bajo presión" y **dos** tipos de respuesta: **defensa** y **evasión**.
- **FR-002** _(Principio III)_: Agregar el Nivel 3 MUST requerir los datos en el catálogo y una sola regla nueva en el dominio: el sorteo del tipo de respuesta (FR-004, FR-005). Fuera de esa regla, MUST NOT agregar un tipo de señal nuevo ni cambiar los tiempos, los estados del ejercicio, la cancelación, las voces, el movimiento del oponente, los datos de los patrones ni la configuración.
- **FR-003**: Los dos patrones existentes (frontal y transversal) MUST poder jugarse con el Nivel 3 sin cambiar sus datos.

**Tipo de respuesta de cada ataque**

- **FR-004**: En cada ataque, el tipo de respuesta MUST elegirse **al azar** entre los tipos de respuesta del nivel, con la misma probabilidad para cada uno, y **por separado** del lado. En un nivel con un solo tipo de respuesta (Niveles 1 y 2), ese tipo MUST ser el de todos los ataques.
- **FR-005** _(RN2)_: En un ejercicio MUST NOT haber más de **N** ataques seguidos con el mismo tipo de respuesta. Al llegar a N seguidos, el siguiente ataque MUST tener el otro tipo. N MUST ser el mismo valor configurado y guardado en la Spec 005 que limita los lados.
- **FR-006**: La regla del máximo de N sobre los lados (Spec 001, FR-017 a FR-019) MUST seguir aplicándose sin cambios en el Nivel 3. Las dos rachas (lado y tipo) MUST controlarse por separado; no hay un límite de repeticiones para la mitad de la pantalla en la que aparece la señal (Clarifications, 2026-11-18).
- **FR-007**: Las rachas de tipo de respuesta MUST empezar de cero al inicio de cada ejercicio, igual que las de lado.

**Señales**

- **FR-008**: En cada ataque del Nivel 3 MUST mostrarse **exactamente una** señal, la del tipo sorteado:
  - **defensa**: el símbolo de defensa, del lado **contrario** al color (azul → izquierda, rojo → derecha), con la forma y el color de la Spec 004 (FR-014) y la colocación de la Spec 001 (FR-015);
  - **evasión**: la flecha de evasión, del lado **del** color (azul → derecha, rojo → izquierda), con la forma y el color de la Spec 004 (FR-013) y la colocación de la Spec 003 (FR-006 a FR-008).
- **FR-009**: La señal MUST aparecer al mismo tiempo que el sable cambia de color y MUST permanecer visible hasta que termina el corte (Spec 001, FR-016), igual que en los Niveles 1 y 2.
- **FR-010**: Con el Patrón transversal, el costado del corte MUST seguir determinado solo por el color (Spec 002; Spec 003, FR-010), sin importar el tipo de respuesta: el símbolo de defensa queda del lado del costado del corte y la flecha, del lado contrario.
- **FR-011**: La postura y el corte del oponente MUST NOT revelar el lado ni el tipo de respuesta; solo los indican el color del sable y la señal.

**Selección y HUD**

- **FR-012**: La pantalla de selección MUST mostrar el Nivel 3 como una tarjeta más en la columna NIVEL, leída del catálogo y en su orden, con nombre y "respuesta — propósito" (Spec 004, FR-021). El Nivel 1 MUST seguir preseleccionado.
- **FR-012a**: Todas las tarjetas de las columnas NIVEL y PATRÓN MUST verse completas **sin desplazar** la columna, en orientación horizontal de 4:3 a 20:9, con hasta cuatro niveles en el catálogo (previendo el Nivel 4). Si no caben a su tamaño actual, las tarjetas MUST compactarse (ícono y textos más pequeños), conservando el ícono, el nombre y "respuesta — propósito" legibles, y sin tapar el resumen de la sesión, CONFIGURACIÓN ni INICIAR (Spec 005, FR-001) (Clarifications, 2026-11-18).
- **FR-013**: El ícono de la tarjeta de un nivel con **varios** tipos de respuesta MUST mostrar las señales de todos sus tipos **juntas, lado a lado**, en blanco y a menor tamaño, en el orden del catálogo (para el Nivel 3: símbolo de defensa y flecha de evasión). El ícono MUST construirse a partir de los tipos de respuesta del nivel en el catálogo, sin código propio del Nivel 3, y MUST cumplir la regla de color (sin rojo, azul ni amarillo; Spec 004). Los íconos de los Niveles 1 y 2 MUST NOT cambiar.
- **FR-014**: El usuario MUST poder combinar el Nivel 3 con cualquier patrón, sin desbloqueos. La sesión elegida MUST mantenerse al pulsar Repetir, y el usuario MUST poder cambiar de nivel o de patrón al volver a la selección.
- **FR-015**: Durante un ejercicio de Nivel 3, el HUD MUST mostrar "NIVEL 3" y "Defensa o evasión lateral", leídos del catálogo (Spec 004, FR-015). El HUD MUST NOT indicar la respuesta del ataque en curso; esa información la da solo la señal.

**Reglas heredadas**

- **FR-016**: El ejercicio de Nivel 3 MUST cumplir sin cambios los requisitos de la Spec 001 sobre flujo, tiempos e intervalos, aleatoriedad de lados y máximo de N, estados y cancelación, presentación y voces; los de movimiento del oponente de la Spec 002; los de la señal de evasión de la Spec 003; los visuales de la Spec 004, y los de configuración de la Spec 005.
- **FR-017**: Los Niveles 1 y 2 MUST comportarse exactamente igual que antes de esta spec: el Nivel 1 solo con el símbolo de defensa y el Nivel 2 solo con la flecha de evasión, con los mismos sorteos de lado, tiempos, tarjetas e íconos.

### Key Entities _(include if feature involves data)_

- **Nivel 3**: identificador, nombre ("Nivel 3"), orden (después del Nivel 2), respuesta ("Defensa o evasión lateral"), propósito ("Decisión bajo presión") y tipos de respuesta (defensa y evasión).
- **Ataque**: su tipo de respuesta deja de ser siempre el primero del nivel y pasa a sortearse entre los tipos del nivel, junto con el lado.
- **Racha**: además de la racha de lados, el ejercicio lleva la racha de tipos de respuesta, ambas limitadas por el mismo N.
- Las demás entidades (catálogo, patrón, sesión, parámetros, configuración guardada, señal) no cambian respecto de las Specs 001 a 005.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Desde que abre la app, un usuario inicia un ejercicio de Nivel 3 con cualquier patrón en menos de 15 s y con un máximo de tres acciones (elegir el nivel, elegir el patrón y pulsar INICIAR).
- **SC-002**: En 200 ataques observados de Nivel 3 (con los dos patrones), el 100 % muestra exactamente una señal, del color del sable y en el lado correcto según su tipo (defensa del lado contrario al color, evasión del lado del color).
- **SC-003**: En 200 ataques transversales observados de Nivel 3, el 100 % tiene el costado del corte determinado por el color, sea cual sea la señal.
- **SC-004**: En 1 000 ejercicios simulados de Nivel 3 con cada valor de N de 1 a 5, ninguno tiene más de N ataques seguidos al mismo lado ni más de N seguidos con el mismo tipo de respuesta.
- **SC-005**: En 1 000 ejercicios simulados de Nivel 3 con N = 5, la proporción de defensas y de evasiones está entre el 45 % y el 55 % cada una, y la de lados también, y las secuencias de dos ejercicios con la misma configuración no son necesariamente iguales (RN1).
- **SC-006**: En una prueba a 3 m con ejercicios de Nivel 3 y el tiempo de aviso por defecto (0.7 s), al menos 2 de cada 3 observadores identifican correctamente el tipo de respuesta **y** el lado pedidos en al menos el 95 % de los ataques, incluido el final del barrido transversal.
- **SC-007**: En la pantalla de selección, al menos 2 de cada 3 observadores reconocen en el ícono del Nivel 3 la mezcla de defensa y evasión sin leer el texto.
- **SC-007a**: En un muestreo automático de la pantalla de selección en 20:9, 16:9, 16:10 y 4:3, con tres y con cuatro niveles en el catálogo, el 100 % de las tarjetas se ve completo sin desplazar, y ninguna se superpone al resumen, a CONFIGURACIÓN ni a INICIAR.
- **SC-008**: Fuera de la regla nueva del sorteo del tipo de respuesta (FR-004, FR-005), agregar el Nivel 3 no cambia los tiempos, los estados, la cancelación, las voces, la configuración ni los datos de los patrones, y todas las pruebas de las Specs 001 a 005 siguen pasando sin cambiar sus expectativas sobre los Niveles 1 y 2. Solo pueden cambiar las pruebas que enumeran los niveles del catálogo, para incluir el Nivel 3.

## Assumptions

- **Alcance**: solo el Nivel 3 (defensa o evasión al azar) con los dos patrones existentes y la configuración guardada en la Spec 005.
- El tipo de respuesta y el lado se sortean por separado, cada uno con probabilidad 50 % antes de aplicar la regla de N.
- El texto de la tarjeta y del HUD sale de la tabla de niveles del brief: "Defensa o evasión lateral" y "Decisión bajo presión".
- El ícono de la tarjeta del Nivel 3 reutiliza los dibujos de las dos señales en blanco a menor tamaño, sin un dibujo nuevo.
- No se agrega ningún aviso, sonido ni efecto que distinga los ataques de defensa de los de evasión; la diferencia está solo en la señal.
- No hay un parámetro configurable para la proporción de defensas y evasiones ni un N distinto para los tipos.
- La app no detecta si el usuario defiende, evade o se equivoca de respuesta; varios usuarios pueden entrenar a la vez frente a la misma pantalla.

## Out of Scope

- Señales nuevas o combinadas (por ejemplo, un aviso previo de "defensa" o "evasión", o una señal que pida las dos a la vez).
- Límite de repeticiones por mitad de la pantalla en la que aparece la señal (Clarifications, 2026-11-18).
- Proporción configurable entre defensas y evasiones, o un N separado para el tipo de respuesta.
- Nivel 4 (evasión con contraataque), Spec 007.
- Flechas adelante, atrás, diagonales o con giro.
- Cambios en los tiempos, los estados, la cancelación, las voces, la configuración o la experiencia visual existente, salvo la compactación de las tarjetas de selección (FR-012a).
- Backend, autenticación, detección de las respuestas del usuario y marcador app vs. usuario.
