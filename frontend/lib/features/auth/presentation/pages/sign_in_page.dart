import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _goToSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpPage()));
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state is AuthLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (!context.mounted) return;

          if (state is AuthLoading) {
            AppLoadingOverlay.show(context, message: 'Iniciando sesión…');
            return;
          }

          // cualquier estado distinto a loading
          AppLoadingOverlay.hide(context);

          if (state is AuthError) {
            AppToast.showError(
              context,
              AppErrorMapper.authMessage(state.error),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : () => context.read<AuthCubit>().signIn(
                          _email.text,
                          _pass.text,
                        ),
                  child: Text(loading ? 'Iniciando…' : 'Entrar'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: loading ? null : _goToSignUp,
                child: const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
