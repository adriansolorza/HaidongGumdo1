# Feature Specification: Nivel 2, señal de evasión

**Feature Branch**: `003-nivel2-evasion`

**Created**: 2026-11-06

**Status**: Draft

**Input**: User description: "Spec 003: Nivel 2, señal de evasión. Usa como contexto @docs/000-haidonggumdo-v010.md, @docs/brief.md, @specs/001-motor-nivel1-frontal/spec.md y @specs/002-patron-transversal/spec.md. Alcance y decisiones del responsable: Nivel 2 = evasión lateral, con una flecha horizontal pura del lado de la pantalla hacia el que el usuario se mueve (azul → derecha, rojo → izquierda; del lado contrario al símbolo de defensa). El Nivel 2 se combina con los dos patrones. Contra el corte transversal, la evasión lateral es deseable: el instinto es retroceder, pero en un área de combate finita retroceder siempre lleva a quedar acorralado. El mal hábito a corregir es no evadir ni defender. En el corte frontal, el lado de la evasión no importa técnicamente; lo decide el color. Fuera de alcance: flechas adelante, atrás y diagonales (8 direcciones), que serán una spec futura. Reutiliza el motor sin rediseñarlo (Principio III). Hazme antes las preguntas que necesites para resolver ambigüedades. No implementes nada."

## Contexto

Las Specs 001 y 002 entregaron el **Nivel 1 (defensa)** con los dos patrones de la v1, el **frontal** (_Chayôn-se_ → _Chochôn-se_ → _Chungmyôn begi_) y el **transversal** (_Chayôn-se_ → _Sodose_ → _Hwengdan ilgôm begi_). En cada ataque, el sable del oponente cambia a azul o rojo y aparece un símbolo de sable del lado en que el usuario debe defender.

Esta spec agrega el **Nivel 2 (evasión lateral)**, con propósito de calentamiento y base del entrenamiento. En lugar del símbolo de defensa aparece una **flecha horizontal** del lado de la pantalla hacia el que el usuario debe moverse: a la derecha con sable azul y a la izquierda con sable rojo, siempre del lado contrario al que ocuparía el símbolo de defensa. El Nivel 2 se juega con los dos patrones y conserva todas las demás reglas: tiempos, aleatoriedad, máximo de N repeticiones, movimiento del oponente, inicio, fin y cancelación.

**Por qué importa.** El mal hábito que se corrige es no evadir ni defender (quedarse en la línea de ataque). Contra el corte transversal, el instinto es retroceder, pero en un área de combate finita retroceder siempre termina en quedar acorralado; la evasión lateral saca al usuario de la línea sin ceder terreno. Contra el corte frontal, el lado de la evasión no importa técnicamente; lo decide el color, para entrenar la reacción a la señal.

**Principio III.** La evasión es un **tipo de señal nuevo**, el único caso en que la constitution admite cambiar la lógica del dominio al agregar un nivel. Ese cambio se limita a la colocación y el dibujo de la nueva señal. El motor (tiempos, sorteos, máximo de N, estados) no se rediseña, y el Nivel 2 se agrega como datos en el catálogo.

### Hoja de ruta de la v1 (según `docs/brief.md`, rev. 3)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| 001            | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| 002            | Patrón transversal                                                         |
| **003 (esta)** | Nivel 2 (señal de evasión)                                                 |
| 004            | Experiencia visual                                                         |
| 005            | Configuración de parámetros e invariante de tiempos                        |
| 006            | Nivel 3                                                                    |
| 007            | Nivel 4                                                                    |

### Glosario (términos que agrega esta spec)

| Término           | Significado en la app                                                                                                        |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Evasión lateral   | Respuesta del Nivel 2: el usuario sale de la línea de ataque moviéndose hacia un costado, sin retroceder ni defender con el sable |
| Señal de evasión  | Flecha horizontal en la mitad de la pantalla hacia la que el usuario debe moverse, apuntando hacia el borde de esa mitad     |

