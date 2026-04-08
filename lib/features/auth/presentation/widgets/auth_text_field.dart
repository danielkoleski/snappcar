import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.formControlName,
    required this.label,
    super.key,
    this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.validationMessages,
  });

  final String formControlName;
  final String label;
  final String? hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Map<String, String Function(Object)>? validationMessages;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField<String>(
      formControlName: widget.formControlName,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureText = !_obscureText),
              )
            : null,
      ),
      validationMessages: widget.validationMessages ??
          {
            ValidationMessage.required: (_) => 'Campo obrigatório',
            ValidationMessage.email: (_) => 'E-mail inválido',
            ValidationMessage.minLength: (error) {
              final e = error as Map;
              return 'Mínimo ${e['requiredLength']} caracteres';
            },
            'hasNumber': (_) => 'Deve conter ao menos um número',
            'hasSpecial': (_) => 'Deve conter ao menos um caractere especial',
          },
    );
  }
}
