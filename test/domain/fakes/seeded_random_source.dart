import 'dart:math';

import 'package:haidonggumdo/domain/ports/random_source.dart';

/// Aleatoriedad reproducible para simulaciones.
final class SeededRandomSource implements RandomSource {
  SeededRandomSource(int seed) : _random = Random(seed);

  final Random _random;

  @override
  int nextInt(int maxExclusive) => _random.nextInt(maxExclusive);
}
