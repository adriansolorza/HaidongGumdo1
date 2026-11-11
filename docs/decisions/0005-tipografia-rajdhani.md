# ADR 0005: Tipografía Rajdhani incluida como asset

- **Estado**: Aceptada
- **Fecha**: 2026-11-10
- **Spec**: `specs/004-experiencia-visual` (FR-026)
- **Aprobó**: responsable del proyecto

## Contexto

La Spec 004 adopta el estilo "consola actual" de los bocetos aprobados (`docs/design/bocetos/Retro.dc.html` y `Seleccion.dc.html`), que usan la tipografía Rajdhani en pesos 500 y 700. La app debe funcionar sin conexión (se usa en el dojang) y no debe agregar paquetes sin aprobación (Principio VII). La interfaz muestra además términos en hangul (해동검도, 횡단일검베기) y hanja (海東劍道), que Rajdhani no incluye.

## Decisión

Incluir en la app los archivos estáticos `Rajdhani-Medium.ttf` (500) y `Rajdhani-Bold.ttf` (700) del repositorio oficial de Google Fonts (`ofl/rajdhani`), en `assets/fonts/rajdhani/`, y declararlos en la sección `fonts:` de `pubspec.yaml`, sin paquete. El tema usa `fontFamily: 'Rajdhani'`. El hangul y el hanja se muestran con la fuente del sistema mediante el *fallback* de glifos del motor de Flutter (en Android, Noto Sans CJK).

## Alternativas

| Opción | Pros | Contras |
|---|---|---|
| **Archivos de Rajdhani como asset** (elegida) | Sin paquete; funciona sin conexión; mismo aspecto que los bocetos | ≈ 0.8 MB más en la app |
| Paquete `google_fonts` | Configuración sencilla; muchas fuentes | Dependencia nueva; descarga en tiempo de ejecución salvo que se empaqueten los archivos igual |
| Fuente del sistema (Roboto) | Sin archivos ni aprobación | Pierde el estilo "consola actual" aprobado |
| Rajdhani + Noto Sans KR incluidas | Hangul idéntico en todas las plataformas | Varios MB más sin necesidad en Android, que ya trae CJK |

## Consecuencias

- La licencia SIL Open Font License 1.1 permite incluir la fuente en la app; el texto de la licencia va en `assets/fonts/rajdhani/OFL.txt`.
- Solo se incluyen los pesos 500 y 700. Un peso nuevo requiere agregar su archivo y su entrada en `pubspec.yaml`.
- Si una plataforma futura no trae una fuente con hangul y hanja, se reevalúa incluir Noto Sans KR.
