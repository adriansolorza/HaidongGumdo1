# Quickstart: Configuración de parámetros e invariante de tiempos

**Feature**: [spec.md](./spec.md) | **Contrato**: [contracts/settings-ui.md](./contracts/settings-ui.md)

## Requisitos previos

- Rama `005-configuracion`, con `path_provider` agregado (ADR 0006).
- Dispositivo o emulador Android en horizontal.

## 1. Pruebas automáticas

```powershell
flutter analyze
flutter test                                          # todo (SC-008: 001 a 004 siguen pasando)
flutter test test/domain/parameter_editor_test.dart   # pasos, límites, ajuste, recorrido exhaustivo (SC-003, SC-004)
flutter test test/data                                # mapper y repositorio de archivo (SC-002, SC-007)
flutter test test/presentation/settings_screen_test.dart test/presentation/selection_screen_test.dart
```

Resultado esperado: todo en verde y ningún import de Flutter ni de `path_provider` en `lib/domain/`:

```powershell
Select-String -Path lib/domain -Pattern "package:flutter|path_provider" -Recurse   # sin resultados
```

## 2. Recorrido manual

| # | Paso | Resultado esperado | Spec |
|---|---|---|---|
| 1 | Instalación nueva → abrir la app | Resumen "Nivel 1 · Frontal · 30 s" | Edge "Primera vez" |
| 2 | CONFIGURACIÓN | Valores 30 s, 5, 0.7 s, 0.5 s, 2.5 s; rango "entre 1.0 s y 2.5 s" | US1-1, FR-005 |
| 3 | Duración: + tres veces | "1 min 15 s"; con 3 min, el + se desactiva | US1-3, FR-006 |
| 4 | Aviso: − hasta el mínimo | 0.65 … 0.35, 0.33; el − se desactiva | FR-004 |
| 5 | Intervalo: − hasta el mínimo | 1.0 s; el − se desactiva; rango "Cada ataque: 1.0 s" | US2-2 |
| 6 | Corte: + hasta 0.8 s | El intervalo sube a 1.1, 1.2 y 1.3 s; aviso "Intervalo ajustado a 1.3 s…" | US2-1, FR-008 |
| 7 | Corte: − hasta 0.5 s | El intervalo se queda en 1.3 s | US2-4 |
| 8 | CANCELAR | Resumen sin cambios; al volver a abrir, valores anteriores | US3-1 |
| 9 | Repetir 3 y 4, GUARDAR | Resumen "… · 1 min 15 s" | US1-5 |
| 10 | INICIAR | Señal → corte en ≈ 0.33 s; el HUD cuenta desde 75 s | US1-4, SC-005 |
| 11 | Cerrar la app desde recientes y volver a abrir | Resumen y configuración iguales al paso 9 | US1-7, CA7 |
| 12 | RESTABLECER → CANCELAR | Configuración guardada sin cambios | US3-4 |
| 13 | RESTABLECER → GUARDAR | Resumen "… · 30 s"; valores por defecto | US3-3 |
| 14 | Con `adb`, escribir basura en `settings.json` y reabrir | La app abre con valores por defecto, sin errores | FR-012 |

Para el paso 14 (build de depuración):

```powershell
adb shell "run-as <applicationId> sh -c 'echo basura > app_flutter/settings.json'"
```

## 3. Pruebas con personas

- **SC-001**: 3 personas cambian el tiempo de aviso, guardan y vuelven a la selección; cronometrar menos de 20 s cada una.
- **SC-006**: 3 observadores revisan la pantalla con el aviso de ajuste visible y con el error de guardado forzado (build de depuración con un repositorio que falla). Ninguno nombra rojo, azul o amarillo.
- **FR-019**: revisar la pantalla en un teléfono 20:9 y en una tablet 4:3, también con la letra del sistema al 130 %: las acciones siempre visibles y la lista desplazable.
