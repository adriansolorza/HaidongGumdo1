# Feature Specification: Patrón transversal

**Feature Branch**: `002-patron-transversal`

**Created**: 2026-11-04

**Status**: Draft

**Input**: User description: "Spec 002: Patrón transversal. Usa como contexto @docs/000-haidonggumdo-v010.md, @docs/brief.md y @specs/001-motor-nivel1-frontal/spec.md. Alcance: agregar el Patrón transversal (Sodose → Hwengdan ilgôm begi), jugable con el Nivel 1, reutilizando el motor de la 001 sin rediseñarlo (Principio III: idealmente datos en el catálogo más la animación nueva). Hazme antes las preguntas que necesites para resolver ambigüedades. No implementes nada."

## Contexto

La Spec 001 entregó un ejercicio completo de **Nivel 1 (defensa)** con el **Patrón frontal**: el oponente virtual está en guardia en _Chayôn-se_, sube a _Chochôn-se_ al aparecer la señal, ejecuta _Chungmyôn begi_ y regresa a la guardia. El motor, el catálogo y las pantallas quedaron preparados para que un patrón nuevo se agregue **como datos**.

Esta spec agrega el segundo patrón de la v1, el **Patrón transversal**: guardia en _Chayôn-se_, postura de ataque _Sodose_ (sable a un costado del cuerpo) y corte _Hwengdan ilgôm begi_ (corte transversal). Se juega con el Nivel 1 y conserva todas las reglas de la Spec 001: tiempos, aleatoriedad, máximo de N repeticiones, señal de defensa, inicio, fin y cancelación.

### Hoja de ruta de la v1 (según `docs/brief.md`, rev. 3)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| 001            | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| **002 (esta)** | Patrón transversal                                                         |
| 003            | Nivel 2 (señal de evasión)                                                 |
| 004            | Experiencia visual                                                         |
| 005            | Configuración de parámetros e invariante de tiempos                        |
| 006            | Nivel 3                                                                    |
| 007            | Nivel 4                                                                    |

La tabla de la Spec 001 tiene un orden anterior (002 = Nivel 2, 003 = transversal). Prevalece el brief.

### Glosario (términos que agrega esta spec)

| Término                              | Significado en la app                         |
| ------------------------------------ | --------------------------------------------- |
| _Sodose_                             | Postura con el sable a un costado del cuerpo  |
| _Hwengdan ilgôm begi_ (횡단일검베기) | Corte transversal                             |
| Costado del corte                    | Costado del oponente desde el que sale el corte transversal; queda del mismo lado de la pantalla que el lado por el que el corte llega al usuario |

Los demás términos (_Si-jak_, _Guman_, _Chayôn-se_, _Chochôn-se_, _Chungmyôn begi_, ataque, tiempo de aviso, velocidad del corte, intervalo, piso del intervalo) mantienen el significado de la Spec 001. _Sodose_ no tiene hangul en el glosario del proyecto.

## Clarifications

### Session 2026-11-04

- Q: ¿Hacia dónde va el corte transversal respecto de la señal? → A: Siempre llega por el lado en que el usuario debe defender: con sable azul (defensa a la izquierda), por la izquierda del usuario; con sable rojo (defensa a la derecha), por la derecha.
- Q: ¿A qué costado se lleva el sable en _Sodose_? → A: Al costado del que sale el corte, reflejado según el lado. Como la subida a la postura empieza al mismo tiempo que el color y la señal (Spec 001, FR-010), la postura no adelanta información que el color no dé ya.
- Q: ¿Se representa la "rodilla contraria" (juego de piernas)? → A: No. Queda fuera de alcance; se considerará en la Spec 004 (experiencia visual). El oponente se dibuja como en la Spec 001.

### Session 2026-11-05 (corrección del responsable tras ver el corte en el emulador)

