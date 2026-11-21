import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(const MyApp());

/* ============================================================
 * 1. AUTH CUBIT + IMMUTABLE STATES (Equatable)
 * ============================================================ */

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String username;
  final String email;
  const AuthSuccess({required this.username, required this.email});

  @override
  List<Object?> get props => [username, email];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  static const _validEmail = 'student@narxoz.kz';
  static const _validPassword = '123456';

  Future<void> login(String email, String password) async {
    // Loading всегда эмитится первым, поэтому повторная ошибка
    // с тем же текстом всё равно вызовет listener (Loading -> Error).
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 2)); // имитация сети

    final e = email.trim();
    if (e.isEmpty || password.isEmpty) {
      emit(const AuthError('Please fill in all fields'));
    } else if (e == _validEmail && password == _validPassword) {
      emit(AuthSuccess(username: e.split('@').first, email: e));
    } else {
      emit(const AuthError('Invalid email or password'));
    }
  }
}

/* ============================================================
 * 2. MODELS + CART BLOC (Events, State, Handlers)
 * ============================================================ */

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

// ---- Events ----
abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class AddProductEvent extends CartEvent {
  final Product product;
  const AddProductEvent(this.product);
  @override
  List<Object?> get props => [product];
}

class RemoveProductEvent extends CartEvent {
  final int productId;
  const RemoveProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

// ---- State ----
class CartState extends Equatable {
  final List<CartItem> items;
  const CartState({this.items = const []});

  double get totalPrice =>
      items.fold(0, (sum, i) => sum + i.product.price * i.quantity);

  int get count => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [items];
}

// ---- Bloc ----
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddProductEvent>(_onAdd);
    on<RemoveProductEvent>(_onRemove);
    on<ClearCartEvent>((event, emit) => emit(const CartState()));
  }

  void _onAdd(AddProductEvent event, Emitter<CartState> emit) {
    // Всегда создаём НОВЫЙ список (иммутабельность), иначе Equatable
    // не увидит изменений и UI не перерисуется.
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
    final items = state.items
        .where((i) => i.product.id != event.productId)
        .toList();
    emit(CartState(items: items));
  }
}

/* ============================================================
 * APP ROOT — провайдеры выше MaterialApp, чтобы были доступны во всех роутах
 * ============================================================ */

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => CartBloc()),
      ],
      child: MaterialApp(
        title: 'LW12 BLoC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const LoginScreen(),
      ),
    );
  }
}

/* ============================================================
 * SCREEN 1: LOGIN (BlocConsumer)
 * ============================================================ */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<AuthCubit, AuthState>(
        // listener — только одноразовые побочные эффекты
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          } else if (state is AuthSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CatalogScreen(username: state.username),
              ),
            );
          }
        },
        // builder — только отрисовка виджетов
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (state is AuthLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.read<AuthCubit>().login(
                        _emailCtrl.text,
                        _passCtrl.text,
                      ),
                      child: const Text('Login'),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Test: student@narxoz.kz / 123456',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ============================================================
 * SCREEN 2: CATALOG + live Badge (BlocBuilder)
 * ============================================================ */

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

/* ============================================================
 * SCREEN 3: CART VIEW
 * ============================================================ */

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(child: Text('Cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final item = state.items[i];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(
                        '${item.product.price.toStringAsFixed(0)} ₸ × ${item.quantity}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => context.read<CartBloc>().add(
                          RemoveProductEvent(item.product.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.totalPrice.toStringAsFixed(0)} ₸',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.read<CartBloc>().add(
                          const ClearCartEvent(),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
