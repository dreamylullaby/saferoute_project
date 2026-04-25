import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme.dart';
import '../../data/datasources/user_remote_datasource.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _ds         = UserRemoteDatasource();
  final _correoCtrl = TextEditingController();

  bool    _cargando = false;
  bool    _enviado  = false;
  String? _error;

  Future<void> _enviar() async {
    final correo = _correoCtrl.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }

    setState(() { _cargando = true; _error = null; });
    try {
      await _ds.forgotPassword(correo);
      if (!mounted) return;
      setState(() { _enviado = true; _cargando = false; });
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
    _correoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _enviado ? _confirmacion() : _formulario(),
      ),
    );
  }

  Widget _confirmacion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Color(0xFF166534), size: 32),
        ),
        const SizedBox(height: 20),
        Text('Revisa tu correo',
            style: GoogleFonts.montserrat(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        const SizedBox(height: 12),
        Text(
          'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/reset-password'),
            child: const Text('Tengo un código'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver al login'),
        ),
      ],
    );
  }

  Widget _formulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub)),
        const SizedBox(height: 24),
        TextField(
          controller: _correoCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email_outlined),
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
            onPressed: _cargando ? null : _enviar,
            child: _cargando
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar enlace'),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al login'),
          ),
        ),
      ],
    );
  }
}
