# Research: Experiencia visual ("que enamore")

**Feature**: [spec.md](./spec.md) | **Base**: [Spec 001](../001-motor-nivel1-frontal/plan.md) (motor, catálogo, painters), [Spec 002](../002-patron-transversal/plan.md) (barrido transversal) y [Spec 003](../003-nivel2-evasion/plan.md) (flecha de evasión)

El stack, los paquetes y la arquitectura son los de la Spec 001. Esta spec cambia solo la presentación, un dato del catálogo y agrega una tipografía. Las dudas reales eran: dónde cabe la escena sin que el HUD tape el sable (R5), cómo se distinguen las piernas oscuras sobre la duela (R7), cómo se ve el sable horizontal cuando apunta al usuario (R4) y cómo se garantiza la regla de color (R9).

Los contrastes citados son WCAG 2.x (luminancia relativa), calculados con los colores de [`referencia-visual-spec004.md`](../../docs/design/referencia-visual-spec004.md).

## R1. Alcance del cambio (Principios II y III)

- **Decision**: No cambia nada en `lib/domain/` ni en `lib/data/`. Cambian:
  - `assets/catalog/catalog.json`: `tip.y` de `cut.start` y `cut.end` del Patrón transversal (R3).
  - `assets/fonts/`: Rajdhani 500 y 700 y su licencia (R2); sección `fonts:` en `pubspec.yaml`.
  - `lib/presentation/`: tema, paleta, painters, pantallas y un proveedor de parámetros (R11).
- **Rationale**: El motor ya entrega todo lo que la presentación necesita: `saberColor`, `signal`, `motion`, `countdownValue`, `elapsed` y `remaining` en el snapshot, y niveles, patrones y glosario en el catálogo. Ninguna señal nueva, ningún estado nuevo.
- **Alternatives considered**: Agregar al dominio la duración total o un "progreso del ejercicio" en el snapshot. Innecesario: la presentación ya conoce los parámetros (R11). Se rechaza.

## R2. Tipografía Rajdhani (Principio VII; aprobada el 2026-11-10)

- **Decision**: Incluir los archivos estáticos `Rajdhani-Medium.ttf` (500) y `Rajdhani-Bold.ttf` (700) del repositorio oficial de Google Fonts (`ofl/rajdhani`) en `assets/fonts/rajdhani/`, junto con `OFL.txt`. Declararlos en `pubspec.yaml` (`flutter: fonts:` con `family: Rajdhani` y `weight: 500/700`). El tema usa `fontFamily: 'Rajdhani'`. El hangul y el hanja caen en la fuente del sistema por el *fallback* de glifos del motor de Flutter (en Android, Noto Sans CJK). Se registra el ADR `docs/decisions/0005-tipografia-rajdhani.md`.
- **Rationale**: Funciona sin conexión (FR-026), sin paquete nuevo, y la licencia SIL OFL 1.1 permite incluir la fuente en la app con su licencia. Rajdhani no tiene glifos coreanos ni CJK; el *fallback* del sistema los resuelve sin configuración y sin caracteres faltantes en Android.
- **Alternatives considered**:
  - Paquete `google_fonts`: es una dependencia nueva y descarga en tiempo de ejecución salvo que se empaqueten los archivos igual. Se rechaza.
  - Fuente del sistema (Roboto): no requiere aprobación, pero pierde el estilo "consola actual" aprobado. Se rechaza.
  - Incluir también una fuente CJK (Noto Sans KR): +MB al APK sin necesidad en Android. Se rechaza; se reevalúa si una plataforma futura no tiene CJK.

## R3. Sable horizontal en el Patrón transversal (FR-010)

- **Decision**: Cambiar solo dos números del catálogo:

  | Postura | Antes | Después |
  |---|---|---|
  | `cut.start` | `hilt [-0.45, 0.1]`, `tip [-1.3, -0.1]` | `hilt [-0.45, 0.1]`, `tip [-1.3, 0.1]` |
  | `cut.end` | `hilt [0.45, 0.1]`, `tip [1.3, -0.1]` | `hilt [0.45, 0.1]`, `tip [1.3, 0.1]` |

