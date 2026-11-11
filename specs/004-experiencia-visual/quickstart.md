# Quickstart: validar la experiencia visual

**Feature**: [spec.md](./spec.md) | **Datos**: [data-model.md](./data-model.md) | **Contrato**: [contracts/visual-ui.md](./contracts/visual-ui.md)

## Requisitos previos

- Los de la Spec 001 ([quickstart de la 001](../001-motor-nivel1-frontal/quickstart.md)): Flutter 3.47.7 / Dart 3.13.5 y un dispositivo Android de referencia (tablet de 10" o imagen enviada a una TV).
- Rama `004-experiencia-visual` con la spec implementada.
- Para las pruebas con personas: 3 observadores (SC-001 a SC-003) y 5 practicantes (SC-005); una cinta o marca a 3 m de la pantalla.
- Para SC-005: la versión anterior instalada en un segundo dispositivo, o un APK de `main` compilado en un worktree aparte (`git worktree add ../haidonggumdo-main main`, y ahí `flutter build apk --release`).

## 1. Pruebas automáticas

```bash
flutter analyze
flutter test
git diff --stat main -- lib/domain lib/data   # vacío: el dominio y los datos no cambian (FR-001)
git diff main -- assets/catalog/catalog.json  # solo las dos puntas del transversal (FR-010)
git diff main -- pubspec.yaml                 # solo la sección fonts:, sin dependencias nuevas
```

| Comprobación | Referencia |
|---|---|
| Todas las pruebas de dominio de las Specs 001 a 003 pasan sin cambios | SC-007 |
| Transversal: `tip.y == hilt.y` en `cut.start` y `cut.end`; reflejo exacto | FR-010 |
| `SceneLayout`: figura entre `hudBottom` y `floorLimit`; carriles fuera del alcance; botones fuera de la figura, en 20:9, 16:9, 16:10, 4:3 y teléfono | FR-007, FR-017 |
| Muestreo de píxeles: ninguna señal ni panel se superpone al oponente o a su sable en cada postura y tramo de los dos patrones y lados, en las 4 proporciones | SC-004 |
| A la mitad del barrido transversal hay un disco del color del sable de ≥ 0.3 u | FR-011 |
| Flecha: lado, dirección y color de la Spec 003; estela hacia el centro; nada fuera del carril | FR-013, FR-002 |
| Defensa: diagonal, hoja del color del sable, guarda gris, alto ≥ 0.30 h en 4:3, lado de la Spec 001 | FR-014 |
| Paleta: colores neutros con croma ≤ 0.10, excepciones de dojang listadas; el tema no usa colores de señal | FR-004, FR-005 |
| HUD: textos de los 4 combos desde el catálogo; segundos y barra avanzan | FR-015 |
| Selección: tarjetas en orden, Nivel 1 y Frontal preseleccionados, palomita, resumen, INICIAR en una acción; ícono para un patrón de prueba | FR-020 a FR-024 |

## 2. Recorrido en el dispositivo

```bash
flutter run --release -d <android-device-id>
```

Sin conexión (modo avión) para comprobar la tipografía incluida.

| # | Paso | Resultado esperado | Referencia |
|---|---|---|---|
| 1 | Abrir la app en modo avión | Dojang oscurecido; "HAIDONG GUMDO" en Rajdhani; subtítulo con 해동검도 sin cuadros vacíos; tarjetas NIVEL 1 y FRONTAL con palomita; nada amarillo | US4-1, US4-4, FR-026 |
| 2 | Mirar las tarjetas | Niveles con la señal en blanco y "respuesta — propósito"; patrones con silueta, secuencia y línea de hangul (en Transversal, sin hueco por *Sodose*) | US4-2, US4-3 |
| 3 | Elegir Nivel 2 + Transversal | Resumen "Nivel 2 · Transversal · 30 s" | US4-5 |
| 4 | Pulsar INICIAR | Cuenta 3, 2, 1 grande, blanca con contorno, sobre el dojang | FR-018 |
| 5 | Observar el HUD | "NIVEL 2 / Evasión lateral", segundos con barra que avanza, "TRANSVERSAL / Sodose → Hwengdan ilgôm begi 횡단일검베기", DETENER abajo a la izquierda | US3-1, US3-2 |
| 6 | Observar varios ataques | Sable horizontal a la cintura en *Sodose* y en todo el barrido; a la mitad, la punta de frente como disco del color; flecha corta con estela del color del sable, del lado de la Spec 003 | US1-4, US1-5, US2-1 |
| 7 | Esperar a *Guman* | VOLVER abajo a la izquierda, REPETIR abajo a la derecha, en píldora; Repetir conserva la sesión | FR-019 |
| 8 | Volver, elegir Nivel 1 + Frontal e iniciar | Símbolo de defensa en diagonal con hoja del color del sable, del lado de la Spec 001; en *Chochôn-se* la punta no toca el panel de los segundos | US2-2, caso límite |
| 9 | Pulsar DETENER durante un aviso | Vuelve a la selección sin sonido, como antes | FR-016 |
| 10 | Si hay dispositivo 4:3 o teléfono 20:9, repetir 6 y 8 | Dojang sin franjas; HUD y señales sin tapar al oponente | FR-007, FR-017 |

## 3. Pruebas con personas (dispositivo de referencia, a 3 m)

| Prueba | Procedimiento | Criterio de éxito | Referencia |
|---|---|---|---|
| Color y lado | 2 ejercicios por combinación (4 combos). Cada observador anota color y lado de la señal en cada ataque, también en la punta de frente | ≥ 2 de 3 observadores aciertan ≥ 95 % | SC-001 |
| Respuesta | Mismos ejercicios; cada observador dice "defender" o "evadir" | ≥ 2 de 3 aciertan ≥ 95 % | SC-002 |
| Regla de color | Mostrar las dos pantallas y preguntar "¿qué ves rojo, azul o amarillo?" | Nadie nombra algo que no sea el sable o una señal | SC-003 |
| Preferencia | App nueva y anterior lado a lado, 1 ejercicio en cada una; preguntar cuál prefieren y por qué | ≥ 4 de 5 prefieren la nueva; ≥ 3 de 5 dan un comentario concreto | SC-005 |
| Tiempos | Grabar un ejercicio a 60 fps y medir aviso, corte e intervalo con el método de la Spec 001 | Desvío < 50 ms y sin saltos visibles | SC-006 |
| Inicio | Cronometrar desde abrir la app hasta iniciar; luego cambiar a otra combinación | < 10 s con una acción; tres acciones para cambiar | SC-008 |

Si SC-001 falla en la punta de frente, subir el diámetro del disco (research R4). Si alguien nombra amarillo o rojo un elemento del dojang o los pies, ajustar ese token de paleta (research R7, R9).
