# Contrato: tarjeta, ícono y HUD del Nivel 4

**Spec**: [../spec.md](../spec.md) (FR-014 a FR-018) · **Research**: R7, R8 · **Base**: [Spec 006, selection-ui](../../006-nivel3-decision/contracts/selection-ui.md)

## 1. Tarjeta

| Elemento | Valor |
|---|---|
| Posición | cuarta tarjeta de la columna NIVEL, después del Nivel 3 (orden del catálogo) |
| Título | "Nivel 4" |
| Detalle | "Evasión y contraataque — Combate" |
| Ícono | `LevelIcon(types: [ResponseType.counter])` |
| Preselección | sigue siendo el Nivel 1 |

La pantalla de selección no cambia de código. Con 4 niveles reales, `SelectionDensity` (Spec 006) elige `regular` o `compact` igual que con el catálogo de prueba de 4 niveles.

## 2. `LevelIconPainter`

- `_paintGlyph` agrega `case ResponseType.counter`. El glifo, de izquierda a derecha, tiene:
  - 3 líneas de movimiento (como la evasión);
  - la flecha `SignalShapes.evasionArrow` de largo `L`;
  - una separación de 0.10 `L`;
  - el sable `SignalShapes.saber(…, angleDegrees: 90)` de alto 1.10 × 1.06 `L`.
- `L` = ancho de la caja / 1.80. Todo va centrado en vertical, en `AppColors.textPrimary` y sin brillo.
- Los glifos `defense` y `evasion` no cambian (mismos pixeles).

Postcondiciones (`level_icon_test`):
- I1: sin pixeles rojos, azules ni amarillos.
- I2: todos los pixeles quedan dentro de la caja con el margen del 10 %.
- I3: los íconos de los Niveles 1, 2 y 3 producen los mismos pixeles que antes de esta spec.

## 3. HUD

Durante un ejercicio de Nivel 4: "NIVEL 4" y "Evasión y contraataque", leídos del catálogo (Spec 004, FR-015). No hay código nuevo.

## 4. Lienzos de referencia

Los mismos 7 de la Spec 006 (20:9, 16:9, 16:10, 4:3 y los tres de teléfono, incluido 889 × 400 dp), ahora con el **catálogo real** de 4 niveles. En cada uno:
- las 6 tarjetas se ven completas;
- no hay desplazamiento;
- nada se superpone al resumen, a CONFIGURACIÓN ni a INICIAR (SC-008).
