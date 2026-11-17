# Feature Specification: Configuración de parámetros e invariante de tiempos

**Feature Branch**: `005-configuracion`

**Created**: 2026-11-16

**Status**: Draft

**Input**: User description: "Spec 005: Configuración de parámetros e invariante de tiempos. Usa como contexto @docs/000-haidonggumdo-v010.md, @docs/brief.md y las specs 001 a 004. Alcance y decisiones del responsable: El usuario puede configurar y guardar: duración del ejercicio (30 s a 3 min, por defecto 30 s), máximo de repeticiones seguidas N (1 a 5, por defecto 5), tiempo de aviso (⅓ s a 1 s, por defecto 0.7 s), velocidad del corte (0.3 s a 1 s, por defecto 0.5 s) e intervalo entre ataques (por defecto 2.5 s, máximo 5 s). Propósito: 1 s de aviso es adecuado para una cinta blanca que empieza a desarrollar reacción; bajar los tiempos mantiene el reto para practicantes avanzados. La configuración se conserva al cerrar y volver a abrir la app (CA7), en JSON local detrás de un repositorio del dominio (Principio IV). La invariante de tiempos (Spec 001, FR-007) se valida al editar (CL1). La pantalla de configuración sigue el estilo de la Spec 004 y la regla de color (rojo, azul y amarillo solo para el sable y las señales). No cambian el motor ni las reglas del ejercicio: el motor ya acepta cualquier valor dentro de rango. Si hace falta una dependencia para guardar el archivo, propónla con ADR (Principio VII). Hazme antes las preguntas que necesites. No implementes nada."

## Contexto

Las Specs 001 a 004 entregaron el motor del ejercicio, los Niveles 1 y 2, los patrones frontal y transversal y la experiencia visual. Hasta ahora todos los ejercicios usan los **parámetros por defecto** (Spec 001, FR-006), aunque el motor ya acepta cualquier valor dentro de rango y rechaza los que no cumplen la invariante de tiempos (Spec 001, FR-007).

Esta spec permite que el usuario **ajuste los parámetros a su nivel y los guarde**. El tiempo de aviso es el más importante: **1 s** es adecuado para una cinta blanca que empieza a desarrollar reacción, y bajarlo hacia **⅓ s** mantiene el reto para practicantes avanzados. La velocidad del corte y el intervalo entre ataques permiten ajustar el ritmo del ejercicio, y la duración y N, su carga.

**Lo que no cambia.** El motor, los estados, las reglas de aleatoriedad, el máximo de N, los tiempos derivados de los parámetros (subida en la primera mitad del aviso, regreso de 0.5 s, sorteo del intervalo entre el piso y el valor configurado), las señales, las voces y la cancelación. Todas las pruebas funcionales de las Specs 001 a 004 siguen pasando.

**Principios IV y VII.** La configuración se guarda en un archivo **JSON local**, a través de una interfaz de repositorio definida en el dominio. Para ubicar ese archivo en la carpeta de la app hace falta un paquete: se propone `path_provider` en `docs/decisions/0006-carpeta-de-la-app-path-provider.md` (estado: **Propuesta**, pendiente de aprobación del responsable).

### Hoja de ruta de la v1 (según `docs/brief.md`, rev. 3)

| Spec           | Contenido                                                                  |
| -------------- | -------------------------------------------------------------------------- |
| 001            | Motor del ejercicio + Nivel 1 + Patrón frontal, con parámetros por defecto |
| 002            | Patrón transversal                                                         |
| 003            | Nivel 2 (señal de evasión)                                                 |
| 004            | Experiencia visual                                                         |
| **005 (esta)** | Configuración de parámetros e invariante de tiempos                        |
| 006            | Nivel 3                                                                    |
| 007            | Nivel 4                                                                    |

### Glosario

Se usan los términos del glosario de la Spec 001. Se agregan:

