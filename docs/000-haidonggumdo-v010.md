# Especificación: Reacción de Combate para Haidong Gumdo v0.1.0

> Entrada para `/speckit-specify`. Describe **qué** hace la app, no **cómo**. Las decisiones técnicas viven en `.specify/memory/constitution.md`.
> Contexto completo: `docs/brief.md`.

## 1. Objetivo y contexto de negocio

1. Mejorar la capacidad de reacción de un practicante de Haidong Gumdo: el practicante responde a los ataques de un oponente virtual en pantalla, guiado por señales que indican hacia dónde reaccionar. El enfoque viene de los drills de reacción del fútbol americano.
2. Corregir el combate "frente a frente" de cintas blancas a azules: entrenar el hábito de defender o salir de la línea de ataque en lugar de intercambiar golpes a la cabeza.

## 2. Usuarios

- Uso principalmente, aunque no exclusivamente, personal.
- El número de usuarios simultáneos puede ir desde uno hasta lo que permitan el tamaño de la pantalla y el espacio disponible. Por ejemplo, una pantalla de 50" o más en un espacio de 8 × 8 m permitiría hasta 5 personas.

## Glosario

| Término | Significado en la app |
|---|---|
| *Si-jak* (시작) | Voz de inicio |
| *Guman* (그만) | Voz de fin |
| *Chochôn-se* (초천세) | Postura con el sable sobre la cabeza |
| *Sodose* | Postura con el sable a un costado del cuerpo |
| *Chungmyôn begi* (정면베기) | Corte frontal |
| *Hwengdan ilgôm begi* (횡단일검베기) | Corte transversal |
| Oponente virtual | Figura de un competidor de Haidong Gumdo dentro de la app |
| Patrón | Tipo de ataque del oponente virtual |
| Nivel | Tipo de respuesta que entrena el usuario |
| Sesión | Combinación de un nivel y un patrón |
| Tiempo de aviso | Tiempo desde que aparece la señal hasta que inicia el corte (ventana de reacción) |
| Velocidad del corte | Duración del corte del oponente virtual |

## 3. Escenarios de usuario (historias de usuario)

- **HU1 (P1)** — Como practicante de combate de Haidong Gumdo, quiero reaccionar defendiendo con el sable ante cortes frontales y transversales, para calentar (nivel 1).
- **HU2 (P2)** — Como practicante de combate de Haidong Gumdo, quiero reaccionar evadiendo lateralmente cortes frontales y transversales, para calentar y como base del entrenamiento (nivel 2).
- **HU3 (P3)** — Como practicante de combate de Haidong Gumdo, quiero reaccionar defendiendo o evadiendo, según la señal, cortes frontales y transversales, para mejorar la decisión bajo presión (nivel 3).
- **HU4 (P4)** — Como practicante de combate de Haidong Gumdo, quiero reaccionar evadiendo lateralmente y contraatacando cortes frontales y transversales, para competir eficazmente (nivel 4).

## 4. Requisitos funcionales

- **RF1. Configuración.** El sistema debe permitir configurar y guardar los siguientes parámetros:

  | Parámetro | Mínimo | Máximo | Por defecto |
  |---|---|---|---|
  | Duración del ejercicio | 30 s | 3 min | 30 s |
  | Máximo de repeticiones seguidas (N) | 1 | 5 | 5 |
  | Tiempo de aviso | [NEEDS CLARIFICATION: mínimo] | [NEEDS CLARIFICATION: máximo] | [NEEDS CLARIFICATION: valor por defecto] |
  | Velocidad del corte | 0.3 s | 1 s | 0.5 s |
  | Intervalo entre ataques | 0.5 s | 5 s | 2.5 s |

  [NEEDS CLARIFICATION: ¿el intervalo entre ataques es fijo o aleatorio, por ejemplo entre el mínimo y el valor configurado?]

- **RF2. Patrones.** Existen dos patrones para el oponente virtual:

  | Patrón | Postura | Corte |
  |---|---|---|
  | Frontal | *Chochôn-se* | *Chungmyôn begi* |
  | Transversal | *Sodose* | *Hwengdan ilgôm begi* |

  La postura **no revela** el lado del ataque. El corte transversal puede salir hacia cualquier lado.

- **RF3. Señales.**
  - Dispositivo de preferencia en horizontal, con el oponente virtual al centro, reconocible a distancia.
  - Colores del sable del oponente virtual:
    - **Blanco:** reposo.
    - **Amarillo:** en guardia.
    - **Azul:** respuesta hacia la derecha del usuario.
    - **Rojo:** respuesta hacia la izquierda del usuario.
  - **Señal de evasión:** flecha del lado de la pantalla hacia el que el usuario debe moverse, visto desde el usuario.
  - **Señal de defensa:** símbolo de sable del lado contrario al de la evasión.
  - **Señal de contraataque:** flecha de evasión con un símbolo de sable casi junto a su punta.