Los demás términos (_Si-jak_, _Guman_, _Chayôn-se_, _Chochôn-se_, _Sodose_, _Chungmyôn begi_, _Hwengdan ilgôm begi_, ataque, tiempo de aviso, velocidad del corte, intervalo, piso del intervalo, costado del corte) mantienen el significado de las Specs 001 y 002.

## Clarifications

### Session 2026-11-06

- Q: En el Nivel 2 con el Patrón transversal, ¿de qué costado sale el corte? → A: Igual que en la Spec 002: el color decide el costado del corte en todos los niveles. Con sable azul, _Sodose_ y el inicio del corte quedan a la izquierda de la pantalla y la flecha de evasión a la derecha; el usuario se aleja del costado del que sale el corte.
- Q: ¿De qué color es la flecha de evasión? → A: Del color del sable en ese ataque (azul o rojo), con contorno definido.
- Q: ¿Dónde se coloca la flecha? → A: En la misma zona de la pantalla que el símbolo de defensa (en su mitad, centrada en vertical y cerca del borde exterior), apuntando hacia el borde exterior. No se cruza con el oponente ni con el sable al final del corte.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Ejercicio de evasión lateral ante el corte transversal (Priority: P1)

Como practicante de combate de Haidong Gumdo, quiero reaccionar evadiendo lateralmente cortes transversales de un oponente virtual, para calentar y como base del entrenamiento (Nivel 2), y así perder el hábito de retroceder hasta quedar acorralado.

El usuario elige el Nivel 2 y el Patrón transversal y pulsa **Iniciar**. Aparece la cuenta regresiva 3, 2, 1 y se escucha _Si-jak_; el sable pasa de blanco a amarillo y el oponente está en _Chayôn-se_. En cada ataque el sable cambia a azul o rojo y, al mismo tiempo, aparece una flecha horizontal de ese mismo color en la mitad de la pantalla hacia la que el usuario debe moverse, y el oponente lleva el sable a _Sodose_ en el costado contrario. Pasado el tiempo de aviso, el oponente ejecuta _Hwengdan ilgôm begi_, que sale del costado opuesto a la flecha. El sable vuelve a amarillo, la flecha desaparece, el oponente regresa a _Chayôn-se_ y, tras el intervalo, llega el siguiente ataque. A los 30 s suena _Guman_; si hay un ataque en curso, se termina primero.

**Why this priority**: Es el caso que motiva el nivel: contra el corte transversal, la evasión lateral es la respuesta deseable y corrige el hábito de retroceder. Es el primer uso de la señal de evasión y valida que el motor la acepta sin rediseño.

**Independent Test**: Elegir Nivel 2 + Patrón transversal, iniciar un ejercicio con los valores por defecto y observarlo de principio a fin desde 3 m. Se comprueban el color y el lado de la flecha en cada ataque, que el corte sale del costado contrario a la flecha, los tiempos y el cierre con _Guman_.

**Acceptance Scenarios**:

1. **Given** un ejercicio de Nivel 2 en curso, **When** el sable cambia a azul, **Then** aparece una flecha azul en el lado **derecho** de la pantalla, apuntando hacia la derecha, y no aparece el símbolo de defensa. _(CA1)_
2. **Given** un ejercicio de Nivel 2 en curso, **When** el sable cambia a rojo, **Then** aparece una flecha roja en el lado **izquierdo** de la pantalla, apuntando hacia la izquierda, y no aparece el símbolo de defensa.
3. **Given** un ejercicio de Nivel 2 con el Patrón transversal, **When** el sable cambia a azul, **Then** el oponente lleva el sable a _Sodose_ en el costado que queda a la **izquierda** de la pantalla y el corte sale de ese costado; con rojo, a la **derecha**. La flecha queda siempre del lado contrario al costado del corte.
4. **Given** una flecha que acaba de aparecer, **When** pasa el tiempo de aviso (0.7 s) y el corte (0.5 s), **Then** la flecha se mantiene visible todo ese tiempo y desaparece al terminar el corte, cuando el sable vuelve a amarillo.
5. **Given** cualquier ejercicio de Nivel 2, **When** se observan los lados de los ataques y los tiempos, **Then** cumplen las mismas reglas que el Nivel 1: lados aleatorios, nunca más de N seguidos al mismo lado, intervalo entre el inicio de un corte y la siguiente señal entre 1.0 s y 2.5 s, y fin con _Guman_ como en la Spec 001.

