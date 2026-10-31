import 'dart:convert';

import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/catalog_exception.dart';
import '../../domain/catalog/enums.dart';

/// Traduce el JSON del catálogo a entidades del dominio y valida a mano las
/// reglas de contracts/catalog.schema.json más las referencias cruzadas.
/// Cualquier violación lanza [CatalogException] con la ruta del campo.
final class CatalogJsonMapper {
  const CatalogJsonMapper();

  static final _idPattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static const _pointMin = -2.0;
  static const _pointMax = 2.0;

  Catalog fromJsonString(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw CatalogException('JSON mal formado: ${e.message}');
    }

    final root = _object(
      decoded,
      r'$',
      required: const {
        'version',
        'glossary',
        'voiceCommands',
        'levels',
        'patterns',
      },
    );

    final version = _int(root['version'], 'version', min: 1);
    final glossary = _parseGlossary(root['glossary']);
    final termIds = {for (final t in glossary) t.id};
    final voiceCommands = _parseVoiceCommands(root['voiceCommands'], termIds);
    final levels = _parseLevels(root['levels']);
    final patterns = _parsePatterns(root['patterns'], termIds);

    return Catalog(
      version: version,
      glossary: glossary,
      voiceCommands: voiceCommands,
      levels: levels..sort((a, b) => a.order.compareTo(b.order)),
      patterns: patterns..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  List<GlossaryTerm> _parseGlossary(Object? value) {
    final items = _list(value, 'glossary', minItems: 1);
    final terms = <GlossaryTerm>[];
    final seen = <String>{};
    for (var i = 0; i < items.length; i++) {
      final path = 'glossary[$i]';
      final json = _object(
        items[i],
        path,
        required: const {'id', 'romanization', 'meaning'},
        optional: const {'hangul'},
      );
      final id = _id(json['id'], '$path.id');
      if (!seen.add(id)) throw CatalogException('$path.id duplicado: $id');
      terms.add(
        GlossaryTerm(
          id: id,
          romanization: _string(json['romanization'], '$path.romanization'),
          hangul: json.containsKey('hangul')
              ? _string(json['hangul'], '$path.hangul')
              : null,
          meaning: _string(json['meaning'], '$path.meaning'),
        ),
      );
    }
    return terms;
  }

  Map<VoiceCommand, String> _parseVoiceCommands(
    Object? value,
    Set<String> termIds,
  ) {
    final json = _object(
      value,
      'voiceCommands',
      required: {for (final c in VoiceCommand.values) c.name},
    );
    return {
      for (final command in VoiceCommand.values)
        command: _termRef(
          json[command.name],
          'voiceCommands.${command.name}',
          termIds,
        ),
    };
  }

  List<Level> _parseLevels(Object? value) {
    final items = _list(value, 'levels', minItems: 1);
    final levels = <Level>[];
    final seenIds = <String>{};
    final seenOrders = <int>{};
    for (var i = 0; i < items.length; i++) {
      final path = 'levels[$i]';
      final json = _object(
        items[i],
        path,
        required: const {
          'id',
          'order',
          'name',
          'responseLabel',
          'purpose',
          'responseTypes',
        },
      );
      final id = _id(json['id'], '$path.id');
      if (!seenIds.add(id)) throw CatalogException('$path.id duplicado: $id');
      final order = _int(json['order'], '$path.order', min: 1);
      if (!seenOrders.add(order)) {
        throw CatalogException('$path.order duplicado: $order');
      }
      levels.add(
        Level(
          id: id,
          order: order,
          name: _string(json['name'], '$path.name'),
          responseLabel: _string(json['responseLabel'], '$path.responseLabel'),
          purpose: _string(json['purpose'], '$path.purpose'),
          responseTypes: _parseResponseTypes(
            json['responseTypes'],
            '$path.responseTypes',
          ),
        ),
      );
    }
    return levels;
  }

  List<ResponseType> _parseResponseTypes(Object? value, String path) {
    final items = _list(value, path, minItems: 1);
    final types = <ResponseType>[];
    for (var i = 0; i < items.length; i++) {
      final name = _string(items[i], '$path[$i]');
      final type = ResponseType.values.where((t) => t.name == name).firstOrNull;
      if (type == null) {
        throw CatalogException(
          '$path[$i]: tipo de respuesta desconocido: $name',
        );
      }
      if (types.contains(type)) {
        throw CatalogException('$path[$i]: tipo de respuesta duplicado: $name');
      }
      types.add(type);
    }
    return types;
  }

  List<Pattern> _parsePatterns(Object? value, Set<String> termIds) {
    final items = _list(value, 'patterns', minItems: 1);
    final patterns = <Pattern>[];
    final seenIds = <String>{};
    final seenOrders = <int>{};
    for (var i = 0; i < items.length; i++) {
      final path = 'patterns[$i]';
      final json = _object(
        items[i],
        path,
        required: const {
          'id',
          'order',
          'name',
          'stanceTermId',
          'cutTermId',
          'cut',
        },
      );
      final id = _id(json['id'], '$path.id');
      if (!seenIds.add(id)) throw CatalogException('$path.id duplicado: $id');
      final order = _int(json['order'], '$path.order', min: 1);
      if (!seenOrders.add(order)) {
        throw CatalogException('$path.order duplicado: $order');
      }
      patterns.add(
        Pattern(
          id: id,
          order: order,
          name: _string(json['name'], '$path.name'),
          stanceTermId: _termRef(
            json['stanceTermId'],
            '$path.stanceTermId',
            termIds,
          ),
          cutTermId: _termRef(json['cutTermId'], '$path.cutTermId', termIds),
          cut: _parseCut(json['cut'], '$path.cut'),
        ),
      );
    }
    return patterns;
  }

  CutMotion _parseCut(Object? value, String path) {
    final json = _object(
      value,
      path,
      required: const {'start', 'end', 'mirroredBySide'},
    );
    return CutMotion(
      start: _parsePose(json['start'], '$path.start'),
      end: _parsePose(json['end'], '$path.end'),
      mirroredBySide: _bool(json['mirroredBySide'], '$path.mirroredBySide'),
    );
  }

  SaberPose _parsePose(Object? value, String path) {
    final json = _object(value, path, required: const {'hilt', 'tip'});
    return SaberPose(
      hilt: _parsePoint(json['hilt'], '$path.hilt'),
      tip: _parsePoint(json['tip'], '$path.tip'),
    );
  }

  Point2 _parsePoint(Object? value, String path) {
    final items = _list(value, path, minItems: 2);
    if (items.length != 2) {
      throw CatalogException('$path debe tener exactamente 2 componentes');
    }
    return Point2(
      _number(items[0], '$path[0]', min: _pointMin, max: _pointMax),
      _number(items[1], '$path[1]', min: _pointMin, max: _pointMax),
    );
  }

  // --- Validadores genéricos ---

  Map<String, Object?> _object(
    Object? value,
    String path, {
    required Set<String> required,
    Set<String> optional = const {},
  }) {
    if (value is! Map<String, Object?>) {
      throw CatalogException('$path debe ser un objeto');
    }
    for (final key in required) {
      if (!value.containsKey(key)) {
        throw CatalogException('${_join(path, key)} es obligatorio');
      }
    }
    for (final key in value.keys) {
      if (!required.contains(key) && !optional.contains(key)) {
        throw CatalogException('${_join(path, key)} no está permitido');
      }
    }
    return value;
  }

  List<Object?> _list(Object? value, String path, {required int minItems}) {
    if (value is! List<Object?>) {
      throw CatalogException('$path debe ser una lista');
    }
    if (value.length < minItems) {
      throw CatalogException('$path debe tener al menos $minItems elemento(s)');
    }
    return value;
  }

  String _string(Object? value, String path) {
    if (value is! String || value.isEmpty) {
      throw CatalogException('$path debe ser un texto no vacío');
    }
    return value;
  }

  String _id(Object? value, String path) {
    final id = _string(value, path);
    if (!_idPattern.hasMatch(id)) {
      throw CatalogException('$path no cumple el patrón de id: $id');
    }
    return id;
  }

  String _termRef(Object? value, String path, Set<String> termIds) {
    final id = _string(value, path);
    if (!termIds.contains(id)) {
      throw CatalogException('$path: término inexistente en el glosario: $id');
    }
    return id;
  }

  int _int(Object? value, String path, {required int min}) {
    if (value is! int) throw CatalogException('$path debe ser un entero');
    if (value < min) throw CatalogException('$path debe ser ≥ $min');
    return value;
  }

  double _number(
    Object? value,
    String path, {
    required double min,
    required double max,
  }) {
    if (value is! num) throw CatalogException('$path debe ser un número');
    final number = value.toDouble();
    if (number < min || number > max) {
      throw CatalogException('$path debe estar en [$min, $max]');
    }
    return number;
  }

  bool _bool(Object? value, String path) {
    if (value is! bool) throw CatalogException('$path debe ser booleano');
    return value;
  }

  String _join(String path, String key) => path == r'$' ? key : '$path.$key';
}
