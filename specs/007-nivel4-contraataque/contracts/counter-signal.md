# Contrato: tipo de respuesta y señal de contraataque

**Spec**: [../spec.md](../spec.md) · **Research**: R1–R6 · **Data model**: §1, §3, §5

## 1. Catálogo (delta sobre `specs/001-motor-nivel1-frontal/contracts/catalog.schema.json`)

`levels[].responseTypes.items.enum` pasa a ser `["defense", "evasion", "counter"]`. El resto del esquema no cambia.

```json
"responseTypes": {
  "type": "array",
  "minItems": 1,
  "uniqueItems": true,
  "items": { "enum": ["defense", "evasion", "counter"] }
}
```

Entrada nueva: ver [data-model §2](../data-model.md#2-nivel-4-catálogo-assetscatalogcatalogjson).

## 2. Dominio

```dart
enum ResponseType { defense, evasion, counter }

abstract final class SignalPlacement {
  static Signal forAttack(Attack attack) => switch (attack.responseType) {
    ResponseType.defense => /* lado contrario al color */,
    ResponseType.evasion => /* lado del color */,
    // Contraataque: del lado del color, como la evasión (Spec 007, FR-008).
    ResponseType.counter => Signal(responseType: attack.responseType, screenSide: attack.side),
  };
}
```

Garantías:
- `ExerciseEngine` no cambia (FR-002).
- Con `level.responseTypes == [counter]`, cada `Attack.responseType == counter` y no se consume sorteo para el tipo.
- Mismo `RandomSource`, mismos parámetros y mismo patrón: los ataques del Nivel 4 son iguales a los del Nivel 2 salvo `responseType`.

## 3. `SignalShapes` (presentación, solo geometría)

```dart
/// Sable visto desde arriba con su eje a [angleDegrees] sobre la horizontal
/// (115 = defensa, 90 = contraataque), ajustado a [box].
static ({Path blade, Path guard, Path grip, Offset bladeBase, Offset bladeTip})
    saber(Rect box, {required double angleDegrees});

/// Mayor caja con la proporción del sable a [angleDegrees] que cabe en [lane] con alto ≤ [maxHeight].
static Rect fitSaber(Rect lane, double maxHeight, {required double angleDegrees});

// Se conservan con la misma salida exacta:
static ... defenseSaber(Rect box) => saber(box, angleDegrees: defenseAngleDegrees);
static Rect fitDefense(Rect lane, double maxHeight) => fitSaber(lane, maxHeight, angleDegrees: defenseAngleDegrees);

static const counterAngleDegrees = 90.0;
```

## 4. `SignalPainter`

- `paint` agrega `case ResponseType.counter: _paintCounter(canvas, size, color);`.
- `_paintCounter` sigue la geometría de [data-model §5](../data-model.md#5-geometría-de-la-señal-de-contraataque-presentación).
- `_paintEvasion` y `_paintDefense` comparten con `_paintCounter` los métodos privados `_paintArrow` y `_paintSaber`, sin cambiar sus operaciones de dibujo.
- Constantes nuevas: `_counterSaberHeightFactor = 1.10` (respecto al alto de la punta), `_counterGapFraction = 0.10`, `_counterMinWidthFactor = 2.24`.

Postcondiciones (las comprueba `signal_painter_test`):

| # | Propiedad | Requisito |
|---|---|---|
| P1 | Ningún pixel no transparente fuera del carril de `signal.screenSide` | FR-010, SC-009 |
| P2 | `Lc ≥ 0.75 · L2` en el mismo lienzo | FR-010 |
| P3 | La caja del sable está del lado al que apunta la flecha (hacia el borde exterior), a ≤ 0.15 `Lc` de la punta | FR-007 |
| P4 | El eje de la hoja es vertical (las columnas de color de la hoja tienen el mismo `x` ± 1 px a lo largo de toda su altura) | FR-007, Clarifications |
| P5 | El centro vertical del sable coincide con el eje de la flecha (± 1 px) | FR-007, Clarifications |
| P6 | Flecha y hoja del color del sable; sin amarillo; el sable rojo es el reflejo exacto del azul | FR-008, FR-009, Spec 004 |
| P7 | La evasión y la defensa producen los mismos pixeles que antes de esta spec | FR-020 |

## 5. Lo que no cambia

`Attack`, `Signal`, `ExerciseEngine`, `StreakSequencer`, `SceneLayout`, `OpponentPainter`, `ExerciseHud`, las voces, los estados, la configuración y `strings_es.dart`.
