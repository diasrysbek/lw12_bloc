import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../models/product.dart';
import 'cart_screen.dart';

const _products = [
  Product(id: 1, name: 'Laptop', price: 450000),
  Product(id: 2, name: 'Smartphone', price: 250000),
  Product(id: 3, name: 'Headphones', price: 35000),
  Product(id: 4, name: 'Keyboard', price: 20000),
  Product(id: 5, name: 'Mouse', price: 12000),
];

class CatalogScreen extends StatelessWidget {
  final String username;

  const CatalogScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catalog — $username'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                icon: Badge(
                  label: Text('${state.count}'),
                  isLabelVisible: state.count > 0,
                  child: const Icon(Icons.shopping_cart),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = _products[i];
          return ListTile(
            title: Text(p.name),
            subtitle: Text('${p.price.toStringAsFixed(0)} ₸'),
            trailing: ElevatedButton(
              onPressed: () => context.read<CartBloc>().add(AddProductEvent(p)),
              child: const Text('Add'),
            ),
          );
        },
      ),
    );
  }
}
