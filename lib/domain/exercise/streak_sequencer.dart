import '../ports/random_source.dart';

/// Sortea con un máximo de [maxRepeats] repeticiones seguidas (Spec 001,
/// FR-017 y FR-018; Spec 006, FR-005). Una instancia por ejercicio y por
/// magnitud. Con una sola opción o un solo candidato no consume sorteo
/// (Spec 006, research R2).
final class StreakSequencer<T> {
  StreakSequencer({
    required List<T> options,
    required this.maxRepeats,
    required this._random,
  }) : options = List.unmodifiable(options) {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'no puede estar vacía');
    }
    if (options.toSet().length != options.length) {
      throw ArgumentError.value(options, 'options', 'tiene duplicados');
    }
    if (maxRepeats < 1) {
      throw ArgumentError.value(maxRepeats, 'maxRepeats', 'debe ser >= 1');
    }
  }

  /// Opciones en orden: el sorteo `i` devuelve la opción `i` de los
  /// candidatos.
  final List<T> options;
  final int maxRepeats;
  final RandomSource _random;

  T? _last;
  int _streak = 0;

  /// Última opción devuelta; `null` antes del primer [next].
  T? get last => _last;

  /// Repeticiones seguidas de [last]; 0 al inicio.
  int get streak => _streak;

  T next() {
    final T result;
    if (options.length == 1) {
      result = options.first;
    } else {
      // Racha completa: se quita la última opción de los candidatos.
      final candidates = _streak == maxRepeats
          ? [
              for (final o in options)
                if (o != _last) o,
            ]
          : options;
      result = candidates.length == 1
          ? candidates.first
          : candidates[_random.nextInt(candidates.length)];
    }
    _streak = result == _last ? _streak + 1 : 1;
    _last = result;
    return result;
  }
}
