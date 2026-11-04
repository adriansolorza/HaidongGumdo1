import 'package:haidonggumdo/domain/ports/random_source.dart';

/// Devuelve los valores del guion en orden. Falla si se agota o si un valor
/// no cabe en el rango pedido, para detectar sorteos inesperados.
final class ScriptedRandomSource implements RandomSource {
  ScriptedRandomSource(List<int> script) : _script = List.unmodifiable(script);

  final List<int> _script;
  int _consumed = 0;

  /// Cantidad de valores ya devueltos.
  int get consumed => _consumed;

  @override
  int nextInt(int maxExclusive) {
    if (_consumed >= _script.length) {
      throw StateError('Guion agotado tras $_consumed sorteos');
    }
    final value = _script[_consumed];
    if (value < 0 || value >= maxExclusive) {
      throw StateError(
        'Valor $value del guion (posición $_consumed) fuera de [0, $maxExclusive)',
      );
    }
    _consumed++;
    return value;
  }
}
