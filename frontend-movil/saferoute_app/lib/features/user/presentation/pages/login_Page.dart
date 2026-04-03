import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../widgets/input_field.dart';
import '../widgets/submit_button.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../domain/usecases/login_user.dart';
import '../../data/repositories/user_repository.impl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey           = GlobalKey<FormState>();
  bool isLoading           = false;

  void _mostrarError(String mensaje) => mostrarError(context, mensaje);

  void login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final datasource   = UserRemoteDatasource();
      final repository   = UserRepositoryImpl(datasource);
      final loginUsecase = LoginUser(repository);

      await loginUsecase(
        correo: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo.');
    }

    setState(() => isLoading = false);
  }

  void loginWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final googleProvider = GoogleAuthProvider();
      final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      final idToken        = await userCredential.user!.getIdToken();
      final datasource     = UserRemoteDatasource();

      await datasource.loginWithGoogle(idToken: idToken!);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo iniciar sesión con Google. Intenta de nuevo.');
    }

    setState(() => isLoading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Image.asset('assets/Logo_SafeRoute_Oficial_Color.png', height: 90),
                  const SizedBox(height: 16),

                  Text(
                    'SAFEROUTE',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
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
                        ),
                        const SizedBox(height: 24),
                        SubmitButton(
                          text: 'Iniciar sesión',
                          onPressed: login,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 12),
                        SubmitButton(
                          text: 'Continuar con Google',
                          onPressed: loginWithGoogle,
                          isGoogle: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text(
                      '¿No tienes cuenta? Crear cuenta',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
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
}
