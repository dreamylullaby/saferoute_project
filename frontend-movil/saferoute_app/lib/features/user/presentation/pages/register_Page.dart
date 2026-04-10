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
  const RegisterPage({super.key});

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

  void _mostrarError(String mensaje) => mostrarError(context, mensaje);

  void _mostrarExito(String mensaje, {VoidCallback? alCerrar}) =>
      mostrarExito(context, mensaje, alCerrar: alCerrar);

  void register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final datasource = UserRemoteDatasource();
      final repository = UserRepositoryImpl(datasource);
      final registerUsecase = RegisterUser(repository);

      final user = await registerUsecase(
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

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  'assets/Logo_SafeRoute_Oficial_Color.png',
                  height: 80,
                ),
                const SizedBox(height: 12),

                Text(
                  'SAFEROUTE',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea tu cuenta',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
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
                          if (v != passwordController.text)
                            return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SubmitButton(
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