- Q: ¿Qué recorrido tiene _Hwengdan ilgôm begi_? → A: Un barrido **horizontal de 180° a la altura de la cintura**. Empieza con el sable extendido hacia el costado de _Sodose_, pasa por el frente del oponente (instante en que apunta al usuario y se ve corto por el escorzo) y **termina extendido hacia el costado contrario**. **Reemplaza** la respuesta anterior en la que el corte terminaba en el impacto frente al flanco del usuario (un recorrido de unos 90°, diagonal de la cadera a la cintura), que era incorrecta.
- Q: ¿A qué altura está _Sodose_? → A: Manos a la altura de la cintura, en el costado del corte, con la hoja hacia afuera y atrás; el corte no sube ni baja durante el barrido.
- Q: ¿La velocidad del corte es la duración del barrido completo de 180°, o solo hasta que el sable pasa frente al oponente? → A: Del barrido completo de 180°. El sable pasa frente al oponente a la mitad del corte (0.25 s por defecto); los tiempos del ejercicio no cambian.
- Q: ¿El barrido se ve como un recorrido a velocidad uniforme en la pantalla o como un giro a velocidad angular constante? → A: Velocidad uniforme en la pantalla: la punta cruza de un costado al otro en línea recta a la altura de la cintura y la hoja se acorta al pasar por el frente. Se mantiene como solo datos (FR-002), con el mismo tipo de movimiento que el corte frontal.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Ejercicio de defensa ante el corte transversal (Priority: P1)

Como practicante de combate de Haidong Gumdo, quiero reaccionar defendiendo con el sable ante cortes transversales de un oponente virtual, para calentar (Nivel 1).

El usuario elige el Nivel 1 y el Patrón transversal y pulsa **Iniciar**. Aparece la cuenta regresiva 3, 2, 1 y se escucha _Si-jak_; el sable del oponente pasa de blanco a amarillo. El oponente está en guardia en _Chayôn-se_. En cada ataque el sable cambia a azul o rojo, aparece el símbolo de sable del lado en que el usuario debe defender y, al mismo tiempo, el oponente lleva el sable a _Sodose_, en el costado del que saldrá el corte. Pasado el tiempo de aviso, ejecuta _Hwengdan ilgôm begi_: un barrido horizontal de 180° a la altura de la cintura, que llega por el lado de la defensa, pasa frente al oponente y termina extendido hacia el costado contrario. El sable vuelve a amarillo, el oponente regresa a _Chayôn-se_ y, tras el intervalo, llega el siguiente ataque. A los 30 s suena _Guman_; si hay un ataque en curso, se termina primero.

**Why this priority**: Es el valor que agrega esta spec: un segundo tipo de ataque, distinto del frontal, que obliga a defender por los costados. Sin él no hay nada nuevo que entrenar.

**Independent Test**: Elegir Nivel 1 + Patrón transversal, iniciar un ejercicio con los valores por defecto y observarlo de principio a fin desde 3 m. Se comprueban la guardia, la postura _Sodose_ en el costado correcto, el corte horizontal que llega por el lado del símbolo de defensa, los tiempos y el cierre con _Guman_.

**Acceptance Scenarios**:

