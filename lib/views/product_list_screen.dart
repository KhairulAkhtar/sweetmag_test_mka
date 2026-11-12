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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductListViewModel>().loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final viewModel = context.read<ProductListViewModel>();
    if (_scrollController.position.extentAfter < 300) {
      viewModel.loadNextPage();
    }
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
        child: _buildContent(viewModel),
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
