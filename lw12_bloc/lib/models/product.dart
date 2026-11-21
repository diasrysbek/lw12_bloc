import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final double price;

  const Product({required this.id, required this.name, required this.price});

  @override
  List<Object?> get props => [id, name, price];
}

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}
