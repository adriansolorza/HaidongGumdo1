# Entrada para la constitution — HaidongGumdo

> Texto para el comando de constitution de Spec Kit. Son principios que aplican a **todas** las features del proyecto. No describe funcionalidad: esa vive en `docs/brief.md` y en las specs.
>
> Los puntos marcados con *(sugerido)* los propuso Claude. Confírmalos o quítalos antes de usar este texto.

## Principios

### I. Stack
- Flutter y Dart, en el canal **stable** más reciente con soporte vigente al iniciar el proyecto.
- La versión del SDK queda fijada en `pubspec.yaml`. Una actualización mayor de Flutter o Dart requiere aprobación explícita. *(sugerido)*

### II. Clean Architecture
- Capas separadas: **dominio**, **datos** y **presentación**.
- El **dominio es Dart puro**: no importa Flutter ni paquetes de infraestructura.
- Las dependencias apuntan hacia el dominio, nunca al revés.

### III. Datos sobre código
- Patrones, niveles y glosario se definen como **datos** (JSON de solo lectura incluido en la app).
- Agregar un patrón o un nivel no debe requerir cambios en la lógica del dominio, salvo que introduzca un tipo de señal nuevo.

### IV. Persistencia
- Sin backend en la v1.
- La configuración del usuario se guarda en **JSON local**.
- Toda persistencia pasa por **interfaces de repositorio definidas en el dominio**. Un backend futuro debe ser solo otra implementación, sin tocar el dominio.

### V. Gestión de estado
- **Riverpod.**

### VI. Pruebas
- Las pruebas se escriben **después del código**, pero son **obligatorias para el dominio** antes de cerrar cada historia de usuario.
- Las pruebas se derivan de los **criterios de aceptación de la spec**, no del código ya escrito.
- Las reglas de secuencia aleatoria, el máximo de N repeticiones seguidas y la invariante de tiempos deben tener pruebas.
- La fuente de aleatoriedad y el reloj se **inyectan** en el dominio, para que las pruebas sean deterministas. *(sugerido)*

### VII. Dependencias y decisiones de la IA
- La IA **no agrega paquetes por su cuenta**. Propone opciones con pros, contras y una recomendación, y el responsable del proyecto aprueba.
- Cada decisión aprobada queda registrada en `docs/decisions/` (formato ADR). *(sugerido)*

### VIII. Interfaz
- Alto contraste y legibilidad a distancia: el oponente virtual, el sable y las señales deben tener contornos definidos.
- Orientación horizontal preferente.

### IX. Idioma y terminología
- Código e identificadores en **inglés**. Interfaz en **español** para esta versión.
- Los términos coreanos se usan siempre exactamente como en el glosario (romanización + hangul).

### X. Flujo de trabajo
- Una rama por spec y Pull Request a `main`.
- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`).

### XI. Seguridad y alcance
- Sin autenticación ni autorización en la v1.

## Gobernanza
- Solo el responsable del proyecto aprueba cambios a esta constitution. La IA puede proponerlos, pero no aplicarlos.
- La constitution se versiona (semver) y cada cambio indica qué principio se modificó.
