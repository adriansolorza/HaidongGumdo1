# Feature Specification: Motor del ejercicio + Nivel 1 + Patrón frontal

**Feature Branch**: `001-motor-nivel1-frontal`

**Created**: 2026-10-28

**Status**: Draft

**Input**: User description: "Genera la especificación del proyecto usando como entrada @docs/000-haidonggumdo-v010.md. Respeta la constitution." Alcance acordado con el responsable del proyecto: solo la **Spec 001** del brief (`docs/brief.md`), es decir, motor del ejercicio + Nivel 1 + Patrón frontal con parámetros por defecto. El documento 000 sirve de contexto para toda la v1. Las specs 002–006 van después.

## Contexto

La app entrena la reacción de un practicante de Haidong Gumdo ante los ataques de un oponente virtual en pantalla, guiado por señales visuales que indican hacia dónde reaccionar. El enfoque viene de los drills de reacción del fútbol americano. Busca además corregir el combate "frente a frente" de cintas blancas a azules: entrenar el hábito de defender o salir de la línea de ataque en lugar de intercambiar golpes a la cabeza.

Esta spec entrega el primer incremento usable: un ejercicio completo de **Nivel 1 (defensa)** con el **Patrón frontal**, de principio a fin y con los parámetros por defecto. El ejercicio y el catálogo deben quedar preparados para que las specs posteriores agreguen niveles, patrones, configuración y pausa **sin rediseñar el motor**.

### Hoja de ruta de la v1 (contexto, no se especifica aquí)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| **001 (esta)** | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| 002            | Nivel 2 (señal de evasión)                                                 |
| 003            | Patrón transversal                                                         |
| 004            | Configuración y guardado de parámetros e invariante de tiempos al editar   |
| 005            | Nivel 3                                                                    |
| 006            | Nivel 4                                                                    |
| Posterior      | Pausa y reanudación del ejercicio                                          |

### Glosario

| Término                     | Significado en la app                                                                              |
| --------------------------- | -------------------------------------------------------------------------------------------------- |
| _Si-jak_ (시작)             | Voz de inicio                                                                                      |
| _Guman_ (그만)              | Voz de fin                                                                                         |
| _Chochôn-se_ (초천세)       | Postura con el sable sobre la cabeza                                                               |
| _Chungmyôn begi_ (정면베기) | Corte frontal                                                                                      |
| Oponente virtual            | Figura de un competidor de Haidong Gumdo dentro de la app                                          |
| Patrón                      | Tipo de ataque del oponente virtual (postura + corte)                                              |
| Nivel                       | Tipo de respuesta que entrena el usuario                                                           |
| Sesión                      | Combinación de un nivel y un patrón                                                                |
| Ataque                      | Una repetición del ciclo: señal, tiempo de aviso y corte                                           |
| Tiempo de aviso             | Tiempo desde que aparece la señal hasta que inicia el corte (ventana de reacción)                  |
| Velocidad del corte         | Duración del corte del oponente virtual                                                            |
| Intervalo entre ataques     | Tiempo desde el **inicio del corte** de un ataque hasta la aparición de la **señal del siguiente** |
| Piso del intervalo          | Valor mínimo del sorteo del intervalo: velocidad del corte + 0.5 s                                 |

_Sodose_ y _Hwengdan ilgôm begi_ (횡단일검베기) pertenecen al Patrón transversal (Spec 003) y no se usan aquí.

## Clarifications

### Session 2026-10-28

- Q: Si el tiempo se acaba durante el tiempo de aviso (señal visible, corte aún no iniciado), ¿qué pasa? → A: El ataque se completa (aviso + corte) y después suena _Guman_.
- Q: ¿Se anima el movimiento del oponente virtual o basta con imágenes fijas? → A: Solo el corte se anima, con duración exacta igual a la velocidad del corte; la postura aparece de inmediato.
- Q: ¿En qué dispositivos debe funcionar la app en esta entrega? → A: Android (teléfono o tablet); la pantalla grande se cubre enviando la imagen a una TV desde el dispositivo.
- Q: ¿Las voces _Si-jak_ y _Guman_ son grabadas o sintéticas? → A: Voz sintética del dispositivo, en coreano.
- Q: Si el dispositivo no tiene voz sintética en coreano, ¿qué hace la app? → A: Usa la voz sintética predeterminada del dispositivo (de otro idioma) para pronunciar _Si-jak_ y _Guman_.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Ejercicio de defensa ante el corte frontal (Priority: P1)

