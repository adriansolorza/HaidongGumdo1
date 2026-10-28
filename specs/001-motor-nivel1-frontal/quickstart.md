# Quickstart: validar la Spec 001

Esta guía comprueba que la feature funciona de punta a punta. Los detalles están en [data-model.md](./data-model.md) y [contracts/](./contracts/).

## Requisitos previos

- Flutter 3.47.7 stable / Dart 3.13.5 (`flutter --version`).
- Un dispositivo Android (teléfono o tablet) con depuración USB, o un emulador Android.
- Para la prueba de legibilidad: una tablet de 10" o más, o una TV a la que se envíe la imagen del dispositivo.
- Opcional: un dispositivo **sin** voz coreana instalada, para probar FR-030.

## 1. Pruebas automáticas

```bash
flutter pub get
flutter analyze                     # sin errores ni advertencias
flutter test test/domain            # obligatorias (Principio VI)
flutter test                        # todo: dominio, datos y presentación
```

**Resultado esperado**: todo en verde. Las pruebas del dominio cubren G1–G10 de [contracts/domain-ports.md](./contracts/domain-ports.md) y las simulaciones de SC-003, SC-004 y SC-006.

Para comprobar que el dominio no importa Flutter (Principio II), este comando no debe devolver nada:

```bash
grep -rE "package:flutter|package:flutter_riverpod|package:flutter_tts|package:wakelock_plus" lib/domain
```

## 2. Ejecución en el dispositivo

```bash
flutter run --release -d <android-device-id>
```

| #   | Paso                                                                          | Resultado esperado                                                                                                                                          | Referencia          |
| --- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| 1   | Abrir la app                                                                  | Pantalla horizontal de selección con "Nivel 1 — Defensa — Calentamiento" y "Frontal — _Chochôn-se_ (초천세) → _Chungmyôn begi_ (정면베기)" ya seleccionados | FR-003, FR-004      |
| 2   | Pulsar **Iniciar**                                                            | Cuenta 3, 2, 1; se escucha _Si-jak_; el sable pasa de blanco a amarillo                                                                                     | CA6, FR-009         |
| 3   | Observar varios ataques                                                       | Sable azul → símbolo de sable a la **izquierda**; sable rojo → a la **derecha**. El corte se ve continuo, de arriba hacia el frente                         | CA2, FR-010, FR-015 |
| 4   | Contar los lados durante el ejercicio                                         | Nunca más de 5 seguidos al mismo lado                                                                                                                       | CA4                 |
| 5   | Esperar el fin (30 s)                                                         | Si termina durante un ataque, el corte se completa y después suena _Guman_. El sable vuelve a blanco y aparecen **Repetir** y **Volver**                    | CA5, FR-013, FR-014 |
| 6   | Iniciar y pulsar **Detener** durante el aviso                                 | Vuelve a la selección sin sonido                                                                                                                            | FR-021, SC-008      |
| 7   | Iniciar y pulsar el botón Inicio de Android durante un corte; volver a la app | Se ve la pantalla de selección; no se escuchó _Guman_                                                                                                       | FR-022, CL2         |
| 8   | Bajar la barra de notificaciones durante el ejercicio                         | El ejercicio **continúa**                                                                                                                                   | R10                 |
| 9   | Dejar el dispositivo sin tocar durante un ejercicio de 30 s                   | La pantalla no se apaga                                                                                                                                     | FR-028              |
| 10  | En un dispositivo sin voz coreana                                             | _Si-jak_ y _Guman_ se oyen con la voz predeterminada, pronunciando la romanización                                                                          | FR-030              |

## 3. Legibilidad a 3 m (manual, SC-007)

1. Coloca la tablet o la TV y marca 3 m en el suelo.
2. Al menos 10 observadores ven un ejercicio de 30 s cada uno y dicen en voz alta el color del sable y el lado de la señal en cada ataque. Una persona anota los aciertos.
3. **Criterio**: al menos 2 de 3 observadores aciertan en al menos el 95 % de los ataques.

## 4. Precisión de tiempos (SC-005)

Graba en video la pantalla a 60 fps o más y revisa un ejercicio cuadro a cuadro:

- La señal dura 0.7 s ± 50 ms antes de que empiece el corte.
- El corte dura 0.5 s ± 50 ms.
- Entre el inicio de un corte y la siguiente señal pasan entre 1.0 s y 2.5 s.