- **Rationale**: Con la punta a la altura de la empuñadura, la hoja es horizontal en *Sodose*, en el fin del corte y en todo el barrido, porque el painter interpola linealmente empuñadura y punta y las dos `y` son iguales (sin trayectoria diagonal, Spec 002 FR-008). La punta avanza de `x = −1.3` a `1.3` a velocidad uniforme. El largo visible es `|−0.85 + 1.7·t|`: se acorta hasta **0 en t = 0.5** (el sable apunta al usuario) y vuelve a crecer, que es la "punta de frente" (R4). El mapper acepta los valores (rango `[-2, 2]`). La guardia no cambia.
- **Consecuencias en pruebas** (la spec lo prevé en Assumptions): la prueba (e) del mapper ("a la mitad la hoja visible no mide cero", `|Δy| ≥ 0.2`) pasa a exigir `tip.y == hilt.y` en `cut.start` y `cut.end`; la prueba de `OpponentPainter` que esperaba `midLength = 0.2` pasa a esperar `0` y el disco de tamaño máximo. Las expectativas de lógica del ejercicio no cambian (SC-007).
- **Alternatives considered**: Dibujar el sable horizontal en el painter ignorando `tip.y`. Rompe "datos sobre código" (Principio III) y el contrato del catálogo. Se rechaza.

## R4. Punta de frente (FR-011)

- **Decision**: Conservar `OpponentPainter.tipDiameter(visibleLength)` (0 con hoja ≥ 0.8 u; crece linealmente hasta **0.3 u** con hoja ≤ 0.2 u) y aplicar al disco el mismo tratamiento que a la hoja: brillo del color del sable, contorno oscuro y reflejo blanco. El disco se dibuja **encima** de los guantes, porque a la mitad del barrido la punta coincide con la empuñadura.
- **Rationale**: El diámetro mínimo con hoja de largo 0 es 0.3 u ≈ 0.077 × alto de la pantalla (con `u ≈ 0.255 h`, R5): ≈ 1 cm en una tablet de 10" (≈ 13.5 cm de alto) ≈ 11 minutos de arco a 3 m, más el halo del brillo. Es el mismo tamaño que la Spec 002 ya validó a 3 m (SC-001 de esa spec) con hoja de 0.2 u; ahora el disco está solo, sin hoja, así que el color lo da el disco completo. La hoja sigue avanzando a velocidad uniforme: el disco no cambia la trayectoria.
- **Alternatives considered**: Aumentar el disco a 0.4 u. Se reserva como ajuste si SC-001 falla en el instante de punta de frente; es una constante del painter.

## R5. Composición de la escena: `SceneLayout` (FR-007, FR-017, SC-004)

- **Problema**: Con la geometría actual (`u = 0.27 h`, origen en `0.58 h`), la punta del sable en *Chochôn-se* (`y = −1.6 u`) queda a `≈ 0.148 h`. El panel de los segundos del boceto termina a `117/800 ≈ 0.146 h`; con el grosor y el brillo de la hoja, se tapan (caso límite "Sable alzado en *Chochôn-se*"). Además, la figura nueva tiene piernas hasta `y ≈ 1.42 u`, que hoy no existen.
- **Decision**: Una clase pura de presentación, `SceneLayout`, calcula **una sola vez por tamaño de pantalla y patrón** toda la geometría que comparten el dojang, el oponente, las señales y el HUD:
  - `hudScale s = clamp(alto / 800, 0.7, 1.4)`: el HUD conserva las proporciones del boceto (1280 × 800) en una tablet y no se vuelve ilegible en un teléfono.
  - `hudBottom = (117 + 12) · s`: borde inferior de la franja superior del HUD más un margen.
  - Extensión vertical de la figura en unidades `u`: arriba `topReach − 0.13`, donde `topReach = min(−1.6, menor y de las posturas del patrón)` y 0.13 u es el medio grosor de la hoja más su brillo; abajo `1.42` (pies con contorno).
  - `u = (0.965 · alto − hudBottom) / (0.13 − topReach + 1.42)`, limitado también por el ancho (R10). Con 1280 × 800 y el Patrón frontal: `u ≈ 204 px ≈ 0.255 h`.
  - `origin = (ancho / 2, hudBottom + (0.13 − topReach) · u)` ≈ `0.60 h`.
  - Alcance horizontal del oponente: `reachX = max(1.3, mayor |x| de las posturas) + 0.13`; carriles de señal: `[0.04 · ancho, centro − (reachX + 0.02) · u]` a la izquierda y su reflejo a la derecha. Con el catálogo actual, `reachX + 0.02 = 1.45 u`, la misma constante de la Spec 003.
