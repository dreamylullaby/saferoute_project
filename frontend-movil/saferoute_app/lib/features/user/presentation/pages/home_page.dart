import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';
import '../../data/datasources/user_Remote_Datasource.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await UserRemoteDatasource().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeRoute'),
        actions: [
          TextButton.icon(
            onPressed: () => cerrarSesion(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset('assets/Logo_SafeRoute_Oficial_Color.png', height: 80),
            const SizedBox(height: 20),

            Text(
              'Bienvenido a SafeRoute',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mantente seguro, mantente informado.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.report_outlined),
                label: const Text('Registrar hurto'),
                onPressed: () => Navigator.pushNamed(context, '/reportar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