| Término               | Significado en la app                                                                                                   |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Configuración         | Conjunto de los cinco parámetros del ejercicio guardado por el usuario                                                  |
| Configuración guardada | La última configuración que el usuario guardó; es la que usan los ejercicios                                           |
| Borrador              | Valores que el usuario está editando en la pantalla de configuración y que todavía no guarda                            |
| Piso del intervalo    | Valor mínimo del sorteo del intervalo: velocidad del corte + 0.5 s (Spec 001). Es también el mínimo del intervalo configurable |
| Ajuste automático     | Subida del intervalo al menor valor permitido cuando un cambio en la velocidad del corte lo deja por debajo del piso   |

## Clarifications

### Session 2026-11-16

- Q: Si el usuario sube la velocidad del corte y el intervalo queda por debajo del piso, ¿qué hace la pantalla? → A: El intervalo **sube solo** al menor valor permitido que cumple el piso y se avisa en pantalla. Nunca hay un borrador inválido, así que siempre se puede guardar. _(CL1)_
- Q: ¿De cuánto en cuánto se ajusta cada parámetro? → A: **Pasos finos**: duración de 15 en 15 s; N de 1 en 1; tiempo de aviso 0.33 s y después de 0.05 en 0.05 s (0.35 … 1.00); velocidad del corte de 0.05 en 0.05 s; intervalo de 0.1 en 0.1 s.
- Q: ¿Cómo se entra a la configuración y cuándo se guarda? → A: Con un botón **Configuración** en la pantalla de selección, que abre una **pantalla aparte** con **Guardar**, **Cancelar** (descarta los cambios) y **Restablecer valores por defecto**. El resumen de la sesión muestra la duración guardada.
- Q: ¿Qué dependencia se propone para ubicar el archivo JSON? → A: `path_provider` (paquete oficial de Flutter), registrada como ADR 0006 en estado Propuesta.
- Q: ¿Con qué control se cambia cada parámetro? → A: Con botones **− / +**: cada toque avanza exactamente un paso, y en el mínimo o el máximo vigente el botón correspondiente se desactiva. Sin deslizador.
- Q: ¿Cómo se muestra que el intervalo es el tope de un sorteo y no un valor fijo? → A: Con la etiqueta "Intervalo máximo entre ataques" y, debajo, el rango real, por ejemplo "Cada ataque: entre 1.0 s y 2.5 s, al azar". El rango se actualiza al cambiar la velocidad del corte o el intervalo.
- Q: ¿Dónde va el botón Configuración en la pantalla de selección? → A: Abajo, como píldora con borde blanco "CONFIGURACIÓN" a la izquierda de INICIAR, junto al resumen de la sesión.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Ajustar y guardar los parámetros (Priority: P1)

Como practicante de Haidong Gumdo, quiero ajustar el tiempo de aviso, la velocidad del corte, el intervalo entre ataques, la duración y el máximo de repeticiones seguidas, y que la app los recuerde, para entrenar al nivel que me corresponde sin reconfigurar cada vez.

En la pantalla de selección, el usuario pulsa **Configuración**. Ve los cinco parámetros con su valor guardado, su rango y una breve explicación; en el tiempo de aviso, la referencia "1 s: cinta blanca · ⅓ s: avanzado". Baja el tiempo de aviso a 0.5 s, sube la duración a 1 min y pulsa **Guardar**. Vuelve a la selección, cuyo resumen ahora dice "Nivel 1 · Frontal · 1 min". Inicia el ejercicio: el aviso dura 0.5 s y el ejercicio, 1 min. Cierra la app, la vuelve a abrir y la configuración sigue ahí.

**Why this priority**: Es el valor central de la spec: adaptar el reto al practicante (cinta blanca o avanzado) y conservarlo (CA7). Sin esto, la app solo sirve con los valores por defecto.

