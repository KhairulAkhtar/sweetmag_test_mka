import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetmag_test_mka/models/product.dart';
import 'package:sweetmag_test_mka/services/product_service.dart';
import 'package:sweetmag_test_mka/view_models/favourites_view_model.dart';

class NoNetworkProductService extends ProductService {
  NoNetworkProductService()
    : super(client: MockClient((_) async => http.Response('{}', 500)));

  @override
  Future<Product> fetchProductById(int id) {
    throw StateError(
      'The product should have been restored from local storage',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favourite product details survive view-model recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final product = Product(
      id: 42,
      title: 'Saved product',
      description: 'Persisted product details',
      price: 19.99,
      rating: 4.7,
      stock: 12,
      thumbnail: 'https://example.com/product.png',
      images: const ['https://example.com/product.png'],
    );

    final firstViewModel = FavouritesViewModel(
      service: NoNetworkProductService(),
    );
    await firstViewModel.initialized;
    await firstViewModel.toggleFavourite(product);

    final restoredViewModel = FavouritesViewModel(
      service: NoNetworkProductService(),
    );
    await restoredViewModel.initialized;

    expect(restoredViewModel.isFavourite(product), isTrue);
    expect(restoredViewModel.favouriteProducts, hasLength(1));
    expect(restoredViewModel.favouriteProducts.single.title, product.title);
  });
}
