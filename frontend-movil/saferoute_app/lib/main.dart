import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_theme.dart';
import 'services/auth_storage.dart';
import 'features/user/presentation/pages/splash_page.dart';
import 'features/user/presentation/pages/login_page.dart';
import 'features/user/presentation/pages/register_page.dart';
import 'features/user/presentation/pages/report_Incidente_page.dart';
import 'features/user/presentation/pages/home_page.dart';
import 'features/user/presentation/pages/mapa_page.dart';
import 'features/user/presentation/pages/alerta_config_page.dart';
import 'features/user/presentation/pages/perfil_page.dart';
import 'features/user/presentation/pages/estadisticas_page.dart';
import 'features/user/presentation/pages/ranking_zonas_page.dart';
import 'features/user/presentation/pages/mis_reportes_page.dart';
import 'features/user/presentation/pages/forgot_password_page.dart';
import 'features/user/presentation/pages/reset_password_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final ValueNotifier<RemoteMessage?> notificacionPendiente = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  try {
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
  } catch (_) {}
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await AuthStorage.clear();
  runApp(const MyApp());
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthStorage.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.data == null) { WidgetsBinding.instance.addPostFrameCallback((_) { Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false); }); return const SizedBox.shrink(); }
        return child;
      },
    );
  }
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
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashPage(),
        routes: {
          '/login':           (context) => const LoginPage(),
          '/register':        (context) => const RegisterPage(),
          '/home':            (context) => AuthGuard(child: const MapaPage()),
          '/reportar':        (context) => AuthGuard(child: const ReportIncidentePage()),
          '/mapa':            (context) => AuthGuard(child: const MapaPage()),
          '/alertas':         (context) => AuthGuard(child: const AlertaConfigPage()),
          '/perfil':          (context) => AuthGuard(child: const PerfilPage()),
          '/estadisticas':    (context) => AuthGuard(child: const EstadisticasPage()),
          '/ranking':         (context) => AuthGuard(child: const RankingZonasPage()),
          '/mis-reportes':    (context) => AuthGuard(child: const MisReportesPage()),
          '/forgot-password': (context) => const ForgotPasswordPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/reset-password')) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'] ?? '';
            return MaterialPageRoute(builder: (_) => ResetPasswordPage(token: token));
          }
          return null;
        },
      ),
    );
  }
}
