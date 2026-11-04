import '../../domain/ports/elapsed_clock.dart';

/// Reloj real sobre Stopwatch (monótono, no depende de la hora del sistema).
final class StopwatchClock implements ElapsedClock {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void start() {
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