- **RF4. Niveles.** El sistema debe permitir al usuario elegir y jugar cualquiera de los cuatro niveles de la v1:

  | Nivel | Respuesta | Propósito |
  |---|---|---|
  | 1 | Defensa | Calentamiento |
  | 2 | Evasión lateral | Calentamiento / base |
  | 3 | Defensa o evasión lateral, mezcladas al azar | Decisión bajo presión |
  | 4 | Evasión lateral + corte del usuario (contraataque) | Combate |

  El usuario elige libremente nivel y patrón, sin desbloqueos. Los atletas pueden saltarse el calentamiento.

- **RF5. Flujo del ejercicio.**
  1. El usuario elige nivel y patrón e inicia el ejercicio.
  2. Cuenta regresiva en pantalla: 3, 2, 1, voz *Si-jak*. El sable pasa de blanco a amarillo.
  3. Ciclo de ataque, que se repite hasta que se cumple la duración:
     1. El oponente virtual toma la postura del patrón.
     2. El sable cambia a azul o rojo y aparece la señal del nivel.
     3. Pasado el tiempo de aviso, el oponente virtual ejecuta el corte.
     4. El sable regresa a amarillo y, tras el intervalo entre ataques, viene el siguiente ataque.
  4. Al cumplirse la duración suena la voz *Guman*. Si hay un corte en curso, se termina primero, como en torneo.

## 5. Reglas de negocio (con ejemplos)

- **RN1. Secuencia aleatoria.** El lado de cada ataque es aleatorio. En el nivel 3, el tipo de respuesta (defensa o evasión) también es aleatorio.
  - *Ejemplo:* en el nivel 2, dos ejercicios con la misma configuración no producen necesariamente la misma secuencia de lados.
- **RN2. Máximo de repeticiones seguidas.** No puede haber más de N ataques seguidos al mismo lado ni, en el nivel 3, más de N respuestas seguidas del mismo tipo.
  - *Ejemplo:* con N = 5, si los últimos 5 ataques fueron a la derecha, el siguiente es a la izquierda.
  - *Ejemplo:* con N = 1, los lados se alternan siempre.
- **RN3. Invariante de tiempos.** El intervalo entre ataques siempre es mayor que la velocidad del corte.
  - *Ejemplo:* con velocidad del corte de 1 s, un intervalo de 0.5 s no es válido.

## 6. Criterios de aceptación (verificables sin código)

- **CA1.** Dado el nivel 2, cuando el sable cambia a azul, entonces aparece una flecha en el lado derecho de la pantalla.
- **CA2.** Dado el nivel 1, cuando el sable cambia a azul, entonces aparece un símbolo de sable en el lado izquierdo de la pantalla.
- **CA3.** Dado el nivel 4, cuando el sable cambia a rojo, entonces aparece una flecha en el lado izquierdo de la pantalla con un símbolo de sable junto a su punta.
- **CA4.** Dado N = 5, en ningún ejercicio aparecen 6 ataques seguidos al mismo lado.
- **CA5.** Dado un ejercicio de 30 s, cuando se cumple el tiempo a la mitad de un corte, entonces el corte termina y después suena *Guman*.
- **CA6.** Al iniciar un ejercicio se ve la cuenta 3, 2, 1 y se escucha *Si-jak* antes del primer ataque.
- **CA7.** Los parámetros configurados se conservan al cerrar y volver a abrir la app.
- **CA8.** El oponente virtual, el color del sable y las señales se distinguen claramente a [NEEDS CLARIFICATION: distancia de referencia, por ejemplo 3 m] de la pantalla.

## 7. Casos límite

- **CL1.** El usuario configura un intervalo entre ataques menor o igual que la velocidad del corte. [NEEDS CLARIFICATION: ¿la app impide guardar o ajusta el intervalo automáticamente?]
- **CL2.** El usuario sale de la app o la app pasa a segundo plano a la mitad de un ejercicio. [NEEDS CLARIFICATION: ¿el ejercicio se cancela o se pausa?]

## 8. Fuera de alcance (v1)

- Backend.
- Autenticación y autorización.
- Detección de las defensas y evasiones del usuario y marcador app vs. usuario.
- Más tipos de evasión (con giro, atrás y adelante) y más patrones o posturas.
