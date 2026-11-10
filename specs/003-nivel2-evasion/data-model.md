# Data Model: Nivel 2, señal de evasión

**Feature**: [spec.md](./spec.md) | **Base**: [data-model de la 001](../001-motor-nivel1-frontal/data-model.md) y [de la 002](../002-patron-transversal/data-model.md)

Solo se describe lo que cambia. Las demás entidades (catálogo, patrón, término, sesión, parámetros, ejercicio, ataque, snapshot, movimiento del oponente) no cambian.

## ResponseType (enum del dominio)

| Valor | Spec | Señal | Lado de la pantalla |
|---|---|---|---|
| `defense` | 001 | Símbolo de sable, blanco | `attack.side.opposite` |
| `evasion` | **003 (nuevo)** | Flecha horizontal del color del sable, apuntando al borde | `attack.side` |

- Es el único tipo nuevo que esta spec agrega al dominio (excepción del Principio III: tipo de señal nuevo).
- En el JSON del catálogo se escribe con su nombre: `"evasion"`.

## Signal (sin cambios de forma)

`Signal { responseType, screenSide }`. Regla de colocación (`SignalPlacement.forAttack`):

| `attack.side` (color) | `defense` → `screenSide` | `evasion` → `screenSide` |
|---|---|---|
| `right` (azul) | `left` | `right` |
| `left` (rojo) | `right` | `left` |

Validaciones (FR-006, FR-009):
- Para un mismo ataque, la señal de evasión y la de defensa quedan siempre en lados opuestos.
- La señal existe desde `signalAt` hasta `cutEndAt` (sin cambios respecto de la 001, FR-016).
- La señal no lleva color: el color de la flecha lo pone la presentación con el `SaberColor` del mismo snapshot (research R3).

## Level: instancia nueva del catálogo

| Campo | Nivel 1 (sin cambios) | **Nivel 2 (nuevo)** |
|---|---|---|
| `id` | `level_1` | `level_2` |
| `order` | 1 | 2 |
| `name` | Nivel 1 | Nivel 2 |
| `responseLabel` | Defensa | Evasión lateral |
| `purpose` | Calentamiento | Calentamiento / base |
| `responseTypes` | `["defense"]` | `["evasion"]` |

Reglas del mapper (de la 001, sin cambios): `id` y `order` únicos, `responseTypes` con al menos un elemento, sin repetidos, y cada nombre debe existir en `ResponseType`.

## Geometría de la flecha (presentación)

No es un dato del catálogo; vive en `SignalPainter`. Medidas en función del tamaño del lienzo (`w × h`) y de la unidad del oponente `u = 0.27 h` (research R4):

| Medida | Valor |
|---|---|
| Alcance del oponente (`opponentClearance`) | 1.45 u desde el centro (≥ mayor `|x|` del catálogo + margen de hoja y contorno) |
| Borde exterior | 4 % del ancho desde el borde de la pantalla |
| Largo `L` | `min(0.36 h, tramo entre el alcance y el borde exterior)`, anclado al borde exterior |
| Punta | `0.42 L` de largo, `0.62 L` de alto |
| Cuerpo | `0.24 L` de alto |
| Centro vertical | `h / 2` |
| Relleno | `AppColors.saberBlue` o `AppColors.saberRed`, según el `SaberColor` del snapshot |
| Contorno | `AppColors.outline`, `kOutlineWidth` |

La flecha de la izquierda es el reflejo exacto en `x` de la de la derecha.
