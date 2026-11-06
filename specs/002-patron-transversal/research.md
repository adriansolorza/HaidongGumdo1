# Research: Patrón transversal

**Feature**: [spec.md](./spec.md) | **Base**: [Spec 001](../001-motor-nivel1-frontal/plan.md) (motor, catálogo, `OpponentMotion`, punta vista de frente)

El contexto técnico no tenía incógnitas abiertas: el stack, los paquetes y la arquitectura son los de la Spec 001. La única duda real era si el corte transversal cabe en el modelo de corte de la 001 sin cambiar código (FR-002). La resuelve R1 con un prototipo.

## R1. El corte transversal como `CutMotion` (solo datos)

- **Decision**: Expresar *Hwengdan ilgôm begi* con el modelo de la 001, sin cambios de código: `CutMotion` interpola linealmente la empuñadura y la punta entre `start` (*Sodose*, extendido hacia el costado del corte) y `end` (su reflejo, extendido hacia el costado contrario), con `mirroredBySide: true`. *(Revisión 2026-11-05: barrido de 180°; antes, `end` era el impacto.)* La subida (`guard → stance`), el corte (`stance → cutEnd`) y el regreso (`cutEnd → guard`) salen de `OpponentMotion`, igual que en el frontal.
- **Rationale**: Visto de frente, un barrido horizontal de 180° se lee como una hoja que sale larga de un costado, se acorta al pasar frente al oponente (apunta al usuario) y vuelve a alargarse hacia el otro costado. La interpolación lineal produce exactamente eso, a velocidad uniforme en la pantalla, que es lo que pide la spec (sesión 2026-11-05). Se comprobó con un **prototipo** (posiciones de R2 dibujadas con el `OpponentPainter` actual, 2026-11-05): *Sodose* extendido a un costado, la hoja acortándose hacia el frente, la punta vista de frente a la mitad, el sable extendido al otro costado al final y el regreso a la guardia. No hizo falta tocar ningún archivo de `lib/`.
- **Alternatives considered**:
  - Trayectoria en arco o con fotogramas intermedios (p. ej. un barrido que cruza todo el frente). Requiere ampliar `CutMotion`, lo que es código nuevo en el dominio y la presentación y entra en tensión con el Principio III. Se rechaza: la interpolación lineal ya se lee como corte horizontal.
  - *(Descartada el 2026-11-05)* Terminar el corte en el impacto, frente al flanco del usuario. Era la decisión del 2026-11-04 y el responsable la corrigió tras verla en el emulador: el corte real es un barrido de 180° que termina extendido hacia el costado contrario.

## R2. Posiciones del sable

- **Decision**: Coordenadas de la 001 (origen en el centro de la figura, unidad = media altura, `x` a la derecha de la pantalla, `y` hacia abajo). Los valores base son para el lado `right` (sable azul) y se reflejan en `x` con el lado `left` (rojo).

  *(Revisión 2026-11-05: barrido de 180° a la cintura.)*

  | Postura | `hilt` | `tip` | Lectura |
  |---|---|---|---|
  | Guardia (*Chayôn-se*) | (0, 0.05) | (0, −0.3) | Igual que el frontal: manos al ombligo, punta al usuario |
  | *Sodose* (`cut.start`) | (−0.45, 0.1) | (−1.3, −0.1) | Manos a la cintura en el costado izquierdo de la pantalla; hoja extendida hacia afuera |
  | Mitad del barrido (interpolada, no es un dato) | (0, 0.1) | (0, −0.1) | Frente al oponente; hoja en escorzo apuntando al usuario |
  | Fin del corte (`cut.end`) | (0.45, 0.1) | (1.3, −0.1) | Reflejo de *Sodose*: sable extendido hacia el costado contrario, a la misma altura |

- **Rationale**:
  - **Altura**: la empuñadura va a la cintura (`y` 0.1, justo debajo del ombligo de la guardia) y no cambia de altura en todo el barrido; la punta tampoco (`y` −0.1). Ninguna de las dos sigue una trayectoria diagonal (FR-008).
  - **Largo a la mitad del barrido (FR-009)**: como `cut.end` es el reflejo de `cut.start`, a la mitad del barrido la empuñadura y la punta quedan en `x = 0`, y la hoja visible mide solo la diferencia de altura entre ellas. Con la punta 0.2 u más alta que la empuñadura, la hoja nunca mide cero: mide 0.2 u y la punta vista de frente aparece con su diámetro máximo (0.3 u). Si ambas fueran a la misma altura, a la mitad la hoja mediría cero.
  - **Largo en los costados**: en *Sodose* y al final la hoja mide ≈ 0.87 u, así que se ve larga y con el color legible sin la punta vista de frente. La leve inclinación hacia arriba (≈ 13°) no cambia la lectura de corte horizontal.
  - **Rango**: todos los valores están en [−2, 2].
