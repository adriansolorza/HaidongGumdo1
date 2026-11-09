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
    guardTermId: 'chayon_se',
    stanceTermId: 'chochon_se',
    cutTermId: 'chungmyon_begi',
    guard: SaberPose(hilt: Point2(0, 0.05), tip: Point2(0, -0.3)),
    cut: CutMotion(
      start: SaberPose(hilt: Point2(0, -0.9), tip: Point2(0, -1.6)),
      end: SaberPose(hilt: Point2(0, -0.2), tip: Point2(0, -0.35)),
      mirroredBySide: false,
    ),
  ),
);

/// Sesión de Nivel 1 / Patrón transversal (Spec 002, data-model.md): barrido
/// de 180° a la cintura; `cut.end` es el reflejo de `cut.start`. Las pruebas
/// del dominio no leen el asset.
Session testTransversalSession() => Session(
  level: testSession().level,
  pattern: const Pattern(
    id: 'transversal',
    order: 2,
    name: 'Transversal',
    guardTermId: 'chayon_se',
    stanceTermId: 'sodose',
    cutTermId: 'hwengdan_ilgom_begi',
    guard: SaberPose(hilt: Point2(0, 0.05), tip: Point2(0, -0.3)),
    cut: CutMotion(
      start: SaberPose(hilt: Point2(-0.45, 0.1), tip: Point2(-1.3, -0.1)),
      end: SaberPose(hilt: Point2(0.45, 0.1), tip: Point2(1.3, -0.1)),
      mirroredBySide: true,
    ),
  ),
);

/// Nivel 2 (Spec 003, data-model.md): evasión lateral.
Level _level2() => Level(
  id: 'level_2',
  order: 2,
  name: 'Nivel 2',
  responseLabel: 'Evasión lateral',
  purpose: 'Calentamiento / base',
  responseTypes: const [ResponseType.evasion],
);

/// Sesión de Nivel 2 / Patrón frontal; el patrón es el mismo de [testSession].
Session testLevel2Session() =>
    Session(level: _level2(), pattern: testSession().pattern);

/// Sesión de Nivel 2 / Patrón transversal; el patrón es el mismo de
/// [testTransversalSession].
Session testLevel2TransversalSession() =>
    Session(level: _level2(), pattern: testTransversalSession().pattern);
