# Data Model: Experiencia visual ("que enamore")

**Feature**: [spec.md](./spec.md) | **Base**: data-model de la [001](../001-motor-nivel1-frontal/data-model.md), la [002](../002-patron-transversal/data-model.md) y la [003](../003-nivel2-evasion/data-model.md) | **Decisiones**: [research.md](./research.md)

Ninguna entidad del dominio cambia (catálogo, nivel, patrón, término, sesión, parámetros, ejercicio, ataque, señal, snapshot, movimiento del oponente). Esta spec cambia **un dato** del catálogo y agrega **modelos de presentación**: la composición de la escena, la paleta, la geometría de la figura, del sable y de las señales, y el contenido del HUD y de las tarjetas.

Unidades:
- `u`: unidad de la figura (media altura del cuerpo; la misma de `Point2` en el catálogo). `x` a la derecha, `y` hacia abajo, origen en `SceneLayout.origin`.
- `s`: escala del HUD (`hudScale`). Las medidas "boceto px" se multiplican por `s`.
- `h`, `w`: alto y ancho del lienzo en dp lógicos.

## 1. Catálogo: Patrón transversal (dato)

Único cambio de datos (FR-010, research R3). Todo lo demás del catálogo queda igual.

| Campo | Antes | Después |
|---|---|---|
| `patterns[transversal].cut.start.tip` | `[-1.3, -0.1]` | `[-1.3, 0.1]` |
| `patterns[transversal].cut.end.tip` | `[1.3, -0.1]` | `[1.3, 0.1]` |

Reglas del barrido transversal (reemplazan la regla (e) de la Spec 002 "a la mitad la hoja no mide cero"):
- `cut.start.tip.y == cut.start.hilt.y` y `cut.end.tip.y == cut.end.hilt.y` (hoja horizontal).
- `cut.end` sigue siendo el reflejo exacto de `cut.start` en `x`; `y` no cambia entre `start` y `end` (sin trayectoria diagonal).
- Largo visible a progreso `t`: `|−0.85 + 1.7 t|` u; vale **0 en t = 0.5** y la punta se dibuja de frente (§5).

## 2. SceneLayout (presentación)

Geometría compartida por el dojang, el oponente, las señales y el HUD. Inmutable; se calcula a partir de `Size` y `Pattern` (research R5).

| Campo | Tipo | Definición |
|---|---|---|
| `size` | `Size` | Lienzo |
| `hudScale` (`s`) | `double` | `clamp(h / 800, 0.7, 1.4)` |
| `hudBottom` | `double` | `(117 + 12) · s`: fin de la franja superior del HUD más margen |
| `topReach` | `double` (u) | `min(−1.6, menor y de guard, cut.start y cut.end, empuñadura y punta)` |
| `reachX` | `double` (u) | `max(1.3, mayor \|x\| de esas posturas) + saberExtent` |
| `unit` (`u`) | `double` (dp) | `min(uV, uH)` (abajo) |
| `origin` | `Offset` | `(w / 2, hudBottom + (saberExtent − topReach) · u)` |
| `leftLane`, `rightLane` | `Rect` | Carriles de señal (abajo) |
| `bottomLeftButton`, `bottomRightButton` | `Rect` | Zonas de Detener / Volver y Repetir |

Constantes:

| Constante | Valor | Origen |
|---|---|---|
| `saberExtent` | 0.13 u | medio ancho de hoja 0.045 u + brillo (§5) |
| `figureBottom` | 1.42 u | pies (1.36 u) + medio alto 0.046 u + contorno |
| `floorLimit` | 0.965 h | borde inferior de los pies |
| `laneGap` | 0.02 u | margen entre el alcance y el carril |
| `edgeMargin` | 0.04 w | margen exterior del carril (Spec 003) |
| `minLaneWidth` | 0.20 h | carril mínimo para las señales |

Fórmulas:
- `uV = (floorLimit − hudBottom) / (saberExtent − topReach + figureBottom)`.
- `uH = (w / 2 − edgeMargin − minLaneWidth) / (reachX + laneGap)`.
- `rightLane = Rect.fromLTRB(origin.dx + (reachX + laneGap) · u, hudBottom, w − edgeMargin, floorLimit)`; `leftLane` es su reflejo respecto de `w / 2`.

Valores de referencia (Patrón frontal y transversal del catálogo actual, `topReach = −1.6`, `reachX = 1.43`):

| Lienzo | `s` | `u` | `origin.dy` | Ancho del carril |
|---|---|---|---|---|
| 1280 × 800 (16:10) | 1.0 | 204 (0.255 h) | 482 (0.60 h) | 0.37 h |
| 1422 × 800 (16:9) | 1.0 | 204 | 482 | 0.45 h |
| 1778 × 800 (20:9) | 1.0 | 204 | 482 | 0.65 h |
| 1067 × 800 (4:3) | 1.0 | 204 | 482 | 0.24 h |
| 889 × 400 (20:9, teléfono) | 0.7 | ≈ 94 (0.235 h) | ≈ 253 | 0.68 h |