- **Rationale**: Ningún panel del HUD puede tapar la figura porque toda la figura, en cualquier postura del patrón, queda por debajo de `hudBottom` **por construcción**, en cualquier proporción. Las señales y la figura usan el mismo `u`, así que la regla de alcance de la Spec 003 se conserva. Un patrón nuevo que suba más el sable reduce la figura en lugar de chocar con el HUD (Principio III). La figura queda del tamaño actual (0.255 h frente a 0.27 h), sin pérdida apreciable a 3 m.
- **Alternatives considered**:
  - Mover el panel de los segundos fuera del centro: contradice FR-015. Se rechaza.
  - Achicar solo el panel: no resuelve el brillo ni patrones futuros. Se rechaza.
  - Medir el HUD en tiempo de ejecución (`GlobalKey`, `LayoutBuilder` con dos pasadas): agrega un cuadro de retraso y estado. Se rechaza; el HUD se dimensiona con las mismas constantes que usa `SceneLayout`.

## R6. Dojang (FR-006, FR-007; caso límite "Proporciones de pantalla")

- **Decision**: `DojangPainter` dibuja el fondo en coordenadas `u` alrededor de `origin`, no estirado:
  - Bandas horizontales (pared, viga, zócalo, duela, foco de luz) ocupan **todo el ancho** a cualquier proporción.
  - Elementos puntuales (columnas, estandartes, juntas de la duela) se colocan a distancias fijas del centro en `u`; en 4:3 los estandartes pueden recortarse en las orillas; en 20:9 se agregan juntas de duela hasta cubrir el ancho.
  - Estandartes con 해동검도 / 海東劍道 dibujados con `TextPainter` (fuente del sistema).
  - La **viñeta** se dibuja en esta capa, **debajo** del oponente y las señales (en el boceto va encima): así no oscurece la flecha cerca del borde (FR-003).
  - Va en su propio `CustomPaint` dentro de un `RepaintBoundary`, con `shouldRepaint` solo si cambia `SceneLayout`: se rasteriza una vez y no se repinta en cada cuadro (SC-006).
- **Rationale**: Llena la pantalla sin franjas ni deformación (FR-007), y la relación entre pies, duela y zócalo es la misma en todas las proporciones porque el fondo usa la misma unidad que la figura.
- **Alternatives considered**: Imagen de fondo (PNG/SVG). Requiere un asset raster por densidad o un paquete SVG (dependencia nueva), y no se alinea con la unidad de la figura. Se rechaza; se mantiene `CustomPainter` (ADR 0004).

## R7. Oponente con equipo de competencia y silueta sobre la duela (FR-008, FR-009)

