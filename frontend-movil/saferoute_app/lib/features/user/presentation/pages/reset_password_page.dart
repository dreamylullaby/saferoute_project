import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme.dart';
import '../../data/datasources/user_remote_datasource.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _ds           = UserRemoteDatasource();
  final _tokenCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool    _cargando   = false;
  bool    _verPass    = false;
  bool    _verConfirm = false;
  String? _error;

  String? _validar() {
    if (_tokenCtrl.text.trim().isEmpty)   return 'Ingresa el código del correo';
    if (_passCtrl.text.length < 8)        return 'La contraseña debe tener al menos 8 caracteres';
    if (_passCtrl.text != _confirmCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _cambiar() async {
    final err = _validar();
    if (err != null) { setState(() => _error = err); return; }

    setState(() { _cargando = true; _error = null; });
    try {
      await _ds.resetPassword(_tokenCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Inicia sesión.'),
          backgroundColor: AppColors.zonaSegura,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error    = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa el código que recibiste en tu correo y tu nueva contraseña.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub),
            ),
            const SizedBox(height: 24),

            // Token
            TextField(
              controller: _tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Código de recuperación',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Nueva contraseña
            TextField(
              controller: _passCtrl,
              obscureText: !_verPass,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirmar contraseña
            TextField(
              controller: _confirmCtrl,
              obscureText: !_verConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verConfirm = !_verConfirm),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _cambiar,
                child: _cargando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Cambiar contraseña'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
