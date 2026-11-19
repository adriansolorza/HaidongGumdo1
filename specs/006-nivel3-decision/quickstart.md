# Quickstart: validar el Nivel 3

**Feature**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md)

## Requisitos previos

- Flutter 3.47.7 / Dart 3.13.5 (sin cambios), rama `006-nivel3-decision`.
- `flutter pub get`.

## 1. Pruebas automáticas

```powershell
flutter analyze
flutter test
```

**Resultado esperado**: todo en verde. En particular:

| Suite | Qué demuestra |
|---|---|
| `test/domain/exercise_engine_sequence_regression_test.dart` | Las secuencias de los Niveles 1 y 2 son idénticas a las de antes del cambio ([contrato E1](./contracts/domain-sequencer.md#2-orden-de-los-sorteos-en-exerciseengine)) |
| `test/domain/streak_sequencer_test.dart` | Las expectativas del antiguo `SideSequencer` se mantienen (G1), y una sola opción no consume sorteos (G2) |
| Pruebas del motor del Nivel 3 | Rachas de lado y de tipo ≤ N, proporciones y orden de sorteos (SC-004, SC-005) |
| `test/data/catalog_json_mapper_test.dart` | El asset tiene tres niveles y `level_3` tiene `[defense, evasion]` |
| `test/presentation/selection_screen_test.dart` | Las tarjetas se ven sin desplazar en los 7 lienzos, con 3 y 4 niveles (SC-007a) |

Las suites de las Specs 001 a 005 no cambian sus expectativas. Las únicas excepciones son la enumeración de niveles del asset y el renombre del secuenciador.

## 2. Validación manual (dispositivo en horizontal)

1. **Selección**: abre la app. Deben verse las tres tarjetas de nivel y las dos de patrón sin desplazar. La tarjeta "NIVEL 3" muestra el sable y la flecha en blanco. El Nivel 1 está preseleccionado. Repite la comprobación en un teléfono en horizontal.
2. **Nivel 3 + Transversal**: inicia con N = 5 y desde 3 m comprueba en cada ataque ([spec US1](./spec.md#user-story-1---decidir-entre-defender-y-evadir-ante-el-corte-transversal-priority-p1)):
   - aparece una sola señal;
   - sable azul: el símbolo de defensa sale a la izquierda o la flecha a la derecha;
   - sable rojo: es al revés;
   - el corte sale del costado que indica el color;
   - el HUD muestra "NIVEL 3 · Defensa o evasión lateral".
3. **Nivel 3 + Frontal**: en un ejercicio de 1 min aparecen defensas y evasiones, y el oponente se mueve igual que en los Niveles 1 y 2.
4. **N = 1** (Configuración): lados y tipos se alternan, y la señal queda siempre en la misma mitad de la pantalla (caso límite documentado).
5. **Niveles 1 y 2**: se juegan igual que antes: solo el símbolo de defensa o solo la flecha.
6. **Repetir y Volver**: conservan el Nivel 3 y permiten volver al Nivel 1 o al 2.