- **Decision**: `OpponentPainter` dibuja la figura del boceto `Retro.dc.html` convertida a unidades `u` ([data-model.md](./data-model.md#figura-del-oponente)): pies, *hakama*, dobok, peto con ribete, cinturón, casco con rejilla y brazos (manga blanca, codera, guante oscuro) de cada hombro a la empuñadura. Solo los brazos y el sable siguen las posturas del catálogo (Out of Scope). Colores:
  - Casco, peto, mangas y coderas: blancos y gris muy claro (degradados del boceto, ya neutros).
  - *Hakama* `#2b2c31`, cinturón `#15151a`, guantes `#1c1c22`: gris carbón sin tinte azul (Clarifications).
  - Contorno de la figura `#1a1d2b` con grosor `0.0145 u` (3.5 px del boceto con u = 241 px), mínimo 2 dp.
  - **Luz de contorno**: un trazo interior claro `#d8d5cc` al 70 % sobre el borde exterior de la *hakama*, los guantes y el cinturón.
  - Foco de luz cálido de la duela centrado bajo la figura (R6).
- **Rationale**: Contrastes medidos de la *hakama* `#2b2c31`:

  | Fondo detrás | Sin luz de contorno | Con luz de contorno `#d8d5cc` |
  |---|---|---|
  | Pared (parte baja) `#8c887e` | 3.9 : 1 | — |
  | Duela con foco | 4.4 : 1 | — |
  | Duela media `#805329` | 2.1 : 1 | — |
  | Duela arriba `#694322` | **1.6 : 1** | 5.9 : 1 |
  | Zócalo `#3d3027` | **1.1 : 1** | 8.7 : 1 |

  Sin la luz de contorno, las piernas se pierden en el zócalo y en la parte alta de la duela (FR-009 falla). Con ella, el borde de la silueta supera 3 : 1 (WCAG 1.4.11) sobre todos los fondos. El casco y el peto (blancos) sobre la pared tienen 2.5 : 1, pero los separa el contorno oscuro (6.8 : 1 contra la pared).
- **Alternatives considered**:
  - *Hakama* gris medio (p. ej. `#5a5b60`): mejora el contraste con el zócalo, pero lo empeora con la pared (zona alta de las piernas) y se aleja del boceto. Se rechaza.
  - Aclarar la duela o el zócalo: se pierde la calidez del dojang y el contraste del peto blanco. Se rechaza.
  - Pies descalzos color piel del boceto (`#f1c9a5`): se conservan. Es un tono piel desaturado, no un rojo ni un amarillo; lo verifica SC-003. Si un observador lo nombra amarillo o rojo, se cambian a gris claro (constante de paleta).

## R8. Dibujo del sable (FR-012) y sable blanco sobre fondo claro

- **Decision**: El sable se dibuja en capas, de abajo arriba:
  1. Brillo: trazo del color del sable, ancho 0.11 u, opacidad 0.6, `MaskFilter.blur(BlurStyle.normal, σ = 0.025 u)`. Extensión total desde el eje: 0.13 u (R5).
  2. Contorno: trazo negro de ancho `hoja + 2 × kOutlineWidth` (4 dp, sin cambio).
  3. Hoja: color del sable (los mismos `AppColors.saber*`), ancho 0.09 u (sin cambio).
  4. Reflejo: trazo blanco al 55 %, ancho 0.02 u, sobre la mitad superior de la hoja.
  5. Empuñadura `#26201b` desde la empuñadura del catálogo (`hilt`) hasta el 23 % del largo visible, con contorno; tsuba gris `#8f8f96` (elipse perpendicular a la hoja) en ese punto.
  6. Disco de la punta de frente (R4).
- **Rationale**: Con hoja horizontal y un largo visible variable, que la empuñadura sea una fracción fija del largo visible (23 %, como en el boceto) mantiene las proporciones en escorzo: todo el sable se acorta igual. Contra la pared, los colores del sable tienen poco contraste de relleno (azul 1.9, rojo 1.5, amarillo 1.7, blanco 2.5 : 1), pero el contorno negro da 4.6–6.8 : 1 con la hoja y con la pared, y el brillo amplía la mancha de color: es el mismo argumento de la Spec 003 (R5) para el "contorno definido". En guardia el sable blanco pasa frente al peto blanco (1.7 : 1): lo separa el contorno negro (21 : 1).
- **Alternatives considered**: Sombra (`Canvas.drawShadow`) en lugar de brillo: oscurece, no ilumina, y no tiene color. Se rechaza.

## R9. Regla de color (FR-004, FR-005, SC-003)

- **Decision**:
  - `AppColors` se divide en dos grupos con nombre: **colores de señal** (`saberWhite`, `saberYellow`, `saberBlue`, `saberRed`; los únicos que usan los painters del sable y de las señales) y **paleta neutra** (dojang, figura, interfaz).
  - El `ColorScheme` del tema deja de sembrarse con `saberYellow` y se define explícito en blancos y grises (`primary` blanco, `onPrimary` `#12141c`, superficies oscuras translúcidas). Así los widgets de Material (indicador de carga, foco, *ripple*, botones deshabilitados) no introducen amarillo ni tonos derivados.
  - Prueba automática de la paleta: todo color de la interfaz y del equipo del oponente tiene croma `(max(R,G,B) − min(R,G,B)) / 255 ≤ 0.10` (gris; el gris azulado más tintado del boceto, `#aeb3c4`, da 0.086). Los tonos de madera, pared, piel y foco de luz del dojang forman una lista explícita y nombrada de excepciones, cada una con croma ≤ 0.45 (la madera más intensa, `#96622f`, da 0.40; el azul, el rojo y el amarillo de señal dan 0.82 a 1.0). Agregar un color fuera de esas reglas hace fallar la prueba. SC-003 (observadores) es la verificación final.
- **Rationale**: El riesgo real no está en la paleta del boceto (ya neutra salvo la *hakama* y la guarda, corregidas en Clarifications), sino en el tema actual, sembrado con amarillo, que tiñe los widgets de Material sin que nadie lo escriba. La prueba evita regresiones al agregar colores.
- **Alternatives considered**: Revisar solo a ojo. No previene regresiones. Se rechaza.

## R10. Señales: flecha corta con estela y defensa en diagonal (FR-002, FR-013, FR-014)

- **Decision**:
  - Las formas viven en un módulo de geometría compartido, `signal_shapes.dart`, que construye los `Path` en una caja unitaria. Lo usan `SignalPainter` (con color, brillo y estela) y los íconos de nivel de la selección (en blanco, R12).
  - **Carril**: las dos señales se dibujan dentro del carril de su lado (`SceneLayout`, R5), entre el alcance del oponente (1.45 u) y el 4 % del ancho desde el borde, centradas en vertical. El brillo y la estela cuentan dentro del carril: ningún píxel sale de él.
  - **Flecha de evasión** (proporciones del boceto `Retro.dc.html`): punta triangular de largo 0.54 L y alto 1.06 L, cuerpo de largo 0.46 L y alto 0.46 L, donde `L` es el largo de la flecha (sin estela). Anclada al borde exterior del carril. La **estela** va de la cola hacia el centro, de largo hasta 1.0 L, con el alto del cuerpo y un degradado del color del sable de 85 % a 0 %, más dos líneas de movimiento finas. Contorno oscuro de `1.5 × kOutlineWidth`, brillo 0.6 y reflejo blanco al 50 %. `L = min(0.30 h, carril / 1.6)`: si el carril es corto, se acorta primero la estela.
  - **Defensa**: sable en diagonal, de 65° sobre la horizontal, con la punta arriba y hacia el borde exterior (se refleja con el lado, como la flecha); hoja delgada del **color del sable**, empuñadura más gruesa (hoja = 0.55 × empuñadura) `#26201b`, guarda gris `#8f8f96` (Clarifications), contorno oscuro y brillo. Alto `min(0.45 h, lo que permita el ancho del carril)`; en 4:3 el carril (≈ 0.24 h) da ≈ 0.31 h, por encima del mínimo de 30 % del alto de la Spec 001 (research R12 de esa spec).
- **Rationale**: Usar el carril para **las dos** señales garantiza FR-002 por construcción en cualquier proporción (hoy la defensa se centra en `0.18 × ancho` sin comprobar el alcance). A 45° (boceto) la caja del símbolo es casi cuadrada y en 4:3 quedaría en ≈ 0.24 h de alto; a 65° sigue leyéndose como diagonal y llega a ≈ 0.31 h. Si la prueba en 4:3 da menos de 0.30 h, se sube el ángulo (constante del painter).
- **Inconsistencia de la spec — color del símbolo de defensa**: FR-014 y US2-2 piden "hoja delgada **del color del sable**" (y así lo dibuja `Senales.dc.html`), mientras que Assumptions dice "El sable y las señales mantienen sus colores actuales" (hoy el símbolo es blanco). La Spec 001 no fija el color del símbolo (el blanco fue una decisión de su plan, D6). **Se sigue FR-014**: hoja azul o roja, del mismo color que el sable en ese instante. *(Confirmado por el responsable el 2026-11-11; se corrigió la línea de Assumptions de la spec.)*
- **Alternatives considered**: Mantener la defensa centrada en `0.18 × ancho`. No garantiza el alcance en 4:3. Se rechaza.

## R11. HUD del ejercicio (FR-015 a FR-019)

- **Decision**:
  - Widgets de Flutter sobre los painters, dimensionados con `hudScale` (R5). Paneles con fondo `rgba(18,20,28,0.74)`, borde blanco al 35 % y radio 14 · s, sin `BackdropFilter` (el boceto no desenfoca y es caro por cuadro).
  - **Izquierda**: `level.name.toUpperCase()` (700) y `level.responseLabel` (500).
  - **Centro**: segundos restantes con el mismo cálculo de hoy (`ceil(remaining)`), en grande, y una barra `progress = clamp(1 − remaining / parameters.duration, 0, 1)`: vacía durante la cuenta regresiva y llena al terminar.
  - **Derecha**: `pattern.name.toUpperCase()` y la secuencia `postura → corte`, cada término con su romanización seguida de su hangul si lo tiene (p. ej. "Sodose → Hwengdan ilgôm begi 횡단일검베기", "Chochôn-se 초천세 → Chungmyôn begi 정면베기").
  - Los paneles laterales usan `FittedBox(fit: scaleDown)` con ancho máximo `(ancho − panel central) / 2 − márgenes`, así nunca se tocan entre sí.
  - **Detener** abajo a la izquierda, píldora con borde blanco, en las mismas fases que hoy.
  - **Repetir** (abajo a la derecha, píldora blanca con texto oscuro) y **Volver** (abajo a la izquierda, en el lugar de Detener, píldora con borde). En el boceto no aparecen; centrados abajo taparían los pies del oponente (FR-017).
  - **Cuenta regresiva**: número Rajdhani 700, blanco, con contorno negro (texto con `Paint` de trazo detrás del relleno), centrado. No es parte del HUD según el glosario y dura solo 3 s sin señal visible.
  - `parameters.duration` sale de un proveedor de presentación nuevo, `exerciseParametersProvider` (`ExerciseParameters.defaults()`), que usan el controlador, el HUD y el resumen de la selección. La Spec 005 lo reemplazará por la configuración del usuario.
- **Rationale**: Todos los textos salen del catálogo (Spec 001, SC-009). La barra se calcula con datos que el snapshot ya trae. Un solo proveedor de parámetros evita que la duración del HUD, del resumen y del motor puedan diferir.
- **Alternatives considered**: Calcular el progreso con `elapsed / (elapsed + remaining)`: incluye la cuenta regresiva y no llega a la proporción "respecto de la duración" que pide FR-015. Se rechaza.

## R12. Pantalla de selección (FR-020 a FR-025)

- **Decision**:
  - Fondo: `DojangPainter` con la escena de referencia (sin figura) bajo una capa `#0c0e14` al 62 %.
  - Encabezado "HAIDONG GUMDO" y "Entrenamiento de reacción · 해동검도" (textos fijos de la interfaz en `StringsEs`).
  - Dos columnas, "NIVEL" y "PATRÓN", cada una un `ListView` de tarjetas (`SelectionCard`) por si el catálogo crece.
  - Tarjeta de nivel: ícono = forma de la señal de `level.responseTypes.first` en blanco (de `signal_shapes.dart`); nombre en mayúsculas; detalle `"${responseLabel} — ${purpose}"` (FR-021; el boceto usa "·", la spec manda).
  - Tarjeta de patrón: ícono = `PatternIconPainter`, una silueta de palitos generada con el cuerpo fijo y los brazos y el sable en la postura `cut.start` del patrón, escalada para caber en la caja (FR-022, Clarifications); nombre en mayúsculas; secuencia guardia → postura → corte en romanización; línea de hangul con solo los términos que lo tienen, unidos por " → " (caso límite "Términos sin hangul").
  - Selección: fondo blanco al 16 %, borde blanco de 2 · s, anillo exterior blanco al 12 % y palomita blanca; `Semantics(selected: true, button: true)`. Nivel 1 y Frontal siguen preseleccionados por `selectedSessionProvider` (sin cambio).
  - Abajo: resumen `"${level.name} · ${pattern.name} · ${duration.inSeconds} s"` y botón INICIAR píldora blanca, texto `#12141c`; deshabilitado (blanco al 38 %) durante la carga y con error.
  - Carga: indicador circular blanco y texto; error: mensaje en panel translúcido.
- **Rationale**: Cumple el boceto y la regla de color; los íconos y textos salen del catálogo, así que un nivel o patrón nuevo aparece con ícono sin cambiar código (caso límite). Un nivel nuevo con un tipo de respuesta nuevo ya exige código de señal (Principio III), y su ícono sale del mismo módulo de formas.
- **Alternatives considered**: Íconos de patrón dibujados a mano por id (`frontal`, `transversal`). Viola FR-022 y SC-009 de la Spec 001. Se rechaza.

## R13. Rendimiento (SC-006; caso límite "Dispositivo modesto")

- **Decision**:
  - Dojang en `RepaintBoundary` sin repintado por cuadro (R6).
  - Brillos con `MaskFilter.blur` solo en trazos pequeños (sable, disco, señal); sin `BackdropFilter` ni `saveLayer` de pantalla completa.
  - El HUD se separa en widgets que observan solo lo que necesitan (`select` sobre `remaining`, `status`), para no reconstruir la escena completa por cambios del texto.
  - `SceneLayout` se calcula en `LayoutBuilder` y se memoiza por tamaño y patrón.
- **Rationale**: El motor, el `Ticker` y los tiempos no cambian; el costo por cuadro solo crece por los brillos, que son trazos cortos. SC-006 se verifica en el dispositivo de referencia con la grabación de la Spec 001.
- **Alternatives considered**: Pre-renderizar el sable con brillo a una imagen: complica el cambio de color y el escorzo. Se reserva si SC-006 falla.

## R14. Pruebas (Principio VI, SC-004, SC-007)

- **Decision**:
  - El dominio no cambia: sus pruebas pasan tal cual (SC-007).
  - Pruebas ajustadas (permitidas por Assumptions): finders por texto en mayúsculas (`'NIVEL 1'`, `'FRONTAL'`) y por `SelectionCard` en lugar de `ListTile`; `StringsEs.start/stop/repeat/back` pasan a mayúsculas, así que las pruebas que usan las constantes no cambian; geometría de la flecha y del símbolo a las formas nuevas, conservando lado, color, dirección y espacio libre; datos del transversal (R3).
  - Pruebas nuevas:
    - `SceneLayout` en 20:9, 16:9, 16:10 y 4:3 (y alto de teléfono): figura bajo `hudBottom`, carriles fuera del alcance, Detener/Repetir/Volver fuera de la figura.
    - Muestreo de píxeles (SC-004): para cada patrón, lado, postura y tramo (guardia, postura de ataque, mitad del barrido, fin del corte), se pinta el oponente y la señal en lienzos separados y se comprueba que ningún píxel con alfa > 0 coincide; los rectángulos del HUD no coinciden con píxeles del oponente.
    - Punta de frente: a la mitad del barrido transversal hay un disco del color del sable de diámetro ≥ 0.3 u.
    - Paleta (R9) y tema sin amarillo.
    - Ícono de patrón generado para un patrón de prueba que no existe en el catálogo real.
    - HUD: textos de los cuatro combos desde el catálogo; segundos y barra avanzan con el reloj manual.
    - Selección: tarjetas, palomita, resumen y una sola acción para iniciar.
- **Rationale**: SC-004 es automático por diseño; el resto de los criterios (SC-001, -002, -003, -005, -006) son observacionales y van en el quickstart.
- **Alternatives considered**: Pruebas *golden*. La tipografía y el antialias varían entre plataformas y obligarían a fijar fuentes en CI. Se rechazan para esta spec.
