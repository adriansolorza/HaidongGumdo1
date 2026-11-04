import 'package:haidonggumdo/domain/ports/elapsed_clock.dart';

/// Reloj que solo avanza cuando la prueba lo indica.
final class ManualClock implements ElapsedClock {
  Duration _elapsed = Duration.zero;

  @override
  void start() => _elapsed = Duration.zero;

  @override
  Duration get elapsed => _elapsed;

  void advance(Duration delta) => _elapsed += delta;

  void set(Duration elapsed) => _elapsed = elapsed;
}
