# Quickstart: validar el Patrón transversal

**Feature**: [spec.md](./spec.md) | **Datos**: [data-model.md](./data-model.md) | **Contrato**: [contracts/catalog-entries.md](./contracts/catalog-entries.md)

## Requisitos previos

- Los de la Spec 001 ([quickstart de la 001](../001-motor-nivel1-frontal/quickstart.md)): Flutter 3.47.7 / Dart 3.13.5 y un dispositivo Android (tablet de 10" o más, o imagen enviada a una TV, para las pruebas a 3 m).
- Rama `002-patron-transversal` con las entradas de [catalog-entries.md](./contracts/catalog-entries.md) en `assets/catalog/catalog.json`.

## 1. Pruebas automáticas

```bash
flutter analyze
flutter test test/domain      # lógica del ejercicio: debe pasar sin cambios
flutter test                  # todo, incluido el catálogo real con 2 patrones
git diff --stat main -- lib   # FR-002 / SC-007: no debe listar archivos de lib/
```

Qué deben comprobar las pruebas nuevas o ajustadas:

| Comprobación | Referencia |
|---|---|
| El asset real tiene 2 patrones (frontal y transversal, en ese orden) y 7 términos; *Sodose* sin hangul y *Hwengdan ilgôm begi* / 횡단일검베기 exactos | FR-001, FR-003 |
| El patrón `transversal` tiene la guardia, *Sodose*, el fin del barrido (reflejo de *Sodose*) y `mirroredBySide: true` de data-model.md | FR-007, FR-008, FR-011 |
| La selección muestra los dos patrones, preselecciona el frontal y muestra "Chayôn-se (자연세) → Sodose → Hwengdan ilgôm begi (횡단일검베기)" | FR-004, US2 |
| Iniciar con el transversal abre el ejercicio con ese patrón, y Repetir lo conserva | FR-005, US2 |
| Con el transversal, el movimiento del oponente sigue los tramos de la 001 (subida, arriba, corte, regreso) y el costado depende del lado | FR-007, FR-010 |
| Las simulaciones de aleatoriedad, N y tiempos de la 001 dan los mismos resultados con una sesión transversal | SC-005, SC-006 |

## 2. Ejecución en el dispositivo

```bash
flutter run --release -d <android-device-id>
```

| # | Paso | Resultado esperado | Referencia |
|---|---|---|---|
| 1 | Abrir la app | La lista "Patrón" muestra Frontal (preseleccionado) y Transversal con sus tres términos | FR-004 |
| 2 | Elegir Transversal y pulsar **Iniciar** | Cuenta 3, 2, 1 con el oponente en *Chayôn-se*; *Si-jak*; sable de blanco a amarillo | US1-1 |
| 3 | Observar ataques azules | Símbolo de defensa a la **izquierda**; el oponente lleva el sable a *Sodose* en el costado **izquierdo** de la pantalla, con las manos a la cintura, y se queda quieto. Después barre en horizontal a la cintura: pasa frente al oponente a la mitad (hoja corta, apuntando al usuario) y termina con el sable extendido hacia el costado **derecho** | US1-2, US1-4, US1-5 |
| 4 | Observar ataques rojos | Todo reflejado: símbolo y *Sodose* a la **derecha** | US1-3, FR-011 |
| 5 | Observar el fin de cada corte | El sable vuelve a amarillo, la señal desaparece y el oponente regresa a *Chayôn-se*; nunca pasa directo de un costado al otro | US1-6, FR-010 |
| 6 | Esperar el fin (30 s) | Si termina durante un ataque, se completa y después suena *Guman*; aparecen **Repetir** y **Volver** | US1-8 |
| 7 | Pulsar **Repetir** | El nuevo ejercicio también es transversal | US2-2 |
| 8 | Pulsar **Volver**, elegir Frontal e iniciar | Ejercicio frontal normal, sin reiniciar la app | US2-3 |
| 9 | Pulsar **Detener** durante un corte transversal | Vuelve a la selección sin sonido | FR-012 (cancelación de la 001) |

## 3. Pruebas a 3 m (manuales)

1. **Legibilidad (SC-003)**: como en la 001 (quickstart §3), con ejercicios transversales. Los observadores dicen el color del sable y el lado de la señal en cada ataque, también cuando el sable pasa frente al oponente (hoja en escorzo, a la mitad del barrido). Criterio: al menos 2 de 3 aciertan en al menos el 95 % de los ataques.
2. **Distinguir patrones (SC-004)**: alterna ejercicios frontales y transversales sin anunciar cuál es. Los observadores dicen "frontal" o "transversal" en cada ataque. Criterio: al menos 2 de 3 aciertan en al menos el 95 %.

Si alguna falla, se ajustan las posiciones del patrón en `assets/catalog/catalog.json` (solo datos) y se repite. Si con datos no alcanza, se vuelve al plan (FR-002).

## 4. Tiempos (SC-005)

Igual que el quickstart §4 de la 001, grabando un ejercicio transversal a 60 fps o más.