**Independent Test**: Cambiar cada parámetro, guardar, iniciar un ejercicio y comprobar que usa los valores nuevos; cerrar la app por completo, volver a abrirla y comprobar que los valores siguen guardados.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** el usuario pulsa Configuración, **Then** ve la pantalla de configuración con los cinco parámetros y sus valores guardados (los por defecto si nunca guardó).
2. **Given** la pantalla de configuración, **When** el usuario toca − o + en un parámetro, **Then** el valor cambia exactamente un paso y se ve de inmediato, siempre dentro de su rango (FR-004, FR-004a).
3. **Given** un parámetro en su máximo (por ejemplo, la duración en 3 min), **When** el usuario mira sus botones, **Then** el + está desactivado y el − activo.
4. **Given** un tiempo de aviso de 0.5 s guardado, **When** el usuario inicia un ejercicio, **Then** el corte empieza 0.5 s después de que aparece la señal, y la subida a la postura de ataque dura 0.25 s (la primera mitad del aviso, Spec 001, FR-010).
5. **Given** una duración de 1 min guardada, **When** el usuario vuelve a la selección, **Then** el resumen de la sesión dice "Nivel 1 · Frontal · 1 min" y el ejercicio dura 1 min, con la barra de progreso y los segundos restantes del HUD calculados sobre 1 min.
6. **Given** N = 1 guardado, **When** el usuario juega un ejercicio, **Then** los lados se alternan siempre (Spec 001, FR-018).
7. **Given** una configuración guardada, **When** el usuario cierra la app por completo y la vuelve a abrir, **Then** la pantalla de configuración y el resumen muestran los mismos valores, y el siguiente ejercicio los usa. _(CA7)_
8. **Given** una configuración guardada, **When** el usuario pulsa Repetir al terminar un ejercicio, **Then** el ejercicio nuevo usa la misma configuración guardada.

---

### User Story 2 - Invariante de tiempos al editar (Priority: P2)

Como practicante, quiero que la app no me deje configurar un intervalo entre ataques más corto que el corte, para que el oponente siempre termine el corte y regrese a guardia antes del siguiente ataque.

En la pantalla de configuración, el intervalo está en 1.0 s y la velocidad del corte en 0.5 s. El usuario sube la velocidad del corte a 0.8 s. El piso pasa a 1.3 s, así que el intervalo sube solo a 1.3 s y aparece un aviso: "Intervalo ajustado a 1.3 s: debe ser al menos la velocidad del corte + 0.5 s". El rango que se muestra debajo del intervalo pasa a "Cada ataque: 1.3 s", porque el piso y el tope coinciden. El usuario puede guardar sin hacer nada más.

**Why this priority**: Cierra CL1 y garantiza que ninguna configuración guardada viole la invariante (RN3), así que el motor nunca rechaza un ejercicio. Depende de que exista la edición (US1).

**Independent Test**: Con la velocidad del corte y el intervalo en sus mínimos, subir la velocidad del corte paso a paso hasta 1 s y comprobar que el intervalo nunca queda por debajo del piso; intentar bajar el intervalo por debajo del piso y comprobar que no se puede.

**Acceptance Scenarios**:

1. **Given** velocidad del corte 0.5 s e intervalo 1.0 s, **When** el usuario sube la velocidad del corte a 0.8 s, **Then** el intervalo sube automáticamente a 1.3 s y se muestra el aviso de ajuste. _(CL1)_
2. **Given** velocidad del corte 0.5 s e intervalo 1.0 s, **When** el usuario mira el intervalo, **Then** su botón − está desactivado, porque 1.0 s es su mínimo en ese momento, y el intervalo no puede bajar más.
3. **Given** velocidad del corte 0.35 s (piso 0.85 s), **When** el usuario baja el intervalo a su mínimo, **Then** el intervalo queda en 0.9 s, el menor valor permitido que no está por debajo del piso.
4. **Given** velocidad del corte 0.8 s e intervalo 1.3 s, **When** el usuario baja la velocidad del corte a 0.5 s, **Then** el intervalo se queda en 1.3 s (no baja solo) y su mínimo pasa a 1.0 s.
5. **Given** un intervalo de 2.5 s, **When** el usuario sube la velocidad del corte a 1 s (piso 1.5 s), **Then** el intervalo no cambia y no aparece ningún aviso.
6. **Given** cualquier combinación de valores que el usuario pueda elegir, **When** pulsa Guardar, **Then** se guarda y el motor la acepta al iniciar un ejercicio.