Como practicante de combate de Haidong Gumdo, quiero reaccionar defendiendo con el sable ante cortes frontales de un oponente virtual, para calentar (Nivel 1).

El usuario abre la app y ve la pantalla de selección con el Nivel 1 y el Patrón frontal (las únicas opciones del catálogo por ahora) ya elegidos. Pulsa **Iniciar**. Aparece la cuenta regresiva 3, 2, 1 y se escucha _Si-jak_; el sable del oponente pasa de blanco a amarillo. El oponente toma la postura _Chochôn-se_. En cada ataque el sable cambia a azul o rojo y aparece el símbolo de sable del lado en que el usuario debe defender. Pasado el tiempo de aviso, el oponente ejecuta _Chungmyôn begi_. El sable vuelve a amarillo y, tras el intervalo, llega el siguiente ataque. A los 30 s suena _Guman_: si hay un ataque en curso, se termina primero.

**Why this priority**: Es el flujo completo mínimo que aporta valor de entrenamiento y valida el motor (tiempos, aleatoriedad, señales, inicio y fin) sobre el que se apoyan todas las specs siguientes.

**Independent Test**: Iniciar un ejercicio con los valores por defecto y observarlo de principio a fin desde 3 m. Se puede comprobar la cuenta regresiva, _Si-jak_, la correspondencia color ↔ lado del símbolo de defensa en cada ataque, los tiempos y el cierre con _Guman_.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** el usuario pulsa Iniciar, **Then** ve la cuenta 3, 2, 1 en pantalla, escucha _Si-jak_ antes del primer ataque y el sable pasa de blanco a amarillo. _(CA6)_
2. **Given** un ejercicio de Nivel 1 en curso, **When** el sable cambia a azul, **Then** aparece un símbolo de sable en el lado **izquierdo** de la pantalla. _(CA2)_
3. **Given** un ejercicio de Nivel 1 en curso, **When** el sable cambia a rojo, **Then** aparece un símbolo de sable en el lado **derecho** de la pantalla.
4. **Given** un ejercicio con el Patrón frontal, **When** el oponente se prepara para atacar, **Then** toma la postura _Chochôn-se_, que no revela el lado del ataque, y el corte ejecutado es _Chungmyôn begi_.
5. **Given** una señal que acaba de aparecer, **When** pasa el tiempo de aviso (0.7 s), **Then** el oponente inicia el corte, que se ve como un movimiento continuo y dura la velocidad del corte (0.5 s). Al terminar el corte, el sable vuelve a amarillo y la señal desaparece.
6. **Given** el inicio de un corte, **When** se mide el tiempo hasta la siguiente señal, **Then** está entre 1.0 s y 2.5 s, ambos incluidos, y varía de un ataque a otro.
7. **Given** N = 5, **When** se observa cualquier ejercicio, **Then** nunca aparecen 6 ataques seguidos al mismo lado. _(CA4)_
8. **Given** un ejercicio de 30 s, **When** el tiempo se cumple a la mitad de un corte, **Then** el corte termina y después suena _Guman_. _(CA5)_
9. **Given** un ejercicio de 30 s, **When** el tiempo se cumple con la señal visible y antes de que inicie el corte, **Then** el oponente ejecuta el corte al terminar el tiempo de aviso y después suena _Guman_.
10. **Given** un ejercicio de 30 s, **When** el tiempo se cumple sin ningún ataque en curso, **Then** suena _Guman_ de inmediato y no aparece ninguna señal nueva.
11. **Given** un ejercicio terminado, **When** suena _Guman_, **Then** el sable vuelve a blanco y el usuario puede repetir el ejercicio o volver a la pantalla de selección.

---

### User Story 2 - Cancelar un ejercicio en curso (Priority: P2)

