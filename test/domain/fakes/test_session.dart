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

/// Nivel 3 (Spec 006, data-model.md): defensa o evasión lateral al azar.
/// El orden de los tipos es significativo: el sorteo 0 → defensa.
Level _level3() => Level(
  id: 'level_3',
  order: 3,
  name: 'Nivel 3',
  responseLabel: 'Defensa o evasión lateral',
  purpose: 'Decisión bajo presión',
  responseTypes: const [ResponseType.defense, ResponseType.evasion],
);

/// Sesión de Nivel 3 / Patrón frontal; el patrón es el mismo de [testSession].
Session testLevel3Session() =>
    Session(level: _level3(), pattern: testSession().pattern);

/// Sesión de Nivel 3 / Patrón transversal; el patrón es el mismo de
/// [testTransversalSession].
Session testLevel3TransversalSession() =>
    Session(level: _level3(), pattern: testTransversalSession().pattern);

/// Nivel 4 (Spec 007, data-model §2): evasión con contraataque.
Level _level4() => Level(
  id: 'level_4',
  order: 4,
  name: 'Nivel 4',
  responseLabel: 'Evasión y contraataque',
  purpose: 'Combate',
  responseTypes: const [ResponseType.counter],
);

/// Sesión de Nivel 4 / Patrón frontal; el patrón es el mismo de [testSession].
Session testLevel4Session() =>
    Session(level: _level4(), pattern: testSession().pattern);

/// Sesión de Nivel 4 / Patrón transversal; el patrón es el mismo de
/// [testTransversalSession].
Session testLevel4TransversalSession() =>
    Session(level: _level4(), pattern: testTransversalSession().pattern);
