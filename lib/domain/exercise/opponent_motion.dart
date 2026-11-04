import 'attack.dart';

/// Posturas clave del oponente: `pattern.guard`, `pattern.cut.start` y
/// `pattern.cut.end`.
enum PoseKey { guard, stance, cutEnd }

/// Movimiento del oponente en un instante: de [from] a [to] con [progress].
/// El dominio calcula los tiempos; la presentación solo interpola posturas.
final class OpponentMotion {
  const OpponentMotion({
    required this.from,
    required this.to,
    required this.progress,
    this.side,
  });

  /// Quieto en la guardia: antes de *Si-jak*, entre ataques y al terminar.
  static const atGuard = OpponentMotion(
    from: PoseKey.guard,
    to: PoseKey.guard,
    progress: 0,
  );

  final PoseKey from;

  /// Igual a [from] cuando está quieto.
  final PoseKey to;

  /// En [0, 1]; 0 cuando está quieto.
  final double progress;

  /// Lado del ataque al que pertenece el tramo (para `mirroredBySide`). Se
  /// conserva durante el regreso; `null` en la guardia quieta.
  final Side? side;

  @override
  bool operator ==(Object other) =>
      other is OpponentMotion &&
      other.from == from &&
      other.to == to &&
      other.progress == progress &&
      other.side == side;

  @override
  int get hashCode => Object.hash(from, to, progress, side);

  @override
  String toString() =>
      'OpponentMotion(${from.name} → ${to.name}, $progress, ${side?.name})';
}
