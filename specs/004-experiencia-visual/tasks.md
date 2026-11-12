---
description: "Task list for Spec 004: Experiencia visual"
---

# Tasks: Experiencia visual ("que enamore")

**Input**: Design documents from `specs/004-experiencia-visual/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/visual-ui.md](./contracts/visual-ui.md), [quickstart.md](./quickstart.md)

**Tests**: Incluidas. El Principio VI las exige y el plan (research R14, contrato §6) las detalla. Se escriben **después del código**, derivadas de los criterios de aceptación. Las pruebas de dominio no se tocan (SC-007).

**Organization**: La Foundational deja lista la base común (tipografía, paleta, tema, textos, `SceneLayout`, dojang, proveedor de parámetros y los painters ya conectados a `SceneLayout` con el dibujo actual). Cada historia reescribe una parte de la presentación y la cierra con sus pruebas y su validación manual.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Puede correr en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: Historia de usuario (US1 escena, US2 señales, US3 HUD, US4 selección)

## Path Conventions

Proyecto Flutter único: `lib/`, `test/`, `assets/` y `docs/` en la raíz del repositorio (estructura de la Spec 001).

## Reglas para todas las tareas

- **No cambiar** nada en `lib/domain/` ni en `lib/data/` (FR-001, research R1). Si una tarea parece requerirlo, detenerse y consultarlo.
- **No agregar paquetes** a `pubspec.yaml` (Principio VII). La única novedad es la sección `fonts:`.
- Rojo, azul y amarillo (`AppColors.saberBlue`, `saberRed`, `saberYellow`) solo en el sable, la punta de frente y las señales (FR-004).
- Medidas: `u` = `SceneLayout.unit`; `s` = `SceneLayout.hudScale`; `h`, `w` = alto y ancho del lienzo (data-model, "Unidades").

---

## Phase 1: Setup

**Purpose**: Línea base y assets de la tipografía.

- [x] T001 Desde la raíz, en la rama `004-experiencia-visual`, ejecutar `flutter analyze` y `flutter test` y confirmar que todo pasa (línea base de las Specs 001 a 003, SC-007). Si algo falla, detenerse y reportarlo.
- [x] T002 [P] Descargar del repositorio oficial de Google Fonts (`https://github.com/google/fonts/tree/main/ofl/rajdhani`) los archivos estáticos `Rajdhani-Medium.ttf` y `Rajdhani-Bold.ttf` y el archivo `OFL.txt`, y guardarlos en `assets/fonts/rajdhani/` con esos nombres (research R2). No descargar otros pesos.
- [x] T003 En `pubspec.yaml`, dentro de `flutter:`, agregar la sección `fonts:` con `family: Rajdhani` y dos entradas: `asset: assets/fonts/rajdhani/Rajdhani-Medium.ttf` con `weight: 500`, y `asset: assets/fonts/rajdhani/Rajdhani-Bold.ttf` con `weight: 700`. No tocar `dependencies` ni `dev_dependencies`. Ejecutar `flutter pub get`. Depende de T002.
- [x] T004 [P] Crear `docs/decisions/0005-tipografia-rajdhani.md` con el formato de `docs/decisions/0004-graficos-custompainter.md`: Estado Aceptada, Fecha 2026-11-10, Spec `specs/004-experiencia-visual` (FR-026), Aprobó: responsable del proyecto. Contexto: estilo "consola actual" de los bocetos, uso sin conexión. Decisión: archivos estáticos 500 y 700 incluidos como asset, sin paquete; hangul y hanja con la fuente del sistema por _fallback_. Alternativas (tabla con pros y contras): paquete `google_fonts`, fuente del sistema (Roboto), incluir además Noto Sans KR (research R2). Consecuencias: licencia SIL OFL 1.1 en `assets/fonts/rajdhani/OFL.txt`; si una plataforma futura no tiene CJK, se reevalúa.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Paleta, tema, textos, geometría compartida, dojang y painters conectados a `SceneLayout`. Todas las historias dependen de esto.

**⚠️ CRITICAL**: T009 a T012 deben terminarse juntos para que compile: cambian los constructores de `OpponentPainter` y `SignalPainter` y sus usos.

