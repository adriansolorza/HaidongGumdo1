# Haidong Gumdo

App Android para entrenar la reacción de un practicante de Haidong Gumdo ante los ataques de un oponente virtual. En cada ataque, el color del sable y una señal en pantalla indican hacia dónde reaccionar. El enfoque viene de los drills de reacción del fútbol americano y busca crear el hábito de defender o salir de la línea de ataque en lugar de intercambiar golpes.

Esta versión incluye el **Nivel 1 (defensa)** con el **Patrón frontal**: cuenta regresiva, voz *Si-jak*, ataques con lado aleatorio, señal de defensa y cierre con *Guman*. La especificación está en [specs/001-motor-nivel1-frontal/](specs/001-motor-nivel1-frontal/).

## Requisitos

- Flutter 3.47.7 / Dart 3.13.5 (canal stable).
- Un teléfono o tablet Android. La app es solo horizontal. Para entrenar frente a una pantalla grande, envía la imagen a una TV desde el dispositivo.
- Sin conexión a internet ni cuentas de usuario.

## Ejecutar

```bash
flutter pub get
flutter run                  # en modo debug
flutter run --release        # para medir tiempos o probar en el dispositivo
```

## Probar

```bash
flutter test test/domain     # reglas del ejercicio: tiempos, lados, estados
flutter test                 # todas las pruebas (dominio, datos y pantallas)
flutter analyze
```

El dominio se prueba con un reloj manual y una aleatoriedad controlada, así que las pruebas son deterministas. La validación manual en el dispositivo (legibilidad a 3 m, precisión de tiempos) está en [quickstart.md](specs/001-motor-nivel1-frontal/quickstart.md).

## Estructura

El código sigue Clean Architecture, con una carpeta por capa:

```text
lib/
├── domain/        Dart puro: catálogo, motor del ejercicio, parámetros y puertos
├── data/          catálogo JSON y adaptadores de plataforma (voz, reloj, pantalla encendida)
└── presentation/  pantallas, painters y providers de Riverpod
assets/catalog/    catálogo de niveles, patrones y glosario
test/              pruebas con la misma estructura por capas
```

El dominio no importa Flutter ni paquetes. Recibe el tiempo y la aleatoriedad desde fuera, y calcula todo (fases, señales, postura del oponente) a partir del tiempo transcurrido.

## Agregar un nivel o un patrón

Los niveles, los patrones y el glosario son datos de [assets/catalog/catalog.json](assets/catalog/catalog.json). El formato está en [catalog.schema.json](specs/001-motor-nivel1-frontal/contracts/catalog.schema.json).

1. Agrega al glosario los términos nuevos, con la romanización y el hangul exactos.
2. Agrega el nivel (`levels`) o el patrón (`patterns`) con un `id` y un `order` únicos.
   - Un patrón declara su guardia (`guardTermId`, `guard`), su postura de ataque (`stanceTermId`) y su corte (`cutTermId`, `cut`). Las posiciones del sable son coordenadas relativas a la figura, explicadas en el esquema.
   - Un nivel declara sus tipos de respuesta (`responseTypes`).
3. Ejecuta `flutter test`: el catálogo se valida al cargar.

Si el nivel o el patrón usa tipos de respuesta que ya existen, no hace falta tocar código: aparece en la pantalla de selección y se puede jugar. Un tipo de respuesta nuevo (por ejemplo, la evasión del Nivel 2) sí requiere código: su regla de colocación en el dominio y su dibujo en la presentación.

## Decisiones

Los paquetes y las decisiones técnicas aprobadas están registrados en [docs/decisions/](docs/decisions/):

- [0001](docs/decisions/0001-riverpod-sin-codegen.md): Riverpod sin generación de código.
- [0002](docs/decisions/0002-voz-sintetica-flutter-tts.md): voz sintética con `flutter_tts`.
- [0003](docs/decisions/0003-pantalla-encendida-wakelock-plus.md): pantalla encendida con `wakelock_plus`.
- [0004](docs/decisions/0004-graficos-custompainter.md): gráficos con `CustomPainter`.

Las reglas del proyecto están en la [constitution](.specify/memory/constitution.md).
