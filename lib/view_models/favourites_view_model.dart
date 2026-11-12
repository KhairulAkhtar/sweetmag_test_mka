import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class FavouritesViewModel extends ChangeNotifier {
  FavouritesViewModel({ProductService? service})
    : _service = service ?? ProductService() {
    _initialized = _load();
  }

  static const String _idsStorageKey = 'favourite_product_ids';
  static const String _productsStorageKey = 'favourite_products';
  static const String _catalogueCacheKey = 'cached_product_list';

  final ProductService _service;
  final Set<int> _favouriteIds = <int>{};
  final Map<int, Product> _productsById = <int, Product>{};
  late final Future<void> _initialized;
  SharedPreferences? _prefs;
  bool _isLoading = true;
  String? _loadError;

  Future<void> get initialized => _initialized;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isEmpty => !_isLoading && _favouriteIds.isEmpty;

  List<Product> get favouriteProducts => _favouriteIds
      .map((id) => _productsById[id])
      .whereType<Product>()
      .toList(growable: false);

  bool isFavourite(Product product) => _favouriteIds.contains(product.id);

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final storedProducts = _decodeProducts(
      _prefs!.getString(_productsStorageKey),
    );
    _productsById.addAll({
      for (final product in storedProducts) product.id: product,
    });

    final cachedCatalogue = _decodeProducts(
      _prefs!.getString(_catalogueCacheKey),
    );
    _productsById.addAll({
      for (final product in cachedCatalogue) product.id: product,
    });

    final storedIds = _prefs!.getStringList(_idsStorageKey) ?? const <String>[];
    _favouriteIds.addAll(
      storedIds.map(int.tryParse).whereType<int>().where((id) => id > 0),
    );

    // Older app versions saved only IDs. Recover product details from the
    // catalogue cache first, then fetch any remaining products by ID.
    final missingIds = _favouriteIds
        .where((id) => !_productsById.containsKey(id))
        .toList(growable: false);
    for (final id in missingIds) {
      try {
        _productsById[id] = await _service.fetchProductById(id);
      } catch (error) {
        _loadError = 'Could not restore some saved products: $error';
      }
    }

    _isLoading = false;
    await _persist();
    notifyListeners();
  }

  List<Product> _decodeProducts(String? json) {
    if (json == null || json.isEmpty) {
      return const <Product>[];
    }

    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Saved products have an invalid format');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Product.fromCache)
        .toList(growable: false);
  }

  Future<void> toggleFavourite(Product product) async {
    registerProduct(product);
    if (!_favouriteIds.add(product.id)) {
      _favouriteIds.remove(product.id);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(
      _idsStorageKey,
      _favouriteIds.map((id) => id.toString()).toList(growable: false),
    );
    final products = _favouriteIds
        .map((id) => _productsById[id])
        .whereType<Product>()
        .map((product) => product.toJson())
        .toList(growable: false);
    await prefs.setString(_productsStorageKey, jsonEncode(products));
  }

  void registerProduct(Product product) {
    _productsById[product.id] = product;
  }
}
