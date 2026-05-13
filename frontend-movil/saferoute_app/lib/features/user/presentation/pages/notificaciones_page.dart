import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/app_theme.dart';
import '../../../../../services/auth_storage.dart';

/// Pantalla de notificaciones/mensajes del usuario.
/// Muestra respuestas a solicitudes de eliminación y mensajes del sistema.
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});
  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final token = await AuthStorage.getToken();
      final res = await http.get(
        Uri.parse('$base/api/perfil/mensajes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _notificaciones = List<Map<String, dynamic>>.from(body['data'] ?? []);
          _cargando = false;
        });
      }
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _marcarLeida(String id) async {
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final token = await AuthStorage.getToken();
      await http.patch(
        Uri.parse('$base/api/perfil/mensajes/$id/leer'),
        headers: {'Authorization': 'Bearer $token'},
      );
      setState(() {
        final idx = _notificaciones.indexWhere((n) => n['id'] == id);
        if (idx != -1) _notificaciones[idx]['leida'] = true;
      });
    } catch (_) {}
  }

  Future<void> _marcarTodas() async {
    try {
      final base = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
      final token = await AuthStorage.getToken();
      await http.patch(
        Uri.parse('$base/api/perfil/mensajes/leer-todas'),
        headers: {'Authorization': 'Bearer $token'},
      );
      setState(() {
        for (var n in _notificaciones) { n['leida'] = true; }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : AppColors.textMain;
    final subColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final sinLeer = _notificaciones.where((n) => n['leida'] != true).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notificaciones', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        actions: [
          if (sinLeer > 0)
            TextButton(
              onPressed: _marcarTodas,
              child: Text('Marcar todas', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.notifications_off_outlined, size: 48, color: subColor),
                    const SizedBox(height: 12),
                    Text('No tienes notificaciones', style: GoogleFonts.inter(fontSize: 14, color: subColor)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notificaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = _notificaciones[index];
                      final leida = n['leida'] == true;
                      final tipo = n['tipo'] ?? 'sistema';
                      final icono = tipo == 'solicitud_aprobada'
                          ? Icons.check_circle_outline
                          : tipo == 'solicitud_rechazada'
                              ? Icons.cancel_outlined
                              : Icons.info_outline;
                      final iconColor = tipo == 'solicitud_aprobada'
                          ? const Color(0xFF16A34A)
                          : tipo == 'solicitud_rechazada'
                              ? const Color(0xFFDC2626)
                              : AppColors.primary;

                      return GestureDetector(
                        onTap: () { if (!leida) _marcarLeida(n['id']); },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: leida ? cardColor : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: leida
                                ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                : AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(icono, color: iconColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n['titulo'] ?? '', style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: leida ? FontWeight.w400 : FontWeight.w600, color: textColor)),
                              const SizedBox(height: 4),
                              Text(n['mensaje'] ?? '', style: GoogleFonts.inter(
                                fontSize: 13, color: subColor, height: 1.4)),
                              const SizedBox(height: 8),
                              Text(_formatFecha(n['fecha_creacion']), style: GoogleFonts.inter(
                                fontSize: 11, color: subColor)),
                            ])),
                            if (!leida)
                              Container(
                                width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatFecha(String? fecha) {
    if (fecha == null) return '';
    try {
      final d = DateTime.parse(fecha);
      final ahora = DateTime.now();
      final diff = ahora.difference(d);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }
}
