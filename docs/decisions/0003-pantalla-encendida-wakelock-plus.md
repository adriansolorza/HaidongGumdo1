# ADR 0003: Pantalla encendida con `wakelock_plus`

- **Estado**: Aceptada
- **Fecha**: 2026-10-28
- **Spec**: `specs/001-motor-nivel1-frontal` (FR-028)
- **Aprobó**: responsable del proyecto

## Contexto

La pantalla no debe apagarse por inactividad mientras el ejercicio está en curso: el usuario entrena a distancia y no toca el dispositivo.

## Decisión

Usar `wakelock_plus` detrás del puerto de dominio `ScreenWakeLock`. Se activa al empezar la cuenta regresiva y se desactiva al terminar o cancelar el ejercicio.

## Alternativas

| Opción | Pros | Contras |
|---|---|---|
| **`wakelock_plus`** (elegida) | Estándar en la comunidad; solo `enable` y `disable` | Una dependencia más |
| Canal nativo propio (`FLAG_KEEP_SCREEN_ON`) | Cero paquetes | Código nativo propio |

## Consecuencias

- El bloqueo solo está activo durante el ejercicio. Fuera de él, la pantalla se comporta según la configuración del sistema.
