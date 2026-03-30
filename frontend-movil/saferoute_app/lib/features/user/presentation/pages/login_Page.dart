import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final datasource = UserRemoteDatasource();

      final repository = UserRepositoryImpl(datasource);

      final loginUsecase = LoginUser(repository);

      final user = await loginUsecase(
        correo: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Credenciales incorrectas")));
    }

    setState(() {
      isLoading = false;
    });
  }

  void loginWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final googleProvider = GoogleAuthProvider();

      final userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final idToken = await userCredential.user!.getIdToken();

      final datasource = UserRemoteDatasource();
      final user = await datasource.loginWithGoogle(idToken: idToken!);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al iniciar con Google")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const Text(
                  "SAFEROUTE",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                InputField(
                  controller: emailController,
                  label: "Correo",
                  icon: Icons.email,
                ),

                const SizedBox(height: 15),

                InputField(
                  controller: passwordController,
                  label: "Contraseña",
                  icon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 25),

                SubmitButton(
                  text: "Iniciar sesión",
                  onPressed: login,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 15),

                SubmitButton(
                  text: "Continuar con Google",
                  onPressed: loginWithGoogle,
                  isGoogle: true,
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/register");
                  },

                  child: const Text("Crear cuenta"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
