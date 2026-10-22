# Brief — App de entrenamiento de reacción para Haidong Gumdo (v1, rev. 3)

> Documento de intención. Describe **qué** y **por qué**, no **cómo**. La tecnología y la arquitectura se deciden en la *constitution* y en el *plan*.

## Problemas que resuelve

1. **Mejorar la reacción en combate.** El enfoque viene de los drills de reacción del fútbol americano.
2. **Corregir el combate "frente a frente"** de cintas blancas a azules: entrenar el hábito de defender o salir de la línea de ataque en lugar de intercambiar golpes a la cabeza.

## Usuarios

- Uso principalmente personal.
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
| Patrón | Tipo de ataque del oponente |
| Nivel | Tipo de respuesta que entrena el usuario |
| Tiempo de aviso | Tiempo desde que aparece la señal hasta que inicia el corte (ventana de reacción) |
| Velocidad del corte | Duración del corte del oponente |

## Pantalla y señales

- Dispositivo de preferencia en horizontal, con el oponente virtual al centro, reconocible a distancia.
- Colores del sable del oponente:
  - **Blanco:** reposo.
  - **Amarillo:** en guardia.
  - **Azul:** respuesta hacia la **derecha** del usuario.
  - **Rojo:** respuesta hacia la **izquierda** del usuario.
- **Señal de evasión:** flecha del lado de la pantalla hacia el que el usuario debe moverse, visto desde el usuario.
- **Señal de defensa:** símbolo de sable del lado contrario al de la evasión.
- **Señal de contraataque:** flecha de evasión con un símbolo de sable casi junto a su punta.

## Patrones v1

| Patrón | Postura | Corte |
|---|---|---|
| Frontal | *Chochôn-se* | *Chungmyôn begi* |
| Transversal | *Sodose* | *Hwengdan ilgôm begi* |

La postura **no revela** el lado del ataque. El corte transversal puede salir hacia cualquier lado, incluso con la rodilla contraria.

## Niveles v1

| Nivel | Respuesta | Propósito |
|---|---|---|
| 1 | Defensa | Calentamiento |
| 2 | Evasión lateral | Calentamiento / base |
| 3 | Defensa o evasión lateral, mezcladas al azar | Decisión bajo presión |
| 4 | Evasión lateral + corte del usuario (contraataque) | Combate |

- El usuario elige libremente nivel y patrón, sin desbloqueos. Los atletas pueden saltarse el calentamiento.
- Una sesión es la combinación **Nivel × Patrón**.

## Flujo del ejercicio

1. El usuario elige nivel, patrón y, si quiere, ajusta los parámetros.
2. Cuenta regresiva en pantalla: 3, 2, 1, voz *Si-jak*. El sable pasa a amarillo.
3. **Ciclo de ataque**, que se repite hasta que se cumple la duración:
   1. El oponente toma la postura del patrón.
   2. El sable cambia a azul o rojo (lado aleatorio) y aparece la señal del nivel.
   3. Pasado el tiempo de aviso, el oponente ejecuta el corte.
   4. El sable regresa a amarillo y, tras un intervalo aleatorio, viene el siguiente ataque.
4. Al cumplirse la duración suena *Guman*. Si hay un corte en curso, **se termina primero**, como en torneo.

## Reglas

- **Secuencia aleatoria** de lados y, en el nivel 3, de tipo de respuesta.
- **Máximo de repeticiones seguidas:** no puede haber más de N ataques seguidos al mismo lado ni más de N respuestas seguidas del mismo tipo (N configurable).
- **Invariante de tiempos:** el intervalo entre ataques nunca es menor que la velocidad del corte. El intervalo siempre debe ser un poco más lento.

## Parámetros configurables

| Parámetro | Rango | Por defecto |
|---|---|---|
| Duración del ejercicio | — | 30 s |
| Máximo de repeticiones seguidas (N) | — | 5 |
| Tiempo de aviso | ⅓ s – 1 s | *pendiente* |
| Velocidad del corte | *pendiente* | *pendiente* |
| Intervalo entre ataques | 0.5 s – 5 s | *pendiente* |

Referencia del tiempo de aviso: 1 s (decir "mil uno") es lento para un corte real, pero adecuado para que una cinta blanca empiece a desarrollar reacción. ⅓ s sigue siendo más lento que un corte real, pero deja tiempo suficiente para reaccionar sin volverse demasiado difícil. Bajar estos tiempos es lo que mantiene el reto para practicantes avanzados.

## Restricciones

- Sin backend en la v1.
- Diseñada para que agregar después un backend o la detección de la respuesta del usuario no obligue a reescribir la lógica central.

## Entrega de la v1 en ciclos SDD

1. **Spec 001:** motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto.
2. **Spec 002:** Nivel 2 (señal de evasión).
3. **Spec 003:** Patrón transversal.
4. **Spec 004:** configuración de parámetros e invariante de tiempos.
5. **Spec 005:** Nivel 3.
6. **Spec 006:** Nivel 4.

## Visión a futuro (fuera de la v1)

- Más tipos de evasión: con giro (flecha circular), atrás y adelante.
- Más patrones y posturas.
- Detección de defensas y evasiones con un solo usuario, con marcador **app vs. usuario**: si el usuario no reacciona a tiempo, el punto es para la app.

## Preguntas abiertas

1. ¿El rango de ⅓ s a 1 s es solo para el tiempo de aviso? Si es así, ¿qué rango tiene la velocidad del corte?
2. ¿Cuáles son los valores por defecto del tiempo de aviso, la velocidad del corte y el intervalo?
