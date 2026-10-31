/// Pantalla encendida (FR-028). Data: WakelockPlusScreenWakeLock.
abstract interface class ScreenWakeLock {
  Future<void> enable();
  Future<void> disable();
}
