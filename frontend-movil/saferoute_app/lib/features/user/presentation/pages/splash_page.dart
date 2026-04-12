import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../services/auth_storage.dart';
import '../../../../../features/user/data/datasources/user_remote_datasource.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnim  = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Espera la animación + un momento, luego verifica token
    Future.delayed(const Duration(milliseconds: 2200), _navigate);
  }

  Future<void> _navigate() async {
    final token = await AuthStorage.getValidToken();
    if (!mounted) return;

    // Mostrar modal de permisos si nunca se ha mostrado
    final prefs = await SharedPreferences.getInstance();
    final yaRespondio = prefs.getBool('permisos_respondido') ?? false;

    if (!yaRespondio && mounted) {
      await _mostrarModalPermisos();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, token != null ? '/home' : '/login');
  }

  Future<void> _mostrarModalPermisos() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Mantente seguro', style: GoogleFonts.montserrat(
            fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'SafeRoute necesita acceso a notificaciones y ubicación para alertarte cuando haya un hurto cerca de ti.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('permisos_respondido', true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Más tarde',
                style: GoogleFonts.inter(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('permisos_respondido', true);
              if (ctx.mounted) Navigator.pop(ctx);
              await _pedirPermisos();
            },
            child: Text('Activar ahora',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _pedirPermisos() async {
    // 1. Permiso de notificaciones
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // 2. Permiso de ubicación
    final locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    // 3. Registrar FCM token en el backend si hay sesión activa
    await UserRemoteDatasource().registrarFcmToken();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/Logo_SafeRoute_Oficial_Color.png',
                    height: 110,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SAFEROUTE',
                    style: GoogleFonts.montserrat(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantente seguro, mantente informado.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2.5,
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
