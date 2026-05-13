import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/app_theme.dart';

/// AppBar flotante del mapa con título, badge de filtros y botón hamburguesa.
class MapAppBar extends StatelessWidget {
  const MapAppBar({
    super.key,
    required this.hayFiltros,
    required this.conteoFiltros,
    required this.totalReportes,
    required this.onMenuTap,
    this.notificacionesSinLeer = 0,
    this.onNotificacionesTap,
  });

  final bool hayFiltros;
  final int conteoFiltros;
  final int totalReportes;
  final VoidCallback onMenuTap;
  final int notificacionesSinLeer;
  final VoidCallback? onNotificacionesTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final barText = isDark ? Colors.white : AppColors.textMain;

    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Stack(children: [
                      Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: hayFiltros
                              ? AppColors.primary
                              : (isDark ? const Color(0xFF334155) : AppColors.background),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.menu,
                            color: hayFiltros ? Colors.white : barText, size: 20),
                      ),
                      if (hayFiltros)
                        Positioned(
                          top: 0, right: 4,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(
                                color: AppColors.error, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('$conteoFiltros',
                                style: GoogleFonts.inter(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                    ]),
                  ),
                  Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('CivicTrackIO',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold, fontSize: 15,
                          color: isDark ? Colors.white : AppColors.primaryDark)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$totalReportes reportes',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Campana de notificaciones
            GestureDetector(
              onTap: onNotificacionesTap,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Stack(children: [
                  Center(child: Icon(Icons.notifications_outlined, color: barText, size: 22)),
                  if (notificacionesSinLeer > 0)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('$notificacionesSinLeer',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
