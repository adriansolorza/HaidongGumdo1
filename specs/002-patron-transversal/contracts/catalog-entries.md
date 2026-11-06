# Contrato: entradas nuevas del catálogo

El esquema [catalog.schema.json de la 001](../../001-motor-nivel1-frontal/contracts/catalog.schema.json) **no cambia**. Esta spec agrega las siguientes entradas a `assets/catalog/catalog.json`, que deben validar contra ese esquema y contra las reglas cruzadas del mapper (ids únicos, `order` único, referencias existentes en el glosario).

## `glossary` (agregar después de `chungmyon_begi`)

```json
{ "id": "sodose", "romanization": "Sodose", "meaning": "Postura con el sable a un costado del cuerpo" },
{ "id": "hwengdan_ilgom_begi", "romanization": "Hwengdan ilgôm begi", "hangul": "횡단일검베기", "meaning": "Corte transversal" }
```

`sodose` no lleva `hangul` (FR-003, research R5).

## `patterns` (agregar después de `frontal`)

```json
{
  "id": "transversal",
  "order": 2,
  "name": "Transversal",
  "guardTermId": "chayon_se",
  "stanceTermId": "sodose",
  "cutTermId": "hwengdan_ilgom_begi",
  "guard": { "hilt": [0, 0.05], "tip": [0, -0.3] },
  "cut": {
    "start": { "hilt": [-0.45, 0.1], "tip": [-1.3, -0.1] },
    "end": { "hilt": [0.45, 0.1], "tip": [1.3, -0.1] },
    "mirroredBySide": true
  }
}
```

## Efecto en las pantallas (sin cambios de código)

| Pantalla | Resultado esperado |
|---|---|
| Selección | La lista "Patrón" muestra dos opciones por `order`: "Frontal — Chayôn-se (자연세) → Chochôn-se (초천세) → Chungmyôn begi (정면베기)" (preseleccionado) y "Transversal — Chayôn-se (자연세) → Sodose → Hwengdan ilgôm begi (횡단일검베기)" |
| Ejercicio | Con el Patrón transversal, el oponente usa `pattern.guard`, `pattern.cut.start` (*Sodose*) y `pattern.cut.end` (fin del barrido de 180°, reflejo de *Sodose*), reflejados según el lado, con los tramos de `snapshot.motion` (contrato `ui-screens.md` de la 001) |

`cut.end` debe ser el reflejo exacto de `cut.start` en `x`, y `tip.y` debe ser distinto de `hilt.y` para que la hoja no mida cero a la mitad del barrido (data-model.md). Revisión 2026-11-05: antes, `cut.end` era el impacto frente al flanco del usuario.
