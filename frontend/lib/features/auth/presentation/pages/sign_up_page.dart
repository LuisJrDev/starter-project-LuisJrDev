import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error_mapper.dart';
import '../../../../core/widgets/app_loading_overlay.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state is AuthLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (!context.mounted) return;

          if (state is AuthLoading) {
            AppLoadingOverlay.show(context, message: 'Creando cuenta…');
            return;
          }

          AppLoadingOverlay.hide(context);

          if (state is AuthError) {
            AppToast.showError(
              context,
              AppErrorMapper.authMessage(state.error),
            );
          }

          if (state is AuthAuthenticated) {
            AppToast.showSuccess(context, 'Cuenta creada');
            Navigator.of(context).pop();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mín. 6)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : () => context.read<AuthCubit>().signUp(
                          _email.text,
                          _pass.text,
                          _name.text,
                        ),
                  child: Text(loading ? 'Creando…' : 'Crear cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
