import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../widgets/submit_button.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/repositories/user_repository.impl.dart';
import '../../domain/usecases/register_user.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final usernameController = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cuenta creada. Bienvenido ${user.username}")),
      );
      Navigator.pushReplacementNamed(context, '/login');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "SAFEROUTE",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: usernameController,
                  validator: (v) => (v == null || v.isEmpty) ? "Campo obligatorio" : null,
                  decoration: InputDecoration(
                    labelText: "Nombre de usuario",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 15),

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

                const SizedBox(height: 15),

                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Campo obligatorio";
                    if (v != passwordController.text) return "Las contraseñas no coinciden";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Confirmar contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 25),

                SubmitButton(
                  text: "Registrarse",
                  onPressed: register,
                  isLoading: isLoading,
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
