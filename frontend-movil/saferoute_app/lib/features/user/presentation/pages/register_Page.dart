import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../widgets/input_Field.dart';
import '../widgets/submit_Button.dart';
import '../../data/datasources/user_Remote_Datasource.dart';
import '../../data/repositories/user_repository.impl.dart';
import '../../domain/usecases/register_User.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onRegister});

  final Future<dynamic> Function({
    required String username,
    required String correo,
    required String password,
  })? onRegister;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _aceptaTerminos = false;

  void _mostrarError(String mensaje) => mostrarError(context, mensaje);

  void _mostrarExito(String mensaje, {VoidCallback? alCerrar}) =>
      mostrarExito(context, mensaje, alCerrar: alCerrar);

  void register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaTerminos) {
      _mostrarError('Debes aceptar los Términos y Condiciones y la Política de Privacidad para registrarte.');
      return;
    }
    setState(() => isLoading = true);

    try {
      final registerFn = widget.onRegister ??
          ({
            required String username,
            required String correo,
            required String password,
          }) async {
            final datasource = UserRemoteDatasource();
            final repository = UserRepositoryImpl(datasource);
            final registerUsecase = RegisterUser(repository);

            return await registerUsecase(
              username: username,
              correo: correo,
              password: password,
            );
          };

      final user = await registerFn(
        username: usernameController.text.trim(),
        correo: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      _mostrarExito(
        'Bienvenido, ${user.username}. Tu cuenta fue creada exitosamente.',
        alCerrar: () => Navigator.pushReplacementNamed(context, '/login'),
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid,
              AppColors.gradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            key: const Key('register_scroll'),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset(
                    'assets/Logo_CivicTrackIO_Color.png',
                    height: 80,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CivicTrackIO',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea tu cuenta',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        InputField(
                          controller: usernameController,
                          label: 'Nombre de usuario',
                          icon: Icons.person_outline,
                          extraValidator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Campo obligatorio';
                            if (value.length < 3) return 'El apodo debe tener mínimo 3 caracteres';
                            if (value.length > 20) return 'El apodo debe tener máximo 20 caracteres';
                            if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
                              return 'Solo se permiten letras, números, punto y guion bajo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          controller: emailController,
                          label: 'Correo',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          controller: passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordConfirm: true,
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          controller: confirmController,
                          label: 'Confirmar contraseña',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          extraValidator: (v) {
                            if (v != passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTerminosCheckbox(),
                        const SizedBox(height: 24),
                        SubmitButton(
                          key: const Key('btn_registrarse'),
                          text: 'Registrarse',
                          onPressed: register,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminosCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            key: const Key('chk_terminos'),
            value: _aceptaTerminos,
            onChanged: (v) => setState(() => _aceptaTerminos = v ?? false),
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            children: [
              Text(
                'Acepto los ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSub,
                  height: 1.4,
                ),
              ),
              GestureDetector(
                key: const Key('link_terminos'),
                onTap: () => _mostrarTextoLegal('Términos y Condiciones'),
                child: Text(
                  'Términos y Condiciones',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' y la ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSub,
                  height: 1.4,
                ),
              ),
              GestureDetector(
                key: const Key('link_privacidad'),
                onTap: () => _mostrarTextoLegal('Política de Privacidad'),
                child: Text(
                  'Política de Privacidad',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarTextoLegal(String titulo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF475569) : AppColors.border,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n\n'
                  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n'
                  'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textColor,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}