# ADR 0001: `flutter_riverpod` sin generación de código

- **Estado**: Aceptada
- **Fecha**: 2026-10-28
- **Spec**: `specs/001-motor-nivel1-frontal`
- **Aprobó**: responsable del proyecto

## Contexto

La constitution (Principio V) fija Riverpod como solución de gestión de estado, pero no dice qué variante usar. La Spec 001 necesita pocos providers: los puertos del dominio, el catálogo, la sesión seleccionada y el controlador del ejercicio.

## Decisión

Usar solo `flutter_riverpod`, con providers escritos a mano, sin `riverpod_annotation`, `riverpod_generator` ni `build_runner`. También se mantiene `flutter_lints` como dependencia de desarrollo, que viene en la plantilla estándar de `flutter create`.

## Alternativas

| Opción | Pros | Contras |
|---|---|---|
| **`flutter_riverpod` sin codegen** (elegida) | Un solo paquete, sin paso de build y compilación rápida | Algo más verboso |
| Con `riverpod_generator` | Menos código repetitivo | Tres paquetes más, `build_runner` y builds más lentos |

## Consecuencias

- Los puertos se reemplazan en las pruebas con `ProviderScope(overrides: ...)`.
- Si el número de providers crece mucho, se puede reconsiderar la generación de código en un ADR nuevo.
