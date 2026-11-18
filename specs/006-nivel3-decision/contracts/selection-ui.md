# Contrato: selección con el Nivel 3

**Feature**: [../spec.md](../spec.md) · **Research**: R6, R7 · **Base**: Spec 004, contrato de la selección

## 1. Tarjeta del Nivel 3

| Elemento | Valor |
|---|---|
| Título | `NIVEL 3` (de `level.name`, en mayúsculas) |
| Detalle | `Defensa o evasión lateral — Decisión bajo presión` (`responseLabel — purpose`) |
| Posición | Tercera en la columna NIVEL, según `order` |
| Selección inicial | No: el Nivel 1 sigue preseleccionado |
| Resumen | `Nivel 3 · <Patrón> · <duración>` |

## 2. `LevelIcon`

```dart
LevelIcon({required List<ResponseType> types, required double size});
```

- Caja útil: el ícono menos un margen del 10 % del lado. Se divide en `n = types.length` celdas horizontales iguales, con una separación de 8 % del ancho de la caja entre celdas.
- Cada celda dibuja el glifo de su tipo, en el orden de `types`, ajustado al cuadrado más grande que cabe en ella y centrado:
  - `defense`: el sable de defensa;
  - `evasion`: la flecha con tres líneas de movimiento.
- Color único: `AppColors.textPrimary` (blanco). Sin rojo, azul ni amarillo (Spec 004, regla de color).
- `n = 1`: la imagen es idéntica a la de antes del cambio.

## 3. Densidad de la selección

```dart
enum SelectionDensity { regular, compact }

/// Pura: sin BuildContext.
static SelectionDensity choose({
  required double columnsHeight, // alto disponible para el área de columnas en densidad regular
  required double scale,         // SceneLayout.hudScale
  required int maxCards,         // max(niveles, patrones)
});
```

- `regular` si `maxCards × 104 s + (maxCards − 1) × 14 s + 8 s ≤ columnsHeight`; si no, `compact`.
- `regular` usa las medidas actuales de la Spec 004, sin cambios.
- `compact` usa las medidas en dp de [research R7](../research.md#r7-tarjetas-sin-desplazar-fr-012a-sc-007a): tarjeta de 48 de altura mínima, ícono de 40, título de 16, detalle de 12, separación de 6 y márgenes reducidos.
- El pie (resumen, CONFIGURACIÓN e INICIAR) no cambia con la densidad.
- Red de seguridad: si en `compact` las tarjetas tampoco caben, la columna se desplaza. Con los lienzos de referencia esto no debe ocurrir.

## 4. Lienzos de referencia (SC-007a)

| Nombre | Tamaño lógico | Densidad esperada con 3 niveles | Con 4 niveles |
|---|---|---|---|
| 20:9 | 1778 × 800 | regular | regular |
| 16:9 | 1422 × 800 | regular | regular |
| 16:10 | 1280 × 800 | regular | regular |
| 4:3 | 1067 × 800 | regular | regular |
| 4:3 (Spec 005) | 1024 × 768 | regular | regular |
| 20:9 grande (Spec 005) | 2400 × 1080 | regular | regular |
| Teléfono 20:9 | 889 × 400 | compact | compact |

**En cada lienzo**: todas las tarjetas están completamente dentro de la vista; ninguna se superpone al pie; no hay `Scrollable` con contenido fuera de la vista ni desbordamientos (`FlutterError` de overflow).