---

### User Story 2 - Ejercicio de evasión lateral ante el corte frontal (Priority: P2)

Como practicante, quiero reaccionar evadiendo lateralmente cortes frontales, para salir de la línea de ataque en lugar de intercambiar golpes a la cabeza.

El usuario elige el Nivel 2 y el Patrón frontal y pulsa **Iniciar**. El ejercicio se desarrolla como el de la Spec 001, pero en cada ataque aparece la flecha de evasión del color del sable en lugar del símbolo de defensa. El oponente sube a _Chochôn-se_ y ejecuta _Chungmyôn begi_ igual que en el Nivel 1; la postura y el corte no revelan el lado, que solo indican el color y la flecha.

**Why this priority**: Completa la combinación del Nivel 2 con los dos patrones. Aporta menos técnica que el transversal (el lado de la evasión no importa contra un corte vertical), pero entrena salir de la línea de ataque según la señal.

**Independent Test**: Elegir Nivel 2 + Patrón frontal, iniciar un ejercicio con los valores por defecto y comprobar en cada ataque el color y el lado de la flecha, y que el oponente se mueve igual que en el Nivel 1 frontal.

**Acceptance Scenarios**:

1. **Given** un ejercicio de Nivel 2 con el Patrón frontal, **When** el sable cambia a azul, **Then** aparece una flecha azul en el lado derecho de la pantalla apuntando a la derecha; **When** cambia a rojo, **Then** aparece una flecha roja en el lado izquierdo apuntando a la izquierda.
2. **Given** un ejercicio de Nivel 2 con el Patrón frontal, **When** aparece la señal, **Then** el oponente sube a _Chochôn-se_, ejecuta _Chungmyôn begi_ y regresa a _Chayôn-se_ exactamente como en el Nivel 1, sin revelar el lado.

---

### User Story 3 - Elegir entre los dos niveles (Priority: P3)

Como practicante, quiero elegir en la pantalla de selección entre el Nivel 1 y el Nivel 2, con cualquiera de los dos patrones, para entrenar la respuesta que necesito sin desbloqueos.

**Why this priority**: Es necesaria para llegar al Nivel 2, pero solo aporta valor una vez que el Nivel 2 existe (US1 y US2).

**Independent Test**: Abrir la app, comprobar que la lista "Nivel" muestra los dos niveles, elegir cada combinación de nivel y patrón, iniciar y confirmar la señal mostrada; usar Repetir y Volver.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** se abre la app, **Then** la lista "Nivel" muestra el Nivel 1 y el Nivel 2, en ese orden, con el Nivel 1 preseleccionado. El Nivel 2 se muestra como "Evasión lateral — Calentamiento / base".
2. **Given** el Nivel 2 y cualquier patrón elegidos, **When** el usuario pulsa Iniciar, **Then** el ejercicio muestra la señal de evasión; **When** termina y pulsa Repetir, **Then** el nuevo ejercicio conserva el nivel y el patrón.
3. **Given** un ejercicio de Nivel 2 terminado o cancelado, **When** el usuario vuelve a la selección, **Then** puede elegir el Nivel 1 e iniciar un ejercicio de defensa sin reiniciar la app.

---

### Edge Cases

- **Final del barrido transversal del lado de la flecha.** Con el Patrón transversal, el corte termina extendido hacia el costado de la flecha. La flecha MUST seguir visible y legible durante todo el corte; ni el oponente ni el sable la tapan, porque está en la misma zona que el símbolo de defensa, cerca del borde.
- **Fin del tiempo durante el aviso o el corte.** Igual que en la Spec 001: el ataque se completa (la flecha sigue visible hasta el fin del corte) y después suena _Guman_.
- **Fin del ejercicio al terminar un corte.** Igual que en la Spec 001: el oponente aparece en _Chayôn-se_ con el sable blanco y no queda ninguna flecha en pantalla.
- **Racha máxima alcanzada.** Con N = 5, si las últimas 5 flechas fueron al mismo lado, la siguiente es al lado contrario; con N = 1 las flechas se alternan siempre. La regla de N se aplica a los lados, igual que en el Nivel 1.
- **Color de la flecha y del sable.** La flecha tiene siempre el mismo color que el sable en ese ataque; nunca aparece una flecha azul con sable rojo ni al revés.
- **Cancelación.** Detener el ejercicio o mandar la app a segundo plano cancela igual que en la Spec 001; la flecha desaparece con la pantalla del ejercicio.
- **Retroceder.** La app no detecta la respuesta del usuario. La flecha indica solo un movimiento lateral; no hay señal de retroceso ni de avance.