1. **Given** el Patrón transversal elegido, **When** el usuario pulsa Iniciar, **Then** ve la cuenta 3, 2, 1, escucha _Si-jak_ antes del primer ataque, el sable pasa de blanco a amarillo y el oponente está en _Chayôn-se_.
2. **Given** un ejercicio transversal en curso, **When** el sable cambia a azul, **Then** el símbolo de defensa aparece en el lado **izquierdo** de la pantalla y el oponente lleva el sable a _Sodose_ en el costado que queda a la **izquierda** de la pantalla.
3. **Given** un ejercicio transversal en curso, **When** el sable cambia a rojo, **Then** el símbolo de defensa aparece en el lado **derecho** de la pantalla y el oponente lleva el sable a _Sodose_ en el costado que queda a la **derecha** de la pantalla.
4. **Given** una señal que acaba de aparecer, **When** pasa la primera mitad del tiempo de aviso (0.35 s), **Then** el oponente ya está quieto en _Sodose_ y se mantiene así hasta que empieza el corte.
5. **Given** el oponente en _Sodose_, **When** pasa el tiempo de aviso (0.7 s), **Then** ejecuta _Hwengdan ilgôm begi_ como un barrido horizontal continuo de 180° a la altura de la cintura: empieza con el sable extendido hacia el costado de _Sodose_ (lado del símbolo de defensa), pasa frente al oponente apuntando al usuario y termina con el sable extendido hacia el costado contrario. El barrido completo dura la velocidad del corte (0.5 s) y pasa frente al oponente a la mitad (0.25 s).
6. **Given** el fin de un corte, **When** termina, **Then** el sable vuelve a amarillo, la señal desaparece y el oponente regresa a _Chayôn-se_ con un movimiento animado de 0.5 s.
7. **Given** cualquier ejercicio transversal, **When** se observan los lados de los ataques, **Then** cumplen las mismas reglas que en la Spec 001: aleatorios, nunca más de N seguidos al mismo lado, e intervalo entre el inicio de un corte y la siguiente señal entre 1.0 s y 2.5 s.
8. **Given** un ejercicio transversal de 30 s, **When** el tiempo se cumple durante un ataque, **Then** el ataque se completa y después suena _Guman_; **When** se cumple en la guardia, **Then** suena _Guman_ de inmediato.

---

### User Story 2 - Elegir entre los dos patrones (Priority: P2)

Como practicante, quiero elegir en la pantalla de selección entre el Patrón frontal y el Patrón transversal, para entrenar el tipo de ataque que necesito.

**Why this priority**: Con dos patrones, la selección deja de ser decorativa. Es necesaria para llegar al Patrón transversal, pero solo aporta valor una vez que ese patrón existe (US1).

**Independent Test**: Abrir la app, comprobar que la lista "Patrón" muestra los dos patrones con sus términos, elegir cada uno, iniciar y confirmar que el oponente ejecuta el corte del patrón elegido; usar Repetir y Volver.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** se abre la app, **Then** la lista "Patrón" muestra el Patrón frontal y el Patrón transversal, en ese orden, con el frontal preseleccionado. El transversal se muestra como "_Chayôn-se_ (자연세) → _Sodose_ → _Hwengdan ilgôm begi_ (횡단일검베기)".
2. **Given** el Patrón transversal elegido, **When** el usuario pulsa Iniciar, **Then** el ejercicio usa el Patrón transversal; **When** termina y pulsa Repetir, **Then** el nuevo ejercicio también es transversal.
3. **Given** un ejercicio transversal terminado o cancelado, **When** el usuario vuelve a la selección, **Then** puede elegir el Patrón frontal e iniciar un ejercicio frontal sin reiniciar la app.

---

### Edge Cases

- **Fin del tiempo durante el aviso o el corte.** Igual que en la Spec 001: el ataque se completa (el oponente termina de llevar el sable a _Sodose_, ejecuta el corte completo) y después suena _Guman_.
- **Fin del ejercicio al terminar un corte.** Igual que en la Spec 001: el oponente aparece en _Chayôn-se_ con el sable blanco, sin animar el regreso.
- **Dos ataques seguidos a lados distintos con el intervalo mínimo.** El regreso a _Chayôn-se_ termina justo cuando aparece la señal siguiente, y la nueva postura _Sodose_ parte de la guardia hacia el otro costado. El oponente nunca pasa directamente de un costado al otro.
- **Racha máxima alcanzada.** Como el costado del corte es el lado del ataque, la regla de N de la Spec 001 limita también los cortes seguidos desde el mismo costado.
- **Sable en escorzo durante el corte.** En algún momento del corte transversal el sable puede apuntar hacia el usuario y verse corto. El color MUST seguir leyéndose a 3 m también en ese instante (ver FR-009).
- **Término sin hangul.** _Sodose_ no tiene hangul; la app muestra solo la romanización, sin paréntesis vacíos.
- **Cancelación.** Detener el ejercicio o mandar la app a segundo plano cancela igual que en la Spec 001, en cualquier fase del Patrón transversal.

