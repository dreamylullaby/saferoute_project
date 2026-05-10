import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../widgets/input_Field.dart';
import '../widgets/submit_Button.dart';
import '../../data/datasources/user_Remote_Datasource.dart';
import '../../domain/usecases/login_User.dart';
import '../../data/repositories/user_repository.impl.dart';

/// Pantalla de inicio de sesión.
/// Permite login con correo/contraseña o con Google Sign-In.
/// Usa clean architecture: datasource → repository → use case.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey           = GlobalKey<FormState>();
  final _passwordFocus     = FocusNode();
  bool isLoading           = false;

  void _mostrarError(String mensaje) => mostrarError(context, mensaje);

  @override
  void dispose() {
    _passwordFocus.dispose();
    super.dispose();
  }

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

      // Registrar FCM token después del login exitoso (fire and forget)
      datasource.registrarFcmToken();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Usuario o contraseña incorrectos. Verifica tus datos e intenta de nuevo.');
    }

    setState(() => isLoading = false);
  }

  void loginWithGoogle() async {
    // Mostrar diálogo de aceptación de términos antes de continuar
    final acepta = await _mostrarDialogoTerminos();
    if (acepta != true) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: usar popup
        final googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // Android/iOS: usar google_sign_in nativo
        // signOut previo para forzar el selector de cuentas
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => isLoading = false);
          return; // El usuario canceló
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final idToken = await userCredential.user!.getIdToken();
      final datasource = UserRemoteDatasource();

      await datasource.loginWithGoogle(idToken: idToken!);
      datasource.registrarFcmToken();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e, stack) {
      debugPrint('=== ERROR GOOGLE LOGIN ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      if (!mounted) return;
      _mostrarError('No se pudo iniciar sesión con Google. Intenta de nuevo.');
    }

    setState(() => isLoading = false);
  }

  Future<bool?> _mostrarDialogoTerminos() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    bool aceptado = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shield_outlined, size: 40, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Términos y Condiciones', style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Para continuar con Google, debes aceptar nuestros términos.', style: GoogleFonts.inter(fontSize: 13, color: subColor), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 24, height: 24, child: Checkbox(
                  value: aceptado,
                  onChanged: (v) => setDialogState(() => aceptado = v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                )),
                const SizedBox(width: 8),
                Expanded(child: RichText(text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 12, color: subColor, height: 1.4),
                  children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'Términos y Condiciones',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => _mostrarTextoLegal(ctx, 'Términos y Condiciones'),
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de Privacidad',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => _mostrarTextoLegal(ctx, 'Política de Privacidad'),
                    ),
                  ],
                ))),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: subColor, fontWeight: FontWeight.w500)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: aceptado ? () => Navigator.pop(ctx, true) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Continuar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _mostrarTextoLegal(BuildContext parentCtx, String titulo) {
    final isDark = Theme.of(parentCtx).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;

    showDialog(
      context: parentCtx,
      builder: (ctx) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(children: [
              Expanded(child: Text(titulo, style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.bold, color: textColor))),
              IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF475569) : AppColors.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n'
                'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n'
                'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.\n\n'
                'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.\n\n'
                'At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga.',
                style: GoogleFonts.inter(fontSize: 14, color: textColor, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
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

                  Image.asset('assets/Logo_CivicTrackIO_Color.png', height: 90),
                  const SizedBox(height: 16),

                  Text(
                    'CivicTrackIO',
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
                          label: 'Correo o usuario',
                          icon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          controller: passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => login(),
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
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 0),

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