Invariantes (probadas en las cuatro proporciones, research R14):
- Toda la figura y el sable, en cualquier postura del patrón, quedan entre `hudBottom` y `floorLimit` (FR-017).
- Ningún carril se cruza con `[origin.dx − (reachX)·u, origin.dx + (reachX)·u]` (FR-002).
- `bottomLeftButton` y `bottomRightButton` no se cruzan con la caja de la figura.

## 3. Paleta (presentación)

`AppColors` se separa en grupos con nombre (FR-004, research R9). Los colores de señal no cambian.

**Colores de señal** (solo el sable, la punta de frente y las señales, con su brillo y estela):

| Token | Valor |
|---|---|
| `saberWhite` | `#FFFFFF` |
| `saberYellow` | `#FFD400` |
| `saberBlue` | `#1E6BFF` |
| `saberRed` | `#FF2D2D` |
| `outline` | `#000000` (contorno del sable y las señales) |

**Dojang** (excepciones cálidas nombradas, croma ≤ 0.45):

| Token | Valor |
|---|---|
| `wallTop` → `wallBottom` | `#aaa598` → `#8c887e` |
| `wood`, `woodShadow`, `beam`, `beamShadow` | `#6a5644`, `#574536`, `#5b4a3a`, `#3f3328` |
| `baseboard` (zócalo) | `#3d3027` |
| `floorBack` → `floorFront`, `floorJoint` | `#694322` → `#96622f`, `#5a391c` (70 %) |
| `spotLight` | `#ffe2b0` al 38 % → 0 % |
| `floorShadow` | `#2e1d0d` al 55 % |
| `bannerCloth`, `bannerText` | `#2a2b31`, `#f2efe6` |
| `lightShaft` | blanco al 7 % y 5 % |
| `vignette` | negro 0 % → 50 % |
| `selectionDim` | `#0c0e14` al 62 % |
| `skin` | `#f1c9a5` (pies) |

**Figura** (croma ≤ 0.10):

| Token | Valor |
|---|---|
| `helmetLight` → `helmetShade` | `#ffffff` → `#cdd3de` |
| `helmetGrille`, `helmetBars` | `#262833`, `#b7bdcb` |
| `petoLight` → `petoShade`, `petoLines` | `#f1f3f7` → `#c2c8d4`, `#aab1bf` |
| `sleeveLight` → `sleeveShade` | `#ffffff` → `#d2d8e3` |
| `hakama`, `hakamaFold` | `#2b2c31`, `#1d1e22` (sin tinte azul; Clarifications) |
| `belt`, `glove` | `#15151a`, `#1c1c22` |
| `figureOutline` | `#1a1d2b` |
| `rimLight` | `#d8d5cc` al 70 % (research R7) |
| `grip`, `gripWrap`, `tsuba` | `#26201b`, `#5c5046`, `#8f8f96` |

**Interfaz** (croma ≤ 0.10):

| Token | Valor |
|---|---|
| `panel` | `rgba(18,20,28,0.74)` (central `0.78`) |
| `panelBorder` | blanco al 35 % (central 40 %, Detener 55 %) |
| `textPrimary`, `textSecondary`, `textTertiary`, `columnHeader` | `#ffffff`, `#d6d9e4`, `#aeb3c4`, `#c9ccd8` |
| `progressTrack`, `progressFill` | blanco al 22 %, `#ffffff` |
| `cardIdle`, `cardIdleBorder` | `rgba(18,20,28,0.6)`, blanco al 22 % |
| `cardSelected`, `cardSelectedBorder`, `cardSelectedRing` | blanco al 16 %, `#ffffff`, blanco al 12 % |
| `iconTile` | blanco al 10 % |
| `primaryButton`, `onPrimaryButton` | `#f4f5f8`, `#12141c` |

Regla de validación: un color fuera de "Colores de señal" con croma > 0.10 solo es válido si está en la lista "Dojang"; la prueba de paleta lo comprueba. El `ColorScheme` del tema se construye solo con tokens de "Interfaz".

## 4. Figura del oponente

Partes en `u` desde `origin`, convertidas del boceto `Retro.dc.html` (u = 241 px, origen en (640, 413)). Se dibujan en este orden; todas con `figureOutline` de `max(0.0145 u, 2 dp)`.