## Requirements _(mandatory)_

### Functional Requirements

**Catálogo (datos)**

- **FR-001**: El catálogo MUST incluir el **Patrón transversal**, ordenado después del frontal, con guardia en _Chayôn-se_, postura de ataque _Sodose_ y corte _Hwengdan ilgôm begi_. El glosario del catálogo MUST incluir _Sodose_ (sin hangul) y _Hwengdan ilgôm begi_ (횡단일검베기).
- **FR-002** _(Principio III)_: Agregar el Patrón transversal MUST requerir solo datos en el catálogo: las posturas y el movimiento del corte se describen como datos, igual que en el Patrón frontal. MUST NOT requerir cambios en la lógica del ejercicio (tiempos, sorteos, estados, señales) ni en las pantallas.
- **FR-003**: Los términos coreanos mostrados MUST coincidir exactamente con el glosario. Un término sin hangul MUST mostrarse solo con su romanización.

**Selección**

- **FR-004**: La pantalla de selección MUST listar los dos patrones leídos del catálogo, en orden, con el Patrón frontal preseleccionado, y mostrar para cada uno su guardia, su postura de ataque y su corte.
- **FR-005**: La sesión elegida (Nivel 1 + patrón) MUST mantenerse al pulsar Repetir, y el usuario MUST poder cambiar de patrón al volver a la selección.

**Movimiento del oponente en el Patrón transversal**

- **FR-006**: En guardia, antes de _Si-jak_ y al terminar, el oponente MUST estar en _Chayôn-se_, igual que en el Patrón frontal (Spec 001, FR-008).
- **FR-007**: Al aparecer el color y la señal, el oponente MUST llevar el sable a _Sodose_ en el **costado del corte**, con las manos a la altura de la cintura y la hoja extendida hacia afuera (vista de frente; el "hacia atrás" de la postura real no se representa, para que el costado se lea a 3 m): el costado que queda a la izquierda de la pantalla con sable azul y a la derecha con sable rojo. El movimiento MUST ser animado, durar la primera mitad del tiempo de aviso y dejar al oponente quieto en _Sodose_ durante la segunda mitad (mismos tiempos que la Spec 001, FR-010 paso 2).
- **FR-008**: Pasado el tiempo de aviso, el oponente MUST ejecutar _Hwengdan ilgôm begi_ como un **barrido horizontal continuo de 180° a la altura de la cintura**: empieza con el sable extendido hacia el costado de _Sodose_, pasa por el frente del oponente (el sable apunta al usuario y se ve corto por el escorzo) y **termina extendido hacia el costado contrario**. El sable MUST mantenerse a la altura de la cintura durante todo el barrido, sin trayectoria diagonal, y su punta MUST avanzar de un costado al otro a **velocidad uniforme en la pantalla** (la hoja se acorta al pasar por el frente). La duración del **barrido completo de 180°** es exactamente igual a la velocidad del corte; el sable pasa frente al oponente a la mitad (0.25 s con el valor por defecto). El corte MUST llegar al usuario por el lado en que debe defender: por su izquierda con sable azul y por su derecha con sable rojo.
- **FR-009**: El color del sable MUST distinguirse a 3 m en _Sodose_ y durante todo el corte, incluido el instante en que el sable apunta al usuario y se ve corto por el escorzo (Spec 001, FR-025).
- **FR-010**: Al terminar el corte, el oponente MUST regresar a _Chayôn-se_ con un movimiento animado de 0.5 s (Spec 001, FR-010 paso 4). Con el intervalo mínimo, la postura siguiente MUST partir de _Chayôn-se_, nunca directamente del costado anterior.
- **FR-011**: Los dos costados de _Sodose_ y las dos direcciones del corte MUST verse como reflejos exactos uno del otro, para que ninguno resulte más fácil de leer.

**Reglas heredadas**

