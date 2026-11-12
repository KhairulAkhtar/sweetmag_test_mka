import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../view_models/favourites_view_model.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final favourites = context.watch<FavouritesViewModel>();
    final isFavourite = favourites.isFavourite(product);
    final imageUrls = product.images.isNotEmpty ? product.images : [product.thumbnail];

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              favourites.registerProduct(product);
              favourites.toggleFavourite(product);
            },
            icon: Icon(
              isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavourite ? Colors.red : null,
            ),
            tooltip: isFavourite ? 'Remove from wishlist' : 'Add to wishlist',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 260,
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = imageUrls[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 48),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.attach_money_rounded, size: 18),
                  label: Text('\$${product.price.toStringAsFixed(2)}'),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text('Stock: ${product.stock}'),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  label: Text(product.rating.toStringAsFixed(1)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description.isEmpty ? 'No description available.' : product.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
