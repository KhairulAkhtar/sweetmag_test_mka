import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweetmag_test_mka/utils/share_util.dart';

import 'view_models/favourites_view_model.dart';
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
        ChangeNotifierProvider<FavouritesViewModel>(
          create: (_) => FavouritesViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'eShop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          appBarTheme: AppBarTheme(
            scrolledUnderElevation: 0,
            elevation: 0,
            backgroundColor: darkPurple(),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
        home: const ProductListScreen(),
      ),
    );
  }
}