| Parte | Forma | Geometría (u) | Color |
|---|---|---|---|
| Sombra | elipse | centro (0, 1.365), radios 0.79 × 0.062 | `floorShadow` |
| Pies | 2 elipses | centros (±0.38, 1.357), radios 0.141 × 0.046 | `skin` |
| *Hakama* | polígono | (−0.282, 0.079) (0.282, 0.079) (0.685, 1.336) (0.091, 1.336) (0, 0.651) (−0.091, 1.336) (−0.685, 1.336) | `hakama` + pliegues `hakamaFold` + `rimLight` |
| Dobok (tronco) | trapecio con borde superior curvo | arriba ±0.228 en y −0.544; abajo ±0.307 en y 0.112 | `sleeveLight` → `sleeveShade` |
| Peto | trapecio curvo | arriba ±0.216 en y −0.485; abajo ±0.266 en y 0.021; ribete interior blanco; 2 líneas | `petoLight` → `petoShade` |
| Cinturón | rectángulo redondeado | x ±0.324, y 0.029…0.137, con nudo | `belt` + `rimLight` |
| Casco | domo | x ±0.2, y −1.017…−0.568 | `helmetLight` → `helmetShade` |
| Rejilla | rectángulo redondeado + 3 barras verticales y 2 horizontales | x ±0.112, y −0.867…−0.643 | `helmetGrille`, `helmetBars` |
| Brazos | trazo de hombro a `hilt` | hombros (±0.20, −0.49); ancho 0.137 u | `sleeveLight` |
| Coderas | elipse en la mitad del brazo | radios 0.09 × 0.105 | `sleeveLight` |
| Guantes | círculo en `hilt` | radio 0.087 | `glove` + `rimLight` |

Reglas:
- Solo brazos, guantes y sable dependen de la postura (`OpponentMotion` interpolado como hoy). El cuerpo es fijo y no se refleja con el lado.
- La caja de la figura (sin sable) es x ±0.70, y −1.03…1.42.

## 5. Sable

Entradas: `hilt` y `tip` en pantalla (interpolados como hoy), `SaberColor`.

| Capa | Geometría | Estilo |
|---|---|---|
| Brillo | trazo `hilt+grip` → `tip`, ancho 0.11 u | color del sable, opacidad 0.6, `blur σ = 0.025 u` |
| Contorno de hoja | mismo trazo, ancho `0.09 u + 2 · kOutlineWidth` | `outline` |
| Hoja | ancho 0.09 u, extremo redondo | color del sable |
| Reflejo | trazo paralelo desplazado −0.02 u, ancho 0.02 u, 5 %…95 % del largo de la hoja | blanco al 55 % |
| Empuñadura | de `hilt` a `hilt + 0.23 · (tip − hilt)`, ancho 0.07 u, con contorno y 3 marcas | `grip`, `gripWrap` |
| Tsuba | elipse perpendicular a la hoja en el fin de la empuñadura, radios 0.03 × 0.095 u | `tsuba` + `figureOutline` |
| Punta de frente | disco en `tip`, diámetro `tipDiameter(largo visible)` | color del sable + brillo + `outline` + reflejo |

- `tipDiameter(L) = 0.3 · clamp((0.8 − L) / 0.6, 0, 1)` u (sin cambio). Se dibuja si el diámetro supera el ancho de la hoja; con `L = 0` vale 0.3 u.
- Con largo visible < 0.05 u no se dibujan empuñadura ni tsuba (apuntan al usuario); solo el disco sobre el guante.
- `kOutlineWidth` sigue en 4 dp para el sable y las señales (Assumptions).

## 6. Señales

Se dibujan dentro del carril del lado `signal.screenSide` (`SceneLayout.leftLane`/`rightLane`), centradas en `y = h / 2`. Ningún píxel, incluidos brillo y estela, sale del carril (FR-002). Se construyen para la derecha y se reflejan en `x` para la izquierda.

### Flecha de evasión (FR-013)

| Elemento | Geometría | Estilo |
|---|---|---|
| Largo de la flecha `L` | `min(0.30 h, (anchoCarril − 2·glowExtent) / 1.6)` | — |
| Punta | triángulo, largo 0.54 L, alto 1.06 L, vértice en el borde exterior del carril menos `glowExtent` | color del sable |
| Cuerpo | rectángulo, largo 0.46 L, alto 0.46 L | color del sable |
| Contorno | sobre punta + cuerpo | `outline`, `1.5 · kOutlineWidth`, uniones redondas |
| Brillo | mismo contorno relleno | color del sable al 60 %, `blur σ = 0.04 L` |
| Reflejo | polilínea en el borde superior del cuerpo y la punta | blanco al 50 % |
| Estela | trapecio desde la cola hacia el centro, largo `min(1.0 L, espacio restante)`, alto 0.46 L → 0.84 · 0.46 L | degradado del color del sable 85 % → 0 % hacia el centro |
| Líneas de movimiento | 2 trapecios finos (alto 0.04 L) arriba y abajo de la estela, largo 0.75 de la estela | mismo degradado al 70 % |

