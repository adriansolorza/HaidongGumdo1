import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/ports/screen_wake_lock.dart';

/// Pantalla encendida con wakelock_plus (research R9). Nunca relanza errores.
final class WakelockPlusScreenWakeLock implements ScreenWakeLock {
  const WakelockPlusScreenWakeLock();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }
}
