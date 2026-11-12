import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../services/product_service.dart';

class ProductListViewModel extends ChangeNotifier {
  ProductListViewModel({ProductService? service})
      : _service = service ?? ProductService(),
        _connectivity = Connectivity() {
    _initConnectivity();
    _initHistory();
  }

  static const String _recentSearchKey = 'recent_product_searches';
  static const String _cachedProductsKey = 'cached_product_list';

  final ProductService _service;
  final Connectivity _connectivity;
  final int _pageSize = 20;
  final List<Product> _products = [];
  final List<String> _recentSearches = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOffline = false;
  bool _hasConnection = true;
  String? _errorMessage;
  String? _activeQuery;
  int _skip = 0;
  int _requestId = 0;
  Timer? _debounceTimer;
  SharedPreferences? _prefs;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isOffline => !_hasConnection || _isOffline;
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
    final cachedJson = _prefs?.getString(_cachedProductsKey);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      final decoded = jsonDecode(cachedJson) as List<dynamic>;
      _products
        ..clear()
        ..addAll(decoded.map((item) => Product.fromCache(item as Map<String, dynamic>)));
      _isOffline = !_hasConnection;
    }
    notifyListeners();
  }

  Future<void> _saveRecentSearches() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setStringList(_recentSearchKey, _recentSearches.take(5).toList());
  }

  Future<void> _saveCachedProducts() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final payload = jsonEncode(_products.map((product) => product.toJson()).toList());
    await prefs.setString(_cachedProductsKey, payload);
  }

  Future<void> _initConnectivity() async {
    final status = await _connectivity.checkConnectivity();
    _handleConnectivityChange(status);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final connected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (_hasConnection == connected) {
      return;
    }

    _hasConnection = connected;
    if (!connected && _products.isNotEmpty) {
      _isOffline = true;
    }
    if (connected) {
      _isOffline = false;
      unawaited(loadInitial());
    }
    notifyListeners();
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
    _isOffline = false;
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
      _isOffline = false;
      unawaited(_saveCachedProducts());
    } catch (error) {
      if (requestToken != _requestId) {
        return;
      }
      _isOffline = !_hasConnection || error is SocketException || error.toString().contains('SocketException');
      _errorMessage = error.toString();
      if (_products.isEmpty && _prefs != null) {
        final cachedJson = _prefs!.getString(_cachedProductsKey);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final decoded = jsonDecode(cachedJson) as List<dynamic>;
          _products
            ..clear()
            ..addAll(decoded.map((item) => Product.fromCache(item as Map<String, dynamic>)));
        }
      }
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
    _isOffline = false;
    if (!_hasConnection && _prefs != null) {
      final cachedJson = _prefs!.getString(_cachedProductsKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        _products
          ..clear()
          ..addAll(decoded.map((item) => Product.fromCache(item as Map<String, dynamic>)));
        _isOffline = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
    }
    await search(_activeQuery ?? '');
  }

  Future<void> refresh() async {
    _skip = 0;
    _hasMore = true;
    _isOffline = false;
    await search(_activeQuery ?? '');
  }

  Future<void> loadNextPage() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    if (!_hasConnection) {
      _isOffline = true;
      _errorMessage = 'No internet connection';
      notifyListeners();
      return;
    }

    final requestToken = ++_requestId;
    _isLoadingMore = true;
    _isOffline = false;
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
      _isOffline = false;
      unawaited(_saveCachedProducts());
    } catch (error) {
      if (requestToken != _requestId) {
        return;
      }
      _isOffline = !_hasConnection || error is SocketException || error.toString().contains('SocketException');
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
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
