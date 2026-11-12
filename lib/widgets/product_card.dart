import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../view_models/favourites_view_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favourites = context.watch<FavouritesViewModel>();
    final isFavourite = favourites.isFavourite(product);

    return Card(
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            _buildGridContent(theme),
            _buildFavouriteButton(favourites, isFavourite),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CachedNetworkImage(
            imageUrl: product.thumbnail,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.image_not_supported_outlined)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(product.rating.toStringAsFixed(1)),
                  const Spacer(),
                  Text(
                    'RM ${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavouriteButton(
    FavouritesViewModel favourites,
    bool isFavourite,
  ) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () {
        favourites.toggleFavourite(product);
      },
      icon: Icon(
        isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavourite ? Colors.red : null,
        size: 20,
      ),
      tooltip: isFavourite ? 'Remove from wishlist' : 'Add to wishlist',
    );
  }
}