---

### User Story 3 - Cancelar y restablecer (Priority: P3)

Como practicante, quiero descartar cambios que no me convencen y volver a los valores por defecto, para experimentar sin miedo a perder una configuración que ya funciona.

**Why this priority**: Da confianza para experimentar, pero la app ya es útil sin estas acciones.

**Independent Test**: Cambiar varios parámetros y pulsar Cancelar: la configuración guardada no cambia. Pulsar Restablecer valores por defecto y después Guardar: quedan guardados los valores por defecto.

**Acceptance Scenarios**:

1. **Given** cambios sin guardar, **When** el usuario pulsa Cancelar o usa el gesto o botón Atrás del sistema, **Then** vuelve a la selección y la configuración guardada no cambia.
2. **Given** la pantalla de configuración, **When** el usuario pulsa Restablecer valores por defecto, **Then** el borrador muestra 30 s, 5, 0.7 s, 0.5 s y 2.5 s, y la configuración guardada no cambia hasta que pulse Guardar.
3. **Given** el borrador restablecido, **When** el usuario pulsa Guardar, **Then** la configuración guardada son los valores por defecto.
4. **Given** el borrador restablecido, **When** el usuario pulsa Cancelar, **Then** la configuración guardada sigue siendo la anterior.

---

### Edge Cases

- **Primera vez.** Si nunca se guardó una configuración, la app usa los valores por defecto (Spec 001, FR-006) y la pantalla de configuración los muestra.
- **Archivo dañado o ilegible.** Si la configuración guardada no se puede leer, o sus valores están fuera de rango o violan la invariante (por ejemplo, un archivo de otra versión), la app usa los valores por defecto sin bloquear ni mostrar un error técnico. El archivo dañado no se reemplaza hasta que el usuario guarde.
- **Error al guardar.** Si no se puede guardar (por ejemplo, sin espacio en el dispositivo), la app avisa con un mensaje claro, se queda en la pantalla de configuración con el borrador intacto y la configuración guardada anterior sigue vigente.
- **Ajuste automático y luego Cancelar.** El ajuste automático del intervalo es parte del borrador: si el usuario cancela, el intervalo guardado no cambia.
- **Varios ajustes seguidos.** Si el usuario sube la velocidad del corte varias veces y cada una exige ajustar el intervalo, el aviso se actualiza con el último valor ajustado.
- **Límites del ajuste.** Con la velocidad del corte en 1 s el piso es 1.5 s, menor que el máximo del intervalo (5 s), así que el ajuste automático siempre es posible.
- **Piso fuera de los pasos.** Cuando el piso no es múltiplo de 0.1 s (por ejemplo, 0.85 s con corte de 0.35 s), el mínimo del intervalo es el siguiente múltiplo de 0.1 s (0.9 s).
- **Tiempo de aviso mínimo.** ⅓ s se muestra y se guarda como 0.33 s, el mínimo que ya acepta el motor (Spec 001, FR-006). El siguiente paso es 0.35 s.
- **Cambios durante un ejercicio.** No se puede abrir la configuración durante un ejercicio: solo desde la pantalla de selección. Un ejercicio usa la configuración guardada al pulsar Iniciar o Repetir.
- **App en segundo plano en la pantalla de configuración.** El borrador puede perderse si el sistema cierra la app; la configuración guardada no cambia.

## Requirements _(mandatory)_

### Functional Requirements

**Acceso y flujo**

