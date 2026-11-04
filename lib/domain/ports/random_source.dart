/// Aleatoriedad inyectable (Principio VI). Data: DartRandomSource(dart:math).
abstract interface class RandomSource {
  /// Entero uniforme en [0, maxExclusive). maxExclusive >= 1.
  int nextInt(int maxExclusive);
}
