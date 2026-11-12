import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetmag_test_mka/const/pref_key.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class FavouritesViewModel extends ChangeNotifier {
  /// Starts get saved favourites when the shared provider is created.
  FavouritesViewModel({ProductService? service}) {
    _load();
  }

  List<Product> _favouriteProducts = [];
  SharedPreferences? _prefs;
  bool _isLoading = true;
  String? _loadError;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  bool get isEmpty => !_isLoading && _favouriteProducts.isEmpty;
  List<Product> get favouriteProducts => _favouriteProducts;

  /// Checks the single favourites collection used by cards and the wishlist.
  bool isFavourite(Product product) =>
      _favouriteProducts.any((saved) => saved.id == product.id);

  /// Loads full saved products; migrates old ID-only favourites when needed.
  Future<void> _load({bool notify = true}) async {
    _prefs = await SharedPreferences.getInstance();

    final savedProducts = _decodeProducts(
      _prefs!.getString(favouritesProductKey),
    );
    if (savedProducts.isNotEmpty) {
      _favouriteProducts = savedProducts;
    }

    _isLoading = false;
    if (notify) {
      notifyListeners();
    }
  }

  /// Decodes a stored product list, returning an empty list when no cache exists.
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
        .toList();
  }

  /// Adds or removes the product then saves
  Future<void> toggleFavourite(Product product, {bool notify = true}) async {
    final index = _favouriteProducts.indexWhere(
      (saved) => saved.id == product.id,
    );
    if (index >= 0) {
      _favouriteProducts.removeAt(index);
    } else {
      _favouriteProducts.add(product);
    }

    await _persist();
    if (notify) {
      notifyListeners();
    }
  }

  /// Saves only full products
  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(
      favouritesProductKey,
      jsonEncode(
        _favouriteProducts.map((product) => product.toJson()).toList(),
      ),
    );
  }
}