## Requirements _(mandatory)_

### Functional Requirements

**Catálogo (datos)**

- **FR-001**: El catálogo MUST incluir el **Nivel 2**, ordenado después del Nivel 1, con nombre "Nivel 2", respuesta "Evasión lateral", propósito "Calentamiento / base" y tipo de respuesta **evasión**.
- **FR-002** _(Principio III)_: Agregar el Nivel 2 MUST requerir solo datos en el catálogo, más el soporte del **tipo de señal nuevo** (evasión): su colocación en la pantalla y su dibujo. MUST NOT requerir cambios en los tiempos, los sorteos, la regla de N, los estados del ejercicio, el movimiento del oponente ni los datos de los patrones.
- **FR-003**: Los dos patrones existentes (frontal y transversal) MUST poder jugarse con el Nivel 2 sin cambiar sus datos.

**Selección**

- **FR-004**: La pantalla de selección MUST listar los dos niveles leídos del catálogo, en orden, con el Nivel 1 preseleccionado, y mostrar para cada uno su respuesta y su propósito.
- **FR-005**: El usuario MUST poder combinar libremente cualquier nivel con cualquier patrón, sin desbloqueos. La sesión elegida (nivel + patrón) MUST mantenerse al pulsar Repetir, y el usuario MUST poder cambiar de nivel o de patrón al volver a la selección.

**Señal de evasión**

- **FR-006**: En el Nivel 2, la señal MUST ser la **señal de evasión**: una flecha **horizontal** en la mitad de la pantalla hacia la que el usuario debe moverse, vista desde el usuario. Con el sable **azul**, la flecha aparece en el lado **derecho** y apunta a la derecha; con el **rojo**, en el lado **izquierdo** y apunta a la izquierda. Es siempre el lado contrario al que ocuparía el símbolo de defensa (Spec 001, FR-015).
- **FR-007**: La flecha MUST ser horizontal pura (sin inclinación ni componente adelante o atrás), con cuerpo y punta reconocibles, apuntando hacia el borde exterior de su mitad de pantalla. MUST ocupar la misma zona de la pantalla que el símbolo de defensa (en su mitad, centrada en vertical y cerca del borde exterior) y MUST NOT cruzarse con el oponente ni con su sable en ninguna fase del ataque.
- **FR-008**: La flecha MUST tener el **color del sable** en ese ataque (azul o rojo) y un contorno definido, y MUST distinguirse a 3 m de la pantalla (Spec 001, FR-025).
- **FR-009**: La flecha MUST aparecer al mismo tiempo que el sable cambia de color y MUST permanecer visible hasta que termina el corte (Spec 001, FR-016). En el Nivel 2 MUST NOT mostrarse el símbolo de defensa.
- **FR-010**: Con el Patrón transversal, el costado del corte MUST seguir determinado por el color, igual que en la Spec 002 (azul → _Sodose_ y corte desde el costado izquierdo de la pantalla; rojo → derecho). Por lo tanto, la flecha queda siempre del lado contrario al costado del que sale el corte.

**Reglas heredadas**

- **FR-011**: El ejercicio de Nivel 2 MUST cumplir sin cambios los requisitos de la Spec 001 sobre parámetros (FR-006, FR-007), flujo, tiempos e intervalos (FR-008 a FR-014), aleatoriedad y máximo de N (FR-017 a FR-019), estados y cancelación (FR-020 a FR-023), presentación (FR-024 a FR-028) y voces (FR-029, FR-030), y los requisitos de movimiento del oponente de la Spec 002 (FR-006 a FR-011) con el Patrón transversal.
- **FR-012**: El Nivel 1 MUST seguir funcionando exactamente como en las Specs 001 y 002, con el símbolo de defensa y sin flecha.