- **FR-001**: La pantalla de selección MUST tener un botón **CONFIGURACIÓN** que abre la pantalla de configuración. El botón MUST estar en la parte inferior, a la izquierda de INICIAR y junto al resumen de la sesión (Spec 004, FR-024), en forma de píldora con borde blanco, y MUST verse claramente secundario frente a INICIAR (blanco con texto oscuro). El botón, el resumen e INICIAR MUST NOT quedar tapados ni recortados en proporciones de 4:3 a 20:9. El botón MUST NOT cambiar que iniciar requiera una sola acción (Spec 001, SC-001).
- **FR-002**: La pantalla de configuración MUST abrirse con un borrador igual a la configuración guardada y MUST tener tres acciones: **Guardar** (guarda el borrador y vuelve a la selección), **Cancelar** (descarta el borrador y vuelve a la selección) y **Restablecer valores por defecto** (pone el borrador en los valores por defecto, sin guardar). El gesto o botón Atrás del sistema MUST equivaler a Cancelar.
- **FR-003**: La configuración MUST abrirse solo desde la pantalla de selección, nunca durante un ejercicio.

**Parámetros, rangos y pasos**

- **FR-004**: La pantalla MUST permitir editar estos parámetros, solo con valores dentro de su rango y en sus pasos:

  | Parámetro                           | Mínimo                                 | Máximo | Paso                         | Por defecto |
  | ----------------------------------- | -------------------------------------- | ------ | ---------------------------- | ----------- |
  | Duración del ejercicio              | 30 s                                   | 3 min  | 15 s                         | 30 s        |
  | Máximo de repeticiones seguidas (N) | 1                                      | 5      | 1                            | 5           |
  | Tiempo de aviso                     | 0.33 s (⅓ s)                           | 1 s    | 0.05 s (0.33, 0.35, 0.40 …) | 0.7 s       |
  | Velocidad del corte                 | 0.3 s                                  | 1 s    | 0.05 s                       | 0.5 s       |
  | Intervalo entre ataques             | Piso del intervalo, redondeado arriba a 0.1 s | 5 s    | 0.1 s                        | 2.5 s       |

  Los rangos son los de la Spec 001, FR-006. El mínimo del intervalo de 0.5 s de esa tabla queda siempre por debajo del piso (al menos 0.8 s), así que el mínimo efectivo es el piso.
- **FR-004a**: Cada parámetro MUST cambiarse con un par de botones **−** y **+**. Cada toque MUST cambiar el valor exactamente un paso. En el mínimo vigente, el botón − MUST estar desactivado; en el máximo, el botón + MUST estar desactivado. Los botones desactivados MUST distinguirse a simple vista de los activos sin usar rojo, azul ni amarillo (FR-018).
- **FR-005**: Cada parámetro MUST mostrar su nombre, su valor actual con unidades, su rango y una explicación breve en español. El tiempo de aviso MUST mostrar la referencia "1 s: cinta blanca · ⅓ s: avanzado". El intervalo MUST llamarse **"Intervalo máximo entre ataques"** y MUST mostrar debajo el rango real del sorteo, desde el piso del intervalo hasta el valor configurado (por ejemplo, "Cada ataque: entre 1.0 s y 2.5 s, al azar"). El rango MUST actualizarse en cuanto cambian la velocidad del corte o el intervalo. Si el piso y el valor configurado coinciden, MUST mostrarse un solo valor (por ejemplo, "Cada ataque: 1.3 s").
- **FR-006**: Los tiempos MUST mostrarse en segundos con dos decimales como máximo (por ejemplo, "0.33 s", "0.7 s", "2.5 s"). La duración MUST mostrarse en segundos por debajo de 1 min y en minutos y segundos a partir de 1 min (por ejemplo, "45 s", "1 min", "2 min 15 s").

**Invariante de tiempos (CL1)**

