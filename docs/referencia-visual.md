# Referencia visual — Spec 004 (estilo B: consola actual)

Bocetos aprobados por el responsable. Las fuentes están en `docs/design/bocetos/` (HTML + SVG). Las coordenadas de esos archivos son de los bocetos (1280 × 800 px), **no** del sistema de coordenadas del catálogo de la app.

| Archivo | Qué muestra |
|---|---|
| `Retro.dc.html` | Pantalla del ejercicio (estilo B elegido): oponente en *Sodose*, sable rojo, flecha de evasión a la izquierda |
| `Seleccion.dc.html` | Pantalla de selección de nivel y patrón |
| `Senales.dc.html` | Señales: evasión actual vs. propuesta, defensa y contraataque (dibujadas en el estilo cómico A; usar solo su forma) |
| `flecha-evasion-boceto.png` | Boceto original del responsable para la flecha |

## Regla de color (la más importante)

- **Rojo, azul y amarillo son exclusivos del sable y de las señales.** Ningún otro elemento los usa: ni la interfaz, ni el equipo del oponente, ni el fondo.
- La interfaz usa solo blanco, grises y fondos oscuros translúcidos.
- El equipo de protección es blanco o gris muy claro (en competencia real es rojo o azul; aquí no, para no competir con la señal).

## Paleta del boceto B

| Elemento | Color |
|---|---|
| Pared del dojang | degradado vertical `#aaa598` → `#8c887e` |
| Columnas y viga de madera | `#6a5644`, sombra `#574536`, viga `#5b4a3a` |
| Zócalo | `#3d3027` |
| Duela | degradado `#694322` (fondo) → `#96622f` (frente), juntas `#5a391c` |
| Foco de luz sobre la duela | `#ffe2b0` al 38 % → transparente |
| Viñeta en las orillas | negro al 0 % → 50 % |
| Estandartes | gris carbón `#2a2b31`, texto `#f2efe6` (해동검도 / 海東劍道) |
| Peto | degradado `#f1f3f7` → `#c2c8d4`, ribete blanco |
| Casco | degradado `#ffffff` → `#cdd3de`, rejilla `#262833` / `#b7bdcb` |
| Coderas | blanco |
| Guantes | `#1c1c22` |
| *Hakama* | degradado `#2e3666` → `#181d3c` |
| Cinturón | `#15151a` |
| Contorno de la figura | `#1a1d2b`, 3.5 px (más fino que hoy) |
| Empuñadura / tsuba | `#26201b` / `#8f8f96` |
| Hoja del sable | colores actuales de la app, con un brillo suave del mismo color |

## Interfaz (HUD) del ejercicio

- Paneles translúcidos: fondo `rgba(18,20,28,0.74)`, borde blanco al 35 %, esquinas redondeadas (14 px).
- Arriba a la izquierda: nivel ("NIVEL 2") y su respuesta ("Evasión lateral").
- Arriba al centro: segundos restantes en grande, con una barra de progreso blanca.
- Arriba a la derecha: patrón ("TRANSVERSAL") y su secuencia con hangul.
- Abajo a la izquierda: botón DETENER en forma de píldora con borde blanco.
- Tipografía: Rajdhani (500 y 700).

## Pantalla de selección

- Mismo dojang de fondo, cubierto por una capa oscura al 62 %.
- Encabezado: "HAIDONG GUMDO" y "Entrenamiento de reacción · 해동검도".
- Dos columnas, NIVEL y PATRÓN, con tarjetas grandes: ícono (señal del nivel o silueta de la postura), nombre, detalle y secuencia en hangul.
- Selección: fondo blanco al 16 %, borde blanco y palomita. Nada amarillo.
- Abajo: resumen ("Nivel 1 · Frontal · 30 s") y botón INICIAR blanco con texto oscuro, en forma de píldora.

## Señales

- **Evasión:** flecha corta y gruesa, con una estela que se desvanece en la cola y un brillo suave, del color del sable.
- **Defensa:** sable en diagonal con hoja delgada y empuñadura más gruesa.
