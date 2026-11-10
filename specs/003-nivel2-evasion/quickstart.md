# Quickstart: validar el Nivel 2 (señal de evasión)

**Feature**: [spec.md](./spec.md) | **Datos**: [data-model.md](./data-model.md) | **Contrato**: [contracts/catalog-and-signal.md](./contracts/catalog-and-signal.md)

## Requisitos previos

- Los de la Spec 001 ([quickstart de la 001](../001-motor-nivel1-frontal/quickstart.md)): Flutter 3.47.7 / Dart 3.13.5 y un dispositivo Android (tablet de 10" o más, o imagen enviada a una TV, para las pruebas a 3 m).
- Rama `003-nivel2-evasion` con el Nivel 2 en `assets/catalog/catalog.json` y la señal de evasión implementada.

## 1. Pruebas automáticas

```bash
flutter analyze
flutter test
git diff --stat main -- lib   # solo enums.dart, signal.dart, signal_painter.dart y exercise_screen.dart (más, si hace falta, la unidad pública de opponent_painter.dart)
```

Qué deben comprobar las pruebas nuevas o ajustadas:

| Comprobación | Referencia |
|---|---|
| Evasión con azul → señal a la derecha; con rojo → a la izquierda; la defensa no cambia | FR-006, CA1 |
| El motor con una sesión de Nivel 2 genera ataques `evasion`, y la señal del snapshot está del lado del color desde la señal hasta el fin del corte | FR-009 |
| Las simulaciones de aleatoriedad, N y tiempos de la 001 dan los mismos resultados con el Nivel 2 y los dos patrones | SC-006 |
| El asset real tiene 2 niveles en orden; `level_2` con "Evasión lateral", "Calentamiento / base" y `["evasion"]` | FR-001 |
| La flecha se dibuja en la mitad correcta, con el color del sable, la punta hacia el borde, y sin píxeles dentro del alcance del oponente en 20:9, 16:9, 16:10 y 4:3; izquierda y derecha son reflejos | FR-007, FR-008 |
| El alcance de la flecha (1.45 u) cubre el mayor `|x|` de los patrones del catálogo real | FR-007 |
| La selección muestra Nivel 1 (preseleccionado) y Nivel 2 con "Evasión lateral — Calentamiento / base"; Iniciar con Nivel 2 abre el ejercicio con ese nivel; Repetir lo conserva; Volver permite elegir el Nivel 1 | FR-004, FR-005, US3 |
| Las pruebas de las Specs 001 y 002 siguen pasando sin cambiar sus expectativas sobre la lógica del ejercicio | FR-012, SC-007 |

## 2. Ejecución en el dispositivo

```bash
flutter run --release -d <android-device-id>
```

| # | Paso | Resultado esperado | Referencia |
|---|---|---|---|
| 1 | Abrir la app | La lista "Nivel" muestra Nivel 1 (preseleccionado) y Nivel 2 "Evasión lateral — Calentamiento / base" | US3-1 |
| 2 | Elegir Nivel 2 + Transversal y pulsar **Iniciar** | Cuenta 3, 2, 1, *Si-jak*, sable de blanco a amarillo | US1 |
| 3 | Observar ataques azules | Flecha **azul** a la **derecha**, apuntando a la derecha, sin símbolo de defensa; *Sodose* y el inicio del corte a la **izquierda** | US1-1, US1-3 |
| 4 | Observar ataques rojos | Flecha **roja** a la **izquierda**, apuntando a la izquierda; *Sodose* a la **derecha** | US1-2, US1-3 |
| 5 | Observar el final de cada barrido | El sable termina extendido hacia el lado de la flecha sin tocarla; la flecha desaparece al terminar el corte | US1-4, caso límite |
| 6 | Pulsar **Repetir** al terminar | El nuevo ejercicio sigue siendo Nivel 2 + Transversal | US3-2 |
| 7 | **Volver**, elegir Nivel 2 + Frontal e iniciar | Flecha del color del sable; el oponente sube a *Chochôn-se* y corta igual que en el Nivel 1 | US2 |
| 8 | **Volver**, elegir Nivel 1 e iniciar | Símbolo de defensa blanco, sin flecha | FR-012, US3-3 |
| 9 | Pulsar **Detener** con una flecha visible | Vuelve a la selección sin sonido | FR-011 (cancelación de la 001) |

Si hay a mano un dispositivo 4:3 o 16:10, repetir el paso 5: la flecha es más corta, pero nunca se cruza con el sable.

## 3. Pruebas a 3 m (manuales)

1. **Legibilidad de la flecha (SC-004)**: como en la 001 (quickstart §3), con ejercicios de Nivel 2 y los dos patrones. Los observadores dicen el lado de la flecha en cada ataque, también al final del barrido transversal. Criterio: al menos 2 de 3 aciertan en al menos el 95 % de los ataques.
2. **Defender o evadir (SC-005)**: alterna ejercicios de Nivel 1 y Nivel 2 sin anunciar cuál es. Los observadores dicen "defender" o "evadir" en cada ataque. Criterio: al menos 2 de 3 aciertan en al menos el 95 %.

Si la flecha azul se lee mal sobre el fondo oscuro, el ajuste previsto es un contorno claro, solo en el painter (research R5). Si falla en 4:3 por el largo, se sube la flecha sobre la línea de la cintura (research R4).

## 4. Tiempos

Igual que el quickstart §4 de la 001, grabando un ejercicio de Nivel 2 a 60 fps o más. Los tiempos no deben cambiar respecto del Nivel 1.
