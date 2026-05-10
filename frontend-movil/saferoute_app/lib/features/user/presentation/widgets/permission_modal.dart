import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/app_theme.dart';

/// Muestra los modales de permisos (ubicación y notificaciones) después del login.
/// Verifica el estado real de los permisos del sistema.
/// Flujo: ubicación → notificaciones (secuencial).
class PermissionModals {
  /// Punto de entrada: verifica qué permisos faltan y muestra los modales.
  /// Llamar después de navegar al mapa (post-login).
  static Future<void> mostrarSiNecesario(BuildContext context) async {
    // Verificar permiso real de ubicación
    final locationPermission = await Geolocator.checkPermission();
    final needsLocation = locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever;

    if (needsLocation && context.mounted) {
      await _mostrarModalUbicacion(context);
    }

    // Verificar permiso real de notificaciones
    final notifSettings = await FirebaseMessaging.instance.getNotificationSettings();
    final needsNotif = notifSettings.authorizationStatus == AuthorizationStatus.notDetermined ||
        notifSettings.authorizationStatus == AuthorizationStatus.denied;

    if (needsNotif && context.mounted) {
      await _mostrarModalNotificaciones(context);
    }
  }

  static Future<void> _mostrarModalUbicacion(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (dialogContext, _, __) => Center(
        child: _PermissionCard(
          icon: Icons.location_on_rounded,
          iconBgColor: AppColors.primary,
          titulo: 'Permitir acceso a ubicación',
          descripcion:
              'CIVICTRACKIO usa tu ubicación para mostrar incidentes cercanos y permitir reportes precisos.',
          textoBoton: 'Permitir acceso a ubicación',
          textoCancelar: 'Ahora no',
          onAceptar: () async {
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            await Geolocator.requestPermission();
          },
          onCancelar: () {
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    );
  }

  static Future<void> _mostrarModalNotificaciones(
      BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (dialogContext, _, __) => Center(
        child: _PermissionCard(
          icon: Icons.notifications_active_rounded,
          iconBgColor: AppColors.primary,
          titulo: 'Activar notificaciones',
          descripcion:
              'Recibe alertas en tiempo real cuando se reporte un hurto cerca de tu ubicación.',
          textoBoton: 'Activar notificaciones',
          textoCancelar: 'Ahora no',
          onAceptar: () async {
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            await FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
          },
          onCancelar: () {
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
        ),
      ),
    );
  }
}


/// Card visual para los modales de permisos.
/// Diseño limpio con ícono circular, título, descripción y dos acciones.
class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String titulo;
  final String descripcion;
  final String textoBoton;
  final String textoCancelar;
  final VoidCallback onAceptar;
  final VoidCallback onCancelar;

  const _PermissionCard({
    required this.icon,
    required this.iconBgColor,
    required this.titulo,
    required this.descripcion,
    required this.textoBoton,
    required this.textoCancelar,
    required this.onAceptar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón cerrar
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: onCancelar,
                child: Icon(Icons.close, color: subColor, size: 22),
              ),
            ),

            // Ícono circular
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBgColor, size: 40),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              titulo,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Descripción
            Text(
              descripcion,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: subColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botón principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAceptar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  textoBoton,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Texto cancelar
            GestureDetector(
              onTap: onCancelar,
              child: Text(
                textoCancelar,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
