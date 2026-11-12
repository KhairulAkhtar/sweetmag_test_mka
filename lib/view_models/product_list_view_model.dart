import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class ProductListViewModel extends ChangeNotifier {
  ProductListViewModel({ProductService? service}) : _service = service ?? ProductService();

  final ProductService _service;
  final int _pageSize = 20;
  final List<Product> _products = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _skip = 0;
  int _requestId = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  List<Product> get products => List.unmodifiable(_products);
  bool get isEmpty => !_isLoading && _products.isEmpty && _errorMessage == null;

  Future<void> loadInitial() async {
    _skip = 0;
    _hasMore = true;
    await refresh();
  }

  Future<void> refresh() async {
    _skip = 0;
    _hasMore = true;
    _errorMessage = null;
    _requestId += 1;
    final requestToken = _requestId;

    _isLoading = true;
    notifyListeners();

    try {
      final page = await _service.fetchProducts(limit: _pageSize, skip: 0);
      if (requestToken != _requestId) {
        return;
      }

      _products
        ..clear()
        ..addAll(page.products);
      _skip = page.products.length;
      _hasMore = _skip < page.total;
      _errorMessage = null;
    } catch (error) {
      if (requestToken != _requestId) {
        return;
      }
      _errorMessage = error.toString();
      _products.clear();
    } finally {
      if (requestToken == _requestId) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadNextPage() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final requestToken = ++_requestId;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _service.fetchProducts(limit: _pageSize, skip: _skip);
      if (requestToken != _requestId) {
        return;
      }

      final seenIds = _products.map((item) => item.id).toSet();
      final nextItems = page.products.where((item) => !seenIds.contains(item.id)).toList();
      _products.addAll(nextItems);
      _skip += page.products.length;
      _hasMore = _skip < page.total;
    } catch (error) {
      if (requestToken != _requestId) {
        return;
      }
      _errorMessage = error.toString();
    } finally {
      if (requestToken == _requestId) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }
}
