# Data Model: Patrón transversal

**Feature**: [spec.md](./spec.md) | **Research**: [research.md](./research.md) | **Modelo base**: [data-model.md de la 001](../001-motor-nivel1-frontal/data-model.md)

Esta spec **no agrega ni cambia entidades, campos, enums ni estados**. `Catalog`, `GlossaryTerm`, `Pattern`, `SaberPose`, `CutMotion`, `OpponentMotion`, `ExerciseSnapshot` y la máquina de estados quedan como en el modelo de la 001. Lo único nuevo son **instancias** en el catálogo.

---

## Glosario: términos nuevos

| `id` | `romanization` | `hangul` | `meaning` |
|---|---|---|---|
| `sodose` | `Sodose` | — (sin hangul) | Postura con el sable a un costado del cuerpo |
| `hwengdan_ilgom_begi` | `Hwengdan ilgôm begi` | `횡단일검베기` | Corte transversal |

La romanización y el hangul deben coincidir carácter por carácter con el glosario de la spec (FR-003).

## Patrón: `transversal`

| Campo | Valor | Regla |
|---|---|---|
| `id` | `transversal` | Único |
| `order` | `2` | Después del frontal (`1`); el frontal sigue preseleccionado (FR-004) |
| `name` | `Transversal` | Texto visible |
| `guardTermId` | `chayon_se` | Misma guardia que el frontal (FR-006) |
| `stanceTermId` | `sodose` | Postura de ataque (FR-007) |
| `cutTermId` | `hwengdan_ilgom_begi` | Corte (FR-008) |
| `guard` | `hilt (0, 0.05)`, `tip (0, −0.3)` | Igual que el frontal |
| `cut.start` (*Sodose*) | `hilt (−0.45, 0.3)`, `tip (−1.25, 0.45)` | Costado izquierdo de la pantalla para el lado `right` |
| `cut.end` (impacto) | `hilt (−0.1, −0.05)`, `tip (−0.3, −0.1)` | Hoja en escorzo hacia la izquierda del usuario, a la altura del torso |
| `cut.mirroredBySide` | `true` | Con el lado `left` se invierte `x` de `cut.start` y `cut.end`, nunca de `guard` |

Coordenadas, reflejo e interpolación: los del modelo de la 001 (`SaberPose`, `CutMotion`, `OpponentMotion`). Justificación de los valores: research R2.

## Posturas resultantes por lado

| Lado del ataque | Sable | Defensa | *Sodose* (`hilt` / `tip`) | Impacto (`hilt` / `tip`) |
|---|---|---|---|---|
| `right` | Azul | Izquierda | (−0.45, 0.3) / (−1.25, 0.45) | (−0.1, −0.05) / (−0.3, −0.1) |
| `left` | Rojo | Derecha | (0.45, 0.3) / (1.25, 0.45) | (0.1, −0.05) / (0.3, −0.1) |

Las dos filas son reflejos exactos (FR-011). El corte sale del costado del símbolo de defensa y llega por ese mismo lado (FR-007, FR-008).

## Longitud visible de la hoja (legibilidad, FR-009)

| Instante | Longitud visible | Punta vista de frente (plan D2 de la 001) |
|---|---|---|
| Guardia | ≈ 0.35 u | ≈ 0.22 u (igual que el frontal) |
| *Sodose* | ≈ 0.81 u | No aparece: hoja larga |
| Impacto | ≈ 0.21 u | ≈ 0.30 u (máxima) |

Durante el corte la hoja se acorta de forma continua y la punta crece sin saltos.

## Tiempos

Sin cambios respecto de la 001: subida en la primera mitad del aviso, quieto en *Sodose* la segunda mitad, corte de la duración configurada y regreso de 500 ms (`OpponentMotion`). No dependen del patrón.
