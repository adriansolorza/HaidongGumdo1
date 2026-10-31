import 'package:flutter/services.dart';

import '../../domain/catalog/catalog.dart';
import '../../domain/ports/catalog_repository.dart';
import 'catalog_json_mapper.dart';

/// Lee el catálogo incluido en la app como asset.
final class AssetCatalogRepository implements CatalogRepository {
  AssetCatalogRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/catalog/catalog.json',
    this.mapper = const CatalogJsonMapper(),
  }) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;
  final String assetPath;
  final CatalogJsonMapper mapper;

  @override
  Future<Catalog> load() async =>
      mapper.fromJsonString(await bundle.loadString(assetPath));
}
