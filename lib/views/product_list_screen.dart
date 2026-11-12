import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/product_list_view_model.dart';
import '../widgets/product_card.dart';
import '../widgets/state_placeholder.dart';

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
    final viewModel = context.read<ProductListViewModel>();
    if (_scrollController.position.extentAfter < 300) {
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
        title: const Text('Product Catalogue'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    onChanged: (value) {
                      viewModel.updateQuery(value);
                    },
                    onSubmitted: (value) {
                      viewModel.search(value);
                    },
                  ),
                  if (_searchFocusNode.hasFocus && viewModel.recentSearches.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                          ...viewModel.recentSearches.map((search) {
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
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(viewModel),
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
        message: 'Unable to load products right now. Check your connection and try again.',
        onRetry: viewModel.refresh,
      );
    }

    if (viewModel.isEmpty) {
      return const StatePlaceholder(
        type: StatePlaceholderType.empty,
        message: 'No products match your search.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: viewModel.products.length + (viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= viewModel.products.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final product = viewModel.products[index];
        return ProductCard(
          product: product,
          onTap: () {
            debugPrint('Tapped product ${product.title}');
          },
        );
      },
    );
  }
}
