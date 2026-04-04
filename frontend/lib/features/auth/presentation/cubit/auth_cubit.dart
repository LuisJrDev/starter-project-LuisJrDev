import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/watch_auth_state.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final WatchAuthStateUseCase _watch;
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;

  StreamSubscription? _sub;

  AuthCubit(this._watch, this._signIn, this._signUp, this._signOut)
    : super(const AuthUnknown());

  void start() {
    _sub?.cancel();
    emit(const AuthUnknown());

    _sub = _watch().listen((user) {
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthAuthenticated(user));
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _signIn(email: email.trim(), password: password);
      // authStateChanges emite y moverá el estado
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    emit(const AuthLoading());
    try {
      await _signUp(email: email.trim(), password: password, name: name.trim());
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signOut() async {
    await _signOut();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