### Key Entities _(include if feature involves data)_

- **Nivel 2**: identificador, nombre ("Nivel 2"), orden (después del Nivel 1), respuesta ("Evasión lateral"), propósito ("Calentamiento / base") y tipo de respuesta (evasión).
- **Tipo de respuesta**: se agrega _evasión_ junto a _defensa_.
- **Señal**: se agrega la _señal de evasión_ (flecha horizontal del color del sable), colocada del mismo lado que el color (azul → derecha, rojo → izquierda), a diferencia de la señal de defensa, que va del lado contrario.
- Las demás entidades (catálogo, patrón, sesión, parámetros, ejercicio, ataque) no cambian respecto de las Specs 001 y 002.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Desde que abre la app, un usuario inicia un ejercicio de Nivel 2 con cualquier patrón en menos de 15 s y con un máximo de tres acciones (elegir el nivel, elegir el patrón y pulsar Iniciar).
- **SC-002**: En 200 ataques observados de Nivel 2 (con los dos patrones), el 100 % muestra la flecha en el lado correcto según el color (azul → derecha, rojo → izquierda), apuntando hacia el borde, del mismo color que el sable y sin símbolo de defensa.
- **SC-003**: En 200 ataques transversales observados de Nivel 2, el 100 % tiene el costado del corte del lado contrario a la flecha.
- **SC-004**: En una prueba de legibilidad a 3 m con ejercicios de Nivel 2, al menos 2 de cada 3 observadores identifican correctamente el lado de la flecha en al menos el 95 % de los ataques, incluido el final del barrido transversal.
- **SC-005**: En una prueba a 3 m que mezcla ejercicios de Nivel 1 y Nivel 2, al menos 2 de cada 3 observadores distinguen si la señal pide defender o evadir en al menos el 95 % de los ataques.
- **SC-006**: Las comprobaciones automáticas de tiempos, aleatoriedad y N de la Spec 001 (SC-003 a SC-006) dan los mismos resultados con el Nivel 2 y los dos patrones.
- **SC-007**: Agregar el Nivel 2 no cambia los tiempos, los sorteos, la regla de N, los estados ni los datos de los patrones, y todas las pruebas de las Specs 001 y 002 siguen pasando sin cambiar sus expectativas sobre la lógica del ejercicio.

## Assumptions

- **Alcance**: solo el Nivel 2 (evasión lateral) con los dos patrones existentes y los parámetros por defecto.
- La flecha es fija, sin animación; la animación de las señales se considerará en la Spec 004 (experiencia visual).
- La flecha usa los mismos tonos de azul y rojo que el sable del oponente.
- El Nivel 1 sigue preseleccionado por ser el primero del catálogo; el patrón preseleccionado sigue siendo el frontal.
- El costado del corte transversal depende solo del color y no del nivel (sesión 2026-11-06), así que los datos de los patrones no cambian.
- La regla de N se aplica a los lados. La regla de N sobre el tipo de respuesta solo aplica a partir del Nivel 3 (Spec 006), porque el Nivel 2 tiene un único tipo de respuesta.
- La app no detecta si el usuario evade, defiende o retrocede; varios usuarios pueden entrenar a la vez frente a la misma pantalla.

## Out of Scope

- Flechas adelante, atrás y diagonales (evasión en 8 direcciones), que serán una spec futura.
- Evasión con giro (flecha circular).
- Nivel 3 (defensa o evasión al azar) y Nivel 4 (evasión con contraataque).
- Un costado del corte que dependa del nivel o sea independiente de la señal (cortes "engañosos").
- Animación de las señales, juego de piernas del oponente y demás mejoras visuales (Spec 004).
- Configuración y guardado de parámetros (Spec 005) y pausa.
- Backend, autenticación y detección de las respuestas del usuario.
