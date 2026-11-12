import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view_models/product_list_view_model.dart';
import 'views/product_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, ProductListViewModel? initialViewModel})
      : _initialViewModel = initialViewModel;

  final ProductListViewModel? _initialViewModel;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductListViewModel>(
          create: (_) => _initialViewModel ?? ProductListViewModel(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'Product Catalogue',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: const ProductListScreen(),
      ),
    );
  }
}