- **FR-007** _(RN3; Spec 001, FR-007)_: El borrador MUST cumplir siempre la invariante: intervalo ≥ piso del intervalo (velocidad del corte + 0.5 s). El usuario MUST NOT poder bajar el intervalo por debajo de su mínimo vigente (FR-004).
- **FR-008** _(ajuste automático)_: Si un cambio en la velocidad del corte deja el intervalo por debajo del piso, el intervalo MUST subir automáticamente al mínimo vigente, y la pantalla MUST mostrar un aviso con el valor nuevo y la razón (por ejemplo, "Intervalo ajustado a 1.3 s: debe ser al menos la velocidad del corte + 0.5 s"). Si la velocidad del corte baja, el intervalo MUST NOT cambiar.
- **FR-009**: Como el borrador siempre es válido, Guardar MUST estar siempre disponible. Toda configuración guardada MUST ser aceptada por el motor al iniciar un ejercicio.

**Persistencia (CA7)**

- **FR-010**: Guardar MUST conservar los cinco parámetros en el dispositivo, de forma que sigan vigentes al cerrar la app por completo y volver a abrirla. _(CA7)_
- **FR-011**: La configuración MUST guardarse como **JSON local** y MUST leerse y escribirse solo a través de una interfaz de repositorio definida en el dominio, para que un backend futuro sea solo otra implementación (Principio IV).
- **FR-012**: Al abrir la app, MUST cargarse la configuración guardada. Si no existe, no se puede leer, está fuera de rango o viola la invariante, MUST usarse la configuración por defecto, sin bloquear la app ni mostrar errores técnicos.
- **FR-013**: Si guardar falla, la app MUST avisar con un mensaje claro en español, quedarse en la pantalla de configuración con el borrador intacto y mantener vigente la configuración guardada anterior.

**Uso en el ejercicio**

- **FR-014**: Todo ejercicio MUST usar la configuración guardada en el momento de pulsar Iniciar o Repetir. Los tiempos derivados se calculan a partir de ella como en las Specs 001 a 003 (subida en la primera mitad del aviso, corte con la velocidad configurada, regreso de 0.5 s, sorteo del intervalo entre el piso y el valor configurado).
- **FR-015**: El resumen de la sesión de la pantalla de selección (Spec 004, FR-024) y la barra de progreso y los segundos restantes del HUD (Spec 004) MUST usar la duración guardada, con el formato de FR-006.
- **FR-016**: Esta spec MUST NOT cambiar el motor, los estados, las reglas de secuencia, las señales, las voces ni la cancelación. Todas las pruebas funcionales de las Specs 001 a 004 MUST seguir pasando.

**Presentación**

- **FR-017**: La pantalla de configuración MUST seguir el estilo de la Spec 004: dojang de fondo bajo una capa oscura, paneles translúcidos, tipografía Rajdhani, botones en forma de píldora (Guardar blanco con texto oscuro; Cancelar y Restablecer con borde blanco).
- **FR-018** _(regla de color, Spec 004, FR-004)_: La pantalla de configuración MUST NOT usar rojo, azul ni amarillo en ningún elemento, incluidos los controles, los valores, el aviso de ajuste automático y el mensaje de error al guardar. Los avisos MUST distinguirse por ícono, texto y contraste en blancos y grises.
- **FR-019**: La pantalla MUST verse completa y usable en orientación horizontal, en proporciones de 4:3 a 20:9, sin que ningún control quede tapado. Si no caben los cinco parámetros, la lista MUST poder desplazarse y las acciones MUST seguir visibles.
- **FR-020**: Toda la interfaz de configuración MUST estar en español (Principio IX).

### Key Entities _(include if feature involves data)_

