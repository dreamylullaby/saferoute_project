import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/app_dialog.dart';
import '../../data/datasources/perfil_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// Página de perfil del usuario.
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, this.datasource});
  final PerfilDatasource? datasource;
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late final PerfilDatasource _datasource =
      widget.datasource ?? PerfilDatasource();
  Map<String, dynamic>? _perfil;
  bool _cargando = true;
  bool _editando = false;
  bool _ubicacionActiva = true;
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _verificarUbicacion();
  }

  Future<void> _verificarUbicacion() async {
    final permiso = await Geolocator.checkPermission();
    if (mounted) {
      setState(() => _ubicacionActiva =
          permiso == LocationPermission.always || permiso == LocationPermission.whileInUse);
    }
  }

  Future<void> _cargarPerfil() async {
    try {
      final data = await _datasource.getPerfil();
      if (!mounted) return;
      setState(() {
        _perfil = data;
        _usernameController.text = data['username'] ?? '';
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      mostrarError(context, 'No se pudo cargar el perfil');
    }
  }

  Future<void> _guardarCambios() async {
    try {
      await _datasource.updatePerfil(
        username: _usernameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _editando = false);
      await _cargarPerfil();
      mostrarExito(context, 'Perfil actualizado correctamente');
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleNotificaciones(bool valor) async {
    if (!valor) {
      // Mostrar advertencia antes de desactivar
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desactivar notificaciones'),
          content: const Text(
            'Se recomienda mantener las notificaciones activas para recibir alertas de seguridad en tiempo real.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desactivar')),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    try {
      await _datasource.toggleNotificaciones(valor);
      if (!mounted) return;
      setState(() => _perfil!['notificaciones_activas'] = valor);
    } catch (e) {
      if (!mounted) return;
      mostrarError(context, 'Error al actualizar notificaciones');
    }
  }

  Future<void> _toggleUbicacion(bool valor) async {
    if (valor) {
      // Activar: pedir permiso
      final permiso = await Geolocator.requestPermission();
      if (mounted) {
        setState(() => _ubicacionActiva =
            permiso == LocationPermission.always || permiso == LocationPermission.whileInUse);
      }
    } else {
      // Desactivar: advertir y abrir configuración del dispositivo
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desactivar ubicación'),
          content: const Text(
            'El mapa y las alertas de proximidad quedarán limitados sin acceso a tu ubicación. '
            'Se abrirá la configuración del dispositivo para gestionar el permiso.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abrir configuración')),
          ],
        ),
      );
      if (confirmar == true) {
        try {
          await Geolocator.openAppSettings();
        } catch (_) {
          // openAppSettings no soportado en web — solo funciona en Android/iOS
          if (mounted) {
            mostrarError(context, 'Esta función solo está disponible en dispositivos móviles');
          }
        }
        // Re-verificar después de volver de configuración
        await Future.delayed(const Duration(seconds: 1));
        await _verificarUbicacion();
      }
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    await UserRemoteDatasource().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  /// Genera iniciales del username (máximo 2 caracteres).
  String _getIniciales(String nombre) {
    if (nombre.isEmpty) return '?';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSub;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (!_editando && _perfil != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
              onPressed: () => setState(() => _editando = true),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _perfil == null
              ? Center(child: Text('Error al cargar perfil', style: GoogleFonts.inter(color: mutedColor)))
              : SingleChildScrollView(
                  child: Column(children: [
                    // Header con gradiente
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientMid, AppColors.gradientEnd],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(children: [
                        // Avatar con iniciales
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            _getIniciales(_perfil!['username'] ?? '?'),
                            style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_perfil!['username'] ?? 'Sin apodo',
                            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(_perfil!['correo'] ?? '',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _perfil!['rol'] == 'admin' ? 'Administrador' : 'Usuario',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ]),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Sección editable
                        if (_editando) ...[
                          Text('Editar perfil', style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textMain)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Apodo',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: OutlinedButton(
                              onPressed: () => setState(() => _editando = false),
                              child: const Text('Cancelar'),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton(
                              onPressed: _guardarCambios,
                              child: const Text('Guardar'),
                            )),
                          ]),
                          const SizedBox(height: 24),
                        ],

                        // Info de cuenta
                        _seccionTitulo('Información de cuenta'),
                        const SizedBox(height: 8),
                        _infoTile(Icons.calendar_today_outlined, 'Miembro desde',
                            _perfil!['fecha_creacion'] != null
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_perfil!['fecha_creacion']).toLocal())
                                : 'N/A',
                            cardColor, mutedColor),

                        const SizedBox(height: 24),

                        // Configuración
                        _seccionTitulo('Configuración'),
                        const SizedBox(height: 8),
                        _toggleTile(
                          Icons.notifications_outlined, 'Notificaciones',
                          'Recibir alertas de hurtos cercanos',
                          _perfil!['notificaciones_activas'] ?? true,
                          _toggleNotificaciones, cardColor, mutedColor,
                        ),
                        _toggleTile(
                          Icons.location_on_outlined, 'Ubicación',
                          'Necesaria para el mapa y alertas',
                          _ubicacionActiva,
                          _toggleUbicacion, cardColor, mutedColor,
                        ),

                        const SizedBox(height: 24),

                        // Seguridad
                        _seccionTitulo('Seguridad'),
                        const SizedBox(height: 8),
                        _actionTile(Icons.lock_outline, 'Cambiar contraseña',
                            'Próximamente', null, cardColor, mutedColor, enabled: false),

                        const SizedBox(height: 24),

                        // Cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cerrarSesion,
                            icon: const Icon(Icons.logout, color: AppColors.error),
                            label: Text('Cerrar sesión',
                                style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
    );
  }

  Widget _seccionTitulo(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3,
        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSub));
  }

  Widget _infoTile(IconData icon, String label, String value, Color cardColor, Color mutedColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain)),
        ])),
      ]),
    );
  }

  Widget _toggleTile(IconData icon, String label, String subtitle, bool value,
      void Function(bool) onChanged, Color cardColor, Color mutedColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFE2E8F0) : AppColors.textMain)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String label, String subtitle,
      VoidCallback? onTap, Color cardColor, Color mutedColor, {bool enabled = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = enabled
        ? (isDark ? const Color(0xFFE2E8F0) : AppColors.textMain)
        : mutedColor;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(children: [
          Icon(icon, size: 20, color: enabled ? AppColors.primary : mutedColor),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
          ])),
          if (!enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6)),
              child: Text('Pronto', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: mutedColor)),
            )
          else
            Icon(Icons.chevron_right, color: mutedColor, size: 20),
        ]),
      ),
    );
  }
}
