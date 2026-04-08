import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

/// Custom validators for password strength.
Map<String, dynamic>? _hasNumber(AbstractControl<dynamic> control) {
  final value = control.value?.toString() ?? '';
  if (RegExp(r'[0-9]').hasMatch(value)) return null;
  return {'hasNumber': true};
}

Map<String, dynamic>? _hasSpecial(AbstractControl<dynamic> control) {
  final value = control.value?.toString() ?? '';
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) return null;
  return {'hasSpecial': true};
}

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final FormGroup _form;

  @override
  void initState() {
    super.initState();
    _form = FormGroup({
      'fullName': FormControl<String>(
        validators: [Validators.required, Validators.minLength(2)],
      ),
      'email': FormControl<String>(
        validators: [Validators.required, Validators.email],
      ),
      'password': FormControl<String>(
        validators: [
          Validators.required,
          Validators.minLength(8),
          _hasNumber,
          _hasSpecial,
        ],
      ),
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }
    await ref.read(authNotifierProvider.notifier).signUp(
          _form.control('email').value as String,
          _form.control('password').value as String,
          _form.control('fullName').value as String,
        );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => context.showSnackBar(
        e.toString().replaceAll('AuthException: ', ''),
        isError: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ReactiveForm(
            formGroup: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Preencha seus dados para começar',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                AuthTextField(
                  formControlName: 'fullName',
                  label: 'Nome completo',
                  hint: 'Seu nome',
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  formControlName: 'email',
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  formControlName: 'password',
                  label: 'Senha',
                  hint: 'Mínimo 8 caracteres',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.lock_outlined,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Criar conta'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem conta? ',
                      style: context.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Entrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
