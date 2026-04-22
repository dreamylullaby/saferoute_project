import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// Botones flotantes del mapa: toggle calor, dark mode, ubicación y FAB registrar.
class MapFloatingButtons extends StatelessWidget {
  const MapFloatingButtons({
    super.key,
    required this.modoCalor,
    required this.isDark,
    required this.onToggleCalor,
    required this.onToggleDark,
    required this.onMiUbicacion,
    required this.onRegistrar,
  });

  final bool modoCalor;
  final bool isDark;
  final VoidCallback onToggleCalor;
  final VoidCallback onToggleDark;
  final VoidCallback onMiUbicacion;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Stack(children: [
      // FAB registrar hurto
      Positioned(
        bottom: 24 + bottomPadding, right: 16,
        child: FloatingActionButton.extended(
          onPressed: onRegistrar,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
          label: Text('Registrar hurto',
              style: GoogleFonts.montserrat(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
      // Columna de botones laterales
      Positioned(
        bottom: 90 + bottomPadding, right: 16,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _boton(
            icon: modoCalor ? Icons.location_on : Icons.whatshot_rounded,
            color: modoCalor ? AppColors.altoRiesgo : Colors.white,
            iconColor: modoCalor ? Colors.white : AppColors.textMain,
            onTap: onToggleCalor,
            tooltip: modoCalor ? 'Ver marcadores' : 'Ver mapa de calor',
          ),
          const SizedBox(height: 10),
          _boton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            iconColor: isDark ? Colors.amber : AppColors.textMain,
            onTap: onToggleDark,
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
          ),
          const SizedBox(height: 10),
          _boton(
            icon: Icons.my_location,
            color: Colors.white,
            iconColor: AppColors.primary,
            onTap: onMiUbicacion,
            tooltip: 'Mi ubicación',
          ),
        ]),
      ),
    ]);
  }

  Widget _boton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}