- **Alternatives considered**:
  - Empuñadura y punta a la misma altura (hoja perfectamente horizontal). A la mitad del barrido la hoja mediría cero y desaparecería justo cuando apunta al usuario; incumple FR-009.
  - Una diferencia de altura mayor (p. ej. 0.4 u) para alargar la hoja a la mitad. Inclinaría la hoja ≈ 25° en los costados y se leería como un corte diagonal; incumple FR-008.
  - *Sodose* con la hoja hacia atrás en escorzo fuerte. Más fiel a la postura real, pero la hoja sería casi invisible de frente. Se rechaza por legibilidad: el costado tiene que leerse a 3 m.

## R3. Lado del ataque ↔ costado del corte

- **Decision**: Lado `right` (sable azul, defensa a la izquierda) → *Sodose* y salida del corte en el costado **izquierdo** de la pantalla, sin reflejar. Lado `left` (sable rojo, defensa a la derecha) → valores reflejados, costado **derecho**.
- **Rationale**: El usuario mira la pantalla de frente, así que el lado izquierdo de la pantalla es su izquierda (research R11 de la 001). Un barrido que sale del costado izquierdo de la pantalla llega primero al flanco izquierdo del usuario y sigue hacia el otro costado, que es justo donde está el símbolo de defensa con el sable azul (FR-015 de la 001). La regla de reflejo de la 001 (plan D5: se reflejan `stance` y `cutEnd`, nunca `guard`) ya implementa esto.
- **Alternatives considered**: Ninguna; la decisión de la spec (Q1: A) fija la relación.

## R4. Legibilidad en *Sodose* y en escorzo (FR-009)

- **Decision**: Sin cambios en la presentación. La punta vista de frente de la 001 (plan D2) aparece sola cuando la hoja visible es corta: en el tramo central del barrido, con su diámetro máximo a la mitad (hoja de 0.2 u, R2). En *Sodose* y al final del corte la hoja es larga y no la necesita.
- **Rationale**: El diámetro de la punta depende solo de la longitud visible, no del patrón, así que funciona igual para el corte transversal. Se valida a 3 m con la prueba manual (quickstart §3, SC-003).
- **Alternatives considered**: Engrosar la hoja en el patrón transversal. Sería una regla por patrón en el painter, que la 001 evita a propósito.

## R5. *Sodose* sin hangul

- **Decision**: Entrada de glosario `sodose` sin `hangul`. La pantalla de selección ya muestra solo la romanización cuando falta el hangul (`_termLabel` de la 001), así que el transversal se lista como "Chayôn-se (자연세) → Sodose → Hwengdan ilgôm begi (횡단일검베기)".
- **Rationale**: El glosario del proyecto (brief y documento 000) no le da hangul a *Sodose*, y FR-003 exige usar los términos exactamente como en el glosario. El esquema del catálogo ya trata `hangul` como opcional.
- **Alternatives considered**: Inventar un hangul. Viola FR-003 y el Principio IX.

## R6. Pruebas existentes y SC-007

- **Decision**: Las pruebas de la 001 que comprueban la **lógica** (tiempos, eventos, estados, señales, cancelación, movimiento) no cambian y deben seguir pasando. Las que comprueban el **contenido del catálogo real** sí cambian, porque el catálogo crece: `test/data/catalog_json_mapper_test.dart` (a) espera 1 patrón y 5 términos y usa `catalog.patterns.single`. Pasará a esperar 2 patrones y 7 términos, y a localizar cada patrón por `id`.
- **Rationale**: Cambiar un recuento de datos no es cambiar la lógica ni las pantallas, que es lo que protegen FR-002 y SC-007. La redacción de SC-007 ("sin cambiar sus expectativas") es más estricta de lo que pretende; conviene precisarla en la spec (ver plan.md, "Notas para la spec").
- **Alternatives considered**: Dejar ese test con el catálogo de la 001 copiado en un fixture. Perdería su propósito, que es validar el asset real que se instala.

## R7. Distinguir los dos patrones a 3 m (SC-004)

- **Decision**: Sin elementos extra. El frontal se lee como un movimiento vertical desde arriba de la cabeza hacia el centro. El transversal, como un barrido horizontal a la altura de la cintura, de un costado al otro, que pasa frente al oponente a la mitad. Se valida con la prueba manual de quickstart §3.
- **Rationale**: La postura de ataque (sable sobre la cabeza frente a sable al costado) ya diferencia los patrones durante medio tiempo de aviso antes del corte.
- **Alternatives considered**: Mostrar el nombre del patrón durante el ejercicio. Compite con la señal y no lo pide la spec.

## R8. Contrato del catálogo

- **Decision**: `contracts/catalog.schema.json` de la 001 **no cambia**: el patrón transversal usa los mismos campos (`guardTermId`, `stanceTermId`, `cutTermId`, `guard`, `cut` con `mirroredBySide`). Esta spec solo agrega entradas al asset; el contrato de las entradas nuevas está en [contracts/catalog-entries.md](./contracts/catalog-entries.md).
- **Rationale**: Es la prueba concreta del Principio III: un patrón nuevo con un tipo de respuesta existente es solo datos.
