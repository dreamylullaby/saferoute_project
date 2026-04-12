import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/app_theme.dart';
import 'services/auth_storage.dart';
import 'features/user/presentation/pages/splash_page.dart';
import 'features/user/presentation/pages/login_page.dart';
import 'features/user/presentation/pages/register_page.dart';
import 'features/user/presentation/pages/report_Incidente_page.dart';
import 'features/user/presentation/pages/home_page.dart';
import 'features/user/presentation/pages/mapa_page.dart';
import 'features/user/presentation/pages/alerta_config_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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

  // Borrar token al iniciar la app para forzar login siempre
  await AuthStorage.clear();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) => MaterialApp(
        title: 'SafeRoute',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const SplashPage(),
        routes: {
          '/login':    (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home':     (context) => const MapaPage(),
          '/reportar': (context) => const ReportIncidentePage(),
          '/mapa':     (context) => const MapaPage(),
          '/alertas':  (context) => const AlertaConfigPage(),
        },
      ),
    );
  }
}
