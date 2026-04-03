import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Modal animado reutilizable para errores, éxitos e info.
Future<void> mostrarModal(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required IconData icono,
  required Color colorIcono,
  String textoBoton = 'Entendido',
  VoidCallback? alCerrar,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, anim, __, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (_, __, ___) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
      titlePadding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      actionsPadding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
      icon: Icon(icono, color: colorIcono, size: 48),
      title: Text(
        titulo,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        textAlign: TextAlign.center,
      ),
      content: Text(
        mensaje,
        style: GoogleFonts.inter(color: AppColors.textSub, fontSize: 14, height: 1.5),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 180,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              alCerrar?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              textoBoton,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}

void mostrarError(BuildContext context, String mensaje) => mostrarModal(
      context,
      titulo: 'Error',
      mensaje: mensaje,
      icono: Icons.error_outline_rounded,
      colorIcono: AppColors.error,
    );

void mostrarExito(BuildContext context, String mensaje, {VoidCallback? alCerrar}) =>
    mostrarModal(
      context,
      titulo: '¡Listo!',
      mensaje: mensaje,
      icono: Icons.check_circle_outline_rounded,
      colorIcono: const Color(0xFF22C55E),
      textoBoton: 'Continuar',
      alCerrar: alCerrar,
    );
