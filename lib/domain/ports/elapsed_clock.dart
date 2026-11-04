/// Reloj inyectable (Principio VI). Data: StopwatchClock. Pruebas: ManualClock.
abstract interface class ElapsedClock {
  void start(); // pone el tiempo transcurrido en cero y empieza a contar
  Duration get elapsed;
}
