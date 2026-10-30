# Contrato: pantallas (presentación)

La app es solo horizontal y solo en español. El fondo es oscuro (`#121212`) y todos los elementos del ejercicio llevan contorno negro de al menos 4 dp (Principio VIII, FR-024–FR-026).

## Pantalla de selección (`SelectionScreen`)

| Elemento | Contenido | Origen |
|---|---|---|
| Lista "Nivel" | Una opción por `Level` del catálogo, ordenada por `order`: nombre, respuesta y propósito | Catálogo (FR-004) |
| Lista "Patrón" | Una opción por `Pattern` del catálogo: nombre, postura y corte como romanización + hangul | Catálogo + glosario (FR-003) |
| Selección inicial | El primer nivel y el primer patrón | FR-004 |
| Botón **Iniciar** | Abre la pantalla del ejercicio con la sesión elegida y `ExerciseParameters.defaults()` | FR-004, SC-001 |
| Estado de carga | Indicador mientras se carga el catálogo | — |
| Error de catálogo | Mensaje en español con el botón Iniciar desactivado | `CatalogException` |

No hay ningún texto de nivel o patrón escrito en el código de la pantalla. La prueba de SC-009 usa un catálogo con 2 niveles y 2 patrones de prueba.

## Pantalla del ejercicio (`ExerciseScreen`)

| Elemento | Comportamiento |
|---|---|
| Oponente virtual | Centrado. En `ready` está en reposo; desde *Si-jak* toma al instante la postura del patrón (FR-010a) |
| Sable | Color según `snapshot.saberColor`. En la fase `cut`, la empuñadura y la punta se interpolan entre `pattern.cut.start` y `pattern.cut.end` con `cutProgress` (FR-010, data-model.md `CutMotion`) |
| Señal | En `warning` y `cut`: símbolo de sable de defensa en `signal.screenSide`, con al menos 30 % del alto de la pantalla (FR-015, FR-016) |
| Cuenta regresiva | Número grande (3, 2, 1) en `countdown` (FR-009) |
| Tiempo restante | Discreto, en una esquina; no compite con la señal |
| Botón **Detener** | Visible en `countdown`, `running` y `finishing`; cancela (FR-021) |
| Fin | En `finished`: sable blanco y botones **Repetir** (misma sesión) y **Volver** (FR-014) |

### Efectos secundarios (los hace el controlador según los eventos)

| Evento o estado | Efecto |
|---|---|
| Entrar en `countdown` | `wakeLock.enable()` |
| `startVoice` | `voice.announce(start)` |
| `endVoice` | `voice.announce(end)` |
| `finished` | `wakeLock.disable()` |
| `cancelled` (Detener, `onHide` u `onPause`) | `voice.stop()`, `wakeLock.disable()` y navegación a la selección (FR-022, FR-023) |