- [x] T005 Reescribir `AppColors` en `lib/presentation/theme.dart` por grupos, con los valores exactos de [data-model §3](./data-model.md#3-paleta-presentación) (research R9):
  - Colores de señal **sin cambio de valor**: `saberWhite #FFFFFF`, `saberYellow #FFD400`, `saberBlue #1E6BFF`, `saberRed #FF2D2D`, `outline #000000`.
  - Dojang: `wallTop #aaa598`, `wallBottom #8c887e`, `wood #6a5644`, `woodShadow #574536`, `beam #5b4a3a`, `beamShadow #3f3328`, `baseboard #3d3027`, `floorBack #694322`, `floorFront #96622f`, `floorJoint #5a391c` (70 %), `spotLight #ffe2b0` (38 % → 0 %), `floorShadow #2e1d0d` (55 %), `bannerCloth #2a2b31`, `bannerText #f2efe6`, `selectionDim #0c0e14` (62 %), `skin #f1c9a5`.
  - Figura: `helmetLight #ffffff`, `helmetShade #cdd3de`, `helmetGrille #262833`, `helmetBars #b7bdcb`, `petoLight #f1f3f7`, `petoShade #c2c8d4`, `petoLines #aab1bf`, `sleeveLight #ffffff`, `sleeveShade #d2d8e3`, `hakama #2b2c31`, `hakamaFold #1d1e22`, `belt #15151a`, `glove #1c1c22`, `figureOutline #1a1d2b`, `rimLight #d8d5cc` (70 %), `grip #26201b`, `gripWrap #5c5046`, `tsuba #8f8f96`.
  - Interfaz: `panel rgba(18,20,28,0.74)`, `panelStrong rgba(18,20,28,0.78)`, `panelBorder` blanco 35 %, `panelBorderStrong` blanco 40 %, `buttonBorder` blanco 55 %, `textPrimary #ffffff`, `textSecondary #d6d9e4`, `textTertiary #aeb3c4`, `columnHeader #c9ccd8`, `progressTrack` blanco 22 %, `progressFill #ffffff`, `cardIdle rgba(18,20,28,0.6)`, `cardIdleBorder` blanco 22 %, `cardSelected` blanco 16 %, `cardSelectedBorder #ffffff`, `cardSelectedRing` blanco 12 %, `iconTile` blanco 10 %, `primaryButton #f4f5f8`, `onPrimaryButton #12141c`.
  - Exponer listas estáticas `signalColors`, `dojangColors`, `figureColors`, `interfaceColors` (para la prueba de paleta). Quitar `background #121212` si queda sin uso. Mantener `kOutlineWidth = 4.0` (sable y señales).
- [x] T006 En `buildAppTheme()` de `lib/presentation/theme.dart` (research R9, contrato §5): quitar `ColorScheme.fromSeed(seedColor: AppColors.saberYellow…)` y construir un `ColorScheme.dark` explícito solo con tokens de interfaz (`primary: textPrimary`, `onPrimary: onPrimaryButton`, `surface` oscuro, `secondary`/`tertiary` grises, sin ningún color de señal); `fontFamily: 'Rajdhani'`; `FilledButtonThemeData` píldora (`StadiumBorder`) fondo `primaryButton`, texto `onPrimaryButton`, Rajdhani 700 con `letterSpacing` 3; `OutlinedButtonThemeData` píldora, fondo `panelStrong`, borde `buttonBorder` 1.5, texto blanco 700; `ProgressIndicatorThemeData(color: textPrimary)`; `displayLarge` de la cuenta regresiva Rajdhani 700 tamaño 200 blanco. Depende de T005.
- [x] T007 [P] En `lib/presentation/strings_es.dart`: `start = 'INICIAR'`, `stop = 'DETENER'`, `repeat = 'REPETIR'`, `back = 'VOLVER'`, `levelHeader = 'NIVEL'`, `patternHeader = 'PATRÓN'`; agregar `appHeader = 'HAIDONG GUMDO'` y `appSubtitle = 'Entrenamiento de reacción · 해동검도'`; eliminar `remaining` en T029, cuando el HUD nuevo deje de usarla. No mover nombres de niveles, patrones ni términos aquí (salen del catálogo).
- [x] T008 [P] Crear `lib/presentation/scene/scene_layout.dart` con `final class SceneLayout` según [data-model §2](./data-model.md#2-scenelayout-presentación) y el contrato §3 (research R5):
  - `factory SceneLayout.compute(Size size, Pattern pattern)`; campos `size`, `hudScale`, `hudBottom`, `unit`, `origin`, `reachX`, `leftLane`, `rightLane`, `bottomLeftButton`, `bottomRightButton`; métodos `laneFor(Side screenSide)` y `toScreen(Point2 p) => origin + Offset(p.x * unit, p.y * unit)`; `==`/`hashCode` por `size` y `pattern`.
  - Constantes públicas: `saberExtent = 0.13`, `figureBottom = 1.42`, `floorLimitFraction = 0.965`, `laneGap = 0.02`, `edgeMarginFraction = 0.04`, `minLaneWidthFraction = 0.20`, `hudBandDesignPx = 117`, `hudGapDesignPx = 12`, `designHeight = 800`.
  - `hudScale = clamp(h / 800, 0.7, 1.4)`; `hudBottom = (117 + 12) · s`.
  - `topReach = min(−1.6, menor y de guard.hilt, guard.tip, cut.start.hilt, cut.start.tip, cut.end.hilt, cut.end.tip)`; `reachX = max(1.3, mayor |x| de esos puntos) + saberExtent`.
  - `uV = (0.965 h − hudBottom) / (saberExtent − topReach + figureBottom)`; `uH = (w / 2 − 0.04 w − 0.20 h) / (reachX + laneGap)`; `unit = min(uV, uH)`.
  - `origin = Offset(w / 2, hudBottom + (saberExtent − topReach) · unit)`.
  - `bottomLeftButton = Rect.fromLTWH(36 s, h − (28 + 48) s, 200 s, 48 s)`; `bottomRightButton` = su reflejo. Se calculan antes que los carriles.
  - `rightLane = Rect.fromLTRB(origin.dx + (reachX + laneGap) · unit, hudBottom, w − 0.04 w, bottomLeftButton.top − 12·s)`; `leftLane` = reflejo respecto de `w / 2`.
  - Solo importa `dart:ui`/`flutter/painting` y el dominio (`catalog.dart`, `attack.dart`); sin widgets.
- [x] T009 Crear `lib/presentation/scene/dojang_painter.dart` con `DojangPainter({required SceneLayout layout})` según research R6 y las coordenadas del boceto `docs/design/bocetos/Retro.dc.html` convertidas a `u` desde `origin` (u del boceto = 241 px, origen del boceto (640, 413)): pared degradada `wallTop → wallBottom` desde `y = 0` hasta `origin.dy + 0.527 u`; 2 haces de luz blancos al 7 % y 5 %; viga `beam` en `y −1.266…−1.166 u` con línea `beamShadow`; columnas `wood` en `x ±(1.320…1.494) u` con sombra `woodShadow` en su tercio exterior; estandartes `bannerCloth` de `x ±(1.793…2.125) u`, `y −1.091…0.154 u`, radio 4 · s, con colgadores, y textos 해동검도 (izquierda) y 海東劍道 (derecha) verticales en `bannerText` con `TextPainter` (fuente del sistema, tamaño 0.174 u); zócalo `baseboard` en `y 0.527…0.618 u`; duela degradada `floorBack → floorFront` desde `0.618 u` hasta el borde inferior; juntas `floorJoint` al 70 %, grosor 0.012 u, cada una del punto `(k · 0.332 u, 0.618 u)` al `(k · 0.73 u, 1.606 u)` prolongado, para todos los `k` enteros que cubran el ancho; foco radial `spotLight` centrado en `(0, 1.191 u)` con radios `1.909 u × 0.456 u`; viñeta radial centrada en `(w/2, 0.45 h)`, transparente hasta el 62 % del radio y negro al 50 % en el borde (radio `0.78 · max(w, h)`). Las bandas horizontales van de `x = 0` a `x = w`. `shouldRepaint` solo si cambia `layout`. No dibuja la sombra del oponente (es del `OpponentPainter`).
- [x] T010 En `lib/presentation/exercise/painters/opponent_painter.dart`: agregar `required SceneLayout layout` al constructor; reemplazar `unit = size.height * unitFraction` y `origin` por `layout.unit` y `layout.origin`; eliminar `unitFraction`; incluir `layout` en `shouldRepaint`. Mantener por ahora el dibujo actual (se reescribe en US1). Depende de T008.
- [x] T011 En `lib/presentation/exercise/painters/signal_painter.dart`: agregar `required SceneLayout layout` al constructor; calcular el tramo de la flecha con `layout.laneFor(signal.screenSide)` en lugar de `opponentClearanceUnits`, `OpponentPainter.unitFraction` y `_edgeMarginFraction`; eliminar esas constantes; incluir `layout` en `shouldRepaint`. Mantener por ahora las formas actuales (se reescriben en US2). Depende de T008.
- [x] T012 En `lib/presentation/exercise/exercise_screen.dart`: envolver el `Stack` en un `LayoutBuilder` que calcule `SceneLayout.compute(constraints.biggest, widget.session.pattern)` (memoizado en el `State` por tamaño); capa 1 `RepaintBoundary(child: CustomPaint(painter: DojangPainter(layout: …)))`; pasar `layout` a `OpponentPainter` y `SignalPainter`; quitar `backgroundColor: AppColors.background`. HUD, botones y cuenta regresiva quedan como hoy (se rehacen en US3). Depende de T009, T010 y T011.
- [x] T013 [P] En `lib/presentation/providers.dart`, agregar `final exerciseParametersProvider = Provider<ExerciseParameters>((ref) => ExerciseParameters.defaults());` con doc "Parámetros vigentes; la Spec 005 lo reemplazará por la configuración del usuario" (research R11). En `lib/presentation/exercise/exercise_controller.dart`, reemplazar las dos llamadas a `ExerciseParameters.defaults()` (líneas ~28 y ~42) por `ref.read(exerciseParametersProvider)`. El valor y el comportamiento no cambian.
- [x] T014 Migrar las pruebas existentes a las firmas nuevas, sin cambiar lo que comprueban: en `test/presentation/opponent_painter_test.dart` y `test/presentation/signal_painter_test.dart`, construir los painters con `layout: SceneLayout.compute(size, pattern)` y reemplazar `SignalPainter.opponentClearanceUnits * OpponentPainter.unitFraction * h` por `(layout.reachX + SceneLayout.laneGap) * layout.unit`. Ejecutar `flutter analyze` y `flutter test`: deben pasar (las de presentación pueden necesitar solo este ajuste). Depende de T012.

**Checkpoint**: la app compila y se ve el dojang detrás del oponente y las señales actuales; todas las pruebas pasan.

---

## Phase 3: User Story 1 - Entrenar frente a un oponente en un dojang (Priority: P1) 🎯 MVP

**Goal**: Oponente con equipo de competencia sobre el dojang; sable con brillo, horizontal en el Patrón transversal y con punta de frente a mitad del barrido.

**Independent Test**: Iniciar Nivel 1 y Nivel 2 con los dos patrones y observar de cerca y a 3 m (quickstart §2 pasos 6 y 8; §3 SC-001).

### Implementation for User Story 1

- [x] T015 [P] [US1] En `assets/catalog/catalog.json`, en el patrón `transversal`, cambiar solo `cut.start.tip` de `[-1.3, -0.1]` a `[-1.3, 0.1]` y `cut.end.tip` de `[1.3, -0.1]` a `[1.3, 0.1]` (FR-010, research R3). No tocar nada más del archivo.
- [x] T016 [US1] Reescribir el cuerpo de `OpponentPainter.paint` en `lib/presentation/exercise/painters/opponent_painter.dart` según [data-model §4](./data-model.md#4-figura-del-oponente) (research R7), en este orden y con contorno `figureOutline` de `max(0.0145 u, 2 dp)` (`StrokeJoin.round`):
  - Sombra: elipse `floorShadow` centro `(0, 1.365)`, radios `0.79 × 0.062`.
  - Pies: elipses `skin` en `(±0.38, 1.357)`, radios `0.141 × 0.046`.
  - _Hakama_: polígono `(−0.282, 0.079) (0.282, 0.079) (0.685, 1.336) (0.091, 1.336) (0, 0.651) (−0.091, 1.336) (−0.685, 1.336)`, relleno `hakama`, pliegues `hakamaFold` (de `(∓0.166, 0.162)` a `(∓0.394, 1.307)`), y luz de contorno: trazo `rimLight` de ancho `0.012 u` desplazado hacia dentro del borde exterior.
  - Dobok: trapecio con borde superior curvo, arriba `±0.228` en `y −0.544` (control `(0, −0.61)`), abajo `±0.307` en `y 0.112`, degradado horizontal `sleeveLight → sleeveShade`.
  - Peto: trapecio curvo, arriba `±0.216` en `y −0.485`, abajo `±0.266` en `y 0.021` (control inferior `(0, 0.095)`), degradado `petoLight → petoShade`, ribete interior blanco de `0.010 u` y dos líneas `petoLines` en `y −0.26` y `−0.13`.
  - Cinturón: rectángulo redondeado `belt` `x ±0.324`, `y 0.029…0.137`, radio 0.02, con nudo (dos lazos hacia `y 0.34`) y `rimLight`.
  - Casco: domo `x ±0.2`, `y −1.017…−0.568`, degradado `helmetLight → helmetShade`; rejilla rectángulo redondeado `helmetGrille` `x ±0.112`, `y −0.867…−0.643`, con 3 barras verticales y 2 horizontales `helmetBars` de `0.010 u`.
  - Brazos (dependen de la postura, como hoy): trazo de cada hombro `(±0.20, −0.49)` a `hilt`, ancho `0.137 u` con contorno, relleno `sleeveLight`; codera elipse `sleeveLight` de radios `0.09 × 0.105` en el punto medio del brazo.
  - Luego el sable (T017) y al final los guantes: círculo `glove` radio `0.087` en `hilt` con `rimLight`. Si el largo visible < 0.05 u, el disco de la punta (T017) se dibuja **después** de los guantes.
  - El cuerpo no se refleja con el lado; solo brazos, guantes y sable siguen `motion` (Out of Scope).
- [x] T017 [US1] En el mismo archivo, implementar el dibujo del sable según [data-model §5](./data-model.md#5-sable) (research R4, R8), con `hilt`/`tip` interpolados como hoy y `L` = largo visible:
  1. Brillo: trazo `gripEnd → tip` ancho `0.11 u`, color del sable con opacidad 0.6, `MaskFilter.blur(BlurStyle.normal, 0.025 u)`, extremo redondo.
  2. Contorno de hoja: ancho `0.09 u + 2 · kOutlineWidth`, `AppColors.outline`.
  3. Hoja: ancho `0.09 u`, color del sable (`saberWhite/Yellow/Blue/Red`), extremo redondo.
  4. Reflejo: trazo blanco al 55 % ancho `0.02 u`, desplazado `−0.02 u` en la normal, del 5 % al 95 % de la hoja.
  5. Empuñadura de `hilt` a `gripEnd = hilt + 0.23 · (tip − hilt)`, ancho `0.07 u`, `grip` con contorno y 3 marcas `gripWrap`; tsuba elipse `tsuba` perpendicular a la hoja en `gripEnd`, radios `0.03 × 0.095 u`, contorno `figureOutline`.
  6. Punta de frente: `diameter = tipDiameter(L) · u` (función sin cambios: "0 con hoja ≥ 0.8 u; 0.3 u con hoja ≤ 0.2 u"); si `diameter > 0.09 u`, disco en `tip` con brillo (mismo blur), relleno del color, contorno `outline` de `kOutlineWidth` y reflejo blanco al 55 % en su cuarto superior.
  - Con `L < 0.05 u` no dibujar empuñadura, tsuba, hoja ni reflejo: solo el disco (sobre los guantes, ver T016).
  - Ningún otro elemento de la figura usa colores de señal (FR-004).
- [x] T018 [P] [US1] Actualizar `test/data/catalog_json_mapper_test.dart`, grupo "Patrón transversal (Spec 002)": en el `expect` de `transversal.cut` usar `tip: Point2(-1.3, 0.1)` y `tip: Point2(1.3, 0.1)`; reemplazar en la prueba (e) la comprobación `(start.tip.y - start.hilt.y).abs() >= 0.2` por `expect(start.tip.y, start.hilt.y)` y `expect(end.tip.y, end.hilt.y)` con el título "(e) reglas del barrido: hoja horizontal y reflejo exacto (Spec 004, FR-010)". Las pruebas (a)–(d) no cambian.
- [x] T019 [US1] Actualizar y ampliar `test/presentation/opponent_painter_test.dart` (depende de T016, T017):
  - En "tipDiameter: 0 en los extremos…": `startLength`/`endLength` ≈ `0.85`, `midLength` = `0` y `tipDiameter(midLength)` = `0.3`.
  - Nueva: con `still(stance, side)` y `still(cutEnd, side)` del transversal, los píxeles del color del sable forman una franja horizontal (alto de la franja ≤ `0.09 u + 2·kOutlineWidth + 2` px fuera del brillo, centrada en `layout.toScreen(Point2(0, 0.1)).dy` ± 2 px) (FR-010, US1-4).
  - Nueva: con `halfSweep(side)` hay un disco del color del sable de diámetro ≥ `0.3 u − 2` px centrado en `layout.toScreen(Point2(0, 0.1))`, para azul y rojo (FR-011, US1-5).
  - Nueva: en cada postura y tramo de los dos patrones y lados, en 1600×720 (20:9), 1600×900 (16:9), 1440×900 (16:10) y 1200×900 (4:3), ningún píxel pintado (alfa > 0) tiene `y < layout.hudBottom` (FR-017, caso límite _Chochôn-se_).
  - Nueva (FR-004, US1-3): pintar con motion `atGuard` y sable blanco, leer con `toByteData(format: ImageByteFormat.rawStraightRgba)` y considerar solo los píxeles con alfa ≥ 128. Ninguno puede tener croma > 0.10, salvo que su tono HSV esté entre 15° y 40° y su croma sea ≤ 0.32 (familia de `skin` y `floorShadow`, incluidas sus mezclas con el contorno). Los valores de la paleta se comprueban por separado en T038.
  - Conservar las pruebas de reflejo y de "pinta sin lanzar".
- [x] T020 [P] [US1] Crear `test/presentation/scene_layout_test.dart` (depende de T008), con el catálogo real (`frontal` y `transversal`) y los lienzos 1778×800 (20:9), 1422×800 (16:9), 1280×800 (16:10), 1067×800 (4:3) y 889×400 (teléfono):
  - Para 1280×800 y frontal: `hudScale == 1`, `unit ≈ 204.1 ± 0.5`, `origin.dy ≈ 482 ± 1` (data-model, valores de referencia).
  - Para 889×400: `hudScale == 0.7`.
  - Toda postura (`guard`, `cut.start`, `cut.end`) con `y − saberExtent` queda en `≥ hudBottom` y la figura (`figureBottom`) en `≤ 0.965 h`.
  - `rightLane.left ≥ origin.dx + reachX · unit` y `leftLane.right ≤ origin.dx − reachX · unit`; `rightLane.right == 0.96 w`; ancho del carril ≥ `0.20 h`.
  - `bottomLeftButton` y `bottomRightButton` no se cruzan con el rectángulo de la figura `x ±0.70 u`, `y −1.03…1.42 u`.
  - `leftLane` y `rightLane` no se cruzan con `bottomLeftButton` ni con `bottomRightButton`, y su alto es ≥ `0.45 h + 2·(3 · 0.009 h)` (cabe la defensa más alta con su brillo) (FR-017).
  - Un patrón de prueba con `tip y = −1.9` produce `unit` menor que el frontal y sigue cumpliendo las invariantes (Principio III).
  - Dojang (FR-007): pintar `DojangPainter(layout)` en los cinco lienzos y comprobar que **todos** los píxeles tienen alfa 255 (sin franjas). Para comprobar que no se deforma: el píxel `(w/2, layout.toScreen(Point2(0, 0.57)).dy)` tiene el color `baseboard` (±3 por canal) y el píxel `(w/2, layout.toScreen(Point2(0, 0.40)).dy)` está dentro del degradado de la pared (`wallTop`…`wallBottom`), en todas las proporciones.
- [x] T021 [US1] Ejecutar `flutter analyze` y `flutter test`. Luego validación manual en el dispositivo (quickstart §2 pasos 6 y 8, parte del oponente y el sable; caso límite "Sable blanco sobre fondo claro"): oponente con equipo claro y _hakama_ oscura, piernas distinguibles de la duela y del zócalo a 3 m, sable horizontal en _Sodose_ y en el barrido, disco de la punta de frente visible. Si las piernas no se distinguen, subir la opacidad de `rimLight` (research R7); si el disco no se lee, subir el 0.3 de `tipDiameter` (research R4).

**Checkpoint**: Escena del ejercicio nueva con las señales y el HUD anteriores; MVP visual.

---

## Phase 4: User Story 2 - Leer señales más llamativas (Priority: P2)

**Goal**: Flecha corta y gruesa con estela y brillo; símbolo de defensa en diagonal con hoja del color del sable; ambas dentro de su carril.

**Independent Test**: Nivel 1 y Nivel 2 con los dos patrones: forma, color, lado, y que la señal no se cruza con el sable (quickstart §2 pasos 6 y 8; §3 SC-001, SC-002).

### Implementation for User Story 2

- [x] T022 [P] [US2] Crear `lib/presentation/exercise/painters/signal_shapes.dart` con `abstract final class SignalShapes` (contrato §3, data-model §6):
  - `static Path evasionArrow(Rect box)`: flecha apuntando a la derecha que ocupa `box` (alto = `box.height`), con punta de largo `0.54 L` y alto `1.06 L`, cuerpo de largo `0.46 L` y alto `0.46 L`, donde `L = box.width` y `box.height = 1.06 L`.
  - `static ({Path blade, Path guard, Path grip}) defenseSaber(Rect box)`: sable con eje a **65° sobre la horizontal**, punta arriba a la derecha, ajustado a `box`; hoja 70 % del largo terminada en punta, ancho `0.55 ×` el de la empuñadura; guarda barra perpendicular de ancho `0.26` del largo; empuñadura 26 % del largo, ancho `0.09 ×` largo.
  - `static Rect fitDefense(Rect lane, double maxHeight)`: mayor caja con la proporción del símbolo que cabe en `lane` con alto ≤ `maxHeight`.
  - Sin colores ni `Canvas`: solo geometría.
- [x] T023 [US2] Reescribir `SignalPainter` en `lib/presentation/exercise/painters/signal_painter.dart` con `SignalShapes` (research R10, data-model §6). Construir la versión derecha y reflejar en `x` respecto de `w / 2` para `Side.left`. Centro vertical `h / 2`. `lane = layout.laneFor(signal.screenSide)`. Color: `saberBlue` o `saberRed` según `saberColor`; con `white`/`yellow` `assert(false)` y no dibujar.
  - Evasión: `glowExtent = 3 · 0.04 L`; `L = min(0.30 h, (lane.width − 2·glowExtent) / 1.6)`; vértice de la punta en `lane.right − glowExtent`; capas: estela (trapecio desde la cola hacia el centro, largo `min(1.0 L, espacio hasta lane.left + glowExtent)`, alto `0.46 L` en la cola → `0.84 · 0.46 L` en el extremo, degradado lineal del color 85 % en la cola → 0 % hacia el centro), 2 líneas de movimiento (trapecios de alto `0.04 L`, `0.75` del largo de la estela, arriba y abajo del cuerpo, mismo degradado al 70 %), brillo (la forma con el color al 60 % y `MaskFilter.blur(normal, 0.04 L)`), relleno, contorno `outline` de `1.5 · kOutlineWidth` con `StrokeJoin.round`, reflejo blanco al 50 % de ancho `0.035 L` sobre el borde superior del cuerpo y de la punta.
  - Defensa: `σDef = 0.009 h`, `glowExtentDef = 3 · σDef`; `box = SignalShapes.fitDefense(lane.deflate(glowExtentDef), 0.45 h − 2 · glowExtentDef)`, centrada en el carril (en `y = h / 2`, sin salir de `lane`); brillo de la hoja con `MaskFilter.blur(normal, σDef)`; hoja del **color del sable** con brillo y reflejo blanco al 55 %; guarda `AppColors.tsuba`; empuñadura `AppColors.grip`; contorno `outline` de `kOutlineWidth` sobre todo el símbolo (FR-014; confirmado en plan D9). Reflejada para la izquierda, la punta queda arriba y hacia el borde exterior.
  - Ningún píxel (incluidos brillo y estela) fuera de `lane` (FR-002). Eliminar `bladeToGripWidth`, `_heightFraction` y el resto de la geometría anterior; actualizar el doc de la clase (Specs 001, 003 y 004).
- [x] T024 [US2] Reescribir `test/presentation/signal_painter_test.dart` para las formas nuevas conservando lado, color, dirección y espacio libre (Assumptions de la spec), en 20:9, 16:9, 16:10 y 4:3 (depende de T023):
  - Evasión: en su mitad; ningún píxel con alfa > 0 fuera de `lane`; la punta (columna extrema con color opaco) está del lado del borde exterior; la estela (píxeles semitransparentes del color) queda del lado del centro respecto del cuerpo; relleno del color del sable y sin el otro color; izquierda es el reflejo de la derecha.
  - Defensa: lado de la Spec 001 (azul → izquierda, rojo → derecha); ningún píxel fuera de `lane`; hay píxeles del color del sable (hoja) y del gris `tsuba`; ninguno del otro color de señal; el alto de la caja pintada es ≥ `0.30 h` en 4:3 (si no, subir el ángulo en `SignalShapes`, research R10); el eje es diagonal (la caja pintada tiene ancho y alto ≥ 0.25 × su diagonal).
  - Reemplazar el grupo "defensa sin cambios (FR-012)" por "defensa del color del sable (Spec 004, FR-014)".
  - Mantener `shouldRepaint` (agregar `layout`).
  - Grupo "alcance con el catálogo real" (SC-004): para cada patrón, lado, color y tramo (`atGuard`, guard→stance 0.5, `stance`, mitad del barrido, `cutEnd`, cutEnd→guard 0.5), pintar oponente y señal en lienzos separados con el mismo `SceneLayout` y comprobar que ningún píxel tiene alfa > 0 en los dos.
  - Ningún píxel de la señal con alfa > 2 cae dentro de `layout.bottomLeftButton` o `layout.bottomRightButton` (FR-017).
- [x] T025 [P] [US2] Ejecutar `flutter test` y validación manual (quickstart §2 pasos 6 y 8, parte de señales; caso límite "Flecha azul sobre la pared"): flecha corta con estela del color del sable, del lado y dirección de la Spec 003; símbolo de defensa en diagonal del color del sable, del lado de la Spec 001; ninguna señal toca el sable al final del barrido.

**Checkpoint**: Escena y señales nuevas; HUD anterior.

---

## Phase 5: User Story 3 - Seguir el ejercicio de un vistazo (Priority: P3)

**Goal**: Paneles translúcidos con nivel, segundos + barra y patrón; Detener, Repetir, Volver en píldora; cuenta regresiva con contorno.

**Independent Test**: Iniciar cada combinación y comprobar paneles, avance de segundos y barra, y que Detener, Repetir y Volver funcionan igual (quickstart §2 pasos 4, 5, 7 y 9).

### Implementation for User Story 3

- [x] T026 [P] [US3] Crear `lib/presentation/exercise/widgets/hud_panel.dart` con `HudPanel({required double scale, required Widget child, bool strong = false, CrossAxisAlignment alignment})`: `DecoratedBox` con fondo `panel` (`panelStrong` si `strong`), borde `panelBorder` (`panelBorderStrong` si `strong`) de `1.5 · scale`, radio `14 · scale` (`18 · scale` si `strong`), padding `10·s` vertical y `22·s` horizontal. Sin `BackdropFilter` (research R11, R13).
- [x] T027 [P] [US3] Crear `lib/presentation/exercise/widgets/countdown_text.dart` con `CountdownText({required int value})`: `Stack` de dos `Text('$value')` con `displayLarge` del tema (Rajdhani 700, 200): detrás, `foreground` de trazo `AppColors.outline` ancho 10; delante, relleno `textPrimary` (FR-018).
- [x] T028 [US3] Crear `lib/presentation/exercise/widgets/exercise_hud.dart` con `ExerciseHud({required SceneLayout layout, required Session session, required Catalog catalog})` como `ConsumerWidget` que observa `exerciseControllerProvider.select((s) => s.remaining)` y lee `exerciseParametersProvider` (data-model §7, research R11):
  - Izquierda (`left: 36·s`, `top: 24·s`): `HudPanel` con `session.level.name.toUpperCase()` (700, `30·s`, `letterSpacing 2·s`) y `session.level.responseLabel` (500, `16·s`, `textSecondary`).
  - Centro (`top: 18·s`, centrado, ancho `150·s`, `strong: true`): segundos `ceil(remaining.inMilliseconds / 1000)` (700, `64·s`) y barra de alto `6·s`, radio `3·s`, fondo `progressTrack` y relleno `progressFill` con `FractionallySizedBox(widthFactor: clamp(1 − remaining / parameters.duration, 0, 1))`.
  - Derecha (`right: 36·s`, `top: 24·s`, alineado a la derecha): `session.pattern.name.toUpperCase()` y `"${termLabel(stance)} → ${termLabel(cut)}"` con `termLabel(t) = t.hangul == null ? t.romanization : "${t.romanization} ${t.hangul}"` (términos con `catalog.term(id)`).
  - Paneles laterales en `FittedBox(fit: BoxFit.scaleDown)` con ancho máximo `(w − 150·s) / 2 − 36·s − 16·s`; todo el HUD superior dentro de `y ≤ layout.hudBottom` (FR-017).
  - `ExerciseScreen` necesita el catálogo: leerlo con `ref.watch(catalogProvider).requireValue` (ya está cargado al iniciar).
- [x] T029 [US3] En `lib/presentation/exercise/exercise_screen.dart` (depende de T026–T028): reemplazar el texto "Restante" por `ExerciseHud`; Detener en `Positioned.fromRect(layout.bottomLeftButton)` como `OutlinedButton` del tema (se alinea a la izquierda, alto `48·s`, texto `StringsEs.stop`, Rajdhani 700 `20·s`, `letterSpacing 3·s`), en los mismos estados que hoy (`_isActive`); con `finished`, Volver (`OutlinedButton`, `StringsEs.back`) en `bottomLeftButton` y Repetir (`FilledButton`, `StringsEs.repeat`) en `bottomRightButton` alineado a la derecha (plan D10); cuenta regresiva con `CountdownText`. Mismos callbacks que hoy (`_cancelAndLeave`, `repeat()`, `Navigator.pop`). Sin `SafeArea` que mueva los botones fuera de sus rectángulos (usar los márgenes de `SceneLayout`). Eliminar `StringsEs.remaining` de `lib/presentation/strings_es.dart` (T007).
- [x] T030 [US3] Ampliar `test/presentation/exercise_screen_test.dart` (depende de T029):
  - Los finders que usan `StringsEs.*` no cambian. Los que buscan nombres del catálogo en la selección se ajustan en T036, cuando la selección pasa a mayúsculas.
  - Nueva, para los 4 combos: textos `NIVEL 1`/`Defensa` o `NIVEL 2`/`Evasión lateral`, y `FRONTAL` + `Chochôn-se 초천세 → Chungmyôn begi 정면베기` o `TRANSVERSAL` + `Sodose → Hwengdan ilgôm begi 횡단일검베기` (US3-1, FR-015).
  - Nueva: con el reloj manual, los segundos bajan y el `widthFactor` de la barra es 0 durante la cuenta regresiva, ≈ 0.5 a mitad de la duración y 1 al terminar (US3-2).
  - Nueva: `tester.getRect` de los tres paneles tiene `bottom ≤ layout.hudBottom`; Detener, Volver y Repetir quedan dentro de `bottomLeftButton`/`bottomRightButton` (FR-017).
  - Las pruebas de Detener, Repetir, Volver y la cuenta 3, 2, 1 siguen pasando sin cambiar sus expectativas.
- [x] T031 [P] [US3] Validación manual (quickstart §2 pasos 4, 5, 7 y 9): números de la cuenta legibles a 3 m sobre el dojang, paneles sin tapar el sable en _Chochôn-se_, Repetir y Volver en píldora y funcionando igual.

**Checkpoint**: Pantalla del ejercicio completa.

---

## Phase 6: User Story 4 - Elegir la sesión en una pantalla atractiva (Priority: P4)

**Goal**: Selección con dojang oscurecido, encabezado, tarjetas con íconos generados, resumen e INICIAR blanco.

**Independent Test**: Abrir la app, cambiar nivel y patrón, comprobar selección y resumen, e iniciar (quickstart §2 pasos 1–3).

### Implementation for User Story 4

- [x] T032 [P] [US4] Crear `lib/presentation/selection/level_icon.dart` con `LevelIcon({required ResponseType type, required double size})`: `CustomPaint` que dibuja en blanco, sin brillo ni estela de color, la forma de `SignalShapes` de ese tipo (`evasion` → flecha a la derecha con 3 líneas de movimiento blancas a su izquierda; `defense` → sable en diagonal relleno blanco), centrada en la caja con margen del 10 % (`switch` exhaustivo sobre `ResponseType`; data-model §6 "Íconos de nivel").
- [x] T033 [P] [US4] Crear `lib/presentation/selection/pattern_icon_painter.dart` con `PatternIconPainter({required Pattern pattern})` (data-model §8, FR-022): puntos fijos cabeza `(0, −0.8)` (círculo blanco relleno, radio 0.2), tronco `(0, −0.55)…(0, 0.1)`, piernas de `(0, 0.1)` a `(±0.3, 1.3)`, hombros `(±0.2, −0.49)`; brazos de los hombros a `pattern.cut.start.hilt`; sable de `cut.start.hilt` a `cut.start.tip` (trazo más fino). Calcular la caja de todos los puntos, escalar uniformemente para que quepa en el lienzo con 10 % de margen y centrar. Trazos blancos de `0.055 ×` el lado del lienzo, extremos redondos. Sin lógica por `pattern.id`.
- [x] T034 [P] [US4] Crear `lib/presentation/selection/selection_card.dart` con `SelectionCard({required Widget icon, required String title, required List<String> lines, required bool selected, required VoidCallback onTap, required double scale})` (contrato §3, research R12): `Semantics(button: true, selected: selected)`; `InkWell` con radio `18·s` y `splashColor` blanco al 12 %; alto mínimo `104·s`; padding `14·s × 20·s`; fondo `cardIdle` y borde `cardIdleBorder` de `2·s`, o seleccionada: fondo `cardSelected`, borde `cardSelectedBorder`, anillo exterior `cardSelectedRing` de `4·s`; caja del ícono `72·s` con fondo `iconTile` y radio `14·s` (ícono `56·s`); título 700 `28·s` `letterSpacing 2·s`; primera línea 500 `17·s` `textSecondary`; segunda línea 500 `15·s` `textTertiary`; palomita: círculo blanco de `30·s` con check `#12141c` solo si `selected`. Nada amarillo (FR-023).
- [x] T035 [US4] Reescribir `lib/presentation/selection/selection_screen.dart` (depende de T032–T034; research R12, contrato §4):
  - Fondo: `CustomPaint(DojangPainter(layout: SceneLayout.compute(size, catalog?.patterns.first ?? patrón neutro fijo)))` + capa `selectionDim`. Para el estado de carga/error usar un `Pattern` constante de presentación con las posturas del frontal (solo para la geometría del fondo).
  - Padding `40·s / 56·s / 36·s`; encabezado `StringsEs.appHeader` (700, `46·s`, `letterSpacing 6·s`) y `appSubtitle` (500, `20·s`, `textSecondary`).
  - Dos columnas separadas `40·s`, cabeceras `StringsEs.levelHeader` / `patternHeader` (700, `18·s`, `letterSpacing 4·s`, `columnHeader`), cada una un `ListView` con `SelectionCard` separadas `14·s`, en el orden del catálogo:
    - Nivel: `icon: LevelIcon(type: level.responseTypes.first)`, `title: level.name.toUpperCase()`, `lines: ['${level.responseLabel} — ${level.purpose}']` (FR-021: "respuesta — propósito"), `onTap: selectLevel`.
    - Patrón: `icon: CustomPaint(PatternIconPainter(pattern))`, `title: pattern.name.toUpperCase()`, `lines: [romanización de guardia → postura → corte, hangul de los términos que lo tienen unidos por ' → ']`; si ningún término tiene hangul, solo una línea (caso límite "Términos sin hangul").
  - Pie: resumen `'${level.name} · ${pattern.name} · ${ref.watch(exerciseParametersProvider).duration.inSeconds} s'` (500, `20·s`) e INICIAR (`FilledButton` del tema, ancho mínimo `360·s`, alto `64·s`, 700 `30·s`, `letterSpacing 6·s`, sombra negra 35 %); `onPressed` igual que hoy (`null` sin catálogo o sin sesión: carga y error) (FR-024, FR-025).
  - Carga: `CircularProgressIndicator` (blanco por el tema) y `StringsEs.loadingCatalog`; error: `StringsEs.catalogError` en `HudPanel`.
  - `_start` no cambia (una sola acción, SC-008).
- [x] T036 [US4] Actualizar `test/presentation/selection_screen_test.dart` (depende de T035):
  - Finders: `ListTile` → `SelectionCard`; títulos en mayúsculas (`'LEVEL 1'`, etc., con el catálogo de prueba); la línea de patrón pasa del formato `'Guard (다) → Stance A (가) → Cut A (나)'` a dos líneas: `'Guard → Stance A → Cut A'` y `'다 → 가 → 나'`; para el patrón sin hangul en postura y corte: `'Guard → Stance B → Cut B'` y `'다'`. El detalle de nivel `'Response 1 — Purpose 1'` no cambia.
  - Nueva: la tarjeta del primer nivel y la del primer patrón tienen `selected: true` y muestran la palomita; al tocar otra, cambia (US4-1, US4-4).
  - Nueva: el resumen muestra `'Nivel 2 · Transversal · 30 s'` con el catálogo real y Nivel 2 + Transversal elegidos; INICIAR abre `ExerciseScreen` con esa sesión en una acción (US4-5, SC-008).
  - Nueva: con un catálogo de prueba que tiene un patrón que no existe en el real (p. ej. `cut.start` con el sable a la derecha), su tarjeta tiene un `CustomPaint` con `PatternIconPainter` y pinta píxeles blancos (FR-022, caso límite "Catálogo con un nivel o patrón nuevo").
  - Carga y error: INICIAR deshabilitado (`onPressed == null`) (FR-025).
  - En `test/presentation/exercise_screen_test.dart`, ajustar los finders de la selección a los títulos en mayúsculas: el helper que hace `tester.tap(find.text(level))` / `find.text(pattern)` pasa a `find.text(level.toUpperCase())` / `find.text(pattern.toUpperCase())`, y los literales `'Frontal'` → `'FRONTAL'` y `'Nivel 1'` → `'NIVEL 1'`. No cambia ninguna expectativa sobre el ejercicio.
- [x] T037 [P] [US4] Validación manual (quickstart §2 pasos 1–3), en modo avión: Rajdhani visible, hangul sin cuadros vacíos, palomita sin amarillo, resumen correcto.

**Checkpoint**: Las dos pantallas con el estilo nuevo.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T038 [P] Crear `test/presentation/palette_test.dart` (research R9, data-model §3): `chroma(c) = (max(r,g,b) − min(r,g,b)) / 255`; todo color de `AppColors.interfaceColors` y `AppColors.figureColors` tiene croma ≤ 0.10 (sin contar alfa); todo color de `AppColors.dojangColors` tiene croma ≤ 0.45; `saberBlue`, `saberRed` y `saberYellow` no aparecen en esas listas; y `buildAppTheme().colorScheme` (`primary`, `secondary`, `tertiary`, `surface`, `onSurface`, `onPrimary`, `outline`) no usa ningún color con croma > 0.10 (FR-004, FR-005).
- [ ] T039 [P] Comprobar alcance del diff (quickstart §1): `git diff --stat main -- lib/domain lib/data` vacío; `git diff main -- assets/catalog/catalog.json` solo con las dos puntas del transversal; `git diff main -- pubspec.yaml` solo con la sección `fonts:`. Si algo más cambió, revertirlo o justificarlo.
- [ ] T040 Ejecutar `flutter analyze` y `flutter test` completos: todo verde, y las pruebas de `test/domain/` sin cambios respecto de `main` (`git diff --stat main -- test/domain` vacío) (SC-007).
- [ ] T041 Medición de tiempos en el dispositivo de referencia (quickstart §3, "Tiempos"): grabar un ejercicio a 60 fps y medir aviso, corte e intervalo con el método de la Spec 001; desvío < 50 ms y sin saltos (SC-006). Si hay saltos, aplicar research R13 (perfilar con DevTools; pre-renderizar el brillo si es la causa).Pospuesta: validación en dojang
- [ ] T042 Pruebas con personas a 3 m (quickstart §3): SC-001 y SC-002 (3 observadores, 4 combos), SC-003 (regla de color en las dos pantallas), SC-005 (5 practicantes, app nueva y anterior lado a lado) y SC-008. Registrar resultados en la descripción del PR. Si un elemento del dojang o los pies se nombran rojo o amarillo, ajustar ese token (research R7, R9) y repetir SC-003.Pospuesta: validación en dojang
- [ ] T043 Abrir el PR de `004-experiencia-visual` a `main` con Conventional Commits (p. ej. `feat: add dojang scene and opponent gear`, `feat: redesign signals with glow and trail`, `feat: add exercise hud panels`, `feat: redesign selection screen`, `docs: add ADR 0005 rajdhani font`, `test: cover scene layout and palette`), mencionando el cambio de datos del transversal (FR-010) y la ADR 0005; verificar en el PR la revisión de cumplimiento de la constitution.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias. T003 depende de T002.
- **Foundational (Phase 2)**: depende de T003 (la fuente debe existir para el tema). Bloquea todas las historias.
- **US1 (Phase 3)**: depende de la Foundational. Es el MVP.
- **US2 (Phase 4)**: depende de la Foundational (T011). Independiente de US1 en código (archivos distintos); su prueba de no superposición (T024) usa el `OpponentPainter` vigente, así que conviene correrla después de US1.
- **US3 (Phase 5)**: depende de la Foundational (T012, T013). Toca `exercise_screen.dart`, que también tocó T012: hacerla después de T012.
- **US4 (Phase 6)**: depende de la Foundational (T005–T009, T013) y de `signal_shapes.dart` (T022, de US2) para los íconos de nivel. Si se hace antes de US2, crear T022 primero.
- **Polish (Phase 7)**: después de las historias deseadas.

### Within Each User Story

- Código antes que pruebas (Principio VI), y pruebas verdes antes de cerrar la historia.
- US1: T015 ∥ T016 → T017 → T018 ∥ T019 ∥ T020 → T021.
- US2: T022 → T023 → T024 → T025.
- US3: T026 ∥ T027 → T028 → T029 → T030 → T031.
- US4: T032 ∥ T033 ∥ T034 → T035 → T036 → T037.

### Archivos compartidos (no paralelizar entre sí)

- `lib/presentation/theme.dart`: T005 → T006.
- `lib/presentation/exercise/exercise_screen.dart`: T012 → T029.
- `lib/presentation/exercise/painters/opponent_painter.dart`: T010 → T016 → T017.
- `lib/presentation/exercise/painters/signal_painter.dart`: T011 → T023.
- `test/presentation/opponent_painter_test.dart`: T014 → T019.
- `test/presentation/signal_painter_test.dart`: T014 → T024.
- `lib/presentation/strings_es.dart`: T007 → T029 (quitar `remaining`).
- `test/presentation/exercise_screen_test.dart`: T030 → T036.

### Parallel Opportunities

- Phase 1: T002 y T004 en paralelo.
- Phase 2: T007, T008 y T013 en paralelo con T005/T006; T009 tras T008.
- US1: T015 en paralelo con T016; T018, T019 y T020 en paralelo.
- US2 y US3 pueden avanzar en paralelo tras la Foundational (archivos distintos hasta T029).
- US4: T032, T033 y T034 en paralelo.
- Polish: T038 y T039 en paralelo.

---

## Parallel Example: User Story 1

```bash
# Tras T017, lanzar juntas las pruebas de US1 (archivos distintos):
Task: "T018 Transversal horizontal en test/data/catalog_json_mapper_test.dart"
Task: "T019 Sable horizontal, punta de frente y bajo el HUD en test/presentation/opponent_painter_test.dart"
Task: "T020 Invariantes de SceneLayout en test/presentation/scene_layout_test.dart"
```

## Parallel Example: User Story 4

```bash
Task: "T032 LevelIcon en lib/presentation/selection/level_icon.dart"
Task: "T033 PatternIconPainter en lib/presentation/selection/pattern_icon_painter.dart"
Task: "T034 SelectionCard en lib/presentation/selection/selection_card.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: línea base verde, fuente y ADR.
2. Phase 2: paleta, tema, `SceneLayout`, dojang, painters conectados, proveedor de parámetros.
3. Phase 3: oponente, sable horizontal y punta de frente, con sus pruebas.
4. **STOP and VALIDATE**: `flutter test` verde y quickstart §2 pasos 6 y 8 (escena) a 3 m.

### Incremental Delivery

1. Setup + Foundational → dojang detrás de la escena anterior.
2. US1 → escena nueva (MVP).
3. US2 → señales nuevas.
4. US3 → HUD nuevo; pantalla del ejercicio completa.
5. US4 → selección nueva.
6. Polish → paleta, alcance del diff, tiempos, pruebas con personas y PR.

---

## Notes

- [P] = archivos distintos, sin dependencias pendientes.
- Las pruebas van después del código (Principio VI), pero deben pasar antes de cerrar cada historia.
- Solo se ajustan las pruebas que la spec permite (Assumptions): forma de localizar elementos, dibujo de la flecha y del símbolo, y datos del transversal. Las expectativas sobre la lógica del ejercicio no cambian (SC-007).
- Ante un conflicto entre estética y legibilidad, prevalece la legibilidad (FR-003).