`glowExtent = 3σ`. El lado y la dirección no cambian: la punta apunta al borde exterior (Spec 003, FR-006, FR-007).

### Símbolo de defensa (FR-014)

| Elemento | Geometría | Estilo |
|---|---|---|
| Eje | recta a 65° sobre la horizontal, punta arriba y hacia el borde exterior | — |
| Alto total `H` | `min(0.45 h, alto que cabe en el ancho del carril)`; ≥ 0.30 h en 4:3 | — |
| Hoja | 70 % del largo, ancho `0.55 ×` empuñadura, termina en punta | color del sable + brillo + reflejo |
| Guarda | barra perpendicular al eje, ancho 0.26 del largo | `tsuba` (gris) |
| Empuñadura | 26 % del largo, ancho `0.09 ×` largo | `grip` |
| Contorno | todo el símbolo | `outline`, `kOutlineWidth` |

Con `SaberColor.white` o `yellow` no se dibuja ninguna señal (no ocurre: la señal solo existe con sable azul o rojo).

### Íconos de nivel

Las mismas formas (`signal_shapes.dart`) en una caja de 56 · s, rellenas de blanco, sin brillo, estela ni contorno de color; la flecha con sus líneas de movimiento en blanco. La forma se elige con `level.responseTypes.first`.

## 7. Contenido del HUD

Todo sale de la sesión, el catálogo, el snapshot y `exerciseParametersProvider` (FR-015).

| Panel | Línea | Fuente | Ejemplo (Nivel 2 + Transversal) |
|---|---|---|---|
| Izquierda | 1 (700, 30 · s) | `level.name.toUpperCase()` | NIVEL 2 |
| Izquierda | 2 (500, 16 · s) | `level.responseLabel` | Evasión lateral |
| Centro | número (700, 64 · s) | `ceil(snapshot.remaining en s)` | 16 |
| Centro | barra (alto 6 · s) | `clamp(1 − remaining / parameters.duration, 0, 1)` | 53 % |
| Derecha | 1 (700, 30 · s) | `pattern.name.toUpperCase()` | TRANSVERSAL |
| Derecha | 2 (500, 16 · s) | `termLabel(stance) + " → " + termLabel(cut)` | Sodose → Hwengdan ilgôm begi 횡단일검베기 |

`termLabel(t) = t.hangul == null ? t.romanization : "${t.romanization} ${t.hangul}"`.

Visibilidad por estado (sin cambios de comportamiento):

| Estado | Paneles | Detener | Cuenta regresiva | Repetir / Volver |
|---|---|---|---|---|
| `countdown` | sí | sí | sí | no |
| `running`, `finishing` | sí | sí | no | no |
| `finished` | sí | no | no | sí |
| `cancelled` | — (se navega fuera) | — | — | — |

## 8. Tarjetas de la selección

| Tarjeta | Ícono | Línea 1 (700, 28 · s) | Línea 2 (500) | Línea 3 (500, `textTertiary`) |
|---|---|---|---|---|
| Nivel | forma de `responseTypes.first` (§6) | `name.toUpperCase()` | `"$responseLabel — $purpose"` | — |
| Patrón | `PatternIconPainter(pattern)` | `name.toUpperCase()` | romanización de guardia → postura → corte | hangul de los términos que lo tienen, unidos por " → "; se omite si ninguno lo tiene |

Estado `selected` = la tarjeta corresponde a `selectedSessionProvider`. Resumen: `"${level.name} · ${pattern.name} · ${parameters.duration.inSeconds} s"`.

### Silueta del patrón (`PatternIconPainter`)

- Cuerpo de palitos fijo: cabeza (círculo relleno, radio 0.2), tronco (0, −0.55)…(0, 0.1), piernas a (±0.3, 1.3).
- Brazos de los hombros (±0.2, −0.49) a `cut.start.hilt`; sable de `cut.start.hilt` a `cut.start.tip`.
- Se calcula la caja de todos los puntos y se escala para caber en la caja del ícono con margen; trazos blancos.
- Un patrón nuevo del catálogo tiene ícono sin cambiar código (FR-022).

## 9. Tipografía

| Familia | Peso | Archivo | Uso |
|---|---|---|---|
| Rajdhani | 500 | `assets/fonts/rajdhani/Rajdhani-Medium.ttf` | textos secundarios |
| Rajdhani | 700 | `assets/fonts/rajdhani/Rajdhani-Bold.ttf` | títulos, números, botones |
| Sistema | — | — | hangul y hanja (fallback automático) |

Licencia `assets/fonts/rajdhani/OFL.txt`. ADR `docs/decisions/0005-tipografia-rajdhani.md`.
