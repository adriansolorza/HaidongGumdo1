# Research: Patrón transversal

**Feature**: [spec.md](./spec.md) | **Base**: [Spec 001](../001-motor-nivel1-frontal/plan.md) (motor, catálogo, `OpponentMotion`, punta vista de frente)

El contexto técnico no tenía incógnitas abiertas: el stack, los paquetes y la arquitectura son los de la Spec 001. La única duda real era si el corte transversal cabe en el modelo de corte de la 001 sin cambiar código (FR-002). La resuelve R1 con un prototipo.

## R1. El corte transversal como `CutMotion` (solo datos)

- **Decision**: Expresar *Hwengdan ilgôm begi* con el modelo de la 001, sin cambios de código: `CutMotion` interpola linealmente la empuñadura y la punta entre `start` (*Sodose*) y `end` (impacto), con `mirroredBySide: true`. La subida (`guard → stance`), el corte (`stance → cutEnd`) y el regreso (`cutEnd → guard`) salen de `OpponentMotion`, igual que en el frontal.
- **Rationale**: Visto de frente, un corte horizontal que viene hacia el usuario se lee como una hoja que sale larga del costado y se acorta al girar hacia él, hasta quedar en escorzo en el impacto. La interpolación lineal produce exactamente eso: la punta avanza en horizontal desde fuera del cuerpo hacia el centro y la hoja visible se acorta. Se comprobó con un **prototipo** (posiciones de R2 dibujadas con el `OpponentPainter` actual, 2026-11-04): *Sodose* se ve a un costado, el corte se acorta hacia el usuario, el impacto muestra la punta vista de frente y el lado rojo es el reflejo exacto del azul. No hizo falta tocar ningún archivo de `lib/`.
- **Alternatives considered**:
  - Trayectoria en arco o con fotogramas intermedios (p. ej. un barrido que cruza todo el frente). Requiere ampliar `CutMotion`, lo que es código nuevo en el dominio y la presentación y entra en tensión con el Principio III. Se rechaza: la interpolación lineal ya se lee como corte horizontal.
  - Terminar el corte con la hoja extendida hacia el lado contrario (después de cruzar). Así el corte ya habría pasado del usuario, en lugar de llegarle; contradice "llega por el lado de la defensa" (FR-008) y el criterio del frontal, que termina en el impacto.

## R2. Posiciones del sable

- **Decision**: Coordenadas de la 001 (origen en el centro de la figura, unidad = media altura, `x` a la derecha de la pantalla, `y` hacia abajo). Los valores base son para el lado `right` (sable azul) y se reflejan en `x` con el lado `left` (rojo).

  | Postura | `hilt` | `tip` | Lectura |
  |---|---|---|---|
  | Guardia (*Chayôn-se*) | (0, 0.05) | (0, −0.3) | Igual que el frontal: manos al ombligo, punta al usuario |
  | *Sodose* (`cut.start`) | (−0.45, 0.3) | (−1.25, 0.45) | Manos a la cadera del costado izquierdo de la pantalla; hoja hacia afuera y un poco hacia abajo |
  | Impacto (`cut.end`) | (−0.1, −0.05) | (−0.3, −0.1) | Manos frente al pecho; hoja en escorzo hacia la izquierda del usuario, a la altura del torso |

- **Rationale**: La hoja en *Sodose* mide ≈ 0.81 u visibles, así que se ve larga y con el color legible sin necesidad de la punta vista de frente. La punta del corte avanza casi en horizontal (de `y` 0.45 a −0.1) a la altura del torso, como pide FR-008. En el impacto la hoja visible mide ≈ 0.21 u, de modo que aparece la punta vista de frente con su diámetro máximo (FR-009). Todos los valores están en [−2, 2].
- **Alternatives considered**: *Sodose* con la hoja hacia atrás en escorzo fuerte, más fiel a la postura real pero con la hoja casi invisible de frente. Se rechaza por legibilidad: el costado tiene que leerse a 3 m.

## R3. Lado del ataque ↔ costado del corte

- **Decision**: Lado `right` (sable azul, defensa a la izquierda) → *Sodose* y salida del corte en el costado **izquierdo** de la pantalla, sin reflejar. Lado `left` (sable rojo, defensa a la derecha) → valores reflejados, costado **derecho**.
- **Rationale**: El usuario mira la pantalla de frente, así que el lado izquierdo de la pantalla es su izquierda (research R11 de la 001). Un corte que sale del costado izquierdo de la pantalla y avanza hacia el centro llega primero al flanco izquierdo del usuario, que es justo donde está el símbolo de defensa con el sable azul (FR-015 de la 001). La regla de reflejo de la 001 (plan D5: se reflejan `stance` y `cutEnd`, nunca `guard`) ya implementa esto.
- **Alternatives considered**: Ninguna; la decisión de la spec (Q1: A) fija la relación.

## R4. Legibilidad en *Sodose* y en escorzo (FR-009)

- **Decision**: Sin cambios en la presentación. La punta vista de frente de la 001 (plan D2) aparece sola cuando la hoja visible es corta: durante el último tramo del corte y en el impacto. En *Sodose* la hoja es larga y no la necesita.
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

- **Decision**: Sin elementos extra. El frontal se lee como un movimiento vertical desde arriba de la cabeza hacia el centro. El transversal, como un movimiento horizontal desde un costado, a la altura de la cadera y el torso, hacia el centro. Se valida con la prueba manual de quickstart §3.
- **Rationale**: La postura de ataque (sable sobre la cabeza frente a sable al costado) ya diferencia los patrones durante medio tiempo de aviso antes del corte.
- **Alternatives considered**: Mostrar el nombre del patrón durante el ejercicio. Compite con la señal y no lo pide la spec.

## R8. Contrato del catálogo

- **Decision**: `contracts/catalog.schema.json` de la 001 **no cambia**: el patrón transversal usa los mismos campos (`guardTermId`, `stanceTermId`, `cutTermId`, `guard`, `cut` con `mirroredBySide`). Esta spec solo agrega entradas al asset; el contrato de las entradas nuevas está en [contracts/catalog-entries.md](./contracts/catalog-entries.md).
- **Rationale**: Es la prueba concreta del Principio III: un patrón nuevo con un tipo de respuesta existente es solo datos.
