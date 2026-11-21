import 'package:equatable/equatable.dart';
import '../models/product.dart';

class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get totalPrice =>
      items.fold(0, (sum, i) => sum + i.product.price * i.quantity);

  int get count => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [items];
}
