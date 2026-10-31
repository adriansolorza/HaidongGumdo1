import '../catalog/enums.dart';
import 'attack.dart';

/// Señal que se muestra al usuario durante el aviso y el corte.
final class Signal {
  const Signal({required this.responseType, required this.screenSide});

  final ResponseType responseType;

  /// Mitad de la pantalla donde se dibuja la señal, vista por el usuario.
  final Side screenSide;

  @override
  bool operator ==(Object other) =>
      other is Signal &&
      other.responseType == responseType &&
      other.screenSide == screenSide;

  @override
  int get hashCode => Object.hash(responseType, screenSide);
}

/// Única regla de colocación de la señal: una rama por tipo de respuesta.
abstract final class SignalPlacement {
  static Signal forAttack(Attack attack) => switch (attack.responseType) {
    // Defensa: la señal va del lado contrario al color del sable (FR-015).
    ResponseType.defense => Signal(
      responseType: attack.responseType,
      screenSide: attack.side.opposite,
    ),
  };
}
