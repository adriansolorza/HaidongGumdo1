/// El catálogo no cumple el esquema o tiene una referencia rota.
final class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => 'CatalogException: $message';
}