Como practicante, quiero que el ejercicio se cancele de forma limpia si lo detengo o si la app deja de estar en primer plano, para no volver a un ejercicio a medias.

**Why this priority**: Evita estados inconsistentes (señales o voces que se reproducen fuera de contexto) y sienta la base de estados que la futura spec de pausa extenderá.

**Independent Test**: Iniciar un ejercicio y, en distintas fases (cuenta regresiva, aviso, corte, descanso), pulsar Detener o mandar la app a segundo plano. Verificar que al volver se ve la pantalla de selección y que no se reproduce ningún sonido.

**Acceptance Scenarios**:

1. **Given** un ejercicio en cualquier fase entre la cuenta regresiva y _Guman_, **When** el usuario pulsa Detener, **Then** el ejercicio se cancela de inmediato, no suena _Guman_ y se muestra la pantalla de selección.
2. **Given** un ejercicio en cualquier fase entre la cuenta regresiva y _Guman_, **When** la app pasa a segundo plano o el usuario sale de ella, **Then** el ejercicio se cancela. Al volver, el usuario ve la pantalla de selección, no un ejercicio a medias. _(CL2)_
3. **Given** un ejercicio cancelado, **When** el usuario pulsa Iniciar de nuevo, **Then** empieza un ejercicio nuevo desde la cuenta regresiva, con una secuencia de lados nueva.

---

### Edge Cases

- **Fin del tiempo durante el aviso.** Si la duración se cumple cuando la señal ya apareció pero el corte aún no empieza, el ataque se completa (aviso + corte) y después suena _Guman_. Una señal mostrada siempre termina en su corte.
- **Fin del tiempo durante el descanso.** Si la duración se cumple entre el fin de un corte y la siguiente señal, suena _Guman_ de inmediato y no aparece la señal siguiente.
- **Racha máxima alcanzada.** Con N = 5, si los últimos 5 ataques fueron al mismo lado, el siguiente es obligatoriamente al lado contrario. Con N = 1 los lados se alternan siempre.
- **Primer ataque.** No hay corte previo desde el cual medir el intervalo; la primera señal aparece tras una espera sorteada en el mismo rango (1.0 s a 2.5 s) contada desde _Si-jak_.
- **Repetición de ejercicios.** Dos ejercicios con la misma configuración no producen necesariamente la misma secuencia de lados. El conteo de rachas se reinicia en cada ejercicio.
- **Interrupción durante la cuenta regresiva.** Cancela igual que en cualquier otra fase; _Si-jak_ no suena.
- **Sin voz coreana.** Si el dispositivo no tiene voz sintética en coreano, _Si-jak_ y _Guman_ se pronuncian con la voz predeterminada del dispositivo (FR-030). Los tiempos del ejercicio no cambian.
- **Sin ninguna voz sintética.** Si el dispositivo no tiene ninguna voz sintética, el ejercicio se ejecuta igual pero sin voces (supuesto; ver Assumptions).
- **Parámetros fuera de rango o que violan la invariante.** En esta spec los parámetros son los valores por defecto, que cumplen la invariante. El motor rechaza cualquier combinación inválida que reciba; la validación al editar (CL1) es de la Spec 004.

## Requirements _(mandatory)_

### Functional Requirements

**Catálogo (datos)**

- **FR-001**: Los niveles y patrones disponibles MUST provenir de un catálogo de datos de solo lectura incluido en la app. En esta spec, el catálogo contiene el **Nivel 1 (Defensa, calentamiento)** y el **Patrón frontal (_Chochôn-se_ → _Chungmyôn begi_)**.
- **FR-002**: El catálogo MUST describir, para cada nivel, el tipo de respuesta y la señal asociada y, para cada patrón, su postura y su corte. Agregar un nivel o un patrón que use tipos de señal ya existentes MUST requerir solo agregar datos al catálogo, sin cambiar la lógica del ejercicio ni las pantallas.
- **FR-003**: Los términos coreanos mostrados MUST coincidir exactamente con el glosario (romanización + hangul).

**Selección e inicio**

