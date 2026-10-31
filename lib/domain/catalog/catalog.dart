import 'catalog_exception.dart';
import 'enums.dart';

/// Término del glosario: romanización y hangul exactamente como en el glosario (Principio IX).
final class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.romanization,
    this.hangul,
    required this.meaning,
  });

  final String id;
  final String romanization;
  final String? hangul;
  final String meaning;

  @override
  bool operator ==(Object other) =>
      other is GlossaryTerm &&
      other.id == id &&
      other.romanization == romanization &&
      other.hangul == hangul &&
      other.meaning == meaning;

  @override
  int get hashCode => Object.hash(id, romanization, hangul, meaning);
}

/// Tipo de respuesta que entrena el usuario.
final class Level {
  Level({
    required this.id,
    required this.order,
    required this.name,
    required this.responseLabel,
    required this.purpose,
    required List<ResponseType> responseTypes,
  }) : responseTypes = List.unmodifiable(responseTypes);

  final String id;
  final int order;
  final String name;
  final String responseLabel;
  final String purpose;
  final List<ResponseType> responseTypes;

  @override
  bool operator ==(Object other) =>
      other is Level &&
      other.id == id &&
      other.order == order &&
      other.name == name &&
      other.responseLabel == responseLabel &&
      other.purpose == purpose &&
      _listEquals(other.responseTypes, responseTypes);

  @override
  int get hashCode => Object.hash(
    id,
    order,
    name,
    responseLabel,
    purpose,
    Object.hashAll(responseTypes),
  );
}

/// Punto en coordenadas de pantalla relativas a la figura: origen en su centro,
/// unidad = media altura de la figura, `x` hacia la derecha y `y` hacia abajo.
final class Point2 {
  const Point2(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is Point2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Posición del sable: empuñadura (manos) y punta visible.
final class SaberPose {
  const SaberPose({required this.hilt, required this.tip});

  final Point2 hilt;
  final Point2 tip;

  @override
  bool operator ==(Object other) =>
      other is SaberPose && other.hilt == hilt && other.tip == tip;

  @override
  int get hashCode => Object.hash(hilt, tip);
}

/// Movimiento del corte como datos: se interpola de [start] a [end] según el progreso.
final class CutMotion {
  const CutMotion({
    required this.start,
    required this.end,
    required this.mirroredBySide,
  });

  final SaberPose start;
  final SaberPose end;

  /// `true` si el corte sale hacia el lado del ataque (se invierte `x` con el lado izquierdo).
  final bool mirroredBySide;

  @override
  bool operator ==(Object other) =>
      other is CutMotion &&
      other.start == start &&
      other.end == end &&
      other.mirroredBySide == mirroredBySide;

  @override
  int get hashCode => Object.hash(start, end, mirroredBySide);
}

/// Tipo de ataque del oponente virtual: postura + corte.
final class Pattern {
  const Pattern({
    required this.id,
    required this.order,
    required this.name,
    required this.stanceTermId,
    required this.cutTermId,
    required this.cut,
  });

  final String id;
  final int order;
  final String name;
  final String stanceTermId;
  final String cutTermId;
  final CutMotion cut;

  @override
  bool operator ==(Object other) =>
      other is Pattern &&
      other.id == id &&
      other.order == order &&
      other.name == name &&
      other.stanceTermId == stanceTermId &&
      other.cutTermId == cutTermId &&
      other.cut == cut;

  @override
  int get hashCode =>
      Object.hash(id, order, name, stanceTermId, cutTermId, cut);
}

/// Catálogo de solo lectura: única fuente de niveles, patrones y glosario (FR-001).
final class Catalog {
  Catalog({
    required this.version,
    required List<GlossaryTerm> glossary,
    required Map<VoiceCommand, String> voiceCommands,
    required List<Level> levels,
    required List<Pattern> patterns,
  }) : glossary = List.unmodifiable(glossary),
       voiceCommands = Map.unmodifiable(voiceCommands),
       levels = List.unmodifiable(levels),
       patterns = List.unmodifiable(patterns),
       _termsById = {for (final t in glossary) t.id: t};

  final int version;
  final List<GlossaryTerm> glossary;
  final Map<VoiceCommand, String> voiceCommands;
  final List<Level> levels;
  final List<Pattern> patterns;
  final Map<String, GlossaryTerm> _termsById;

  /// Lanza [CatalogException] si el término no existe.
  GlossaryTerm term(String id) =>
      _termsById[id] ??
      (throw CatalogException('Término inexistente en el glosario: $id'));

  GlossaryTerm voiceTerm(VoiceCommand command) {
    final id = voiceCommands[command];
    if (id == null) {
      throw CatalogException('Comando de voz sin término: ${command.name}');
    }
    return term(id);
  }

  @override
  bool operator ==(Object other) =>
      other is Catalog &&
      other.version == version &&
      _listEquals(other.glossary, glossary) &&
      _mapEquals(other.voiceCommands, voiceCommands) &&
      _listEquals(other.levels, levels) &&
      _listEquals(other.patterns, patterns);

  @override
  int get hashCode => Object.hash(
    version,
    Object.hashAll(glossary),
    Object.hashAllUnordered(
      voiceCommands.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(levels),
    Object.hashAll(patterns),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
