import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/product.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddProductEvent>(_onAdd);
    on<RemoveProductEvent>(_onRemove);
    on<ClearCartEvent>((event, emit) => emit(const CartState()));
  }

  void _onAdd(AddProductEvent event, Emitter<CartState> emit) {
    // Новый список (иммутабельность), иначе Equatable не заметит изменений
    final items = List<CartItem>.from(state.items);
    final index = items.indexWhere((i) => i.product.id == event.product.id);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItem(product: event.product));
    }
    emit(CartState(items: items));
  }

  void _onRemove(RemoveProductEvent event, Emitter<CartState> emit) {
    final items =
        state.items.where((i) => i.product.id != event.productId).toList();
    emit(CartState(items: items));
  }
}
