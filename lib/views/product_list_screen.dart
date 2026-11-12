import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweetmag_test_mka/utils/share_util.dart';
import 'package:sweetmag_test_mka/views/product_detail_screen.dart';
import '../view_models/product_list_view_model.dart';
import '../widgets/product_card.dart';
import '../widgets/state_placeholder.dart';
import 'wishlist_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _searchFocusNode.addListener(_handleSearchFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductListViewModel>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _searchController.dispose();
    _searchFocusNode.removeListener(_handleSearchFocus);
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final viewModel = context.read<ProductListViewModel>();
    if (_scrollController.position.extentAfter == 0) {
      viewModel.loadNextPage();
    }
  }

  void _handleSearchFocus() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProductListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('eShop'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WishlistScreen()));
            },
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            tooltip: 'Wishlist',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: darkPurple(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onChanged: viewModel.updateQuery,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: _buildContent(viewModel),
                ),
              ),
            ],
          ),
          if (_searchFocusNode.hasFocus && viewModel.recentSearches.isNotEmpty)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: _buildRecentSearches(viewModel),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(ProductListViewModel viewModel) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 340),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent searches'),
                  TextButton(
                    onPressed: viewModel.clearRecentSearches,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: viewModel.recentSearches.map((search) {
                  return ListTile(
                    dense: true,
                    title: Text(search),
                    onTap: () {
                      _searchController.text = search;
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: search.length),
                      );
                      _searchFocusNode.unfocus();
                      viewModel.search(search);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ProductListViewModel viewModel) {
    if (viewModel.isLoading && viewModel.products.isEmpty) {
      return const StatePlaceholder(type: StatePlaceholderType.loading);
    }

    if (viewModel.errorMessage != null && viewModel.products.isEmpty) {
      return StatePlaceholder(
        type: StatePlaceholderType.error,
        message: viewModel.isOffline
            ? 'No internet connection. Please check your network and try again.'
            : 'Unable to load products right now. Check your connection and try again.',
        onRetry: viewModel.refresh,
      );
    }

    if (viewModel.isEmpty) {
      return const StatePlaceholder(
        type: StatePlaceholderType.empty,
        message: 'No products match your search.',
      );
    }

    return Column(
      children: [
        if (viewModel.isOffline)
          Container(
            width: double.infinity,
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Internet connection lost. Showing cached products.',
                  ),
                ),
                TextButton(
                  onPressed: viewModel.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(child: _buildList(viewModel)),
      ],
    );
  }

  Widget _buildList(ProductListViewModel viewModel) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.68,
      ),
      itemCount: viewModel.products.length + (viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= viewModel.products.length) {
          return viewModel.isOffline
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No internet connection. Unable to load more products.',
                    ),
                  ),
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
        }

        final product = viewModel.products[index];
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
    );
  }
}
