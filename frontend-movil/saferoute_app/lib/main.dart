import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/user/presentation/pages/login_page.dart';
import 'features/user/presentation/pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB-t6b7plOtez2YQGhSbJdYg3myQhH_JuI",
      authDomain: "saferouteapp2026.firebaseapp.com",
      projectId: "saferouteapp2026",
      storageBucket: "saferouteapp2026.firebasestorage.app",
      messagingSenderId: "455431452213",
      appId: "1:455431452213:web:c53fe2b4a26145a0b4637c",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
