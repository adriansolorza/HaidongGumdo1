# Implementation Plan: Experiencia visual ("que enamore")

**Branch**: `004-experiencia-visual` | **Date**: 2026-11-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/004-experiencia-visual/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Cambiar solo el aspecto de la pantalla del ejercicio y de la de selección al estilo "consola actual" de los bocetos aprobados: dojang de fondo, oponente con equipo de competencia, sable y señales con brillo, HUD en paneles translúcidos y selección con tarjetas. El dominio y la capa de datos no cambian. Lo que cambia:

- **Un dato** del catálogo: la punta del sable del Patrón transversal a la altura de la empuñadura, para que el sable sea horizontal; a la mitad del barrido se ve la punta de frente (research R3, R4).
- **Una tipografía** incluida como asset, Rajdhani 500 y 700, con ADR (research R2).
- **La presentación**: una geometría compartida (`SceneLayout`) que coloca la figura bajo el HUD y las señales en carriles fuera del alcance del oponente en cualquier proporción (R5); painters nuevos o reescritos para el dojang, el oponente, el sable y las señales (R6 a R8, R10); paleta separada en colores de señal y neutros, con un tema sin amarillo (R9); HUD, botones y selección nuevos (R11, R12).

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (canal stable), sin cambios

**Primary Dependencies**: `flutter_riverpod`, `flutter_tts`, `wakelock_plus` (ADR 0001–0003); gráficos con `CustomPainter` (ADR 0004). Sin paquetes nuevos. Nueva tipografía Rajdhani como asset (ADR 0005, aprobada el 2026-11-10).

**Storage**: Ninguno. Cambian los assets de solo lectura `assets/catalog/catalog.json` (dos valores) y `assets/fonts/rajdhani/` (nuevo).

**Testing**: `flutter_test` con los fakes de la 001 y la comparación de píxeles de los painters de la 002/003. Sin pruebas *golden* (R14).

**Target Platform**: Android (teléfonos y tablets), solo horizontal; proporciones de 4:3 a 20:9; dispositivo de referencia: tablet de 10" o imagen enviada a una TV.

**Project Type**: mobile-app (el mismo proyecto Flutter de la 001)

**Performance Goals**: Los de la 001: 60 fps y tiempos con desviación menor a 50 ms (SC-006). El dojang se rasteriza una vez; los brillos son trazos pequeños (R13).

**Constraints**:
- FR-001 / SC-007: sin cambios de comportamiento, tiempos, reglas, estados, voces, cancelación ni motor; `lib/domain` y `lib/data` sin cambios.
- FR-003: ante un conflicto, la legibilidad a 3 m prevalece sobre la estética.
- FR-004: rojo, azul y amarillo solo en el sable y las señales.
- FR-017 / SC-004: el HUD y las señales nunca tapan al oponente ni al sable, en ninguna postura ni proporción.

**Scale/Scope**: 2 pantallas, 1 clase de geometría, 3 painters nuevos (`DojangPainter`, `PatternIconPainter`, formas compartidas) y 2 reescritos (`OpponentPainter`, `SignalPainter`), tema y paleta, 1 proveedor, 2 valores del catálogo, 2 archivos de fuente; pruebas de presentación y datos; validación con personas a 3 m.

