import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saferoute_app/features/user/data/datasources/user_Remote_Datasource.dart';

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
        title: const Text("SafeRoute"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () => cerrarSesion(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenido a SafeRoute",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.report),
              label: const Text("Registrar hurto"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pushNamed(context, '/reportar'),
            ),
          ],
        ),
      ),
    );
  }
}
