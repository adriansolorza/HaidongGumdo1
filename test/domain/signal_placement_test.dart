import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/attack.dart';
import 'package:haidonggumdo/domain/exercise/signal.dart';

Attack _attack(Side side, [ResponseType type = ResponseType.defense]) => Attack(
  index: 0,
  side: side,
  responseType: type,
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

  group('evasión (Spec 003, contrato §2)', () {
    test('con sable azul (right) → señal a la derecha (FR-006, CA1)', () {
      expect(
        SignalPlacement.forAttack(_attack(Side.right, ResponseType.evasion)),
        const Signal(
          responseType: ResponseType.evasion,
          screenSide: Side.right,
        ),
      );
    });

    test('con sable rojo (left) → señal a la izquierda (FR-006)', () {
      expect(
        SignalPlacement.forAttack(_attack(Side.left, ResponseType.evasion)),
        const Signal(responseType: ResponseType.evasion, screenSide: Side.left),
      );
    });

    test('para un mismo lado, evasión y defensa quedan en lados opuestos', () {
      for (final side in Side.values) {
        final evasion = SignalPlacement.forAttack(
          _attack(side, ResponseType.evasion),
        );
        final defense = SignalPlacement.forAttack(_attack(side));
        expect(
          evasion.screenSide,
          defense.screenSide.opposite,
          reason: '$side',
        );
      }
    });
  });
}
