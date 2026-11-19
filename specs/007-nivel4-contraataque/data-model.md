# Data Model: Nivel 4, evasión con contraataque

**Spec**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

Solo se listan los cambios. Las demás entidades (`Catalog`, `Pattern`, `Session`, `Attack`, `ExerciseParameters`, `StreakSequencer`, configuración guardada) no cambian respecto de las Specs 001 a 006.

## 1. `ResponseType` (dominio, enum)

| Valor | Desde | Señal | Lado de la señal |
|---|---|---|---|
| `defense` | Spec 001 | símbolo de defensa (sable a 115°) | contrario al color |
| `evasion` | Spec 003 | flecha de evasión con estela | del color |
| **`counter`** | **Spec 007** | **flecha de evasión + sable vertical junto a la punta** | **del color** |

- Nombre en el JSON del catálogo: `"counter"`.
- Se actualiza el comentario de `enums.dart`: ya no se habla de "se agregará", sino de que se agregó en la Spec 007 (excepción (a) del Principio III).

## 2. Nivel 4 (catálogo, `assets/catalog/catalog.json`)

```json
{ "id": "level_4", "order": 4, "name": "Nivel 4", "responseLabel": "Evasión y contraataque", "purpose": "Combate", "responseTypes": ["counter"] }
```

| Campo | Valor | Origen |
|---|---|---|
| `id` | `level_4` | patrón de id del catálogo |
| `order` | 4 (después de `level_3`) | FR-001 |
| `name` | "Nivel 4" | FR-001, FR-014 |
| `responseLabel` | "Evasión y contraataque" | FR-001, FR-018 (Clarifications) |
| `purpose` | "Combate" | FR-001 |
| `responseTypes` | `["counter"]` (un solo tipo) | FR-001, FR-004 |

Validación (sin cambios en el mapper): el id es único, el orden es único y ≥ 1, hay al menos un tipo de respuesta, no hay tipos duplicados y no hay tipos desconocidos.

## 3. `Signal` y `SignalPlacement` (dominio)

- `Signal` no cambia: `responseType` y `screenSide`.
- `SignalPlacement.forAttack` agrega una rama:

| `attack.responseType` | `screenSide` |
|---|---|
| `defense` | `attack.side.opposite` |
| `evasion` | `attack.side` |
| **`counter`** | **`attack.side`** |

## 4. `Attack` en el Nivel 4

- `responseType` siempre es `counter` (FR-004). El `StreakSequencer` no consume sorteo con una sola opción (Spec 006, R2).
- Con la misma `RandomSource`, los mismos parámetros y el mismo patrón, la lista de ataques del Nivel 4 es igual a la del Nivel 2 campo por campo, salvo `responseType` (research R3).

## 5. Geometría de la señal de contraataque (presentación)

En unidades de `Lc`, para el lado derecho; el lado izquierdo es su reflejo en `x` (research R4):

| Elemento | Valor |
|---|---|
| `L2` (flecha del Nivel 2 en el mismo lienzo) | `min(0.30 h, lane.width / 1.84)` |
| `Lc` | `min(L2, lane.width / 2.24)`, así que `Lc ≥ 0.82 L2` |
| Flecha | `SignalShapes.evasionArrow`, largo `Lc`, alto de la punta 1.06 `Lc` |
| Sable | `SignalShapes.saber(box, angleDegrees: 90)`, alto ≈ 1.17 `Lc`, ancho ≈ 0.30 `Lc` |
| Separación punta–sable | 0.10 `Lc` |
| Estela | de 0.6 `Lc` a `Lc` |
| Brillo | σ = 0.04 `Lc`, alcance 3σ |
| Centro vertical | eje de la flecha = centro del sable, en `h / 2` y ajustado al carril |

Invariantes que se prueban:
- Todo el dibujo, incluidos el brillo y la estela, queda dentro de `layout.rightLane` o `leftLane`.
- `Lc ≥ 0.75 L2`.
- El sable va del lado de la punta.
- El centro del sable coincide con el eje de la flecha.

## 6. Ícono del Nivel 4 (presentación)

`LevelIcon(types: [counter])`: una celda con 3 líneas de movimiento, la flecha y el sable vertical, en `AppColors.textPrimary` (blanco), sin brillo, de ancho ≈ 1.80 `L` y centrado (research R7).

## 7. Textos visibles

| Lugar | Texto | Fuente |
|---|---|---|
| Tarjeta | "Nivel 4" / "Evasión y contraataque — Combate" | catálogo (`name`, `responseLabel — purpose`) |
| Resumen de la selección | "Nivel 4 · {patrón} · {duración}" | catálogo + configuración |
| HUD | "NIVEL 4" / "Evasión y contraataque" | catálogo |

No hay textos nuevos en `strings_es.dart`.
