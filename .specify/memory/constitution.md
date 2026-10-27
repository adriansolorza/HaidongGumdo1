<!--
## Sync Impact Report
- Version change: 0.0.0 → 1.0.0
- This is the initial ratification; no previous version exists.
- Added principles: I. Stack, II. Clean Architecture, III. Datos sobre código,
  IV. Persistencia, V. Gestión de estado, VI. Pruebas,
  VII. Dependencias y decisiones de la IA, VIII. Interfaz,
  IX. Idioma y terminología, X. Flujo de trabajo, XI. Seguridad y alcance
- Added sections: Restricciones de la v1, Flujo de desarrollo, Governance
- Removed sections: (none)
- Follow-up TODOs: (none)
-->

# HaidongGumdo Constitution

## Core Principles

### I. Stack

- Flutter y Dart, en el canal **stable** más reciente con soporte vigente
  al iniciar el proyecto.
- La versión del SDK queda fijada en `pubspec.yaml`. Una actualización
  mayor de Flutter o Dart DEBE contar con aprobación explícita del
  responsable del proyecto.

### II. Clean Architecture

- Capas separadas: **dominio**, **datos** y **presentación**.
- El dominio es Dart puro: NO DEBE importar Flutter ni paquetes de
  infraestructura.
- Las dependencias apuntan hacia el dominio, nunca al revés.

### III. Datos sobre código

- Patrones, niveles y glosario se definen como **datos** (JSON de solo
  lectura incluido en la app).
- Agregar un patrón o un nivel NO DEBE requerir cambios en la lógica del
  dominio, salvo que introduzca un tipo de señal nuevo.

### IV. Persistencia

- Sin backend en la v1.
- La configuración del usuario se guarda en **JSON local**.
- Toda persistencia pasa por **interfaces de repositorio definidas en el
  dominio**. Un backend futuro DEBE ser solo otra implementación, sin
  tocar el dominio.

### V. Gestión de estado

- **Riverpod** es la solución de gestión de estado del proyecto.

### VI. Pruebas

- Las pruebas se escriben **después del código**, pero son **obligatorias
  para el dominio** antes de cerrar cada historia de usuario.
- Las pruebas se derivan de los **criterios de aceptación de la spec**,
  no del código ya escrito.
- Las reglas de secuencia aleatoria, el máximo de N repeticiones seguidas
  y la invariante de tiempos DEBEN tener pruebas.
- La fuente de aleatoriedad y el reloj se **inyectan** en el dominio,
  para que las pruebas sean deterministas.

### VII. Dependencias y decisiones de la IA

- La IA **NO agrega paquetes por su cuenta**. Propone opciones con pros,
  contras y una recomendación; el responsable del proyecto aprueba.
- Cada decisión aprobada queda registrada en `docs/decisions/` (formato
  ADR).

### VIII. Interfaz

- Alto contraste y legibilidad a distancia: el oponente virtual, el sable
  y las señales DEBEN tener contornos definidos.
- Orientación horizontal preferente.

### IX. Idioma y terminología

- Código e identificadores en **inglés**. Interfaz en **español** para
  esta versión.
- Los términos coreanos se usan siempre exactamente como en el glosario
  (romanización + hangul).

### X. Flujo de trabajo

- Una rama por spec y Pull Request a `main`.
- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`,
  `test:`).

### XI. Seguridad y alcance

- Sin autenticación ni autorización en la v1.

## Restricciones de la v1

- Sin backend: toda persistencia es local (Principio IV).
- Sin autenticación ni autorización (Principio XI).
- Interfaz en español únicamente (Principio IX).

## Flujo de desarrollo

- Una rama por spec; merge a `main` vía Pull Request.
- Conventional Commits obligatorios (ver Principio X).
- Los paquetes nuevos requieren aprobación explícita (ver Principio VII).
- Las pruebas del dominio DEBEN pasar antes de cerrar la historia
  (ver Principio VI).

## Governance

- Esta constitution es el documento de mayor jerarquía del proyecto.
  Ante un conflicto con cualquier otra práctica o documento, prevalece
  la constitution.
- Solo el responsable del proyecto aprueba cambios a esta constitution.
  La IA puede proponerlos, pero NO aplicarlos.
- La constitution se versiona con semver. Cada cambio DEBE indicar qué
  principio se modificó.
- Procedimiento de enmienda:
  1. Propuesta documentada (qué cambia y por qué).
  2. Aprobación del responsable del proyecto.
  3. Actualización del archivo con nuevo número de versión y fecha.
- Revisión de cumplimiento: cada Pull Request DEBE verificar que no
  contradice los principios vigentes.

**Version**: 1.0.0 | **Ratified**: 2026-10-26 | **Last Amended**: 2026-10-26
