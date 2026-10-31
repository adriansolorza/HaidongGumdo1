import '../ports/random_source.dart';
import 'attack.dart';

/// Sortea el lado de cada ataque sin pasar de [maxRepeats] seguidos al mismo
/// lado (FR-017, FR-018). Una instancia por ejercicio.
final class SideSequencer {
  SideSequencer({required this.maxRepeats, required this._random});

  final int maxRepeats;
  final RandomSource _random;

  Side? _lastSide;
  int _streak = 0;

  Side? get lastSide => _lastSide;
  int get streak => _streak;

  Side next() {
    // Racha completa: se fuerza el lado contrario sin consumir sorteo.
    final side = _streak == maxRepeats
        ? _lastSide!.opposite
        : (_random.nextInt(2) == 0 ? Side.right : Side.left);
    _streak = side == _lastSide ? _streak + 1 : 1;
    _lastSide = side;
    return side;
  }
}
