import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_theme.dart';
import '../providers/forgot_password_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  String? _validarPass(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  String? _validarConfirm(String? v) {
    if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
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
        appBar: AppBar(title: const Text('Nueva contraseña')),
        body: Consumer<ForgotPasswordProvider>(builder: (_, prov, __) {
          if (prov.restablecido) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Contraseña actualizada correctamente'), backgroundColor: AppColors.zonaSegura, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            });
            return const SizedBox.shrink();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(key: _formKey, child: Column(children: [
              const SizedBox(height: 24),
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_outline, size: 40, color: AppColors.primary)),
              const SizedBox(height: 20),
              Text('Crea tu nueva contraseña', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: textM)),
              const SizedBox(height: 8),
              Text('Ingresa y confirma tu nueva contraseña para restablecer el acceso a tu cuenta.', style: GoogleFonts.inter(fontSize: 14, color: textS, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              TextFormField(
                controller: _passCtrl, obscureText: !_showPass, validator: _validarPass,
                style: GoogleFonts.inter(fontSize: 14, color: textM),
                decoration: InputDecoration(labelText: 'Nueva contraseña', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _showPass = !_showPass)), filled: true, fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC))),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl, obscureText: !_showConfirm, validator: _validarConfirm,
                style: GoogleFonts.inter(fontSize: 14, color: textM),
                decoration: InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _showConfirm = !_showConfirm)), filled: true, fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderC))),
              ),
              if (prov.error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(prov.error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                onPressed: prov.loading ? null : () { if (_formKey.currentState!.validate()) prov.restablecerPassword(widget.token, _passCtrl.text); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: prov.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Restablecer contraseña', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              )),
            ])),
          );
        }),
      ),
    );
  }
}
