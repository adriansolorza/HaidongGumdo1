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
      'stanceTermId': 'stance',
      'cutTermId': 'cut',
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

    expect(catalog.levels, hasLength(1));
    expect(catalog.patterns, hasLength(1));
    expect(catalog.glossary, hasLength(4));
    expect(catalog.levels.single.responseTypes, [ResponseType.defense]);

    final expected = {
      'si_jak': ('Si-jak', '시작'),
      'guman': ('Guman', '그만'),
      'chochon_se': ('Chochôn-se', '초천세'),
      'chungmyon_begi': ('Chungmyôn begi', '정면베기'),
    };
    for (final MapEntry(key: id, value: (romanization, hangul))
        in expected.entries) {
      final term = catalog.term(id);
      expect(term.romanization, romanization, reason: id);
      expect(term.hangul, hangul, reason: id);
    }

    final pattern = catalog.patterns.single;
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

    test('con "evasion" (no existe en Spec 001)', () {
      final json = _validJson();
      (json['levels']! as List<Object?>)[0] = {
        ..._level('level_1', 1),
        'responseTypes': ['evasion'],
      };
      expect(() => _parse(json), _throwsCatalogException);
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
}
