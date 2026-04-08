import 'package:flutter/material.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';

const _dominiosValidos = ['gmail.com', 'outlook.com', 'hotmail.com'];

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordConfirm; // activa validación de contraseña fuerte
  final String? Function(String?)? extraValidator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword        = false,
    this.isPasswordConfirm = false,
    this.extraValidator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscure = true;
  // Guardamos el último error de correo para mostrarlo en modal al perder foco
  String? _correoError;

  String? _validarCorreo(String value) {
    if (!value.contains('@')) return 'Correo inválido';
    final partes = value.split('@');
    if (partes.length != 2 || partes[1].isEmpty) return 'Correo inválido';
    if (!_dominiosValidos.contains(partes[1].toLowerCase())) {
      return 'El dominio no es válido. Por favor usa: ${_dominiosValidos.join(', ')}';
    }
    return null;
  }

  String? _validarPassword(String value) {
    if (value.length < 5) return 'La contraseña debe tener al menos 5 caracteres';
    final tieneEspecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value);
    if (!tieneEspecial) return 'Debe incluir al menos un carácter especial (!@#\$%...)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        // Cuando pierde foco y hay error de correo, muestra modal
        if (!hasFocus && widget.label == 'Correo' && _correoError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) mostrarError(context, _correoError!);
          });
        }
      },
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.isPassword && _obscure,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        keyboardType: widget.label == 'Correo'
            ? TextInputType.emailAddress
            : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obligatorio';
          if (widget.label == 'Correo') {
            _correoError = _validarCorreo(value.trim());
            if (_correoError != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) mostrarError(context, _correoError!);
              });
              return _correoError;
            }
            return null;
          }
          if (widget.isPasswordConfirm) return _validarPassword(value);
          return widget.extraValidator?.call(value);
        },
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, color: AppColors.primary),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSub,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}
