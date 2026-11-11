import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:haidonggumdo/data/catalog/catalog_json_mapper.dart';
import 'package:haidonggumdo/domain/catalog/catalog.dart';
import 'package:haidonggumdo/domain/catalog/catalog_exception.dart';
import 'package:haidonggumdo/domain/catalog/enums.dart';

const _mapper = CatalogJsonMapper();

/// Catálogo mínimo válido, como mapa, para mutarlo en cada caso.
Map<String, Object?> _validJson() => {
  'version': 1,
  'glossary': [
    {'id': 'si_jak', 'romanization': 'Si-jak', 'meaning': 'Voz de inicio'},
    {'id': 'guman', 'romanization': 'Guman', 'meaning': 'Voz de fin'},
    {'id': 'guard', 'romanization': 'Guard', 'meaning': 'Guardia'},
    {'id': 'stance', 'romanization': 'Stance', 'meaning': 'Postura'},
    {'id': 'cut', 'romanization': 'Cut', 'meaning': 'Corte'},
  ],
  'voiceCommands': {'start': 'si_jak', 'end': 'guman'},
  'levels': [_level('level_1', 1)],
  'patterns': [
    {
      'id': 'frontal',
      'order': 1,
      'name': 'Frontal',
      'guardTermId': 'guard',
      'stanceTermId': 'stance',
      'cutTermId': 'cut',
      'guard': {
        'hilt': [0, 0.05],
        'tip': [0, -0.3],
      },
      'cut': {
        'start': {
          'hilt': [0, -0.9],
          'tip': [0, -1.6],
        },
        'end': {
          'hilt': [0, -0.2],
          'tip': [0, -0.35],
        },
        'mirroredBySide': false,
      },
    },
  ],
};

Map<String, Object?> _level(String id, int order) => {
  'id': id,
  'order': order,
  'name': 'Nivel $order',
  'responseLabel': 'Defensa',
  'purpose': 'Calentamiento',
  'responseTypes': ['defense'],
};

Map<String, Object?> _pattern(Map<String, Object?> json) =>
    (json['patterns']! as List<Object?>).first! as Map<String, Object?>;

Map<String, Object?> _cut(Map<String, Object?> json) =>
    _pattern(json)['cut']! as Map<String, Object?>;

Catalog _parse(Map<String, Object?> json) =>
    _mapper.fromJsonString(jsonEncode(json));

final _throwsCatalogException = throwsA(isA<CatalogException>());

