import '../catalog/catalog.dart';

/// Fuente de catálogo. Implementación en data: AssetCatalogRepository (rootBundle).
abstract interface class CatalogRepository {
  /// Lanza CatalogException si el JSON no cumple contracts/catalog.schema.json
  /// o si una referencia a un término del glosario no existe.
  Future<Catalog> load();
}