- **Configuración**: los cinco parámetros del ejercicio (duración, N, tiempo de aviso, velocidad del corte e intervalo). Es la misma entidad que los parámetros del ejercicio de la Spec 001; siempre cumple rangos, pasos e invariante.
- **Configuración guardada**: la última configuración que guardó el usuario, o la por defecto si no hay ninguna válida. Es la que usan los ejercicios.
- **Borrador**: copia editable de la configuración, que solo existe mientras la pantalla de configuración está abierta. Siempre es válido (FR-007, FR-008).
- **Repositorio de configuración**: interfaz del dominio para cargar y guardar la configuración, sin conocer dónde ni cómo se guarda (Principio IV).
- **Aviso de ajuste**: mensaje que indica que el intervalo subió automáticamente, con el valor nuevo y la razón.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Desde la pantalla de selección, un usuario cambia el tiempo de aviso, guarda y vuelve a la selección en menos de 20 s.
- **SC-002**: En el 100 % de 20 cierres completos de la app con configuraciones distintas, al volver a abrirla la configuración es la última guardada. _(CA7)_
- **SC-003**: Recorriendo todas las combinaciones de velocidad del corte e intervalo que permiten los pasos, ningún borrador viola la invariante, y el 100 % de las configuraciones guardadas son aceptadas por el motor.
- **SC-004**: En el 100 % de los cambios de velocidad del corte que dejan el intervalo por debajo del piso, el intervalo sube al mínimo vigente y aparece el aviso de ajuste; en el 100 % de los cambios que no lo exigen, el intervalo no cambia y no aparece aviso.
- **SC-005**: Con una configuración guardada distinta de la por defecto, el tiempo de aviso, la duración del corte y el intervalo observados se desvían menos de 50 ms de los valores guardados (mismo criterio que la Spec 001, SC-005), y el ejercicio dura la duración guardada.
- **SC-006**: En una revisión de la pantalla de configuración con 3 observadores, ninguno nombra como rojo, azul o amarillo ningún elemento, incluidos el aviso de ajuste y el mensaje de error (mismo criterio que la Spec 004, SC-003).
- **SC-007**: Con un archivo de configuración dañado, ausente o con valores inválidos, en el 100 % de los casos la app abre con los valores por defecto y sin mensajes de error técnico.
- **SC-008**: Todas las pruebas funcionales de las Specs 001 a 004 siguen pasando.

## Assumptions

- Hay **una sola configuración** para toda la app, compartida por todas las sesiones (nivel × patrón). No hay perfiles por usuario ni configuraciones por nivel o patrón.
- La sesión elegida (nivel y patrón) no se guarda: al abrir la app siguen preseleccionados el Nivel 1 y el Patrón frontal (Spec 004, FR-023).
- Restablecer valores por defecto no pide confirmación: solo cambia el borrador, que el usuario puede cancelar.
- Cancelar con cambios sin guardar no pide confirmación.
- La referencia de cinta blanca y avanzado es solo informativa. No hay perfiles predefinidos ("principiante", "avanzado") en esta spec.
- Los pasos de 0.05 s del tiempo de aviso y de la velocidad del corte, y de 0.1 s del intervalo, son suficientes para el entrenamiento; la precisión del motor (Spec 001, SC-005: ±50 ms) no cambia.
- El archivo de configuración vive en la carpeta privada de la app en el dispositivo; se borra si el usuario desinstala la app o borra sus datos.
- Ubicar el archivo en la carpeta de la app requiere el paquete `path_provider`, propuesto en el ADR 0006 y pendiente de aprobación (Principio VII). Si no se aprueba, el plan debe proponer otra forma de cumplir FR-010 y FR-011.
- **Plataforma**: Android, igual que en las specs anteriores.

## Out of Scope

- Perfiles de usuario, configuraciones por nivel o patrón y perfiles predefinidos de dificultad.
- Guardar la última sesión elegida (nivel y patrón).
- Cambiar parámetros durante un ejercicio.
- Nuevos parámetros (por ejemplo, la duración del regreso a _Chayôn-se_ o el margen del piso del intervalo, que siguen fijos en 0.5 s).
- Exportar, importar o sincronizar la configuración; backend.
- Pausa y reanudación del ejercicio.
- Niveles 3 y 4 (Specs 006 y 007).
