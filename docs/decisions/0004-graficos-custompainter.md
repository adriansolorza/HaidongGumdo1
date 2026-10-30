# ADR 0004: Oponente virtual y señales con `CustomPainter`

- **Estado**: Aceptada
- **Fecha**: 2026-10-28
- **Spec**: `specs/001-motor-nivel1-frontal` (FR-010, FR-015, FR-025)
- **Aprobó**: responsable del proyecto

## Contexto

El oponente virtual, el sable y las señales deben tener contornos definidos y alto contraste, y verse a 3 m (Principio VIII, FR-025). El corte se anima y debe durar exactamente la velocidad del corte. El color del sable cambia según el estado.

## Decisión

Dibujar al oponente, el sable y las señales con `CustomPainter` de Flutter, sin paquetes. La posición del sable durante el corte se calcula a partir del progreso del corte que entrega el dominio.

## Alternativas

| Opción | Pros | Contras |
|---|---|---|
| **`CustomPainter`** (elegida) | Sin paquetes; control exacto de contornos, colores y ángulo en función del tiempo | Figura estilizada, no ilustrada |
| Rive o Lottie | Figura más rica | Paquete extra, archivos de diseño externos y sincronización de duración y color más difícil |

## Consecuencias

- El painter interpola la empuñadura y la punta del sable entre las posiciones que define el catálogo para cada patrón (`cut`: `start`, `end`, `mirroredBySide`). Un corte nuevo expresable así (p. ej. *Hwengdan ilgôm begi*, Spec 003) es solo datos; uno que no lo sea requiere ampliar el painter y el modelo.
