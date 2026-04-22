import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../main.dart' show notificacionPendiente;

/// Servicio de notificaciones push para el mapa.
/// No recibe BuildContext — usa messengerKey para SnackBars
/// y onNavigateToReport callback para navegación.
class MapNotifService {
  MapNotifService({
    required this.messengerKey,
    required this.onNavigateToReport,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final void Function(LatLng) onNavigateToReport;

  void initialize() {
    FirebaseMessaging.onMessage.listen(_mostrarBanner);
    FirebaseMessaging.onMessageOpenedApp.listen(_navegarDesdeNotificacion);
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _navegarDesdeNotificacion(msg);
    });
    notificacionPendiente.addListener(_onPendiente);
  }

  void dispose() {
    notificacionPendiente.removeListener(_onPendiente);
  }

  void _onPendiente() {
    final msg = notificacionPendiente.value;
    if (msg != null) {
      _navegarDesdeNotificacion(msg);
      notificacionPendiente.value = null;
    }
  }

  void _mostrarBanner(RemoteMessage message) {
    final tipo   = message.data['tipo_hurto'] ?? 'hurto';
    final barrio = message.data['barrio']     ?? 'zona cercana';
    final lat    = double.tryParse(message.data['latitud']  ?? '');
    final lng    = double.tryParse(message.data['longitud'] ?? '');

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.altoRiesgo,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${tipo[0].toUpperCase()}${tipo.substring(1)} en $barrio',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        action: lat != null && lng != null
            ? SnackBarAction(
                label: 'Ver', textColor: Colors.white,
                onPressed: () => onNavigateToReport(LatLng(lat, lng)),
              )
            : null,
      ),
    );
  }

  void _navegarDesdeNotificacion(RemoteMessage message) {
    final lat = double.tryParse(message.data['latitud']  ?? '');
    final lng = double.tryParse(message.data['longitud'] ?? '');
    if (lat != null && lng != null) {
      onNavigateToReport(LatLng(lat, lng));
    }
  }
}
