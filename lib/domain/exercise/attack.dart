import '../catalog/enums.dart';

/// Lado de respuesta del usuario, visto desde el usuario.
enum Side {
  right,
  left;

  Side get opposite => this == Side.right ? Side.left : Side.right;
}

/// Un ataque del oponente y sus instantes en la línea de tiempo del ejercicio.
final class Attack {
  const Attack({
    required this.index,
    required this.side,
    required this.responseType,
    required this.signalAt,
    required this.cutStartAt,
    required this.cutEndAt,
    required this.nextSignalAt,
  });

  /// 0, 1, 2… dentro del ejercicio.
  final int index;

  /// Azul = `right`, rojo = `left`.
  final Side side;

  /// Uno de `level.responseTypes`.
  final ResponseType responseType;

  /// Menor que el fin nominal E.
  final Duration signalAt;

  /// `signalAt + warningTime`.
  final Duration cutStartAt;

  /// `cutStartAt + cutSpeed`.
  final Duration cutEndAt;

  /// `cutStartAt + sorteo`, con el sorteo en [`intervalFloor`, `attackInterval`].
  final Duration nextSignalAt;

  @override
  bool operator ==(Object other) =>
      other is Attack &&
      other.index == index &&
      other.side == side &&
      other.responseType == responseType &&
      other.signalAt == signalAt &&
      other.cutStartAt == cutStartAt &&
      other.cutEndAt == cutEndAt &&
      other.nextSignalAt == nextSignalAt;

  @override
  int get hashCode => Object.hash(
    index,
    side,
    responseType,
    signalAt,
    cutStartAt,
    cutEndAt,
    nextSignalAt,
  );
}
