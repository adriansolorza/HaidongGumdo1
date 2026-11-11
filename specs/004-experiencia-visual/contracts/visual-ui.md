# Contrato: escena, señales, HUD y selección

**Feature**: [spec.md](../spec.md) | **Datos**: [data-model.md](../data-model.md) | **Decisiones**: [research.md](../research.md)

La app no expone APIs a otros sistemas. Este contrato fija las interfaces internas de presentación que comparten la pantalla del ejercicio, la de selección y las pruebas, y el único cambio en el catálogo. Los nombres son de código (inglés, Principio IX); los textos visibles, en español.

## 1. Catálogo (`assets/catalog/catalog.json`)

Solo cambian dos valores del Patrón transversal ([data-model §1](../data-model.md#1-catálogo-patrón-transversal-dato)):

```json
"cut": {
  "start": { "hilt": [-0.45, 0.1], "tip": [-1.3, 0.1] },
  "end":   { "hilt": [0.45, 0.1],  "tip": [1.3, 0.1] },
  "mirroredBySide": true
}
```

El esquema, el mapper y sus validaciones no cambian.

## 2. Composición de la pantalla del ejercicio

Capas de abajo arriba dentro de un `LayoutBuilder` que calcula un único `SceneLayout`:

| # | Capa | Tipo | Repinta |
|---|---|---|---|
| 1 | Dojang | `RepaintBoundary(CustomPaint(DojangPainter))` | solo si cambia el `SceneLayout` |
| 2 | Oponente y sable | `CustomPaint(OpponentPainter)` | cada cuadro con cambios en `saberColor` o `motion` |
| 3 | Señal | `CustomPaint(SignalPainter)` si `snapshot.signal != null` | al cambiar señal o color |
| 4 | HUD superior (3 paneles) | widgets | al cambiar `remaining` / sesión |
| 5 | Detener / Volver / Repetir | widgets en `bottomLeftButton` / `bottomRightButton` | al cambiar `status` |
| 6 | Cuenta regresiva | widget centrado | al cambiar `countdownValue` |

Reglas:
- Ningún widget de las capas 4 y 5 se dibuja fuera de la franja `[0, hudBottom]` o de las zonas de botón (FR-017).
- La señal nunca se dibuja fuera de su carril (FR-002).
- Detener, Repetir y Volver conservan el comportamiento de hoy (Spec 001, FR-014, FR-021).

## 3. Interfaces de presentación

Firmas orientativas; los nombres de archivo están en el [plan](../plan.md#source-code-repository-root).

```dart
/// Geometría compartida (data-model §2). Pura, sin Flutter widgets.
final class SceneLayout {
  factory SceneLayout.compute(Size size, Pattern pattern);
  Size get size;
  double get hudScale;
  double get hudBottom;
  double get unit;
  Offset get origin;
  double get reachX;            // en u
  Rect get leftLane;
  Rect get rightLane;
  Rect laneFor(Side screenSide);
  Rect get bottomLeftButton;
  Rect get bottomRightButton;
  Offset toScreen(Point2 p);    // origin + p · unit
}

class DojangPainter extends CustomPainter {
  const DojangPainter({required SceneLayout layout});
}

class OpponentPainter extends CustomPainter {
  const OpponentPainter({
    required SceneLayout layout,
    required SaberColor saberColor,
    required SaberPose guard,
    required CutMotion cut,
    required OpponentMotion motion,
  });
  static double tipDiameter(double visibleLength); // sin cambio
}

class SignalPainter extends CustomPainter {
  const SignalPainter({
    required SceneLayout layout,
    required Signal signal,
    required SaberColor saberColor,
  });
}

/// Formas en caja unitaria, compartidas por SignalPainter y los íconos de nivel.
abstract final class SignalShapes {
  static Path evasionArrow(Rect box);          // apunta a la derecha
  static ({Path blade, Path guard, Path grip}) defenseSaber(Rect box); // punta arriba-derecha
}

class LevelIcon extends StatelessWidget {          // blanco, por ResponseType
  const LevelIcon({required ResponseType type, required double size});
}

class PatternIconPainter extends CustomPainter {   // silueta desde cut.start
  const PatternIconPainter({required Pattern pattern});
}

class SelectionCard extends StatelessWidget {
  const SelectionCard({
    required Widget icon,
    required String title,         // ya en mayúsculas
    required List<String> lines,   // 1 o 2 líneas
    required bool selected,
    required VoidCallback onTap,
  });
}

/// Duración y demás parámetros vigentes (Spec 005 lo reemplazará).
final exerciseParametersProvider = Provider<ExerciseParameters>(
  (ref) => ExerciseParameters.defaults(),
);
```

Cambios en interfaces existentes:
- `OpponentPainter.unitFraction` y `SignalPainter.opponentClearanceUnits` dejan de ser la fuente de la geometría: los reemplazan `SceneLayout.unit` y `SceneLayout.reachX + laneGap`. Las pruebas que los usaban pasan a usar `SceneLayout`.
- `ExerciseController` toma los parámetros de `exerciseParametersProvider` en lugar de llamar a `ExerciseParameters.defaults()` directamente. El valor es el mismo; el comportamiento no cambia.
- `StringsEs`: `start`, `stop`, `repeat`, `back` pasan a `'INICIAR'`, `'DETENER'`, `'REPETIR'`, `'VOLVER'`; `levelHeader`, `patternHeader` a `'NIVEL'`, `'PATRÓN'`; se agregan `appHeader` (`'HAIDONG GUMDO'`) y `appSubtitle` (`'Entrenamiento de reacción · 해동검도'`); `remaining` deja de mostrarse.

## 4. Pantalla de selección

| Zona | Contenido | Comportamiento |
|---|---|---|
| Fondo | `DojangPainter` (sin figura) + capa `selectionDim` | — |
| Encabezado | `appHeader`, `appSubtitle` | — |
| Columna NIVEL | `SelectionCard` por `catalog.levels`, en orden | tocar = `selectLevel` |
| Columna PATRÓN | `SelectionCard` por `catalog.patterns`, en orden | tocar = `selectPattern` |
| Pie | resumen + botón INICIAR | INICIAR habilitado solo con catálogo cargado y sesión; una sola acción abre el ejercicio |
| Carga | indicador blanco + `loadingCatalog` | INICIAR deshabilitado |
| Error | `catalogError` en panel translúcido | INICIAR deshabilitado |

Las tarjetas exponen `Semantics(button: true, selected: …)` con el nombre y el detalle como etiqueta.

## 5. Tema

- `fontFamily: 'Rajdhani'`; pesos 500 y 700 declarados en `pubspec.yaml`.
- `ColorScheme` construido solo con tokens de interfaz (blancos, grises, oscuros); ningún `seedColor` de señal.
- `FilledButton`: píldora (`StadiumBorder`), fondo `primaryButton`, texto `onPrimaryButton`, Rajdhani 700 con espaciado de letras.
- `OutlinedButton`: píldora, fondo `panel`, borde blanco al 55 %, texto blanco.
- Indicador de progreso circular: blanco.

## 6. Pruebas que dependen de este contrato

| Prueba | Comprueba |
|---|---|
| `scene_layout_test.dart` | invariantes de data-model §2 en 20:9, 16:9, 16:10, 4:3 y teléfono |
| `signal_painter_test.dart` | lado, color, dirección, carril (sin píxeles fuera), estela hacia el centro, defensa en diagonal con hoja del color del sable, alto ≥ 0.30 h en 4:3 |
| `opponent_painter_test.dart` | sable horizontal en *Sodose* y en el barrido; disco de la punta de frente a mitad del barrido; sin píxeles sobre `hudBottom`; muestreo de no superposición con la señal (SC-004) |
| `palette_test.dart` | regla de croma de data-model §3; tema sin colores de señal |
| `exercise_screen_test.dart` | textos de los paneles para los 4 combos; segundos y barra con el reloj manual; Detener, Repetir y Volver como hoy |
| `selection_screen_test.dart` | tarjetas en orden, preselección, palomita, resumen, ícono de patrón para un patrón de prueba |
| `catalog_json_mapper_test.dart` | transversal con `tip.y == hilt.y` |
