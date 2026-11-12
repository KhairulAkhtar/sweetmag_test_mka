import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sweetmag_test_mka/main.dart';
import 'package:sweetmag_test_mka/models/product.dart';
import 'package:sweetmag_test_mka/services/product_service.dart';
import 'package:sweetmag_test_mka/view_models/product_list_view_model.dart';

class FakeProductService extends ProductService {
  @override
  Future<ProductPage> fetchProducts({int limit = 20, int skip = 0}) async {
    final pageItems = List.generate(
      20,
      (index) => Product(
        id: index + skip + 1,
        title: 'Product ${index + skip + 1}',
        description: 'Description ${index + skip + 1}',
        price: 10 + index.toDouble(),
        rating: 4.5,
        stock: 10,
        thumbnail: 'https://picsum.photos/seed/${index + skip + 1}/200/200',
        images: const [],
      ),
    );

    return ProductPage(
      products: pageItems,
      total: 40,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<ProductPage> searchProducts(String query, {int limit = 20, int skip = 0}) async {
    return fetchProducts(limit: limit, skip: skip);
  }
}

void main() {
  testWidgets('Product list renders and loads first page', (WidgetTester tester) async {
    final fakeViewModel = ProductListViewModel(service: FakeProductService());

    await tester.pumpWidget(MyApp(initialViewModel: fakeViewModel));
    await tester.pump();

    expect(find.text('eShop'), findsOneWidget);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}