No hay incógnitas abiertas: las decisiones están en [research.md](./research.md) R1 a R14 (el color del símbolo de defensa se confirmó el 2026-11-11, ver D9).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Cumplimiento en este plan | Estado |
|---|---|---|
| I. Stack | Sin cambios de SDK | ✅ |
| II. Clean Architecture | Ningún archivo de `lib/domain` ni `lib/data` cambia. `SceneLayout`, la paleta y los painters son de presentación y leen entidades del dominio sin modificarlas (R1) | ✅ |
| III. Datos sobre código | El sable horizontal es un cambio de datos del catálogo (R3). Íconos, textos del HUD y tarjetas salen del catálogo; un patrón nuevo tiene ícono sin cambiar código (R12). La geometría de la escena se adapta a las posturas del patrón (R5) | ✅ |
| IV. Persistencia | Sin persistencia nueva | ✅ |
| V. Gestión de estado | Riverpod; un proveedor de presentación nuevo (`exerciseParametersProvider`) con el mismo valor que hoy (R11) | ✅ |
| VI. Pruebas | El dominio no cambia y sus pruebas pasan tal cual. Pruebas nuevas derivadas de los criterios: `SceneLayout`, no superposición (SC-004), punta de frente, paleta, HUD, selección (R14). Ajustes de pruebas solo en lo que la spec permite (Assumptions) | ✅ |
| VII. Dependencias y decisiones | Ningún paquete. La tipografía fue aprobada por el responsable el 2026-11-10 y se registra como ADR 0005 (R2) | ✅ |
| VIII. Interfaz | Oponente, sable y señales con contorno oscuro definido; la figura con contorno más fino (permitido por Assumptions) y luz de contorno donde la silueta oscura toca fondos oscuros (R7); orientación horizontal | ✅ |
| IX. Idioma y terminología | Identificadores en inglés; textos en español; romanización y hangul tal como en el glosario | ✅ |
| X. Flujo de trabajo | Rama `004-experiencia-visual` → PR a `main`; Conventional Commits | ✅ |
| XI. Seguridad y alcance | Sin cambios | ✅ |

**Resultado (antes de Phase 0)**: PASA, sin violaciones.
**Re-check después de Phase 1**: PASA. El diseño confirma que no se toca el dominio ni los datos de código, que no hay paquetes nuevos y que la única decisión que requiere ADR (la tipografía) ya está aprobada.

## Decisiones de diseño