- **FR-004**: La pantalla de selección MUST listar los niveles y patrones **leídos del catálogo**, con una opción preseleccionada en cada lista, y un botón Iniciar. En esta spec cada lista tiene una sola opción.
- **FR-005**: El usuario MUST poder elegir libremente cualquier nivel y patrón del catálogo, sin desbloqueos.

**Parámetros**

- **FR-006**: El ejercicio MUST usar estos parámetros. En esta spec se usan siempre los valores por defecto. El motor MUST aceptar cualquier valor dentro del rango, para que la Spec 004 solo agregue la edición:

  | Parámetro                                                     | Mínimo | Máximo | Por defecto |
  | ------------------------------------------------------------- | ------ | ------ | ----------- |
  | Duración del ejercicio                                        | 30 s   | 3 min  | 30 s        |
  | Máximo de repeticiones seguidas (N)                           | 1      | 5      | 5           |
  | Tiempo de aviso                                               | 0.33 s | 1 s    | 0.7 s       |
  | Velocidad del corte                                           | 0.3 s  | 1 s    | 0.5 s       |
  | Intervalo entre ataques (valor configurado = tope del sorteo) | 0.5 s  | 5 s    | 2.5 s       |

- **FR-007** _(RN3, invariante de tiempos)_: El intervalo entre ataques configurado MUST ser mayor que la velocidad del corte; en concreto, MUST ser mayor o igual al piso del intervalo (velocidad del corte + 0.5 s). El motor MUST negarse a iniciar un ejercicio con parámetros que no cumplan esta regla o que estén fuera de rango.

**Flujo del ejercicio**

- **FR-008**: Antes de iniciar, el oponente virtual MUST estar en reposo, con el sable **blanco**.
- **FR-009**: Al pulsar Iniciar, el sistema MUST mostrar una cuenta regresiva 3, 2, 1 (un número por segundo) y reproducir la voz _Si-jak_ al terminarla. Con _Si-jak_, el sable MUST pasar a **amarillo** (en guardia) y empieza a correr la duración del ejercicio.
- **FR-010**: Cada ataque MUST seguir este ciclo:
  1. El oponente virtual está en la postura del patrón (_Chochôn-se_) con el sable amarillo. La postura no revela el lado.
  2. El sable cambia a **azul** (respuesta hacia la derecha del usuario) o **rojo** (respuesta hacia la izquierda del usuario) y aparece la señal del nivel.
  3. Pasado el tiempo de aviso, el oponente virtual ejecuta el corte del patrón (_Chungmyôn begi_) como un **movimiento animado continuo** desde la postura hasta el final del corte, con duración exactamente igual a la velocidad del corte.
  4. Al terminar el corte, el sable vuelve a amarillo, la señal desaparece y el oponente regresa **de inmediato** (sin animación) a la postura del patrón.
- **FR-010a**: Los cambios de postura (reposo → postura del patrón al iniciar, y fin del corte → postura) MUST ser instantáneos; solo el corte se anima.
- **FR-011**: El tiempo entre el **inicio del corte** de un ataque y la **aparición de la señal** del siguiente MUST sortearse, en cada ataque, de forma aleatoria entre el piso del intervalo y el intervalo configurado, ambos incluidos. Con los valores por defecto, entre 1.0 s y 2.5 s.
- **FR-012**: La primera señal del ejercicio MUST aparecer tras una espera sorteada en el mismo rango que FR-011, contada desde _Si-jak_.
- **FR-013**: Cuando se cumple la duración, el sistema MUST dejar de generar ataques nuevos. Si hay un ataque en curso (señal visible o corte en ejecución), MUST completarlo; después MUST reproducir _Guman_. Si no hay ataque en curso, MUST reproducir _Guman_ de inmediato.
- **FR-014**: Después de _Guman_, el sable MUST volver a **blanco** y el usuario MUST poder repetir el ejercicio con la misma sesión o volver a la pantalla de selección.

**Señales (Nivel 1)**

