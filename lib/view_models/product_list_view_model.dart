import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class ProductListViewModel extends ChangeNotifier {
  ProductListViewModel({ProductService? service}) : _service = service ?? ProductService() {
    _initHistory();
  }

  static const String _recentSearchKey = 'recent_product_searches';

  final ProductService _service;
  final int _pageSize = 20;
  final List<Product> _products = [];
  final List<String> _recentSearches = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _activeQuery;
  int _skip = 0;
  int _requestId = 0;
  Timer? _debounceTimer;
  SharedPreferences? _prefs;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get activeQuery => _activeQuery;
  List<Product> get products => List.unmodifiable(_products);
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isEmpty => !_isLoading && _products.isEmpty && _errorMessage == null;

  Future<void> _initHistory() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getStringList(_recentSearchKey) ?? const <String>[];
    _recentSearches
      ..clear()
      ..addAll(stored.where((item) => item.trim().isNotEmpty).take(5));
    notifyListeners();
  }

  Future<void> _saveRecentSearches() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(_recentSearchKey, _recentSearches.take(5).toList());
  }

  void _rememberSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      return;
    }

    final normalized = query.toLowerCase();
    _recentSearches.removeWhere((item) => item.toLowerCase() == normalized);
    _recentSearches.insert(0, query);
    while (_recentSearches.length > 5) {
      _recentSearches.removeLast();
    }
    unawaited(_saveRecentSearches());
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    unawaited(_saveRecentSearches());
    notifyListeners();
  }

  void updateQuery(String rawValue) {
    _debounceTimer?.cancel();
    final value = rawValue.trim();

    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      search(value);
    });
  }

  Future<void> search(String rawValue) async {
    final query = rawValue.trim();
    _activeQuery = query.isEmpty ? null : query;
    _skip = 0;
    _hasMore = true;
    _errorMessage = null;
    _requestId += 1;
    final requestToken = _requestId;

    _isLoading = true;
    notifyListeners();

    if (query.isNotEmpty) {
      _rememberSearch(query);
    }

    try {
      final page = query.isEmpty
          ? await _service.fetchProducts(limit: _pageSize, skip: 0)
          : await _service.searchProducts(query, limit: _pageSize, skip: 0);

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

  Future<void> loadInitial() async {
    _skip = 0;
    _hasMore = true;
    await search(_activeQuery ?? '');
  }

  Future<void> refresh() async {
    _skip = 0;
    _hasMore = true;
    await search(_activeQuery ?? '');
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
      final page = (_activeQuery == null || _activeQuery!.isEmpty)
          ? await _service.fetchProducts(limit: _pageSize, skip: _skip)
          : await _service.searchProducts(_activeQuery!, limit: _pageSize, skip: _skip);

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
