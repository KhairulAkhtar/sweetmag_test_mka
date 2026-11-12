import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweetmag_test_mka/views/product_detail_screen.dart';

import '../view_models/favourites_view_model.dart';
import '../widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favourites = context.watch<FavouritesViewModel>();

    if (favourites.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (favourites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: const Center(
          child: Text('No favourites yet. Save a product to see it here.'),
        ),
      );
    }

    if (favourites.favouriteProducts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              favourites.loadError ??
                  'Saved products could not be restored. Connect to the internet and reopen the wishlist.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.68,
        ),
        itemCount: favourites.favouriteProducts.length,
        itemBuilder: (context, index) {
          final product = favourites.favouriteProducts[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
