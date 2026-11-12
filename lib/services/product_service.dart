import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductPage {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
}

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _baseUrl = 'https://dummyjson.com';

  Future<ProductPage> fetchProducts({int limit = 20, int skip = 0}) {
    return _getPage('$_baseUrl/products?limit=$limit&skip=$skip');
  }

  Future<ProductPage> searchProducts(String query, {int limit = 20, int skip = 0}) {
    final encodedQuery = Uri.encodeComponent(query.trim());
    return _getPage('$_baseUrl/products/search?q=$encodedQuery&limit=$limit&skip=$skip');
  }

  Future<ProductPage> _getPage(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['products'];

        if (data is! List) {
          throw const FormatException('Unexpected product payload');
        }

        return ProductPage(
          products: data
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList(),
          total: int.tryParse('${decoded['total']}') ?? 0,
          skip: int.tryParse('${decoded['skip']}') ?? 0,
          limit: int.tryParse('${decoded['limit']}') ?? data.length,
        );
      }

      throw HttpException(
        'Request failed with status ${response.statusCode}',
        uri: Uri.parse(url),
      );
    } on SocketException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }
}
