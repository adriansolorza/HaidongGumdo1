import '../catalog/catalog.dart';

/// Combinación de un nivel y un patrón elegida por el usuario.
final class Session {
  const Session({required this.level, required this.pattern});

  final Level level;
  final Pattern pattern;

  @override
  bool operator ==(Object other) =>
      other is Session && other.level == level && other.pattern == pattern;

  @override
  int get hashCode => Object.hash(level, pattern);
}