- **D1. Alcance.** Solo `lib/presentation/`, dos valores de `assets/catalog/catalog.json`, `assets/fonts/rajdhani/` y la sección `fonts:` de `pubspec.yaml` (R1).
- **D2. Rajdhani.** Archivos estáticos 500 y 700 con `OFL.txt`; `fontFamily` del tema; hangul y hanja por *fallback* del sistema. ADR `docs/decisions/0005-tipografia-rajdhani.md` (R2).
- **D3. Sable horizontal y punta de frente.** `tip.y = 0.1` en `cut.start` y `cut.end` del transversal; el disco de la punta (`tipDiameter`, 0.3 u con largo 0) gana brillo y se dibuja sobre los guantes (R3, R4, [data-model §1, §5](./data-model.md#5-sable)).
- **D4. `SceneLayout`.** Una geometría por tamaño y patrón: `hudScale`, `hudBottom`, `unit`, `origin`, alcance y carriles de señal, zonas de botones. La figura entera queda bajo el HUD por construcción; las dos señales usan carriles fuera del alcance (R5, [data-model §2](./data-model.md#2-scenelayout-presentación)).
- **D5. Dojang.** `DojangPainter` en unidades de la figura, bandas a todo el ancho, viñeta debajo de la figura y de las señales, en `RepaintBoundary` (R6).
- **D6. Oponente.** Figura del boceto en unidades `u`, equipo blanco o gris claro, *hakama* y guantes carbón con luz de contorno; solo brazos y sable siguen las posturas (R7, [data-model §4](./data-model.md#4-figura-del-oponente)).
- **D7. Paleta y tema.** `AppColors` en grupos (señal, dojang, figura, interfaz); `ColorScheme` sin semilla amarilla; prueba de croma (R9, [data-model §3](./data-model.md#3-paleta-presentación)).
- **D8. Señales.** Formas compartidas en `signal_shapes.dart`. Flecha corta y gruesa con estela y brillo, anclada al borde exterior del carril; defensa en diagonal a 65° con hoja del color del sable, guarda gris (R10, [data-model §6](./data-model.md#6-señales)).
- **D9. Color del símbolo de defensa (confirmado el 2026-11-11).** La hoja del símbolo de defensa va del color del sable (azul o rojo), como la flecha de evasión y como en `Senales.dc.html` (FR-014). El responsable lo confirmó y se corrigió la línea de Assumptions de la spec, que decía que las señales mantenían sus colores actuales.
- **D10. HUD y botones.** Paneles con `hudScale`; segundos con el cálculo actual; barra con `1 − remaining / duration`; secuencia del patrón con cada término y su hangul. Volver abajo a la izquierda y Repetir abajo a la derecha, para no tapar los pies (R11, [data-model §7](./data-model.md#7-contenido-del-hud)).
- **D11. Selección.** Tarjetas con íconos generados (señal del nivel; silueta desde `cut.start`), resumen con la duración del proveedor de parámetros, INICIAR píldora blanca (R12, [data-model §8](./data-model.md#8-tarjetas-de-la-selección)).
- **D12. Pruebas.** Las pruebas de dominio no cambian; las de presentación ajustan finders y geometría según Assumptions; nuevas pruebas de `SceneLayout`, superposición, punta de frente, paleta, HUD y selección (R14, [contrato §6](./contracts/visual-ui.md#6-pruebas-que-dependen-de-este-contrato)).

## Project Structure

### Documentation (this feature)

```text
specs/004-experiencia-visual/
├── spec.md
├── plan.md                 # Este archivo
├── research.md             # Phase 0 (R1–R14)
├── data-model.md           # Phase 1 (catálogo, SceneLayout, paleta, figura, sable, señales, HUD, tarjetas, tipografía)
├── quickstart.md           # Phase 1 (pruebas automáticas, recorrido y pruebas con personas)
├── contracts/
│   └── visual-ui.md        # Catálogo, capas, interfaces de presentación, selección, tema
├── checklists/
│   └── requirements.md
└── tasks.md                # Phase 2 (/speckit-tasks; no lo crea este comando)
```

### Source Code (repository root)

Solo se listan los archivos que cambian o se crean; el resto es la estructura de la 001 ([plan de la 001](../001-motor-nivel1-frontal/plan.md#source-code-repository-root)).

```text
pubspec.yaml                                   # + flutter: fonts: Rajdhani 500/700 (sin dependencias)

assets/
├── catalog/catalog.json                       # transversal: tip.y = 0.1 en cut.start y cut.end
└── fonts/rajdhani/                            # nuevo
    ├── Rajdhani-Medium.ttf
    ├── Rajdhani-Bold.ttf
    └── OFL.txt

docs/decisions/
└── 0005-tipografia-rajdhani.md                # nuevo ADR

lib/presentation/
├── theme.dart                                 # paleta por grupos, ColorScheme neutro, Rajdhani, botones píldora
├── strings_es.dart                            # textos en mayúsculas, encabezado y subtítulo
├── providers.dart                             # + exerciseParametersProvider
├── scene/                                     # nuevo
│   ├── scene_layout.dart                      # SceneLayout
│   └── dojang_painter.dart                    # DojangPainter
├── exercise/
│   ├── exercise_controller.dart               # parámetros desde exerciseParametersProvider
│   ├── exercise_screen.dart                   # capas, HUD, botones, cuenta regresiva
│   ├── widgets/                               # nuevo
│   │   ├── hud_panel.dart                     # panel translúcido
│   │   ├── exercise_hud.dart                  # nivel, segundos + barra, patrón
│   │   └── countdown_text.dart                # número con contorno
│   └── painters/
│       ├── opponent_painter.dart              # figura con equipo, sable con brillo, punta de frente
│       ├── signal_painter.dart                # flecha con estela, defensa en diagonal, carriles
│       └── signal_shapes.dart                 # nuevo: formas compartidas
└── selection/
    ├── selection_screen.dart                  # fondo, encabezado, columnas, resumen, INICIAR
    ├── selection_card.dart                    # nuevo
    ├── level_icon.dart                        # nuevo
    └── pattern_icon_painter.dart              # nuevo

test/
├── data/catalog_json_mapper_test.dart         # transversal horizontal (reemplaza la regla (e) de la 002)
└── presentation/
    ├── scene_layout_test.dart                 # nuevo
    ├── palette_test.dart                      # nuevo
    ├── opponent_painter_test.dart             # sable horizontal, punta de frente, bajo el HUD, SC-004
    ├── signal_painter_test.dart               # formas nuevas, carriles, color, lado, dirección
    ├── exercise_screen_test.dart              # HUD, barra, botones; finders en mayúsculas
    └── selection_screen_test.dart             # tarjetas, palomita, resumen, íconos; finders
```

**Structure Decision**: El mismo proyecto Flutter de la 001, con carpetas por capa. Se agrega `lib/presentation/scene/` para la geometría y el fondo que comparten las dos pantallas.

## Complexity Tracking

Sin violaciones de la constitution que justificar.
