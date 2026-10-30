# ADR 0002: Voz sintética con `flutter_tts`

- **Estado**: Aceptada
- **Fecha**: 2026-10-28
- **Spec**: `specs/001-motor-nivel1-frontal` (FR-029, FR-030)
- **Aprobó**: responsable del proyecto

## Contexto

Las voces *Si-jak* (시작) y *Guman* (그만) deben producirse con la voz sintética del dispositivo en coreano. Si el dispositivo no tiene voz coreana, se usa su voz predeterminada.

## Decisión

Usar el paquete `flutter_tts` detrás del puerto de dominio `VoiceAnnouncer`, implementado en la capa de datos.

## Alternativas

| Opción | Pros | Contras |
|---|---|---|
| **`flutter_tts`** (elegida) | Maduro y muy usado; consulta los idiomas disponibles y permite elegir voz | Una dependencia externa |
| Canal nativo propio (Kotlin `TextToSpeech`) | Cero paquetes | Código nativo que mantener |
| Audios grabados | Pronunciación controlada | Descartado en la aclaración Q4 de la spec |

## Consecuencias

- El dominio no conoce `flutter_tts`. Cambiar de motor de voz es otra implementación de `VoiceAnnouncer`.
- Con voz coreana se pronuncia el hangul. Con la voz predeterminada, la romanización del glosario.
