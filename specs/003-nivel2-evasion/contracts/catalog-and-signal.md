# Contrato: entrada del Nivel 2 y señal de evasión

**Feature**: [spec.md](../spec.md) | **Esquema del catálogo**: el de la [Spec 001](../../001-motor-nivel1-frontal/contracts/) (sin cambios)

## 1. Catálogo (`assets/catalog/catalog.json`)

Se agrega una entrada en `levels`, después de `level_1`. El glosario y `patterns` no cambian.

```json
{ "id": "level_2", "order": 2, "name": "Nivel 2", "responseLabel": "Evasión lateral", "purpose": "Calentamiento / base", "responseTypes": ["evasion"] }
```

- `"evasion"` debe existir como valor de `ResponseType`; si no, el mapper rechaza el catálogo con `CatalogException` ("tipo de respuesta desconocido").
- La selección muestra la entrada como "Nivel 2" con el subtítulo "Evasión lateral — Calentamiento / base".

## 2. Colocación de la señal (`SignalPlacement.forAttack`)

| Entrada | Salida |
|---|---|
| `Attack(side: right, responseType: evasion)` | `Signal(responseType: evasion, screenSide: right)` |
| `Attack(side: left, responseType: evasion)` | `Signal(responseType: evasion, screenSide: left)` |
| `defense` | sin cambios (lado contrario) |

## 3. Dibujo de la señal (`SignalPainter`)

- Constructor: `SignalPainter({required Signal signal, required SaberColor saberColor})`. La pantalla del ejercicio pasa `snapshot.saberColor`, el mismo valor que recibe `OpponentPainter`.
- `defense`: sin cambios (sable blanco en planta); ignora `saberColor`.
- `evasion`: flecha horizontal según [data-model.md](../data-model.md#geometría-de-la-flecha-presentación):
  - en la mitad `signal.screenSide`, con la punta hacia el borde exterior de esa mitad;
  - relleno del color de `saberColor` (`blue` → `AppColors.saberBlue`, `red` → `AppColors.saberRed`) y contorno `AppColors.outline`;
  - ningún píxel a menos de `opponentClearance` (1.45 u) del centro horizontal.
- `shouldRepaint`: cuando cambian `signal` o `saberColor`.
