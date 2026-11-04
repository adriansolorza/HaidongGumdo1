import 'dart:math';

import '../../domain/ports/random_source.dart';

/// Aleatoriedad real sobre dart:math.
final class DartRandomSource implements RandomSource {
  DartRandomSource([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  int nextInt(int maxExclusive) {
    if (maxExclusive < 1) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'debe ser >= 1');
    }
    return _random.nextInt(maxExclusive);
  }
}
