import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  static const _validEmail = 'student@narxoz.kz';
  static const _validPassword = '123456';

  Future<void> login(String email, String password) async {
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
