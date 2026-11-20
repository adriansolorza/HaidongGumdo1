# Quickstart: validar el Nivel 4

**Spec**: [spec.md](./spec.md) · **Contratos**: [counter-signal.md](./contracts/counter-signal.md), [selection-ui.md](./contracts/selection-ui.md)

## Requisitos

- Flutter 3.47.7 / Dart 3.13.5 (sin cambios).
- Rama `007-nivel4-contraataque`.
- Un dispositivo o emulador Android en horizontal, y de preferencia una pantalla de 50" o más para la prueba a 3 m.

## 1. Pruebas automáticas

```powershell
flutter analyze
flutter test
```

Resultado esperado: todo pasa. En particular:

| Suite | Qué demuestra |
|---|---|
| `test/domain/exercise_engine_sequence_regression_test.dart` | Los Niveles 1 y 2 producen las mismas secuencias (sin cambios en la prueba) |
| `test/domain/signal_placement_test.dart` | `counter` va del lado del color |
| `test/domain/exercise_engine_level4_test.dart` | Todo ataque es `counter`; lados e instantes iguales a los del Nivel 2 con la misma semilla; rachas ≤ N (SC-004); proporción de lados (SC-005) |
| `test/data/catalog_json_mapper_test.dart` | 4 niveles en orden, `level_4` con sus textos (FR-001) |
| `test/presentation/signal_painter_test.dart` | P1 a P7 del contrato, en 7 lienzos, 2 patrones y todas las fases (SC-009) |
| `test/presentation/level_icon_test.dart` | I1 a I3 |
| `test/presentation/selection_screen_test.dart` | 4 tarjetas reales sin desplazar en 7 lienzos (SC-008) |
| `test/presentation/exercise_screen_test.dart` | Una sola señal por ataque; HUD "NIVEL 4" |

## 2. Recorrido manual

```powershell
flutter run
```

1. **Selección (US3).** La columna NIVEL muestra 4 tarjetas sin desplazar, con el Nivel 1 marcado. La cuarta dice "Nivel 4" y "Evasión y contraataque — Combate", y su ícono es una flecha con un sable vertical, en blanco.
2. **Nivel 4 + Transversal (US1).** Pulsa INICIAR y observa la cuenta 3, 2, 1, *Si-jak* y luego, en cada ataque:
   - con azul, la señal está a la **derecha**: flecha hacia la derecha y sable vertical azul junto a la punta;
   - con rojo, está a la **izquierda**, con la flecha hacia la izquierda;
   - el corte sale del costado contrario a la señal;
   - la señal desaparece al terminar el corte;
   - no aparece nunca el símbolo de defensa solo ni la flecha sola.
3. **Nivel 4 + Frontal (US2).** Se observa lo mismo. El oponente sube a *Chochôn-se* sin revelar el lado.
4. **Repetir y Volver.** Repetir conserva Nivel 4 y el patrón. Al volver, los Niveles 1, 2 y 3 se comportan igual que antes.
5. **Comparar tamaños.** Juega un ejercicio de Nivel 2 y otro de Nivel 4 en el mismo dispositivo: la flecha del Nivel 4 se ve igual o apenas más chica (nunca menos de tres cuartos).

## 3. Pruebas con observadores

- **SC-006.** A 3 m, con el tiempo de aviso por defecto (0.7 s), al menos 2 de 3 observadores distinguen el contraataque de la evasión sola y dicen el lado en ≥ 95 % de los ataques. Incluye el final del barrido transversal.
- **SC-007.** En la selección, al menos 2 de 3 observadores leen "evadir y cortar" en el ícono sin leer el texto.
- **SC-001.** Desde que se abre la app, el ejercicio de Nivel 4 empieza en menos de 15 s y con 3 acciones como máximo.
