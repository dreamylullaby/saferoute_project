import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/forgot_password_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _dominiosPermitidos = ['gmail.com', 'outlook.com', 'hotmail.com'];

  @override
  void dispose() { _correoCtrl.dispose(); super.dispose(); }

  String? _validarCorreo(String? v) {
    if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!regex.hasMatch(v.trim())) return 'Formato de correo inválido';
    final dominio = v.trim().split('@').last.toLowerCase();
    if (!_dominiosPermitidos.contains(dominio)) return 'Solo se permiten: ${_dominiosPermitidos.join(', ')}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textM = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final textS = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final borderC = isDark ? const Color(0xFF475569) : AppColors.border;

    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Recuperar contraseña')),
        body: Consumer<ForgotPasswordProvider>(builder: (_, prov, __) {
          if (prov.enviado) return _estadoExito(textM, textS);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(key: _formKey, child: Column(children: [
              const SizedBox(height: 24),
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_reset_outlined, size: 40, color: AppColors.primary)),
              const SizedBox(height: 20),
              Text('¿Olvidaste tu contraseña?', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: textM)),
              const SizedBox(height: 8),
              Text('Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.', style: GoogleFonts.inter(fontSize: 14, color: textS, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              TextFormField(
                controller: _correoCtrl, keyboardType: TextInputType.emailAddress, validator: _validarCorreo,
                style: GoogleFonts.inter(fontSize: 14, color: textM),
                decoration: InputDecoration(labelText: 'Correo electrónico', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC))),
              ),
              if (prov.error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(prov.error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: prov.loading ? null : () { if (_formKey.currentState!.validate()) prov.enviarEnlace(_correoCtrl.text.trim()); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: prov.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Enviar enlace', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              )),
            ])),
          );
        }),
      ),
    );
  }

  Widget _estadoExito(Color textM, Color textS) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.zonaSegura.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.zonaSegura)),
      const SizedBox(height: 20),
      Text('¡Enlace enviado!', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: textM)),
      const SizedBox(height: 10),
      Text('Revisa tu correo, te enviamos el enlace para restablecer tu contraseña.', style: GoogleFonts.inter(fontSize: 14, color: textS, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Volver al inicio de sesión', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w500))),
    ])));
  }
}