- **FR-015**: En el Nivel 1, la señal MUST ser la **señal de defensa**: un símbolo de sable del lado **contrario** al de la evasión. Con el sable azul, el símbolo aparece en el lado **izquierdo** de la pantalla; con el rojo, en el **derecho**. Los lados se definen vistos desde el usuario, frente a la pantalla.
- **FR-016**: La señal MUST permanecer visible desde que el sable cambia de color hasta que termina el corte.

**Reglas de secuencia**

- **FR-017** _(RN1)_: El lado de cada ataque MUST ser aleatorio, sujeto a FR-018.
- **FR-018** _(RN2)_: El sistema MUST NOT generar más de N ataques seguidos al mismo lado dentro de un ejercicio. Si los últimos N ataques fueron al mismo lado, el siguiente MUST ser al lado contrario.
- **FR-019**: La secuencia de lados y los intervalos sorteados MUST poder reproducirse de forma determinista para verificar las reglas (fuente de aleatoriedad y reloj controlables, Principio VI de la constitution).

**Estados y cancelación**

- **FR-020**: El ejercicio MUST tener un conjunto explícito de estados con transiciones definidas: **Listo → Cuenta regresiva → En curso** (con fases _Guardia_, _Aviso_ y _Corte_); **En curso → Finalizando** (se cumple la duración con un ataque en curso) **→ Terminado** (fin de su corte); **En curso → Terminado** (se cumple la duración sin ataque en curso, FR-013); y desde Cuenta regresiva, En curso o Finalizando **→ Cancelado**. Toda transición no listada MUST rechazarse. El modelo MUST permitir agregar un estado _Pausado_ en una spec futura sin rediseñar los estados existentes.
- **FR-021**: El usuario MUST poder detener el ejercicio en cualquier momento entre la cuenta regresiva y _Guman_. Detenerlo lo cancela.
- **FR-022** _(CL2)_: Si la app pasa a segundo plano o el usuario sale de ella durante un ejercicio, el ejercicio MUST cancelarse. Al volver, MUST mostrarse la pantalla de selección.
- **FR-023**: Un ejercicio cancelado MUST NOT reproducir _Guman_ ni ningún otro sonido o señal posterior a la cancelación.

**Presentación**

- **FR-024**: La pantalla del ejercicio MUST usar orientación horizontal de preferencia, con el oponente virtual al centro.
- **FR-025**: El oponente virtual, el sable y las señales MUST tener contornos definidos y alto contraste, y MUST distinguirse con claridad a **3 m** de la pantalla. _(CA8)_
- **FR-026**: Toda la interfaz MUST estar en español.
- **FR-027**: La app MUST funcionar en teléfonos y tablets Android. Cuando la imagen se envía a una TV, la pantalla del ejercicio MUST seguir cumpliendo FR-024 y FR-025.
- **FR-028**: La pantalla del dispositivo MUST NOT apagarse por inactividad mientras el ejercicio está en curso.

**Voces**

- **FR-029**: Las voces _Si-jak_ (시작) y _Guman_ (그만) MUST producirse con la voz sintética del dispositivo, en coreano.
- **FR-030**: Si el dispositivo no tiene voz sintética en coreano, la app MUST pronunciar _Si-jak_ y _Guman_ con la voz sintética predeterminada del dispositivo, sin bloquear ni retrasar el ejercicio.

### Key Entities _(include if feature involves data)_

