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
| `cut.start` (*Sodose*) | `hilt (−0.45, 0.1)`, `tip (−1.3, −0.1)` | Manos a la cintura en el costado izquierdo de la pantalla para el lado `right`; hoja extendida hacia afuera |
| `cut.end` (fin del barrido) | `hilt (0.45, 0.1)`, `tip (1.3, −0.1)` | Reflejo de `cut.start` en `x`: sable extendido hacia el costado contrario, a la misma altura |
| `cut.mirroredBySide` | `true` | Con el lado `left` se invierte `x` de `cut.start` y `cut.end`, nunca de `guard` |

Coordenadas, reflejo e interpolación: los del modelo de la 001 (`SaberPose`, `CutMotion`, `OpponentMotion`). Justificación de los valores: research R2 (revisión 2026-11-05: barrido de 180° a la cintura).

Reglas que deben cumplir estos datos:
- `cut.end` es el reflejo exacto de `cut.start` en `x` (misma `y`).
- `hilt.y` es igual en `cut.start` y `cut.end` (0.1), y lo mismo `tip.y` (−0.1), así que el barrido es horizontal (FR-008).
- `tip.y` ≠ `hilt.y`: a la mitad del barrido la hoja visible mide `|tip.y − hilt.y|` = 0.2 u, nunca cero (FR-009).

## Posturas resultantes por lado

| Lado del ataque | Sable | Defensa | *Sodose* (`hilt` / `tip`) | Fin del barrido (`hilt` / `tip`) |
|---|---|---|---|---|
| `right` | Azul | Izquierda | (−0.45, 0.1) / (−1.3, −0.1) | (0.45, 0.1) / (1.3, −0.1) |
| `left` | Rojo | Derecha | (0.45, 0.1) / (1.3, −0.1) | (−0.45, 0.1) / (−1.3, −0.1) |

Las dos filas son reflejos exactos (FR-011). El barrido sale del costado del símbolo de defensa (y llega primero por ese lado al usuario), pasa frente al oponente y termina en el costado contrario (FR-007, FR-008). Como `cut.end` es el reflejo de `cut.start`, *Sodose* de un lado coincide con el fin del barrido del otro.

## Longitud visible de la hoja (legibilidad, FR-009)

| Instante | Longitud visible | Punta vista de frente (plan D2 de la 001) |
|---|---|---|
| Guardia | ≈ 0.35 u | ≈ 0.22 u (igual que el frontal) |
| *Sodose* (inicio del barrido) | ≈ 0.87 u | No aparece: hoja larga |
| Un cuarto del barrido | ≈ 0.47 u | ≈ 0.16 u |
| Mitad del barrido (frente al oponente) | 0.2 u | 0.3 u (máxima) |
| Fin del barrido | ≈ 0.87 u | No aparece: hoja larga |

Durante el barrido la hoja se acorta de forma continua hasta la mitad y vuelve a alargarse; la punta crece y se encoge sin saltos.

## Tiempos

Sin cambios respecto de la 001: subida en la primera mitad del aviso, quieto en *Sodose* la segunda mitad, corte de la duración configurada y regreso de 500 ms (`OpponentMotion`). No dependen del patrón. La velocidad del corte cubre el barrido completo de 180°: el sable pasa frente al oponente con `cutProgress` = 0.5 (0.25 s con los valores por defecto).