- **FR-012**: El ejercicio con el Patrón transversal MUST cumplir sin cambios los requisitos de la Spec 001 sobre parámetros (FR-006, FR-007), tiempos e intervalos (FR-009 a FR-014), señal de defensa (FR-015, FR-016), aleatoriedad y máximo de N (FR-017 a FR-019), estados y cancelación (FR-020 a FR-023), presentación (FR-024 a FR-028) y voces (FR-029, FR-030).

### Key Entities _(include if feature involves data)_

- **Patrón transversal**: identificador, nombre ("Transversal"), orden (después del frontal), guardia (_Chayôn-se_), postura de ataque (_Sodose_), corte (_Hwengdan ilgôm begi_), posiciones del sable en guardia, al inicio y al final del corte, e indicación de que el corte sale hacia ambos lados (se refleja según el lado del ataque).
- **Término del glosario**: se agregan _Sodose_ (sin hangul) y _Hwengdan ilgôm begi_ (횡단일검베기).
- Las demás entidades (catálogo, nivel, sesión, parámetros, ejercicio, ataque, señal) no cambian respecto de la Spec 001.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Desde que abre la app, un usuario inicia un ejercicio transversal en menos de 15 s y con dos acciones (elegir el patrón y pulsar Iniciar).
- **SC-002**: En 200 ataques transversales observados, el 100 % muestra la postura _Sodose_ y el inicio del corte en el costado correcto según el color (azul → izquierda de la pantalla, rojo → derecha), y el símbolo de defensa en ese mismo lado.
- **SC-003**: En una prueba de legibilidad a 3 m con ejercicios transversales, al menos 2 de cada 3 observadores identifican correctamente el color del sable y el lado de la señal en al menos el 95 % de los ataques, incluidos los instantes en escorzo.
- **SC-004**: En una prueba a 3 m que mezcla ejercicios frontales y transversales, al menos 2 de cada 3 observadores identifican qué patrón está ejecutando el oponente en al menos el 95 % de los ataques.
- **SC-005**: El tiempo de aviso, la duración del corte, el intervalo y el instante de _Guman_ con el Patrón transversal cumplen los mismos márgenes que la Spec 001 (desviación menor a 50 ms; _Guman_ nunca antes de cumplirse la duración y como máximo 1.2 s después con los valores por defecto).
- **SC-006**: Las comprobaciones automáticas de aleatoriedad y de N de la Spec 001 (SC-003 y SC-004) dan los mismos resultados con el Patrón transversal.
- **SC-007**: Agregar el Patrón transversal no modifica la lógica del ejercicio ni las pantallas: el cambio se limita al catálogo, y todas las pruebas de la Spec 001 siguen pasando sin cambiar sus expectativas sobre la lógica del ejercicio.

## Assumptions

- **Alcance**: solo el Patrón transversal con el Nivel 1 y los parámetros por defecto. No cambian los niveles, las señales, los parámetros ni las reglas de la Spec 001.
- El corte es un barrido horizontal de 180° a la altura de la cintura del oponente. Las posiciones exactas del sable en _Sodose_ y en el corte se definen en el plan, como datos del catálogo.
- Los tiempos de la subida a la postura (primera mitad del aviso) y del regreso a la guardia (0.5 s) son los mismos que en el Patrón frontal.
- Llevar el sable a _Sodose_ en el costado del corte no viola la regla "la postura no revela el lado", porque el movimiento empieza al mismo tiempo que el color y la señal (Spec 001, sesión 2026-11-03).
- El Patrón frontal sigue preseleccionado por ser el primero del catálogo.
- El oponente se dibuja como en la Spec 001 (cabeza, torso, brazos y sable, sin piernas).
- El mismo símbolo de defensa sirve para los dos patrones: indica dónde defender, no el tipo de corte.

## Out of Scope

- Juego de piernas y "rodilla contraria" del corte transversal (se considerará en la Spec 004, experiencia visual).
- Una dirección del corte independiente de la señal (cortes "engañosos").
- Niveles 2, 3 y 4, configuración y guardado de parámetros, y pausa (specs posteriores).
- Más patrones o posturas.
- Backend, autenticación, y detección de las respuestas del usuario.