- **Catálogo**: conjunto de solo lectura de niveles y patrones disponibles. Es la única fuente de las opciones de la pantalla de selección.
- **Nivel**: identificador, nombre, propósito (p. ej. calentamiento), tipo de respuesta (defensa en esta spec) y señal asociada.
- **Patrón**: identificador, nombre, postura (_Chochôn-se_) y corte (_Chungmyôn begi_). Indica si el corte puede salir hacia ambos lados.
- **Sesión**: combinación de un nivel y un patrón elegida por el usuario.
- **Parámetros del ejercicio**: duración, N, tiempo de aviso, velocidad del corte e intervalo configurado. Cumplen rangos e invariante (FR-006, FR-007).
- **Ejercicio**: una ejecución de una sesión con unos parámetros. Tiene un estado (FR-020), el tiempo transcurrido y el historial de lados para aplicar N.
- **Ataque**: lado (derecha o izquierda del usuario), tipo de respuesta, señal mostrada e instantes de señal, inicio y fin del corte.
- **Señal**: representación visual de la respuesta esperada (en esta spec, _defensa_: símbolo de sable) y el lado de la pantalla en que aparece.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Desde que abre la app, un usuario inicia un ejercicio con una sola acción (pulsar Iniciar) y en menos de 10 s.
- **SC-002**: En 200 ataques observados, el 100 % muestra el símbolo de defensa en el lado correcto según el color del sable (azul → izquierda, rojo → derecha).
- **SC-003**: En 1 000 ejercicios simulados de 3 min con N = 5, ninguno contiene más de 5 ataques seguidos al mismo lado. Con N = 1, el 100 % alterna los lados.
- **SC-004**: En ejercicios simulados, ambos lados aparecen en proporción de 50 % ± 5 % sobre al menos 10 000 ataques, y, en 1 000 ejercicios simulados de 3 min con semillas distintas, ninguna secuencia completa de lados se repite.
- **SC-005**: El tiempo de aviso, la duración del corte y el intervalo entre ataques observados se desvían menos de 50 ms de los valores previstos, y el 100 % de los intervalos sorteados cae entre 1.0 s y 2.5 s con los valores por defecto.
- **SC-006**: _Guman_ nunca suena antes de cumplirse la duración. Con los valores por defecto, suena como máximo 1.2 s (aviso + corte) después.
- **SC-007**: En una prueba de legibilidad a 3 m, al menos 2 de cada 3 observadores identifican correctamente el color del sable y el lado de la señal en al menos el 95 % de los ataques.
- **SC-008**: En el 100 % de las cancelaciones (botón Detener o segundo plano, en cualquier fase), el usuario vuelve a la pantalla de selección y no se reproduce ningún sonido después de cancelar.
- **SC-009**: Agregar un nivel o patrón de prueba al catálogo, que use una señal ya existente, lo muestra en la pantalla de selección y lo deja jugable sin modificar la lógica del ejercicio ni las pantallas.

## Assumptions

- **Alcance**: solo Nivel 1 y Patrón frontal con parámetros por defecto. Quedan fuera los niveles 2–4, el Patrón transversal, la edición y el guardado de parámetros (incluidos CL1 y CA7), y la pausa y reanudación. Todo se especifica en specs posteriores.
- La duración del ejercicio empieza a contar con _Si-jak_, no con la cuenta regresiva.
- La cuenta regresiva es solo visual (3, 2, 1, un número por segundo); la única voz de inicio es _Si-jak_.
- El oponente regresa a la postura del patrón al terminar cada corte y la mantiene durante el descanso en amarillo.
- Hay un botón Detener durante el ejercicio, necesario para cancelar sin salir de la app.
- Varios usuarios pueden entrenar a la vez frente a la misma pantalla. La app no distingue usuarios ni detecta sus respuestas.
- **Plataforma**: solo Android en esta entrega. Para enviar la imagen a la TV se usa la función de pantalla compartida del sistema o del dispositivo; la app no la implementa. iOS, escritorio y web quedan fuera.
- Si el dispositivo no tiene ninguna voz sintética disponible, el ejercicio se ejecuta sin voces; la cuenta regresiva y el sable siguen marcando el inicio y el fin.
- La app no necesita conexión a internet ni cuentas de usuario (sin backend ni autenticación en la v1, Principios IV y XI).
- El N configurado se aplica a los lados. La regla de N para el tipo de respuesta solo aplica a partir del Nivel 3 (Spec 005).

## Out of Scope

- Niveles 2, 3 y 4 (señales de evasión y contraataque) y el Patrón transversal (_Sodose_ / _Hwengdan ilgôm begi_).
- Edición y guardado de parámetros y la validación al editar (Spec 004).
- Pausa y reanudación del ejercicio.
- Backend, autenticación y autorización.
- Detección de las defensas y evasiones del usuario y marcador app vs. usuario.
- Más tipos de evasión (con giro, atrás y adelante) y más patrones o posturas.
