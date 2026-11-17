# ADR 0006: Carpeta de la app con `path_provider`

- **Estado**: Aprobado
- **Fecha**: 2026-11-16
- **Spec**: `specs/005-configuracion-parametros` (FR-010, FR-011)
- **Aprobó**: Adrián Solorza

## Contexto

La configuración del usuario debe conservarse al cerrar y volver a abrir la app (CA7) y guardarse como **JSON local** detrás de una interfaz de repositorio del dominio (Principio IV). Para escribir un archivo propio hace falta conocer la carpeta privada de la app en el dispositivo, y Flutter no la expone sin un paquete o sin código nativo.

## Decisión propuesta

Usar `path_provider` (paquete oficial del equipo de Flutter) solo en la capa de datos, para obtener la carpeta de documentos de la app. El JSON se lee y se escribe con `dart:io` en la implementación del repositorio de configuración. El dominio no conoce ni el paquete ni la ruta.

## Alternativas

| Opción                            | Pros                                                                                                                                    | Contras                                                                                       |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **`path_provider`** (recomendada) | Oficial, estándar y pequeño; cumple al pie de la letra el "JSON local" del Principio IV; el archivo es fácil de inspeccionar en pruebas | Una dependencia más                                                                           |
| `shared_preferences`              | Oficial; no toca archivos; API simple                                                                                                   | El JSON queda como una cadena dentro de las preferencias del sistema, no en un archivo propio |
| Canal nativo propio (Kotlin)      | Cero paquetes                                                                                                                           | Hay que escribir y mantener código nativo                                                     |

## Consecuencias

- El archivo vive en la carpeta privada de la app y se borra al desinstalarla o al borrar sus datos.
- Un backend futuro es solo otra implementación del repositorio, sin tocar el dominio.
- Las pruebas del repositorio pueden usar una carpeta temporal en lugar de `path_provider`.
