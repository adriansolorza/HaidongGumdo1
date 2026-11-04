import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/signal.dart';

Attack _attack(Side side) => Attack(
  index: 0,
  side: side,
  responseType: ResponseType.defense,
  signalAt: const Duration(seconds: 4),
  cutStartAt: const Duration(milliseconds: 4700),
  cutEndAt: const Duration(milliseconds: 5200),
  nextSignalAt: const Duration(milliseconds: 5700),
);

void main() {
  test(
    'defensa con sable azul (right) → señal a la izquierda (CA2, escenario 2)',
    () {
      expect(
        SignalPlacement.forAttack(_attack(Side.right)),
        const Signal(responseType: ResponseType.defense, screenSide: Side.left),
      );
    },
  );

  test('defensa con sable rojo (left) → señal a la derecha (escenario 3)', () {
    expect(
      SignalPlacement.forAttack(_attack(Side.left)),
      const Signal(responseType: ResponseType.defense, screenSide: Side.right),
    );
  });
}