void main() {
  test('(a) el asset real se parsea con los términos exactos del glosario', () {
    final source = File('assets/catalog/catalog.json').readAsStringSync();
    final catalog = _mapper.fromJsonString(source);

    expect(catalog.levels, hasLength(2));
    expect(catalog.levels.map((l) => l.id), ['level_1', 'level_2']);
    expect(catalog.patterns, hasLength(2));
    expect(catalog.glossary, hasLength(7));
    expect(catalog.levels.firstWhere((l) => l.id == 'level_1').responseTypes, [
      ResponseType.defense,
    ]);

    final expected = {
      'si_jak': ('Si-jak', '시작'),
      'guman': ('Guman', '그만'),
      'chayon_se': ('Chayôn-se', '자연세'),
      'chochon_se': ('Chochôn-se', '초천세'),
      'chungmyon_begi': ('Chungmyôn begi', '정면베기'),
      'sodose': ('Sodose', null),
      'hwengdan_ilgom_begi': ('Hwengdan ilgôm begi', '횡단일검베기'),
    };
    for (final MapEntry(key: id, value: (romanization, hangul))
        in expected.entries) {
      final term = catalog.term(id);
      expect(term.romanization, romanization, reason: id);
      expect(term.hangul, hangul, reason: id);
    }

    final pattern = catalog.patterns.firstWhere((p) => p.id == 'frontal');
    expect(pattern.guardTermId, 'chayon_se');
    expect(catalog.term(pattern.guardTermId).romanization, 'Chayôn-se');
    expect(
      pattern.guard,
      const SaberPose(hilt: Point2(0, 0.05), tip: Point2(0, -0.3)),
    );
    expect(catalog.term(pattern.stanceTermId).romanization, 'Chochôn-se');
    expect(catalog.term(pattern.cutTermId).romanization, 'Chungmyôn begi');
    expect(catalog.voiceTerm(VoiceCommand.start).id, 'si_jak');
    expect(catalog.voiceTerm(VoiceCommand.end).id, 'guman');
  });

  test('(b) cutTermId inexistente lanza CatalogException con la ruta', () {
    final json = _validJson();
    _pattern(json)['cutTermId'] = 'no_existe';
    expect(
      () => _parse(json),
      throwsA(
        isA<CatalogException>().having(
          (e) => e.message,
          'message',
          contains('patterns[0].cutTermId'),
        ),
      ),
    );
  });

  test('(c) JSON mal formado lanza CatalogException', () {
    expect(
      () => _mapper.fromJsonString('{"version": 1,'),
      _throwsCatalogException,
    );
  });

  test('(d) falta voiceCommands.end lanza CatalogException', () {
    final json = _validJson();
    (json['voiceCommands']! as Map<String, Object?>).remove('end');
    expect(() => _parse(json), _throwsCatalogException);
  });

  group('(e) responseTypes inválido', () {
    test('vacío', () {
      final json = _validJson();
      (json['levels']! as List<Object?>)[0] = {
        ..._level('level_1', 1),
        'responseTypes': <String>[],
      };
      expect(() => _parse(json), _throwsCatalogException);
    });

    test('con "counter" (desconocido)', () {
      final json = _validJson();
      (json['levels']! as List<Object?>)[0] = {
        ..._level('level_1', 1),
        'responseTypes': ['counter'],
      };
      expect(() => _parse(json), _throwsCatalogException);
    });
  });

  group('Nivel 2 (Spec 003)', () {
    test('el asset real incluye level_2 con evasión (FR-001)', () {
      final source = File('assets/catalog/catalog.json').readAsStringSync();
      final level = _mapper
          .fromJsonString(source)
          .levels
          .firstWhere((l) => l.id == 'level_2');

      expect(level.order, 2);
      expect(level.name, 'Nivel 2');
      expect(level.responseLabel, 'Evasión lateral');
      expect(level.purpose, 'Calentamiento / base');
      expect(level.responseTypes, [ResponseType.evasion]);
    });

    test('acepta responseTypes ["evasion"]', () {
      final json = _validJson();
      (json['levels']! as List<Object?>)[0] = {
        ..._level('level_1', 1),
        'responseTypes': ['evasion'],
      };
      expect(_parse(json).levels.single.responseTypes, [ResponseType.evasion]);
    });
  });

  test('(f) ids de nivel duplicados lanzan CatalogException', () {
    final json = _validJson();
    json['levels'] = [_level('level_1', 1), _level('level_1', 2)];
    expect(() => _parse(json), _throwsCatalogException);
  });

  test('(g) los niveles salen ordenados por order', () {
    final json = _validJson();
    json['levels'] = [_level('level_b', 2), _level('level_a', 1)];
    final catalog = _parse(json);
    expect(catalog.levels.map((l) => l.id), ['level_a', 'level_b']);
  });

  group('(h) cut inválido', () {
    test('cut ausente', () {
      final json = _validJson();
      _pattern(json).remove('cut');
      expect(() => _parse(json), _throwsCatalogException);
    });

    test('punto con 1 componente', () {
      final json = _validJson();
      (_cut(json)['start']! as Map<String, Object?>)['hilt'] = [0];
      expect(() => _parse(json), _throwsCatalogException);
    });

    test('punto con 3 componentes', () {
      final json = _validJson();
      (_cut(json)['end']! as Map<String, Object?>)['tip'] = [0, 0, 0];
      expect(() => _parse(json), _throwsCatalogException);
    });

    test('valor fuera de [-2, 2]', () {
      final json = _validJson();
      (_cut(json)['start']! as Map<String, Object?>)['tip'] = [0, -2.5];
      expect(() => _parse(json), _throwsCatalogException);
    });
  });

  group('guardia del patrón (revisión 2026-11-03)', () {
    test('guardTermId inexistente lanza CatalogException con la ruta', () {
      final json = _validJson();
      _pattern(json)['guardTermId'] = 'no_existe';
      expect(
        () => _parse(json),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('patterns[0].guardTermId'),
          ),
        ),
      );
    });

    test('guard ausente lanza CatalogException', () {
      final json = _validJson();
      _pattern(json).remove('guard');
      expect(() => _parse(json), _throwsCatalogException);
    });

    test('guard con un punto fuera de [-2, 2] lanza CatalogException', () {
      final json = _validJson();
      (_pattern(json)['guard']! as Map<String, Object?>)['tip'] = [0, -2.5];
      expect(
        () => _parse(json),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('patterns[0].guard.tip'),
          ),
        ),
      );
    });
  });

  group('Patrón transversal (Spec 002)', () {
    late Catalog catalog;
    late Pattern transversal;

    setUp(() {
      catalog = _mapper.fromJsonString(
        File('assets/catalog/catalog.json').readAsStringSync(),
      );
      transversal = catalog.patterns.firstWhere((p) => p.id == 'transversal');
    });

    test('(a) es el segundo patrón, con sus términos y posiciones', () {
      expect(catalog.patterns[1], same(transversal));
      expect(transversal.order, 2);
      expect(transversal.name, 'Transversal');
      expect(transversal.guardTermId, 'chayon_se');
      expect(transversal.stanceTermId, 'sodose');
      expect(transversal.cutTermId, 'hwengdan_ilgom_begi');
      expect(
        transversal.cut,
        const CutMotion(
          start: SaberPose(hilt: Point2(-0.45, 0.1), tip: Point2(-1.3, 0.1)),
          end: SaberPose(hilt: Point2(0.45, 0.1), tip: Point2(1.3, 0.1)),
          mirroredBySide: true,
        ),
      );
    });

    test('(b) su guardia es la del Patrón frontal (FR-006)', () {
      final frontal = catalog.patterns.firstWhere((p) => p.id == 'frontal');
      expect(transversal.guard, frontal.guard);
    });

    test(
      '(c) el barrido va del costado izquierdo al derecho (FR-007, FR-008)',
      () {
        final cut = transversal.cut;
        expect(cut.start.hilt.x, lessThan(0));
        expect(cut.start.tip.x, lessThan(cut.start.hilt.x));
        expect(cut.end.hilt.x, greaterThan(0));
        expect(cut.end.tip.x, greaterThan(cut.end.hilt.x));
      },
    );

    test('(d) Sodose no tiene hangul (FR-003)', () {
      expect(catalog.term('sodose').hangul, isNull);
    });

    test('(e) reglas del barrido: hoja horizontal y reflejo exacto (Spec 004, FR-010)', () {
      final start = transversal.cut.start;
      final end = transversal.cut.end;
      // cut.end es el reflejo exacto de cut.start en x.
      expect(end.hilt, Point2(-start.hilt.x, start.hilt.y));
      expect(end.tip, Point2(-start.tip.x, start.tip.y));
      // Barrido horizontal: empuñadura y punta no cambian de altura.
      expect(end.hilt.y, start.hilt.y);
      expect(end.tip.y, start.tip.y);
      // Hoja horizontal en Sodose y al final del corte (Spec 004, FR-010):
      // a la mitad del barrido apunta al usuario y se ve la punta de frente.
      expect(start.tip.y, start.hilt.y);
      expect(end.tip.y, end.hilt.y);
    });
  });
}
