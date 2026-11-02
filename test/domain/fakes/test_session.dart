import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';
import 'package:haidonggumdo/domain/exercise/session.dart';

/// Sesión de Nivel 1 / Patrón frontal para las pruebas del motor.
Session testSession() => Session(
  level: Level(
    id: 'level_1',
    order: 1,
    name: 'Nivel 1',
    responseLabel: 'Defensa',
    purpose: 'Calentamiento',
    responseTypes: const [ResponseType.defense],
  ),
  pattern: const Pattern(
    id: 'frontal',
    order: 1,
    name: 'Frontal',
    stanceTermId: 'chochon_se',
    cutTermId: 'chungmyon_begi',
    cut: CutMotion(
      start: SaberPose(hilt: Point2(0, -0.9), tip: Point2(0, -1.6)),
      end: SaberPose(hilt: Point2(0, -0.2), tip: Point2(0, -0.35)),
      mirroredBySide: false,
    ),
  ),
);
